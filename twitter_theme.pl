#!/usr/bin/perl -w
#
# twitter_theme.pl
#
# Colorizes Twitter message components (configured for Bitlbee-style).
# Removes redundant long-format URLs.
#
# Note: Will remove existing color formatting on message part.
#
# Can be configured to colorize the following components:
# * [alphanum]
# * RT
# * @usertag
# * #hashtag
# * http(s)://url
# * 'plain text'
#
# Can be configured to remove URLs that:
# * Appear inside brackets <...>
#
# CHANGELOG
#
# v0.6a
#  - Regex
#     * Usertags can have . as first char
#  - Features
#     * Fixing broken is_long_url() result
# v0.5a
#  - Commands
#     * Cleaned up command bindings for help
#     * Added new help for colors (color list)
#  - Features
#     * Implemented background colors
# v0.4a
#  - Commands
#     * Implemented help command
#  - Settings
#     * Added COLORS hash mapping
#     * Implemented color settings
#     * Validated color settings
#  - Functionality
#     * Refactored colorize function
#     * Added more helpers and organized layout
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
################################################################################

use strict;
use warnings;
use vars qw($VERSION %IRSSI %COLORS);
use Irssi;

#use Data::Dumper;
#$Data::Dumper::Indent = 2;

################################################################################

$VERSION = "0.4";
%IRSSI   = (
    authors     => "Sam Stoller",
    contact     => "snstoller\@gmail.com",
    name        => "Twitter Theme",
    description => "Assign colors to tweet message components",
    license     => "Public Domain",
    url         => "http://irssi.org/",
    changed     => "2014-10-22"
);
%COLORS = (
    white    => 0,
    black    => 1,
    blue     => 2,
    green    => 3,
    lred     => 4,
    red      => 5,
    magenta  => 6,
    yellow   => 7,
    lyellow  => 8,
    lgreen   => 9,
    cyan     => 10,
    lcyan    => 11,
    lblue    => 12,
    lmagenta => 13,
    gray     => 14,
    lgray    => 15
);

#######################
# Command subroutines #
#######################

sub cmd_twt {
    if ( $_[0] eq 'colors' ) {
        cmd_colors();
    }
    else {
        cmd_help();
    }
}

sub cmd_colors {
    Irssi::print(
        <<EOF
Colors:

  Below is a list of colors that you can set your components to. The prefix of 'l' 
  indicates a lighter version which is often a bolded version of the base color.

  Please note that your terminal may display these colors differently than described.
EOF
        , MSGLEVEL_CLIENTCRAP
    );

    print_colors();
}

sub cmd_help {
    Irssi::print( chr(3).sprintf( '%02d', $COLORS{'white'} ).','.sprintf( '%02d', $COLORS{'blue'}).'Twitter Theme', MSGLEVEL_CLIENTCRAP );
    Irssi::print(
        <<EOF

Description:

  Twitter Theme colorizes Twitter-like components in your public messages (channels). Twitter Theme 
  is configured for a Bitlbee-style tweets but should work with most other Irssi Twitter clients 
  or you can enable it for normal IRC channels!

Usage/Options:

  Twitter Theme works out of the box and does not need to be configured for first time use. 
  However, you will most likely want to restrict the script to specific channels and set your 
  colors. All configuration is done through Irssi settings via the /SET or /TOGGLE commands.

Channel Config (default is all):

  Channel names must start with a #.

  /SET twt_channels [<chan1> <chan2> <chan3> ...] or [all]
    
Color Config:
    
  With Twitter Theme, you can colorize up to six different message components as described below. 
  In the very least you must set the foreground aka text color, the background color is optional. 
  For a list of valid colors, see the 'Colors' section below.

  Setting Name           Foreground  Background   Component

  /SET twt_color_bitlbee  [<color>]  [<color>]    [0x->0x]   - Bitlbee tweet numbers
  /SET twt_color_hash     [<color>]  [<color>]    #hashtags  - Twitter hashtags
  /SET twt_color_http     [<color>]  [<color>]    http://    - Basic URLs
  /SET twt_color_retweet  [<color>]  [<color>]    RT         - Bitlbee retweets
  /SET twt_color_text     [<color>]  [<color>]    'string'   - All text
  /SET twt_color_user     [<color>]  [<color>]    \@usertags  - Twitter usernames
EOF
        , MSGLEVEL_CLIENTCRAP
    );

    cmd_colors();

    Irssi::print(
    <<EOF
Removing Long URLs:
    
  You can also toggle the removal of long URLs which are defined as any text that looks like a URL 
  that is between two angle bracket characters such as:

      <https://myurl.com>
      <imgur.com/xxxx>

    /SET twt_remove_long_urls  [ON|OFF|TOGGLE]

Known Issues:
  
  * Existing colors and formatting will be removed from the message part. Note that the message 
    does not include nicks, so nick color will be preserved, however highlights will not.

  * Channels of the same name across different servers cannot be individually configured. For 
    example, setting your channel list to #twitter is server-agnostic and will colorize all 
    #twitter channels regardless of which server you are connected to.

Examples:

  List all Twitter Theme settings:
    /SET twt_

  Set list of channels to three specific channels:
    /SET twt_channels #perl #irssi #twitter

  Set the colorization theme for URLs:
    /SET twt_color_http gray

  Set the colorization theme for hashtags:
    /SET twt_color_hash yellow lblue

EOF
        , MSGLEVEL_CLIENTCRAP
    );
}

