use strict;
use Irssi;
use vars qw($VERSION %IRSSI);

# USAGE:
# Simply add a space-delimited list of network:channel:op-channel
# to the Irssi setting helpchan_channels.
# Example:
# helpchan_channels = esper:#dragonweyr:#secret_oper_channel esper:#help:#secret_oper_channel

# Changelog:
# Version 1.3:
#	*	Like 1.21, except actually works! (1-character bugfix.)
# Version 1.21:
#	*	Will no longer ping if they or us leave the help channel
#		before the timeout.
# Version 1.2:
#	*	Added helpchan_auto_whois, which will automatically whois
#		the user that triggers a hilight.
# Version 1.1:
#	*	Removed the (rather dumb) file-based method of configuration.
#		This pretty much constituted a major overhaul, the code will
#		probably be about 50% shorter.
#	*	Will now silently fail if you aren't in the op channel.
#	*	Won't beep if you are away and beep_when_away is disabled.
#	*	Will now work with multiple records per channel.
# Version 1.0:
#	Initial release.

$VERSION = "1.3";
%IRSSI = (
	authors		=> "mr_flea",
	contact		=> "mrflea\@gmail.com",
	name		=> "helpchan",
	description	=> "Hilight a channel when a non-operator joins.",
	license		=> "BSD",
	url			=> "http://www.phantomflame.com/",
	changed		=> "Wed 14 Apr 2010 02:42:16 PM PDT"
);

Irssi::settings_add_int('misc', 'helpchan_delay', 3);
Irssi::settings_add_bool('misc', 'helpchan_beep', 1);
Irssi::settings_add_str('misc', 'helpchan_channels', '');
Irssi::settings_add_bool('misc', 'helpchan_auto_whois', 0);

my @helpchannels = ();

# I hope to eventually submit an irssi patch that will generate a signal
# when a setting is changed, so this can be bound to that signal. For now,
# though, it's just called every time helpchan gets a join. It should
# execute relatively fast anyway.
sub build_chanlist {
	my @entries = split(/ /, Irssi::settings_get_str('helpchan_channels'));

	@helpchannels = ();

	foreach my $entry (@entries) {
		my @info = split(/:/, $entry);
		next if (@info < 3 || !$info[0] || !$info[1] || !$info[2]);
		my $item = {
			network	=> $info[0],
			channel	=> $info[1],
			opchan	=> $info[2]
		};
		push(@helpchannels, $item);
	}
}

sub message_join {
	my ($server, $channel, $nick, $address) = @_;

	build_chanlist();

	my @records;

	foreach my $rec (@helpchannels) {
		# Is this record for the right network?
		next if (lc($rec->{network}) != lc($server->{chatnet}));

		# Is this record for the right channel?
		next if (lc($rec->{channel}) ne lc($channel));

		# Are we in the operator channel?
		next if (!$server->channel_find($rec->{opchan}));

		# We have located the correct record.
		push (@records, $rec);
	}
	
	return if (!@records);

	my $delay = Irssi::settings_get_int('helpchan_delay');
	my $inforef = [$server, $nick, \@records];

	if (!$delay) {
		join_opcheck($inforef);
	} else {
		Irssi::timeout_add_once($delay * 1000, 'join_opcheck', $inforef);
	}
}

sub join_opcheck {
	my ($server, $nick, $records) = @{(shift)};

	foreach my $rec (@{$records}) {
		# Make sure we and them are still in the help channel.
		my $helpchan = $server->channel_find($rec->{channel});
		last if (!$helpchan || !$helpchan->nick_find($nick));

		# Check the operator channel for the nick.
		my $opchan = $server->channel_find($rec->{opchan});
		next if (!$opchan || $opchan->nick_find($nick));

		# At this point, we have confirmed that they are not an operator.
		my $witem = $server->window_find_item($rec->{channel});
		return if (!$witem); # This should not happen in any case, but may be possible.
		$witem->activity(4);
		do_beep($server) if (Irssi::settings_get_bool('helpchan_beep'));
		$server->command("whois $nick") if (Irssi::settings_get_bool('helpchan_auto_whois'));
	}
}

Irssi::signal_add('message join', 'message_join');

sub do_beep {
	my $server = shift;

	return if (!Irssi::settings_get_bool('kickhilight_beep'));

	return if ($server->{usermode_away} && !Irssi::settings_get_bool('beep_when_away'));

	Irssi::command('beep');
}
