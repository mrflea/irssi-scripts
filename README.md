# irssi-scripts: a useful collection of scripts for the irssi IRC client

After lots of procrastinating, I'm finally publishing all of these.  Documentation and licenses can be found at the top of each file.  A short overview of each script follows below.

## General scripts

### scrollback.pl

scrollback.pl is designed as a clone of x-chat's log replay, with many enhancements.  Instead of using a separate file to store logs to be replayed on next start, scrollback.pl uses your existing autolog configuration.  This script goes one step further and even reformats your log timestamps to match the format of your display timestamps.

### quickwin.pl

quickwin.pl is designed for users with many windows to quickly switch between them.  Instead of typing /w <number>, you can type only /<number>.

### slashslash.pl

slashslash.pl lets you type "//somecommand" to instead send the text "/somecommand" to the current window.

### affiliated.pl

affiliated.pl whoises multiple users in a channel, then displays how many occurances of other channels were found in each whois.  It can be used for quickly showing which channels are affiliated with each other.

### kickhighlight.pl

kickhighlight.pl highlights a channel window when you're kicked from that channel.

### fruitkick.pl

fruitkick.pl kicks people with random fruit names.

## Scripts useful for channel operators

### helpchan.pl

helpchan.pl highlights a channel window when a user not sharing an op channel with you joins.  For example, if users join #mychannel for support, and all ops of #mychannel hang out in #mychannel-ops, helpchan.pl can be used to highlight the #mychannel window when someone comes by looking for help.

## Scripts useful for IRC operators

### killreconnect.pl

My modified version of killreconnect.pl which supports having a list of networks to reconnect to after being /killed, instead of automatically reconnecting to any network you're killed from.

### mwhois.pl

mwhois.pl takes any mask that /who would take, executes a /who with it, but instead of printing the /who results, executes a whois on each entry returned.

### xref.pl

xref.pl cross-references a user's hostmask with other users on the network.

### sping.pl

My modified version of sping.pl adds sub-second accuracy.
