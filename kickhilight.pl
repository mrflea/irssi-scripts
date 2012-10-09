use strict;
use Irssi;

use vars qw($VERSION %IRSSI);

# Changelog:
# Version 1.2
#	*	No longer beeps when away if beep_when_away is disabled.
# Version 1.1
# 	No change history prior to this.

$VERSION = "1.2";
%IRSSI = (
	authors		=> "mr_flea",
	contact		=> "mrflea\@gmail.com",
	name		=> "kickhilight",
	description	=> "Hilight when kicked or killed.",
	license		=> "BSD",
	url			=> "http://www.phantomflame.com/",
	changed		=> "Mon 05 Apr 2010 08:25:19 PM PDT"
);

Irssi::settings_add_bool('misc', 'kickhilight_beep', 1);

sub event_kicked {
	my ($server, $channel, $nick, $kicker, $addr, $reason) = @_;

	return if ($server->{nick} ne $nick);

	my $window = $server->window_find_item($channel);
	$window->activity(4);
	do_beep($server);
}

sub event_killed {
	my ($server, $args, $killer, $address) = @_;

	my $status = $server->window_find_closest('(status)', Irssi::level2bits("ALL -MSGS")); # Search for the status window.
	if (!$status) {
		Irssi::print("Kickhilight: Fatal error when searching for status window! (using this message instead)",
			MSGLEVEL_CRAP | MSGLEVEL_HILIGHT);
		return;
	}
	$status->activity(4);
	do_beep($server);
}

sub do_beep {
	my $server = shift;

	return if (!Irssi::settings_get_bool('kickhilight_beep'));

	return if ($server->{usermode_away} && !Irssi::settings_get_bool('beep_when_away'));

	Irssi::command('beep');
}

Irssi::signal_add('message kick', 'event_kicked');
Irssi::signal_add('event kill', 'event_killed');
