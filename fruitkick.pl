use strict;
use Irssi;
use vars qw($VERSION %IRSSI);

$VERSION = "1.01";
%IRSSI = (
	authors		=> "mr_flea",
	contact		=> "mrflea\@gmail.com",
	name		=> "fruitkick.pl",
	description	=> "Uses a random fruit name as kick message.",
	license		=> "BSD",
	url			=> "http://www.phantomflame.com/",
	changed		=> "Thu 21 Jul 2011 04:48:36 PM UTC",
);

my @fruits = (
	'papaya',
	'banana',
	'apple',
	'tomato',
	'cranberry',
	'blueberry',
	'raspberry',
	'gooseberry',
	'watermelon',
	'boysenberry',
	'blackberry',
	'strawberry',
	'cherry',
	'orange',
	'lemon',
	'lime',
	'grape',
	'kiwi',
	'pomegranate',
	'guava',
	'grapefruit',
	'pineapple',
	'fig',
	'plum',
	'nectarine',
	'mango',
	'cantaloupe',
	'honeydew',
	'durian',
	'lychee',
	'pear',
	'apricot',
	'tangerine',
	'clementine',
);

sub cmd_fruitkick {
	my ($data, $server, $witem) = @_;

	my $kickee = (split(/ /, $data, 2))[0];

	$witem->command("KICK $kickee " . $fruits[rand $#fruits]);
}

Irssi::command_bind('fruitkick', 'cmd_fruitkick');
