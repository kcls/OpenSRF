package OpenSRF::Transport::SlimJabber;
use base qw/OpenSRF::Transport/;

=head2 OpenSRF::Transport::SlimJabber

Implements the Transport interface for providing the system with appropriate
classes for handling transport layer messaging

=cut


sub get_peer_client { return "OpenSRF::Transport::SlimJabber::PeerConnection"; }

1;
