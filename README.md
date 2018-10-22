# ThunderTray

This is not an extension
It mimics Minimize to Tray, but the application runs external to Thunderbird.
It has been developed to be as an alternative to disabled Tray Extensions on Thunderbird 60.
It can be easily installed and removed from the system.

## Getting Started

Download release or zip file.
Unzip. Copy : thundertray.pl to any directory you like

### Prerequisites

* Linux
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
$DEBUG = 0; # 0 - No, 1-Debug, 2-Debug and stop on email count
```
* $DIR
  * thundertray will try to locate your default location for emails, if it can not find it in your computer, write the path in this variable
* $FONT_PATH
  * If you want a specific Font to be used for the email numbers that show in the tray Icon
* $OFFSET
  * If you have been creating and deleting email accounts and the old folders were not deleted. You may see more messages from those old directories. Your best option is to remove those directories, or add an offset to the count, example: -1
* $MSEC
  * Check for new emails every milliseconds, default 1,000 = 1 second . Every cycle, creates an access to your hard drive, if it is to intense, increase to 1500 or 2000. If you use an SSD drive, it could be reduced, but I do not recommend, 1 second gives a good responde time.

## Authors

* **Hans Peyrot**

## License

This project is licensed under the GPL3 License
