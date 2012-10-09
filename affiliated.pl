# Usage:
# /affiliated - (in channel window) operate on current channel.
# /affiliated #channel - operate on #channel on the currently active server.
# /affiliated cancel - cancel current operation.

# This script is written rather badly, it will produce garbage output
# at the end of the line if there are less than 10 results. Also, expect
# it to take quite some time to run on large channels (30+ seconds.)

use strict;
use Irssi;
use Data::Dumper;
use vars qw($VERSION %IRSSI);

$VERSION = "0.96";
%IRSSI = (
	authors		=> "mr_flea",
	contact		=> "mrflea\@gmail.com",
	name		=> "Affiliated",
	description	=> "Finds affiliated channels by counting how many users in one channel are in other channels.",
	license		=> "BSD",
	url			=> "http://www.phantomflame.com/",
	changed		=> "Thu 06 May 2010 02:42:40 PM PDT"
);

Irssi::settings_add_bool('misc', 'affiliated_verbose', 1);
Irssi::settings_add_int('misc', 'affiliated_max_users', 20);

# This script uses a bunch of global variables because I am very lazy. :(
my @nicklist;
my %channels;
my %stats;
my $currserver = 0;

sub printmsg {
	Irssi::print("Affiliated: " . $_[0], MSGLEVEL_CLIENTCRAP);
}

sub clear {
	@nicklist = ();
	%channels = {};
	%stats = {};
	$currserver = 0;
}

sub affiliated {
	my ($data, $server, $channel) = @_;

	if (!$server) {
		printmsg("Please connect to a server.");
		return;
	}

	$data =~ s/\s+//g;
	if (lc($data) eq 'cancel') {
		printmsg("Operation cancelled.");
		if ($currserver) {
			print_results();
		} else {
			clear();
		}
		return;
	}

	if ($currserver) {
		printmsg("There is already an operation in progress! "
			. "Please wait until it is finished.");
		return;
	}

	$currserver = $server;

	if ($data) {
		my $chan = $server->channel_find($data);
		if ($chan)
		{
			$channel = $chan;
		} else {
			populate_nicklist($data);
			return;
		}
	}

	if (!defined $channel || $channel->{chat_type} ne "IRC") {
		printmsg("Give me something to work with! (Supply a channel name "
			. "or run in a channel window.)");
		return;
	}

	if (!$channel->{synced}) {
		# Hopefully this doesn't happen...
		populate_nicklist($channel->name);
		return;
	}

	$stats{'channel'} = $channel->{name};
	foreach ($channel->nicks()) {
		push @nicklist, $_->{nick} unless (lc($_->{nick}) eq lc($currserver->{nick}));
	}
	start();
}

sub populate_nicklist {
	my ($channel) = @_;

	$stats{'channel'} = $channel;

	$currserver->redirect_event('who', 1, $channel, -1, '', {
			'event 352' => 'redir aff_who',
			'event 315'	=> 'redir aff_endwho',
			''			=> 'event empty'
		});
	$currserver->send_raw("WHO $channel");
}

sub receive_who {
	my ($server, $data) = @_;
	return if (!$currserver);

	my @user = split(/\s+/, $data);
	return if (lc($user[5]) eq lc($server->{nick})); # Exclude self.
	push @nicklist, $user[5];
}

sub increment_channel {
	my $chan = lc($_[0]);

	return if ($chan eq lc($stats{'channel'}) || $chan eq "*".lc($stats{'channel'}));

	if (defined $channels{$chan}) {
		$channels{$chan}++;
	} else {
		$channels{$chan} = 1;
	}
}

sub start {
	return if (!$currserver);

	if (@nicklist > Irssi::settings_get_int('affiliated_max_users')) {
		my @newlist;
		my $max = Irssi::settings_get_int('affiliated_max_users');
		for (my $i = 0; $i < $max; $i++) {
			push @newlist, splice(@nicklist, rand @nicklist, 1);
		}
		@nicklist = @newlist;
		$stats{'sample'} = 1;
	} else {
		$stats{'sample'} = 0;
	}

	printmsg("User list: " . join(', ', @nicklist). ".")
		if (Irssi::settings_get_bool('affiliated_verbose'));
	$stats{'opers'} = 0;
	$stats{'users'} = 0;

	if (Irssi::settings_get_bool('affiliated_verbose') && @nicklist > 5) {
		printmsg("Warning: The command may take a while to complete. "
			. "During this time, messages to/from the server will most likely incur a lag. "
			. "To cancel, use /affiliated cancel.");
	}

	do_next_whois();
}

sub do_next_whois {
	return if (!$currserver);

	if (!@nicklist) {
		print_results();
		return;
	}

	my $nick = shift @nicklist;

	$currserver->redirect_event('whois', 1, $nick, -1,
		'redir aff_whois_over', {
			'event 319'	=> 'redir aff_whois_channels',
			'event 313' => 'redir aff_whois_oper',
			'event 318' => 'redir aff_whois_over',
			'event 402' => 'redir aff_whois_over',
			'event 401' => 'redir aff_whois_over',
			''			=> 'event empty'
		});
	$currserver->send_raw("WHOIS $nick");
}

sub receive_whois_channels {
	my ($server, $data) = @_;
	return if (!$currserver);

	$stats{'users'}++;

	my $flags = quotemeta($currserver->get_nick_flags());

	my @chans = split(/\s/, (split(/:/, $data))[1]);

	for my $chan (@chans) {
		$chan =~ s/^(\*?)[$flags]/$1/;
		increment_channel($chan);
	}
}

sub receive_whois_oper {
	return if (!$currserver);
	$stats{'opers'}++;
}

sub print_results {
	return if (!$currserver);

	printmsg("Stats for $stats{'channel'}:");

	if ($stats{'sample'}) {
		printmsg("There were too many users in the channel, so a sample of "
			. $stats{'users'} . " users was taken.");
	} else {
		printmsg("These statistics represent " . $stats{'users'} . " unique nicks.");
	}

	if ($stats{'opers'} > ($stats{'users'} / 2)) {
		printmsg("You've stumbled upon a nest of opers! Run away!");
	}

	my @sorted = sort { $channels{$b} <=> $channels{$a} } keys %channels;

	my $top = "";

	for (my $i = 0; $i < 15; $i++) {
		last if (!@sorted);
		my $chan = shift @sorted;

		$top .= "$chan: $channels{$chan}; ";
	}

	if (!$top) {
		printmsg("No channels!");
	} else {
		$top =~ s/\; $/./;

		printmsg("Top channels: " . $top);
	}	

	clear();
}

Irssi::command_bind('affiliated', 'affiliated');
Irssi::signal_add('redir aff_who', 'receive_who');
Irssi::signal_add('redir aff_endwho', 'start');
Irssi::signal_add('redir aff_whois_channels', 'receive_whois_channels');
Irssi::signal_add('redir aff_whois_oper', 'receive_whois_oper');
Irssi::signal_add('redir aff_whois_over', 'do_next_whois');