######################
# Signal subroutines #
######################

# Colorize user public messages
sub sig_public {
    my ( $server, $msg, $nick, $address, $target ) = @_;

    $msg = colorize( $msg, $target );

    Irssi::signal_continue( $server, $msg, $nick, $address, $target );
}

# Colorize your public messages
sub sig_own_public {
    my ( $server, $msg, $target ) = @_;

    $msg = colorize( $msg, $target );

    Irssi::signal_continue( $server, $msg, $target );
}

# Validates channel and color settings
sub sig_setup_changed {
    validate_channels();
    validate_colors();
}

######################
# Helper subroutines #
######################

sub colorize {
    my ( $msg, $target ) = @_;
    my $pretty_msg = '';
    my $previous = '';
    
    # Is this channel set to be colorized?
    return $msg if ( !is_enabled_chan($target) );

    # Remove colors and some formatting (too messy otherwise)
    $msg =~ s/\x03\d?\d?(,\d?\d?)?|\x02|\x1f|\x16|\x06|\x07//g;

    # Tokenize message string
    my @words = $msg =~ /(\S+)/g;
    foreach my $word (@words) {

        # Skip long URLs if setting enabled
        if ( not( has_remove_long_URLs() and is_long_URL($word) ) ) {

            # Get the type of component and if it's the first component
            my $component = detect_component($word);
            my $msg_start = $pretty_msg eq '' ? 1 : 0;

            # If this is part of the text message then don't reset colors
            if ($component eq 'text' && $component eq $previous) {
                $pretty_msg .= ($msg_start ? '' : ' ') . $word;
            } else {
                $pretty_msg .= chr(15) . ($msg_start ? '' : ' ') . get_component_color($component) . $word;
            }

            $previous = $component;
        }
    }

    return $pretty_msg . chr(15);
}

sub detect_component {
    my ($word) = @_;
    my $component = 'text';

    # Bitlbee-style Tweet #'s, eg: [f9], [04]->[ca]
    if ( $word =~ /\[[0-9A-Za-z]{2}(\->[0-9A-Za-z]{2})?\]/ ) {
        $component = 'bitlbee';

    }
    elsif ( $word =~ /\bRT\b/ ) {
        $component = 'retweet';

    }
    elsif ( $word =~ /^\.?@.+/ ) {
        $component = 'user';

    }
    elsif ( $word =~ /^#.+/ ) {
        $component = 'hash';

    }
    elsif ( $word =~ /^https?:\/\// ) {
        $component = 'http';
    }

    return $component;
}

sub is_long_URL {
    my ($word) = @_;
    return 1 if ( $word =~ /<\S+\.\S+>/ );
    return 0;
}

#######################
# Setting subroutines #
#######################

sub get_component_color {

    # Returns array of color names (eg. green magenta)
    my @colors
        = split( /\s+/, Irssi::settings_get_str( 'twt_color_' . $_[0] ) );

    # Converts names to color codes, then to string, then prepend \003
    return
        chr(3) . join( ',', map { sprintf( '%02d', $COLORS{$_} ); } @colors );
}

sub get_channels {

    return Irssi::settings_get_str('twt_channels');
}

sub has_remove_long_URLs {

    return Irssi::settings_get_bool('twt_remove_long_urls');
}

sub is_all_chan {
    return 1 if ( get_channels() eq 'all' );
    return 0;
}

sub is_enabled_chan {
    my ($target) = @_;
    my $enabled = 0;

    return 1 if ( is_all_chan() );

    # Channel must match one in settings
    foreach my $chan ( split( /\s+/, get_channels() ) ) {
        if ( lc($chan) eq lc($target) ) {
            $enabled = 1;
            last;    # break
        }
    }

    return $enabled;
}

sub validate_channels {
    my $setting = '';
    my $server  = Irssi::active_server();
    my $old     = get_channels();

    if ( $old !~ m/\ball\b/i ) {

        # Valid channels are saved while invalid are discarded
        foreach my $chan ( $old =~ /(\S+)/g ) {
            if ( $server->ischannel($chan) ) {
                $setting .= $chan . ' ';
            }
            else {
                Irssi::print(
                    "'" . $chan . "' is not a valid channel name." );
            }
        }
    }

    # Default Setting - All Channels
    # $setting is empty b/c nothing valid was set OR
    # the word 'all' was detected in setting string above
    if ( $setting eq '' ) { $setting = 'all'; }

    Irssi::settings_set_str( 'twt_channels', $setting );
}

