# killreconnect.pl
#
# Reconnects if you're killed.
#
# This version based on the original version 1.0 by Garion,
# modified by mr_flea to add a setting to decide whether
# to reconect per-network.
# (autoreconnecting after a /kill is usually an even worse
# idea than rejoining after a /kick...)
# Basic usage: set killreconnect_networks with a list of
# network names to reconnect if /killed from.
# Example:
# killreconnect_networks = esper rizon

# Changes in version 1.1:
#	*	Added killreconnect_networks.

use strict;
use vars qw($VERSION %IRSSI);

use Irssi;

$VERSION = '1.1';
%IRSSI = (
    authors	=> 'mr_flea, Garion',
    contact	=> 'mrflea@gmail.com',
    name	=> 'killreconnect',
    description	=> 'Reconnects after a /KILL.',
    license	=> 'Public Domain',
    url		=> 'http://www.phantomflame.com/',
    changed	=> 'Mon 05 Apr 2010 08:25:54 PM PDT',
);

Irssi::settings_add_str('misc', 'killreconnect_networks', '');

#main event handler

Irssi::signal_add('event kill', 
  sub {
    my ($server, $args, $nick, $address) = @_;

	my $chatnet = lc($server->{chatnet});

	return if (!$chatnet);

	return if (lc(Irssi::settings_get_str('killreconnect_networks')) !~ /\b\Q$chatnet\E\b/);

    my $reason = $args;
    $reason =~ s/^.*://g;
    Irssi::print("You were killed by $nick ($reason)."); 
    Irssi::signal_stop(); 
  }
);

# Yes, that's all. Explanation:
# <cras> garion: you could probably do that more easily by preventing
#        irssi from seeing the kill signal
# <cras> garion: signal_add('event kill', sub { Irssi::signal_stop(); });
# <cras> garion: to prevent irssi from setting server->no_reconnect = TRUE

# EOF
