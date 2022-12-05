#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use OpenSRF::Utils::Logger q/$logger/;
use OpenSRF::AppSession;
use OpenSRF::Application;
use Time::HiRes qw/time/;

# Testing with Evergreen storage service by default.
# I tried using opensrf.settings but for reasons I didn't investigate
# hitting opensrf.settings with lots of requests lead to failures.
#my $test_service = "open-ils.storage";
my $test_service = "opensrf.settings";

my $iterations = 500;

my $small_echo_data = <<TEXT;
    1237012938471029348170197908709870987098709870987098709809870987098709870
    1237012938471029348170197908709870987098709870987098709809870987098709870
TEXT

my $large_echo_data = join('', <DATA>);
my $med_echo_data = substr($large_echo_data, length($large_echo_data) / 2);

my $osrf_config = '/openils/conf/opensrf_core.xml';
my $ops = GetOptions(
    'osrf-config=s' => \$osrf_config,
);

OpenSRF::System->bootstrap_client(config_file => $osrf_config);

sub echoloop {
    my $data = shift;
    my $ses = shift || OpenSRF::AppSession->create($test_service);
    my $connected = shift || 0;

    my $start = time;
    for (0..$iterations) {
        my $resp = $ses->request('opensrf.system.echo', $data)->gather(1);

        if ($resp eq $data) {
            print "+";
        } else {
            warn "Got bad data: $resp\n";
        }
    }

    my $dur = time - $start;
    my $avg = $dur / $iterations;
    print sprintf(
        " Connected=$connected Size=%d\tTotal Duration: %0.3f\tAvg Duration: %0.4f\n", 
        length($data), $dur, $avg
    );
}

echoloop($small_echo_data);
echoloop($med_echo_data);
echoloop($large_echo_data);

# Connected sessions

my $ses = OpenSRF::AppSession->create($test_service);

$ses->connect;
echoloop($small_echo_data, $ses, 1);
$ses->disconnect;

$ses->connect;
echoloop($med_echo_data, $ses, 1);
$ses->disconnect;

$ses->connect;
echoloop($large_echo_data, $ses, 1);
$ses->disconnect;

__DATA__
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
asodifuyasoidufyasoidfuyasodfiuyasdofiuaysdofiuaysdfoiasuyfaosidufyasdoifyasoi
