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
# CHANGELOG
#
# v0.3a
#  - Settings
#     * Added settings for colors
#     * Added setting to toggle long url removal
# v0.2a
#  - Signals
#     * Added signal for own public
#     * Changed all signals to fire last
#     * Factored out signals / colorize routines
#  - Regex
#     * Modified <...> to be more greedy
#  - Features
#     * Added channel validation setting
#
#
use strict;
use warnings;
use vars qw($VERSION %IRSSI);
use Irssi;

#use Data::Dumper;
#$Data::Dumper::Indent = 2;

$VERSION = ".1";
%IRSSI = (
	authors	    => "Sam Stoller",
	contact     => "snstoller\@gmail.com",
	name	    => "Twitter Theme",
	description => "Assign colors to tweet message components",
	license	    => "Public Domain",
	url	    => "http://irssi.org/",
	changed     => "2014-03-01"
);

sub twt_colorize {
	my ($msg, $target) = @_;	
	my $new_str = '';

	# Validate current channel
	return $msg if (!is_enabled_chan($target));

	# Remove formatting and colors (too messy otherwise)
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
		} elsif (/<\S+\.\S+>/) {
			#$new_str .= 'embedurl ';
		
		# All other text
		} else {
			$new_str .= chr(3).'00'.$_; # white
		}
		$new_str .= ' ';
	}

	return $new_str;
}


#######################
# Command subroutines #
#######################

sub cmd_help {

}


######################
# Signal subroutines #
######################

sub sig_public {
        my ($server, $msg, $nick, $address, $target) = @_;
	
	$msg = twt_colorize($msg, $target);
	
	Irssi::signal_continue($server, $msg, $nick, $address, $target);
}

sub sig_own_public {
	my ($server, $msg, $target) = @_;

	$msg = twt_colorize($msg, $target);
	
	Irssi::signal_continue($server, $msg, $target);
}

sub sig_setup_changed {

	return if (is_all_chan());

	my $server = Irssi::active_server();
	foreach my $chan (split(/\s+/, Irssi::settings_get_str('twt_channels'))) {
		if (!$server->ischannel($chan)) {
			Irssi::print($chan.' is not a valid channel name.\n');
		}
	}
}


######################
# Helper subroutines #
######################

sub is_all_chan {
	return 1 if (Irssi::settings_get_str('twt_channels') eq lc('all'));
	return 0;
}

sub is_enabled_chan {
	my ($target) = @_;
	my $enabled = 0;
	
	# Setting - 'all'	
	return 1 if (Irssi::settings_get_str('twt_channels') eq 'all');

	# Setting - '#channel' must match one in list
	foreach my $chan (split(/ /, Irssi::settings_get_str('twt_channels'))) {
		if (lc($chan) eq lc($target)) {
			$enabled = 1;
			last;  # break
		}
	}

	return $enabled;
}


################
# Main routine #
################

# Bind (to commands)
Irssi::command_bind('twt', \&cmd_help, 'Twitter Theme');
Irssi::command_bind('twt help', \&cmd_help);
Irssi::command_bind('help twt', \&cmd_help);

# Bind (to signals)
Irssi::signal_add_last('message public', 'sig_public');
Irssi::signal_add_last('message own_public', 'sig_own_public');
Irssi::signal_add_last('setup changed', 'sig_setup_changed');

# Settings w/ defaults (/set)
Irssi::settings_add_str($IRSSI{'name'}, 'twt_channels', 'all');
Irssi::settings_add_str($IRSSI{'name'}, 'twt_color_bitlbee', 'lgray');
Irssi::settings_add_str($IRSSI{'name'}, 'twt_color_hash', 'yellow');
Irssi::settings_add_str($IRSSI{'name'}, 'twt_color_http', 'gray');
Irssi::settings_add_str($IRSSI{'name'}, 'twt_color_retweet', 'green');
Irssi::settings_add_str($IRSSI{'name'}, 'twt_color_text', 'white');
Irssi::settings_add_str($IRSSI{'name'}, 'twt_color_user', 'magenta');
Irssi::settings_add_bool($IRSSI{'name'}, 'twt_remove_long_urls', 1);  # ON
