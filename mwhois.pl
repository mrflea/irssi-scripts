# Usage:
# /mwhois <mask or other garbage usually passed to /who>
# Behaves like /who, but returns whois results! Amazing!
# Alternatively, to /whois all users in a channel except
# yourself, run /mwhois in the channel window without
# any arguments.

# This is based on another script of mine, affiliated.pl.

use strict;
use Irssi;
use Data::Dumper;
use vars qw($VERSION %IRSSI);

$VERSION = "1.1";
%IRSSI = (
	authors		=> "mr_flea",
	contact		=> "mrflea\@gmail.com",
	name		=> "mwhois.pl",
	description	=> "Runs a whois on all results from a WHO request.",
	license		=> "BSD",
	url			=> "http://www.phantomflame.com/",
	changed		=> "Mon 28 May 2012 02:46:31 AM UTC"
);

Irssi::settings_add_int('misc', 'mwhois_max_users', 8);

# This script uses a bunch of global variables because I am very lazy. :(
my @nicklist;
my $currserver = 0;

sub printmsg {
	Irssi::print("mwhois: " . $_[0], MSGLEVEL_CLIENTCRAP);
}

sub clear {
	@nicklist = ();
	$currserver = 0;
}

sub mwhois {
	my ($data, $server, $channel) = @_;

	if (!$server) {
		printmsg("Please connect to a server.");
		return;
	}

	$data =~ s/^\s+//g;
	$data =~ s/\s+$//g;
#	if (lc($data) eq 'cancel') {
#		printmsg("Operation cancelled.");
#		if ($currserver) {
#			print_results();
#		} else {
#			clear();
#		}
#		return;
#	}

	if ($currserver) {
		printmsg("There is already an operation in progress! "
			. "Please wait until it is finished.");
		return;
	}

	$currserver = $server;

	if (!$data && (!defined $channel || $channel->{chat_type} ne "IRC")) {
		printmsg("Usage: /mwhois [mask] - execute WHOIS on all users returned by a " .
			"WHO for 'mask', or execute WHOIS on all users in the current channel.");
		return;
	}

	# This code looks pretty stupid but I'm so tired that I
	# can't figure out how to fix it. :(
	if ($data) {
		# Channel types #, &, !, +.
		if ($data =~ /^[#&!+]/) {
			my $chan = $server->channel_find($data);
			if ($chan)
			{
				$channel = $chan;
			} else {
				populate_nicklist($data);
				return;
			}
		} else {
			populate_nicklist($data);
			return;
		}
	}

	foreach ($channel->nicks()) {
		push @nicklist, $_->{nick} unless (lc($_->{nick}) eq lc($currserver->{nick}));
	}
	start();
}

sub populate_nicklist {
	my ($target) = @_;

	$currserver->redirect_event('who', 1, '', -1, '', {
			'event 352' => 'redir mwhois_who',
			'event 315'	=> 'redir mwhois_endwho',
			''			=> 'event empty'
		});
	$currserver->send_raw("WHO $target");
}

sub receive_who {
	my ($server, $data) = @_;
	return if (!$currserver);

	my @user = split(/\s+/, $data);
	return if (lc($user[5]) eq lc($server->{nick})); # Exclude self.
	push @nicklist, $user[5];
}

sub start {
	return if (!$currserver);

	if (@nicklist > Irssi::settings_get_int('mwhois_max_users')) {
		splice(@nicklist, Irssi::settings_get_int('mwhois_max_users') + 1, -1);
		printmsg("Truncating results to " .
			Irssi::settings_get_int('mwhois_max_users') . " users.");
	}

	if (@nicklist > 0)
	{
		printmsg("User list: " . join(', ', @nicklist). ".");
	} else {
		printmsg("No users match mask.");
	}

	foreach my $nick (@nicklist)
	{
		$currserver->command("whois $nick");
	}

	@nicklist = ();
	$currserver = 0;
}

Irssi::command_bind('mwhois', 'mwhois');
Irssi::signal_add('redir mwhois_who', 'receive_who');
Irssi::signal_add('redir mwhois_endwho', 'start');
