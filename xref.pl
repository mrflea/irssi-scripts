# Usage:
# /xref <nick>
# Extracts the hostname from whois or whowas, then lists
# users currently connected from that hostname.
# /xrefwhois <nick>
# Like the above, except it runs a WHOIS on each
# currently-connected user.

# This is based on another script of mine, mwhois.pl.

use strict;
use Irssi;
use Data::Dumper;
use vars qw($VERSION %IRSSI);

$VERSION = "1.01";
%IRSSI = (
	authors		=> "mr_flea",
	contact		=> "mrflea\@gmail.com",
	name		=> "xref.pl",
	description	=> "Checks to see if other users are connected from the same hostname.",
	license		=> "BSD",
	url			=> "http://www.phantomflame.com/",
	changed		=> "Mon 28 May 2012 02:44:56 AM UTC"
);

Irssi::settings_add_int('misc', 'xref_max_users', 8);

# This script uses a bunch of global variables because I am very lazy. :(
my $do_whois = 0;
my @nicklist = ();
my $target = 0;
my $currserver = 0;

sub printmsg {
	Irssi::print("xref: " . $_[0], MSGLEVEL_CLIENTCRAP);
}

sub clear {
	@nicklist = ();
	$currserver = 0;
}

sub xrefwhois {
	my ($data, $server) = @_;
	$do_whois = 1;

	xref($data, $server);
}

sub xrefnowhois {
	my ($data, $server) = @_;
	$do_whois = 0;

	xref($data, $server);
}

sub xref {
	my ($data, $server) = @_;

	if (!$server) {
		printmsg("Please connect to a server.");
		return;
	}

	$data =~ s/^\s+//g;
	$data =~ s/\s+$//g;

	if (!$data) {
		printmsg("Usage: /xref[whois] <nick> - cross-reference a currently-online or " .
			"recently-signed-off user with currently-connected users, by hostname.");
		printmsg("Use /xref <nick> for WHO output, and /xrefwhois <nick> for WHOIS output.");
		return;
	}

	if ($currserver) {
		printmsg("There is already an operation in progress. "
			. "Please wait until it is finished.");
		return;
	}

	$currserver = $server;
	$target = $data;

	$currserver->redirect_event('whois', 1, $target, 0, undef, {
		'event 311'	=>	'redir xref_whois',
		'event 401'	=>	'redir xref_try_whowas',
		''			=>	'event empty'
	});
	$currserver->send_raw("WHOIS $target");
}

sub try_whowas {
	return if (!$currserver);

	$currserver->redirect_event('whowas', 1, $target, 0, undef, {
		'event 314'	=>	'redir xref_whois',
		'event 406'	=>	'redir xref_failed',
		''			=>	'event empty'
	});
	$currserver->send_raw("WHOWAS $target 1");
}

sub failed {
	printmsg("No such user '$target' found.");
	clear();
}

sub get_whois {
	my ($server, $data) = @_;
	return if (!$currserver);

	my @user = split(/\s+/, $data);
	my $hostname = $user[3];

	if ($do_whois) {
		$currserver->redirect_event('who', 1, '', -1, undef, {
				'event 352' => 'redir xref_who',
				'event 315'	=> 'redir xref_endwho',
				''			=> 'event empty'
		});
		$currserver->send_raw("WHO $hostname");
	} else {
		$currserver->command("who $hostname");
		clear();
	}
}

sub get_who {
	my ($server, $data) = @_;
	return if (!$currserver);

	my @user = split(/\s+/, $data);
	push @nicklist, $user[5];
}

sub execute_whois {
	return if (!$currserver);

	if (@nicklist > 0)
	{
		printmsg("User list: " . join(', ', @nicklist). ".");
	} else {
		printmsg("No users connecting from same host as '$target'.");
	}

	if (@nicklist > Irssi::settings_get_int('xref_max_users')) {
		splice(@nicklist, Irssi::settings_get_int('xref_max_users') + 1, -1);
		printmsg("Truncating results to " .
			Irssi::settings_get_int('xref_max_users') . " users.");
	}

	foreach my $nick (@nicklist)
	{
		$currserver->command("whois $nick");
	}

	clear();
}

Irssi::command_bind('xref', 'xrefnowhois');
Irssi::command_bind('xrefwhois', 'xrefwhois');
Irssi::signal_add('redir xref_whois', 'get_whois');
Irssi::signal_add('redir xref_try_whowas', 'try_whowas');
Irssi::signal_add('redir xref_failed', 'failed');
Irssi::signal_add('redir xref_who', 'get_who');
Irssi::signal_add('redir xref_endwho', 'execute_whois');
