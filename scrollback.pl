# This script assumes that all windows will only have 1 window item. This is not always true.
# However, it will still work, just a bit strangely on windows with more than 1 window item in them.
# (Scrollback will be loaded for the first item, subsequent items will get no scrollback.)

# Please feel free to mail/IM me bugs/patches/comments/feature requests (if there is somehow something
# this doesn't have)/questions (after googling for yourself)/etc.

# Thanks to m0droid, smurf, eri, and Kojak for being wonderful beta testers.

# CHANGELOG
# Version .99
#	*	Added sb_query_only to only add scrollback to query windows.
#	*	Changed the message levels from NEVER, NO_ACT, CRAP, CLIENTCRAP to NEVER, NO_ACT.
#	*	Removed "ignore error" and "quiet" settings, added a "verbose" setting instead.
#	*	Removed "color" setting, to disable colors use a blank color code.
#	*	Removed checks to see if autolog is enabled. It now assumes autolog is enabled.
#	*	(minor) Moved "loaded XXX lines" to top.
# Version .98
# 	*	I don't remember what I had done prior to this release, so I'm going to say that it was
# 		the initial release.

use strict;
use Irssi;
use Irssi::TextUI;
use File::ReadBackwards;
use POSIX qw(strftime);
use POSIX::strptime qw(strptime);
use Carp;
use vars qw($VERSION %IRSSI %HELP);

$VERSION = "1.0";
%IRSSI = (
	authors		=> "mr_flea",
	contact		=> "mr_flea on irc.esper.net, mrflea\@gmail.com",
	name		=> "scrollback.pl",
	description	=> "Load scrollback to buffer (from log file) when a window is created.",
	license		=> "BSD",
	url			=> "http://www.phantomflame.com/",
	changed		=> "Mon 28 May 2012 03:13:13 AM UTC",
	modules		=> "POSIX::strptime File::ReadBackwards"
);
%HELP = (
	main		=> "Scrollback.pl settings help:
sb_lines: the maximum number of scrollback lines to print.
sb_query_only: whether to ignore channel windows when loading scrollback. (only load for query windows.)
sb_convert_timestamp: whether to convert timestamps from log format to scrollback format. Disable if you have frequent timestamp errors.
sb_color_code: the color code to apply, set to blank to disable. See: http://irssi.org/documentation/formats
sb_verbose: whether to display errors/etc. if something goes wrong. Probably only good for debugging."
);

Irssi::settings_add_int('scrollback', 'sb_lines', 100);
Irssi::settings_add_bool('scrollback', 'sb_query_only', 0);
Irssi::settings_add_str('scrollback', 'sb_color_code', '%K');
Irssi::settings_add_bool('scrollback', 'sb_convert_timestamp', 1);
Irssi::settings_add_bool('scrollback', 'sb_verbose', 0);

sub load_logs {
	my ($win, $witem) = @_;

	# Make sure we should be running.
	return if ($witem->{type} ne "CHANNEL" && $witem->{type} ne "QUERY");
	return if ($win->view->{buffer}->{lines_count}); # This checks to see if there's already scrollback in the window.
	# I couldn't come up with a better way to do it other than check to see if there are lines in the window. Sorry. :(
	# If you have a better way to do this, please email me. :)

	return if (Irssi::settings_get_bool('sb_query_only') && $witem->{type} eq "CHANNEL");

	# Miles of initialization fun here!
	# Reading miscellaneous settings first.
	my $lines = Irssi::settings_get_int('sb_lines');
	return if ($lines < 1);

	my $timestamp = "";
	if (Irssi::settings_get_bool('sb_convert_timestamp'))
	{
		$timestamp = Irssi::settings_get_str('timestamp_format') . " ";
	}
	my $logtimestamp = Irssi::settings_get_str('log_timestamp');

	# Compiling regex to ignore "log opened" and the like using the settings from irssi.
	my @ignore;
	for (qw/log_open_string log_close_string log_day_changed/) {
		my $temp = Irssi::settings_get_str($_);
		$temp =~ s/%.*$//;
		push(@ignore, "^\Q$temp\E") if ($temp);
	}
	@ignore = map { qr{$_} } @ignore;

	my $message = timestamp2regex(Irssi::settings_get_str('log_timestamp'));
	$message = qr{^($message)(.*)};

	my $verbose = Irssi::settings_get_bool('sb_verbose');

	# Start trying to find the file.
	my $fileloc = Irssi::settings_get_str('autolog_path');
	$fileloc =~ s/^\s+//;
	$fileloc =~ s/\s+$//;
	$fileloc =~ s/\$0/lc($witem->{name})/ge;
	$fileloc = strftime($fileloc, localtime);
	$fileloc = $witem->parse_special($fileloc);

	my @files = glob($fileloc);
	if (@files == 0 || !$files[0]) {
		# I literally spent hours trying to figure out why glob() would sometimes fail...
		sbprint($witem, "No scrollback available: no log file found.")
			if ($verbose);
		return;
	}
	$fileloc = $files[0];
	undef @files;
	if (not -e $fileloc) {
		sbprint($witem, "No scrollback available: no log file found.")
			if ($verbose);
		return;
	}
	if (!tie *F, 'File::ReadBackwards', $fileloc) {
		sbprint($witem, "Unable to provide scrollback due to error. Path: $fileloc. Error: $!.")
			if ($verbose);
		return;
	}

	# Done finding and opening the file. Time to do the actual work!
	my @buffer;
	while (<F>) {
		my $line = $_;
		chomp($line);

		# Decide if the line should be thrown out. (Log opened, log closed, date changed)
		my $zapped = 0;
		foreach (@ignore) {
			if ($line =~ $_) {
				$zapped = 1;
				last;
			}
		}
		if ($zapped) {
			next;
		}
		undef $zapped;

		# Change timestamps around.
		if ($timestamp && $line =~ $message) {
			my $text = $2;
			my @time = strptime($1, $logtimestamp);
			if (@time) {
				$line = strftime($timestamp, @time).$text;
			}
		}

		# Add to buffer, check to see if we are done.
		push @buffer, $line;
		if (@buffer >= $lines) {
			last;
		}
	}
	close(F);

	$witem->command('^window scroll off');

	sbprint($witem, "Loaded " . @buffer . " scrollback lines.");
	foreach (reverse @buffer) {
		sbprint($witem, $_);
	}

	$witem->command('^window scroll on');
	$witem->command('^scrollback end');
}

