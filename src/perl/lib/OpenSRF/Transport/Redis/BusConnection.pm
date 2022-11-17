package OpenSRF::Transport::Redis::BusConnection;
use strict;
use warnings;
use Redis;
use Net::Domain qw/hostfqdn/;
use OpenSRF::Utils::Logger qw/$logger/;

# domain doubles as the host of the Redis instance.
sub new {
    my ($class, $domain, $port, $username, $password, $max_queue) = @_;

    $logger->debug("Creating new bus connection $domain:$port user=$username");

    my $self = {
        domain => $domain || 'localhost',
        port => $port || 6379,
        username => $username,
        password => $password,
        max_queue => $max_queue
    };

    return bless($self, $class);
}

sub redis {
    my $self = shift;
    return $self->{redis};
}

sub connected {
    my $self = shift;
    return $self->redis ? 1 : 0;
}

sub domain {
    my $self = shift;
    return $self->{domain};
}

sub set_address {
    my ($self) = @_;

    my $address = sprintf(
        "opensrf:client:%s:%s:$$:%s", $self->{domain}, hostfqdn(), int(rand(10_000)));

    $self->{address} = $address;
}

sub address {
    my $self = shift;
    return $self->{address};
}

sub connect {
    my $self = shift;

    return 1 if $self->redis;

    my $domain = $self->{domain};
    my $port = $self->{port};
    my $username = $self->{username}; 
    my $password = $self->{password}; 
    my $address = $self->{address};

    $logger->debug("Redis client connecting: ".
        "domain=$domain port=$port username=$username address=$address");

    # On disconnect, try to reconnect every 100ms up to 60 seconds.
    my @connect_args = (
        server => "$domain:$port",
        reconnect => 60, 
        every => 100_000
    );

    $logger->debug("Connecting to bus: @connect_args");

    unless ($self->{redis} = Redis->new(@connect_args)) {
        die "Could not connect to Redis bus with @connect_args\n";
    }

    unless ($self->redis->auth($username, $password) eq 'OK') {
        die "Cannot authenticate with Redis instance user=$username\n";
    }

    $logger->debug("Auth'ed with Redis as $username OK : address=$address");

    # Each bus connection has its own stream / group for receiving
    # direct messages.  These streams/groups should not pre-exist.

    $self->redis->xgroup(   
        'create',
        $address,
        $address,
        '$',            # only receive new messages
        'mkstream'      # create this stream if it's not there.
    );

    return $self;
}

# Set del_stream to remove the stream and any attached consumer groups.
sub disconnect {
    my ($self, $del_stream) = @_;

    return unless $self->redis;

    $self->redis->del($self->address) if $del_stream;

    $self->redis->quit;

    delete $self->{redis};
}

sub send {
    my ($self, $dest_stream, $msg_json) = @_;
    
    $logger->internal("send(): to=$dest_stream : $msg_json");

    my @params = (
        $dest_stream,
        'NOMKSTREAM',
        'MAXLEN', 
        '~',                        # maxlen-ish
        $self->{max_queue},
        '*',                        # let Redis generate the ID
        'message',                  # gotta call it something 
        $msg_json
    );

    eval { $self->redis->xadd(@params) };

    if ($@) {
        $logger->error("XADD error: $@ : @params");
    }
}

# $timeout=0 means check for data without blocking
# $timeout=-1 means block indefinitely.
#
# $dest_stream defaults to our bus address.  Otherwise, it would be
# the service-level address.
sub recv {
    my ($self, $timeout, $dest_stream) = @_;
    $dest_stream ||= $self->address;

    $logger->debug("Waiting for content at: $dest_stream");

    my @block;
    if ($timeout) {
        # 0 means block indefinitely in Redis
        $timeout = 0 if $timeout == -1;
        $timeout *= 1000; # milliseconds
        @block = (BLOCK => $timeout);
    }

    my @params = (
        GROUP => $dest_stream,
        $self->address,
        COUNT => 1,
        @block,
        'NOACK',
        STREAMS => $dest_stream,
        '>' # new messages only
    );      

    my $packet;
    eval {$packet = $self->redis->xreadgroup(@params) };

    if ($@) {
        $logger->error("Redis XREADGROUP error: $@ : @params");
        return undef;
    }

    # Timed out waiting for data.
    return undef unless defined $packet;

    # TODO make this more self-documenting.  also, too brittle?
    # Also note at some point we may need to return info about the
    # recipient stream to the caller in case we are listening
    # on multiple streams.
    my $container = $packet->[0]->[1]->[0];
    my $msg_id = $container->[0];
    my $json = $container->[1]->[1];

    $logger->internal("recv() $json");

    return {
        msg_json => $json,
        msg_id => $msg_id
    };
}

sub flush_socket {
    my $self = shift;
    # Remove all messages from my address
    $self->redis->xtrim($self->address, 'MAXLEN', 0);
    return 1;
}

1;


