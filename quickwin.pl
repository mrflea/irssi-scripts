use strict;
use Irssi;
use vars qw($VERSION %IRSSI);
$VERSION = "1.0";
%IRSSI = (
	authors		=> "mr_flea",
	contact		=> "mrflea\@gmail.com",
	name		=> "quickwin.pl",
	description	=> "Switch windows with the command \"/number\".",
	license		=> "BSD",
	url			=> "http://www.phantomflame.com/",
	changed		=> "Sun 06 Jun 2010 07:19:36 PM PDT"
);

sub signal_send_cmd {
	my ($command, $server, $witem) = @_;

	if ($command =~ '^/(\d+)\s*$')
	{
		Irssi::command("window goto $1");
		Irssi::signal_stop();
	}
}

Irssi::signal_add('send command', 'signal_send_cmd');