sub sbprint {
	# This sub gets called a lot, so I'm not sure if it's a good idea to have a bunch of
	# Irssi::settings_get_xxx calls in here, but it doesn't appear to be too slow...
	my $witem = shift;
	my $text = shift;

	# Irssi parses anything starting with '%' as a color code.
	# '%%' is the escape for literal '%'.
	$text =~ s/%/%%/g;

	# Do we need to apply a color?
	my $color = Irssi::settings_get_str('sb_color_code');
	if ($color)
	{
		$text = $color.$text."%N";
	}
	$witem->print($text, MSGLEVEL_CLIENTCRAP | MSGLEVEL_NEVER | MSGLEVEL_NO_ACT);
}

Irssi::signal_add_first("window item new", "load_logs");

# If they have set a log_theme, I assume they know what they're doing.
#if (!Irssi::settings_get_bool('sb_ignore_error') &&
#	Irssi::settings_get_str('theme') ne "default" &&
#	Irssi::settings_get_str('log_theme') eq "")
#{
#	Irssi::print("Warning: This script most likely only works with the default theme (unless configured). " .
#		"If I come up with a suitable solution, this warning may not appear in the future.");
#}

# This code may be replaced later with Regexp::Common::time. However, I think it works pretty well.
# The following formatting tokens are not supported by this, and it will croak: %c %E %O %x %X
# (However, I don't know anyone who uses those.)
sub timestamp2regex {
	my $exp = shift;
	my %metareplacements = (
		'D'	=> '%m/%d/%y',		'F'	=> '%Y-%m-%d',
		'r'	=> '%I:%M:%S %p',	'R'	=> '%H:%M',
		'T'	=> '%H:%M:%S'
	);
	my %replacements = (
		'a'	=> '[[:alpha:]]+',	'A'	=> '[[:alpha:]]+',
		'b'	=> '[[:alpha:]]+',	'B'	=> '[[:alpha:]]+',
		'd'	=> '\d{2}',			'e'	=> '[\d\s]\d',
		'g'	=> '\d{2}',			'G'	=> '\d{4}',
		'h'	=> '[[:alpha:]]+',	'H'	=> '\d{2}',
		'I'	=> '\d{2}',			'j'	=> '\d{3}',
		'k'	=> '[\d\s]\d',		'l'	=> '[\d\s]\d',
		'm'	=> '\d{2}',			'M'	=> '\d{2}',
		'p'	=> '[A-Za-z.]{2,}',	'P'	=> '[A-Za-z.]{2,}',
		's'	=> '\d+',			'S'	=> '\d{2}',
		't'	=> '\t',			'u'	=> '\d',
		'U'	=> '\d{2}',			'V'	=> '\d{2}',
		'w'	=> '\d',			'W'	=> '\d{2}',
		'y'	=> '\d{2}',			'Y'	=> '\d{4}',
		'z'	=> '[+-]\d{4}',		'Z'	=> '[[:alpha:]]*',
		'%'	=> '\%'
	);
	$exp = quotemeta($exp);
	$exp =~ s/\\\%\\?(.)/
		if (defined $metareplacements{$1}) {
			timestamp2regex($metareplacements{$1});
		} elsif (defined $replacements{$1}) {
			$replacements{$1};
		} else {
			croak "Unsupported or unrecognized timestamp format token: \%$1.";
		}/eg;
	return $exp;
}
