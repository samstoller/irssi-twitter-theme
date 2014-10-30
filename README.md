Twitter Theme for Irssi
=======================
Twitter Theme is a Perl script for [Irssi](http://www.irssi.org), the terminal based IRC client for UNIX systems.

This script colorizes Twitter-like components in your public messages (channels) in order to enhance readability. Twitter Theme is configured for [Bitlbee](http://www.bitlbee.org)-style tweets but should work with other Irssi Twitter clients. You can also use this script for regular IRC channels.

Use Case
--------
Historically, Irssi has been used to connect users to IRC networks, however with the advent of messaging gateways like Bitlbee, users can now also connect to their favorite IM networks such as AIM and ICQ as well as messaging services such as Facebook and Twitter. It's a great solution for people who have an IRC client running all the time and don't want to run additional clients.

As a basic example, to connect to a Twitter account, the process may go something like the following:
* Install Bitlbee and then launch the Bitlbee server
* Connect to the Bitlbee server in Irssi
* Using the Bitlbee control channel in Irssi, add and enable your Twitter account

Once enabled, your Twitter account will display just like an IRC channel!

So where does Twitter Theme fit in? Twitter Theme is a simple script that sits on top of Irssi and Bitblee to enhance readability by colorizing different components of the message part. Some of the components that Twitter Theme can colorize are usertags, hashtags and URLs. See the Usage section for more on this.

The easiest way to see how Twitter Theme works is to view the screenshots:

### Screenshots
**Default Theme**<br />
A before and after split screen of an Irssi session with and without Twitter Theme installed:<br />
![Default Theme](/theme_default.png?raw=true "Default Theme")

**Example Theme (dark)**<br />
An example theme with a dark background:<br />
![Example Theme (dark)](/theme_A_dark.png?raw=true "Example Theme (dark)")

**Default Theme**<br />
An example theme with a light background:<br />
![Example Theme (light)](theme_A_light.png?raw=true "Example Theme (light)")


Installation
-------------
Copy ```twitter_theme.pl``` to your Irssi scripts directory, usually ```~/.irssi/scripts/```.

Then in Irssi, load the script with the command ```/SCRIPT LOAD twitter_theme```.

If you would like Twitter Theme to start automatically, copy to ```~/.irssi/scripts/autoload``` or better yet, create a symlink from the scripts directory. See [scripts.irssi.org](http://scripts.irssi.org/) for offical installation and autoload instructions.


Usage
-----
Twitter Theme works out of the box and does not need to be configured for first time use. Once loaded, the script will automatically apply the default colorization rules to all public channels (color and channel settings can be customized).

You can disable Twitter Theme by unloading the script like so: ```/SCRIPT UNLOAD twitter_theme```.

### Commands
Twitter Theme provides three commands:
```bash
/twt         # Display inline help
/twt colors  # Display available colors
/twt reset   # Reset colors to the default theme

```
### Components
Twitter Theme looks for the following components in public channel messages and colorizes them:
* \#hashtags
* @usertags
* RT (retweets)
* http(s):// URLs
* Bitlbee message IDs
* Message text

Each component can be set to a specific foreground and background color using the ```/SET``` commands described below.

### Settings
You will most likely want to restrict the script to specific channels and define your own color schemes for each component. All configuration is done through Irssi settings via the ```/SET``` or ```/TOGGLE``` commands.

```bash
## List all Twitter Theme settings
/SET twt_

## Specify channels
## Syntax: /SET twt_channels [<chan1> <chan2> <chan3> ...] or [all]
/SET twt_channels #twitter_HandleA #twitter_HandleB #otherChannel
/SET twt_channels all

## Define component colors
## Syntax: /SET twt_<component> [foreground] [background]
/SET twt_color_hash yellow lblue
/SET twt_color_http gray
```

#### Removing Extra URLs
URLs in Bitlbee tweets come in pairs: the shortened Twitter URL (t.co) and the original full URL. This verbose option can be handy but it can also take up a lot of screenspace so Twitter Theme comes with an option to remove the longer version of the URL. It is enabled by default and controlled by the  ```twt_remove_long_urls``` boolean setting:
```bash
/SET twt_remove_long_urls ON|OFF
```

### Available Colors
Twitter Theme uses custom color keywords (mappings to the standard ANSI escape codes) to set the foreground and background color of components. Currently a total of 16 colors are supported, but only 8 are available as background colors. Each color has a bolded or "bright" version, while white and black and standalone colors.

**Foreground:** white, black, gray/lgray, yellow/lyellow, green/lgreen, cyan/lcyan, blue/lblue, magenta/lmagenta, red/lred

**Background:** white, black, lgray, yellow, green, cyan, blue, magenta, red

To view how these colors are displayed on your terminal, run the ```/twt colors``` command in Irssi.


Known Issues
-------------
1. Existing colors and formatting will be removed from the message text part. Note that the message does not include nicks, so nick color will be preserved, however highlights will not.

2. Channels of the same name across different servers cannot be individually configured. For example, setting your channel list to #twitter is server-agnostic and will colorize all channels named #twitter regardless of which server you are connected to.

Todo
----
1. Ability to save/load user-defined color theme settings
2. Ability to assign a color themes on a per-channel and per-server basis
3. 256-color support?
