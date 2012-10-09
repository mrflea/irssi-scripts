use strict;
use Irssi;
use vars qw($VERSION %IRSSI);
$VERSION = "1.0";
%IRSSI = (
	authors		=> "mr_flea",
	contact		=> "mrflea\@gmail.com",
	name		=> "slashslash",
	description	=> "Turn \"//command\" into the channel message \"/command\".",
	license		=> "BSD",
	url			=> "http://www.phantomflame.com/",
	changed		=> "Sun 29 Nov 2009 09:20:24 PM PST"
);

sub signal_send_cmd {
	my ($command, $server, $witem) = @_;

	if ($command =~ '^//' && $witem)
	{
		$command =~ s'^/'';
		Irssi::signal_emit("send text", $command, $server, $witem);
		Irssi::signal_stop();
	}
}

Irssi::signal_add('send command', 'signal_send_cmd');