sub validate_colors {
    foreach my $component (qw(bitlbee hash http retweet text user)) {

        my $setting = '';
        my $to_validate
            = lc( Irssi::settings_get_str( 'twt_color_' . $component ) );

        # Validate only the first two colors
        foreach my $color ( $to_validate =~ /(\S+)/g ) {
            if ( !exists $COLORS{$color} ) {
                $setting = 'lgray';
                Irssi::print( "'"
                        . $color
                        . "' is not a valid color.\nType '/twt colors' to see a list."
                );
                last;
            }
            else {
            	$setting .= $color . ' ';
            }
        }

        Irssi::settings_set_str( 'twt_color_' . $component, $setting );
    }
}

sub print_colors {
    Irssi::print(
        "Foreground:\n".
        chr(3).sprintf( '%02d', $COLORS{'white'} ).','.sprintf( '%02d', $COLORS{'black'} ) . '  white      ' .
        chr(3).sprintf( '%02d', $COLORS{'black'} ).','.sprintf( '%02d', $COLORS{'lgray'} ) . 'black' . "\n" .
        chr(3).sprintf( '%02d', $COLORS{'gray'}) . '  gray       ' .
        chr(3).sprintf( '%02d', $COLORS{'lgray'}) . 'lgray' . "\n" .
        chr(3).sprintf( '%02d', $COLORS{'yellow'}) . '  yellow     ' .
        chr(3).sprintf( '%02d', $COLORS{'lyellow'}) . 'lyellow' . "\n" .
        chr(3).sprintf( '%02d', $COLORS{'green'}) . '  green      ' .
        chr(3).sprintf( '%02d', $COLORS{'lgreen'}) . 'lgreen' . "\n" .
        chr(3).sprintf( '%02d', $COLORS{'cyan'}) . '  cyan       ' .
        chr(3).sprintf( '%02d', $COLORS{'lcyan'}) . 'lcyan' . "\n" .
        chr(3).sprintf( '%02d', $COLORS{'blue'}) . '  blue       ' .
        chr(3).sprintf( '%02d', $COLORS{'lblue'}) . 'lblue' . "\n" .
        chr(3).sprintf( '%02d', $COLORS{'magenta'}) . '  magenta    ' .
        chr(3).sprintf( '%02d', $COLORS{'lmagenta'}) . 'lmagenta' . "\n" .
        chr(3).sprintf( '%02d', $COLORS{'red'}) . '  red        ' .
        chr(3).sprintf( '%02d', $COLORS{'lred'}) . 'lred' . "\n",
        MSGLEVEL_CLIENTCRAP
    );
    Irssi::print(
        "Background:\n".
        '  '.chr(3).sprintf( '%02d', $COLORS{'black'} ).','.sprintf( '%02d', $COLORS{'lgray'} ) . 'lgray' . "\n" .
        '  '.chr(3).sprintf( '%02d', $COLORS{'black'} ).','.sprintf( '%02d', $COLORS{'yellow'} ) . 'yellow' . "\n" .
        '  '.chr(3).sprintf( '%02d', $COLORS{'black'} ).','.sprintf( '%02d', $COLORS{'green'} ) . 'green' . "\n" .
        '  '.chr(3).sprintf( '%02d', $COLORS{'black'} ).','.sprintf( '%02d', $COLORS{'cyan'} ) . 'cyan' . "\n" .
        '  '.chr(3).sprintf( '%02d', $COLORS{'white'} ).','.sprintf( '%02d', $COLORS{'blue'} ) . 'blue' . "\n" .
        '  '.chr(3).sprintf( '%02d', $COLORS{'white'} ).','.sprintf( '%02d', $COLORS{'magenta'} ) . 'magenta' . "\n" .
        '  '.chr(3).sprintf( '%02d', $COLORS{'white'} ).','.sprintf( '%02d', $COLORS{'red'} ) . 'red' . "\n",
        MSGLEVEL_CLIENTCRAP
    );
}

################
# Main routine #
################

# Bind (to commands)
Irssi::command_bind( 'twt', \&cmd_twt, 'Twitter Theme' );
Irssi::command_bind( 'twt colors', \&cmd_twt );

# Bind (to signals)
Irssi::signal_add_last( 'message public',     'sig_public' );
Irssi::signal_add_last( 'message own_public', 'sig_own_public' );
Irssi::signal_add_last( 'setup changed',      'sig_setup_changed' );

# Settings w/ defaults (/SET)
Irssi::settings_add_str( $IRSSI{'name'}, 'twt_channels',      'all' );
Irssi::settings_add_str( $IRSSI{'name'}, 'twt_color_bitlbee', 'lgray' );
Irssi::settings_add_str( $IRSSI{'name'}, 'twt_color_hash',    'yellow' );
Irssi::settings_add_str( $IRSSI{'name'}, 'twt_color_http',    'gray' );
Irssi::settings_add_str( $IRSSI{'name'}, 'twt_color_retweet', 'green' );
Irssi::settings_add_str( $IRSSI{'name'}, 'twt_color_text',    'white' );
Irssi::settings_add_str( $IRSSI{'name'}, 'twt_color_user',    'magenta' );
Irssi::settings_add_bool( $IRSSI{'name'}, 'twt_remove_long_urls', 1 );    # ON
