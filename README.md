# ThunderTray

This is not a Thunderbir extension.

It mimics Minimize to Tray, but the application runs external to Thunderbird.

It has been developed as an alternative to disabled Tray Extensions on Thunderbird 60.

It can be easily installed and removed from the system.

## Getting Started

Download latest release or zip file.
Unzip. Copy : thundertray.pl to any directory you like

### Prerequisites

* Linux
  * Tested on : Linux Mint 18.3, with Cinnamon 3.6.7
* Perl Libraries
  * Mozilla::Mork;
  * Glib
  * Gtk2
  * Gtk2::TrayIcon
  * MIME::Base64
  * GD
* System
  * xdotool
  * x11-utils

### Installing

```
sudo apt-get install libglib-perl libgtk2-perl libgtk2-trayicon-perl libgd-perl libmime-base64-perl cpanminus xdotool x11-utils
sudo cpanm -qn Mozilla::Mork
unzip ThunderTray.zip
cd ThunderTray
cp thundertray.pl ~/
```
**Recomendations**
* Disable any active tray extension in Thunderbird.
* Because application is not running inside Thunderbird, it has no control over the Close window Button. To minimize: click always on the Tray icon
* Tray Icon states
  * Thunderbird icon normal : No email, window is not minimized
  * Thunderbird icon dimmed : Thunderbird is minimized
  * A number : quantity on unread messages in INBOX (other boxes are not taken into account)
  * Thunderbird dimmed and red X : Thunderbird is closed. To start again, click in Tray Icon.
* If you quit the tray and want to restart, execute:
```
./thundertray.pl &>/dev/null
```
* You may add that instruction to your Main menu so you can start it from there.

## To test

```
cd
perl thundertray.pl
```
When executed, thundertray will minimize to tray any existing Thunderbird Window.

To show Thunderbird: click on Tray Icon

Send emails to your email accounts, check email count on tray icon, read, delete messages.

To exit ThunderTray right click on Tray icon select : Quit

## Deployment

If everything looks fine, add thundertray.pl to your startup applications

## Customization

At the beginning of the file, you will see the following Variables
```
$DIR = "";      #/home/MIUSER/.thunderbird/PROFILE.default
$FONT_PATH =""; #/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
$OFFSET = 0;
$MSEC = 1000;
$SCAN_ALL = 0;
$IGNORE_BOXES = "";
$DEBUG = 0; # 0-No debug, 1-Debug, 2-Debug and stop after scanning boxes
```
* $DIR
  * thundertray will try to locate your default location for emails, if it can not find it in your computer, write the path in this variable
* $FONT_PATH
  * If you want a specific Font to be used for the email numbers that show in the tray Icon
* $OFFSET
  * If you have been creating and deleting email accounts and the old folders were not deleted. You may see more messages from those old directories. Your best option is to remove those directories, or add an offset to the count, example: -1
* $SCAN_ALL
  * 0 - Scan only main INBOX. 1 - Scan all mail boxes available
* $IGNORE_BOXES
  * Used when when SCAN_ALL=1
  * List of comma separated names. Those names are searched within the path/box to be processed. If any name matches, that box or full path is ignored for search of boxes with new emails
* $MSEC
  * Check for new emails every amount of milliseconds, default 1,000 = 1 second. Every cycle, creates an access to your hard drive, if it is to intense, increase to 1500 or 2000. If you use an SSD drive, it could be reduced, but I do not recommend, 1 second gives a good responde time.

## Known Issues

* Icons have no transparency. Sorry, tray icon libraries in Perl are old. You may edit icons included to fit your toolbar background color.

```
After modifying the incons, execute in terminal.

base64 -w 0 iconname.png

Copy the long string
Paste in code in subroutine build_start.
Substitute the string depending on the correct state:
* tbrd : Normal
* tbrdwm : Thunderbird minimized
* tbrdwmx : Thunderbird closed
```

## Authors

* **Hans Peyrot**

## License

This project is licensed under the GPL3 License
