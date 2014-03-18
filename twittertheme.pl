#!/usr/bin/perl -w
#
# twittertheme.pl
#
# Colorizes Twitter channel components (configured for Bitlbee-style). 
# Removes redundant long-format URLs.
#
# Note: Will remove existing color formatting on message part.
#
# Can be configured to colorize the following components:
# * [alphanum]
# * RT @usertag:
# * @usertag
# * #hashtag
# * http(s)://url
#
# Can be configured to remove URLs that:
# * Appear inside brackets <...>
#
use strict;
use warnings;
use vars qw($VERSION %IRSSI);
use Irssi;

#use Data::Dumper;
#$Data::Dumper::Indent = 1;

$VERSION = ".1";
%IRSSI = (
	authors	    => "Sam Stoller",
	contact     => "snstoller\@gmail.com",
	name	    => "Twitter Color",
	description => "Assign colors to tweet components",
	license	    => "Public Domain",
	url	    => "http://irssi.org/",
	changed     => "2014-03-01"
);


sub sig_public {
	my ($server, $msg, $nick, $address, $target) = @_;	
	#return if (!$server->ischannel(Irssi::settings_get_str('test_channel')));
	#return if ($target != Irssi::settings_get_str('test_channel'));	
	my $new_str = '';

	# remove formatting and colors (has to be done, sorry!)
	$msg =~ s/\x03\d?\d?(,\d?\d?)?|\x02|\x1f|\x16|\x06|\x07//g;

	# Tokenize msg string, iterate over components
	my @words = $msg =~ /(\S+)/g;	
	foreach (@words) {
		
		# Bitlbee-style Tweet #'s, eg: [f9], [04]->[ca]
		if (/\[[0-9A-Za-z]{2}(\->[0-9A-Za-z]{2})?\]/) {
			$new_str .= chr(3).'15'.$_; # gray
		
		# Retweets, eg: RT @usertag:
		} elsif (/RT/) {
			$new_str .= chr(3).'03'.$_; # green

		# @usertags
		} elsif (/^@.+/) {
			$new_str .= chr(3).'06'.$_; # magenta
		
		# #hashtags
		} elsif (/^#.+/) {
			$new_str .= chr(3).'07'.$_; # orange

		# http URLs
		} elsif (/^https?:\/\//) {
			$new_str .= chr(3).'14'.$_; # dark gray

		# URLs in <>
		} elsif (/<[\w#~\.\/\-]+>/) {
			#$new_str .= 'embedurl ';
		
		# All other text
		} else {
			$new_str .= chr(3).'00'.$_; # white
		}
		$new_str .= ' ';
	}

	#Irssi::print($new_str, MSGLEVEL_CLIENTCRAP);	
	
	# Keep the signal going
	Irssi::signal_continue($server, $new_str, $nick, $address, $target);
}
Irssi::signal_add('message public', 'sig_public');
Irssi::settings_add_str($IRSSI{'name'}, 'test_channel', '#twitter_');
