use strict;
use Irssi;
use vars qw($VERSION %IRSSI);

$VERSION = "0.10";
%IRSSI = (
	authors		=> "mr_flea",
	contact		=> "mrflea\@gmail.com",
	name		=> "foreachline.pl",
	description	=> "Execute a command for each line in a file.",
	license		=> "BSD",
	url			=> "http://www.phantomflame.com/",
	changed		=> "Thu 24 Oct 2013 08:23:49 AM UTC",
);

sub printmsg {
	Irssi::print("foreachline: $_[0]", MSGLEVEL_CLIENTCRAP);
}

sub cmd_foreachline {
	my ($data, $server, $witem) = @_;

	my ($file, $command) = split(/\s+/, $data, 2);

	if (not defined $file || not defined $command) {
		printmsg("Usage: /foreachline <file> <command|message>");
		return;
	}

	if ($command !~ /(?<!\%)\%s/) {
		printmsg("Error: At least one occurrence of '%s' should be present in the command.");
		return;
	}

	# We can handle ~/file, but not ~user/file.
	if ($file =~ /^~(?!\/)/) {
		printmsg("Error: Please provide an absolute file path.");
		return;
	}

	$file =~ s/^~\//$ENV{"HOME"}\//;

	if (not open(ITERFILE, "<", $file)) {
		printmsg("Couldn't open $file for reading.");
		return;
	}

	while (my $line = <ITERFILE>) {
		chomp($line);
		my $exec = $command;
		$exec =~ s/(?<!%)%s/$line/g;
		$exec =~ s/%%/%/g;

		Irssi::signal_emit("send command", $exec, $server, $witem);
	}

	close(ITERFILE);
}

Irssi::command_bind('foreachline', 'cmd_foreachline');
