use Irssi;
use Irssi::Irc;
use Time::HiRes qw(time);
use strict;

use vars qw($VERSION %IRSSI);
$VERSION = "1.0";
%IRSSI = (
        authors         => "mr_flea, Maciek \'fahren\' Freudenheim",
        contact         => "mr_flea\@esper.net, fahren\@bochnia.pl",
        name            => "Server Ping",
        description     => "/SPING [server] - checks latency between current server and [server]",
        license         => "GNU GPLv2 or later",
        changed         => "Fri 23 Apr 2010 11:58:14 AM PDT"
);

my %askping;

sub cmd_sping {
	my ($target, $server, $winit) = @_;
	
	$target = $server->{address} unless $target;
	$askping{$target} = time();
	$server->send_raw("PING $server->{address} $target");	
}

sub event_pong {
	my ($server, $args, $sname) = @_;
	
	Irssi::signal_stop() if ($askping{$sname});

	Irssi::print(">> $sname latency: " . sprintf("%.3f", (time() - $askping{$sname})) . "s");
	undef $askping{$sname};
}

Irssi::signal_add("event pong", "event_pong");
Irssi::command_bind("sping", "cmd_sping");
