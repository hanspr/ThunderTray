# Project Title

No extension, Minimize to Tray Thunderbird

## Getting Started

Download release or zip file.
Unzip. Copy : thundertray.pl to any directory you like

### Prerequisites

Mozilla::Mork;
Glib
Gtk2
Gtk2::TrayIcon
MIME::Base64
GD
xdotool
x11-utils

### Installing

```
sudo apt-get install libglib-perl libgtk2-perl libgtk2-trayicon-perl libgd-perl libmime-base64-perl cpanminus xdotool x11-utils
sudo cpanm -qn Mozilla::Mork
unzip ThunderTray.zip
cd ThunderTray
cp thundertray.pl ~/
```

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

## Authors

* **Hans Peyrot**

## License

This project is licensed under the GPL3 License - see the [LICENSE.md](LICENSE.md) file for details
