#!/usr/bin/perl

use utf8;
use Mozilla::Mork;
use Glib qw/TRUE FALSE/;
use Gtk2 '-init';
use Gtk2::TrayIcon;
use MIME::Base64;
use GD;

our (%icon,$icon,$eventbox,$trayicon,$tooltip,$NEW,$DIR,$FONT,$FONT_PATH,$TBW,$OFFSET,$emailchk,$MSEC,$IGNORE_CLICK,$DEBUG);

# Begin Constants: Edit if auto setup does not work for you
$DIR = "";      #/home/MIUSER/.thunderbird/PROFILE.default;
$FONT_PATH =""; #/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
$OFFSET = 0;
$MSEC = 1000;
$DEBUG = 0; # 0 - No, 1-Debug, 2-Debug and stop on email count
# End Constants

$NEW = -1;
build_start();
$icon     = Gtk2::Image->new_from_pixbuf($icon{'tbrdwm'});
$eventbox = Gtk2::EventBox->new;
$eventbox->add($icon);
$eventbox->signal_connect( 'button_press_event', \&click );
$trayicon = Gtk2::TrayIcon->new('Tbird Email');
$trayicon->add($eventbox);
$tooltip = Gtk2::Tooltips->new;
$trayicon->show_all;
$emailchk = Glib::Timeout->add($MSEC,\&CheckMail);
Gtk2->main;

sub CheckMail {
	my (@mails,%IDS,$id,$status,$new,$lmt,$x);

	$x = `xdotool search --name 'Mozilla Thunderbird'`;
	chop$x;
	if ((!$x)||(!$TBW)||($IGNORE_CLICK)) {
		if (!$x) {
			select(undef, undef, undef, 0.25);
			$x = `xdotool search --name 'Mozilla Thunderbird'`;
			chop$x;
		}
		if (!$x) {
			$icon->set_from_pixbuf($icon{'tbrdwmx'});
			return 1;
		} elsif ((!$TBW)||($TBW!=$x)) {
			$TBW = $x;
		}
	}
	# Check IMAP Folders
	open OLDER, ">&STDERR";
	open(STDERR,"> /dev/null");
	$new += ReadBoxes("$DIR/ImapMail");
	$new += ReadBoxes("$DIR/Mail");
	open STDERR, ">&OLDER";
	if ($DEBUG==2){print "NEW=$new\nFIN\n";exit 0;}
	if ($new!=$NEW) {
		# Set Tray Icon number off messages
		if ($new==0) {
			my $map = `xwininfo -id $TBW | grep 'IsViewable'`;
			if ($map) {
				$icon->set_from_pixbuf($icon{'tbrd'});
			} else {
				$icon->set_from_pixbuf($icon{'tbrdwm'});
			}
			$tooltip->set_tip($trayicon,"No mail");
		} else {
			my ($x);
			my $pt = 12;
			if (length($new)>2) {$pt=9;}
			my $img = new GD::Image(24,24);
			my $w = $img->colorAllocate(255,255,255);
			my $b = $img->colorAllocate(0,0,0);
			$img->fillToBorder(0,0,$w,$w);
			$x = int(12-(length($new)*$pt)/2);
			if ($x < 0) { $x = 0; }
			if ($FONT_PATH) {
				$img->stringFT($b,$FONT_PATH,$pt,0,$x,18,$new);
			} else {
				$img->string(gdGiantFont,$x,5,$new,$b);
			}
			my $loader = Gtk2::Gdk::PixbufLoader->new();
			$loader->write($img->png);
			$loader->close();
			$icon->set_from_pixbuf($loader->get_pixbuf());
			$tooltip->set_tip($trayicon,"You got mail!");
		}
		$NEW = $new;
	}
	return 1;
}

sub click {
	my ($map,$hidden,$start);

	if ($_[ 1 ]->button == 1) {
		#left mouse button
		if ($IGNORE_CLICK) {
			return 1;
		}
		$start = setTBW();
		if ($start) {
			# Thunderbir was started ignore this click
			return 1;
		}
		$map = `xwininfo -id $TBW | grep 'IsViewable'`;
		$hidden = `xwininfo -all -id $TBW | grep 'Hidden'`;
		if (($map)&&($hidden)) {
			# Show
			system "xdotool windowactivate $TBW";
			if ($NEW==0) {
				$icon->set_from_pixbuf($icon{'tbrd'});
			}
		} elsif ($map) {
			# Hide
			system "xdotool windowunmap $TBW";
			if ($NEW==0) {
				$icon->set_from_pixbuf($icon{'tbrdwm'});
			}
		} else {
			# Unhide
			system "xdotool windowmap $TBW";
			if ($NEW==0) {
				$icon->set_from_pixbuf($icon{'tbrd'});
			}
			if ($hidden) {
				system "xdotool windowactivate $TBW";
			}
		}
	} elsif ($_[ 1 ]->button == 2) {
		#middle mouse button
	} elsif ($_[ 1 ]->button == 3) {
		#right mouse button
		pop_menu();
	}
	return 1;
}

sub pop_menu {
	my $menu = Gtk2::Menu->new();
	my $menu_lbl = Gtk2::MenuItem->new_with_label("Menu");
	$menu->add($menu_lbl);
	my $menu_sep = Gtk2::SeparatorMenuItem->new();
	$menu->add( $menu_sep );
	#Quit
	my $menu_quit = Gtk2::ImageMenuItem->new_with_label("Quit");
	$menu_quit->signal_connect(activate => \&exit_it);
	$menu_quit->set_image(Gtk2::Image->new_from_stock('gtk-quit','menu'));
	$menu->add($menu_quit);
	$menu->show_all;
	$menu->popup(undef,undef,undef,undef,0,0);
	return 1;
}

sub exit_it {
	my $map = `xwininfo -id $TBW | grep 'IsViewable'`;
	if (!$map) {
		system "xdotool windowmap $TBW";
	}
	Gtk2->main_quit;
	return 0;
}

sub ReadBoxes {
	my ($dir) =@_;
	my ($BOXES,$box,$count,$MorkDetails,$results,$r);

	if ($DEBUG) {print "Abrir : $dir\n";}
	$count=0;
	opendir($BOXES,$dir);
	while ($box = readdir($BOXES)) {
		if ($box =~ /^\./) {
			next;
		} elsif ($box =~ /INBOX\.msf/i) {
			$MorkDetails = Mozilla::Mork->new("$dir/$box");
			$results = $MorkDetails->ReturnReferenceStructure();
			foreach $r (@$results) {
				if ($DEBUG) {
					foreach my $k (sort keys %$r) {
						if ($DEBUG) {print "  :: $k=$$r{$k}\n";}
	    			}
				}
				$count += $$r{'unreadChildren'};
			}
		} elsif (-d "$dir/$box") {
			$count += ReadBoxes("$dir/$box")
		}
	}
	if ($DEBUG) {print "  Unread $dir : $count\n";}
	return $count;
}

sub build_start {
	my (%data);

	$data{'tbrd'} = decode_base64('iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAAcRAAAHEQGx3syBAAAAB3RJTUUH4goUCzMLbX+bGQAAA/pJREFUOMuVlVtMHFUYx785Mzs39s4ul2WzyJ1FUiqXVoG+SLw8mdRLNKnUxAfji8bEF16sqcak9lVjbHxsYkzaqolp0tRUodRSxNLbWpAu1IVSYFyWvc3uXPbM58NigYXS+s9JZk5O5pdz/t//fMMgImzTXYVenjGvzhpK2kqqKPHglpmGSra3hd/XxIs2ZvsnTAkoFqcnR7SLUwY8RHYRDnazr/c7eI55KOjspP7FuRy14JEKea2PX5VDFdIOoC/P5X6c0OGx5ZLws9e41lpncUqKj9Pj2g8TOgI8/kjmmSNndGVN2wDNrtAT5/PwvzAIgLCa5Y6f+WcD9M2FHEW0EbNKjCEgApaJUHx55Ji8L41eXwQAMqfQ8TsmIrziHDoafsfLK+V2Zo8riggiozq5NUDcFUZOjWmIyF2aNhCAAWz3zU1HVRtjLGXQB9kPGj/q9l/nOTQtdiEbiqbr5rKNN1L74kZVievTipRMq9xE1AAEn7DcUKlbGHoJRkxz6bnAsKOMMAwDwACgS461V8QAhkfu3z4eGSoB6RY7FomTlZSFADaisywTDlGX8Xuf52ennTDb0ksphOAix+RLTAeGnVdyJJEFwlhrhtcocAKb6whEp+7mC3RL3DMqjUTV364l01ktIPxdahMwiQzleBbVArzfcmw553PKitvB1gbEP2fVjmY7tXBJMRZWdI5lqv1CfVASeQKKWHI70aI2FojHTiiSCineVK4UF+qDomni5FRm9GoqrRZa6+XONnuwkpdFYqCwmAvs9w5vPpqF1OvkSHM1Cwi3k+HNpuxtsVf6+N69rraGMo+DY8n6WkL3DrUd7fLf3GwSmkZno4M808wjwJV4v2VtkDiOqfEL/LZ2EZCXeoORm8muzTvyiPnWJ8rJgTDvEPHaWs+bo6e+mvv0VqrHQrLLXdWoMK50PXCamnpfgy4IAifxzBvd+olRQVFt30/vOW8L86zVXxPp81/ocI9zpFACGlnqz1OhWHcAlEnqreeDhBAOAA4NVP0aic0knABg5/T3Om+M3fNL0v7TC8+ilQnKd3p8v4hsHgAsJN9FD8J/VbOMzKEDNFDp2ehH84uJD0+mFzIOADj85NS7XTELLY5lzQKdSwhj9zyqobn5xdUc+2305fV8GupAQ/yTt9t5nt/S2PKpleitsciyLBHt6Vq1yrklLQVKf5qpPnblqfXoGJmBxrUjh8OyLO3Qak0tq81fKsNVQkrrdTZa8/nlsEZZq6DbSXqwlw6+2FTcy87NHwCSy1FM/CVaCY4FlhCK5Os/6qbjgpusLmQcbUFu8IW66go3IWS3v8gD5dVMJh7Ts6tWQSsgYwHv9IVcvgDP8yWIov4FBkZMMk9C7MUAAAAASUVORK5CYII');
	$data{'tbrdwm'} = decode_base64('iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAACXBIWXMAAAcRAAAHEQGx3syBAAAAB3RJTUUH4goUCzUvBybYTgAAAyRJREFUOMuVlVtv20YQhc/MLm8SRVmyXCeokypFL2iR5A/0/6MPfSiKoHCAuEACp3Gtu0SKWpK7O32QXTmSnTQHfOBtP86cnRmSiOBAayOT3M8KbxppHBQjVEhjHmTcT1nx4QrQHmhdyduRG688HpBWOOvT05OA6WHQh7l/c2W94LNqh/L8iW7F6h7Qmyv3fubwvxUovHxCWTvYXt6kezn9MgqAxuHVe29qtwMVRi7++TLKVrWl15fVDvTXtROA4WNeCyCAZmxPPnvMjBrPNwC4MDLNPQRnwR8vst8iNpFGNyggULAB1RD5JIwupw6AnuTbnZZutF4VluBNgwj2x86rfjRnggeVTauw7aLpLJrjysd7Ca6Mqhurp7kHELFJY1eg/TVG4s1pMgr0zXsK0lXrLtbAaLRZvl7+vAdyQpNlpU0jAjB5IspaUhezLFwF+p7iFUEbY4LzUHtVXRrHtQVBah96ISbbi/NV4fbaxlpZFm4ybxrrErXetwmorddMsB4/ZOfGRoEyQUCtRC0Le9TRIjCVL40nQhJxmgSKAcMHkQoTONQQUKSqTmS2D9IWe4/5yo7nTWOl01a9TCcxKwUHtXHJcTj6OCAJNXMnYQCrOrv7kV6m44gHR0GWqjAguu3P2oc/ZX/24sVHEXnf62gedBjAtBpAdu28zYUPHE/UZtBaLOre3Zuhclk74pOMAyXz+vjX8S8XxctlcwzQJ9rCiZqa/n+JiXcnqWdmrRhPe/5izMbS5ap7xZkiGbSWJ9H1UTAl2h9M483ACd+YAyhqho8SItIAvnkUXy/LvNYAAnbf9xbTMlLq+LL8SmBbKu9H14q2XU3virMd1dvhiSRxuJtH5ab+/W1TNhrAsLv6rl9ChIi8yLrmSRla70LeVI7e5We3HrvTtHrxbXfr5W6wucbki8nSaEVu0LJxsF8sf+fJ+fTolmJP0/r5s0wpdc+o9c76cqxQH7r9oUjOJ5kTgveamuFAho87d/eVDv8itSlQr5TURCAiEVzM0rzigOrS6m5Cw8dpHN2prodAN5la21RrbysRJ0ICDqJWECXMvIfY6l8kuthNC108NAAAAABJRU5ErkJggg');
	$data{'tbrdwmx'} = decode_base64('iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAcRAAAHEQGx3syBAAAAB3RJTUUH4goVDzoPBGUr8AAABC5JREFUSMells1rXFUYxn/nnHvnzkxmJplJ0pa0aaH4gaVWEIqii1a7ERdSGrKQbhREsAsRBPEfEPzciXbnqi6ycSEuhEJRi1Kt+FFDK01p2rSJmWS+78zcuR/ndTFJSsxEW/vAgcPlvOc573Pe9zlXiYiwDdqBsNqyVH1LEAlRAkZDykAurRkraEo5jdFsCzWIoN0T5ssJK03Lf8ExsKek2DvuotVdECzWLFeXYqxwTxhKCQcnHbJpsz3B1aWEW9WE/wvXwKFJRWHI3fi2od5C5f42B4gSuHTLEoTJZgI/EOb+ur/N1xHGiisLvc0E15YTBNBY0rqNAAI4mo35vYxqYFipdfsEfiBUWhYE9ri/8WjhJzwd4Dkw7PogYIhxVQgid8miWKj0FXFWW+ulKAx7bZp+jMISROAR83D+EiWvhlZgUXSiLH48hB/lqUej9Gx6oFTNwBBGMU5ljcDTAbl0gs8QuykjNmBnpozr3AkyCMOmzTBtoEy52+BK48BAgkQUq40eThBJX39lUUpRyAqhX6WQauI627eoCAyxgiLBYgb1MJ0gQYcxKITQprCi0CqmmG7R9BMGmUgcCw0/YbUWEcUJGdMefA9AGFscrSC28FDhMkHs4ZoA11VkM4aGHzOSdxCBoGfpBBalIONpchm370GB3iZDQSvQKQcEhWd65L1gY0Euq7EWas2YlVpEFAv5IUOx4JBJa4yBBEM3yTCaKg9IQEg5Gp3P9E/QDAtbTlEsOKQ9zdiISyFnSLkKtWZot199h2s7nmX3qWcopuub4069wMRjWXjjFfRYvk9Q6Y2BbLbDdTn0ABV2vv86Ztco8XcXqJ/7444fXThH5vzXJDsn2H36U/R4QeMaoRaO8sPK08z5h2hEo4D6d5seybPr47f6krz3LmIFscLwR29jAf3hJ6RKJRyjYW/RMreiCWLFQnOYJV3AKGEs22DcW2bEraDU1rdh6MjjuC+fRH12hsxXnwOQuvIr/snXODj1HEqpvl1bEX78s0Mr7HdVxol5sFin0vHYlQuoBwYhJmtalLxljEo2av3CwgFyJ45Cb61AvDS5s9+yf/8OlFI4AFopDu1z+WU+ohM5dGOHZpjikR1tEKGUTbAitMMci50SsU1I6S69RNFtJOQbVezEPkBwlm4wmQO1Vg2bHpwkCmjVV2kEDkYljGVj0u7gGr/dynC5MkLxzRfJnv2C8ukvKaYj3JdOkJ+eZnJmZmPxJiRxJFFzUWxzXmSbcXtxWc7+3pVvPjgjsyA/P3FUrt2qS5Ikcv3YMZkFqc/MiIiI2u6vIgx8CJsYCVGqn7IIzFVztHoat7aIev4IulZh4vz3jDz1JEopOhcvMn/4MHp8nAdmZ7dm8E/EUSRdvy7t+rL4tUVpVZekWV2W68ePyyzIjampLTE3p6ZkFuTm9LT8DUkbgb0gFPxOAAAAAElFTkSuQmCC');
	foreach my $key ( keys %data ) {
		$icon{$key} = do {
			my $loader = Gtk2::Gdk::PixbufLoader->new();
			$loader->write( $data{ $key } );
			$loader->close();
			$loader->get_pixbuf();
		};
	}
	if ((!$FONT_PATH)&&(-e "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf")) {
		$FONT_PATH ="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf";
	}
	setTBW(1);
	findUserDIR();
}

sub findUserDIR {
	my ($dirh,$fn);

	if ($DIR) {
		return 0;
	}
	opendir($dirh,"$ENV{'HOME'}/.thunderbird") or die "ERROR opendir\n";;
	while ($fn = readdir($dirh)) {
		if ($fn =~ /\.default$/) {
			$DIR = "$ENV{'HOME'}/.thunderbird/$fn";
		}
	}
	closedir($dirh);
	if (!$DIR) {
		die "Could not find user DIR";
	}
}

sub setTBW {
	my $unmap = shift;
	my ($x,$exit);
	my $r = 0;

	# Find Thunderbird Window ID
	if ($TBW) {
		$x = `xdotool search --name 'Mozilla Thunderbird'`;
		chop$x;
		if (!$x) {
			# Is not running, start. FIND new window, recheck emails
			$IGNORE_CLICK=1;
			$TBW=0;
			system "thunderbird &> /dev/null";
			$IGNORE_CLICK=0;
#			$NEW=-1;
			$r=1;
			$icon->set_from_pixbuf($icon{'tbrd'});
		} else {
			$TBW = $x;
			return 0;
		}
	}
	# Start Up script, wait until found and start minimized to tray
	while (!$TBW) {
		$x = `xdotool search --name 'Mozilla Thunderbird'`;
		chop$x;
		if ($x) {
			$TBW = $x;
			if ($unmap) {
				select(undef, undef, undef, 0.25);
				system "xdotool windowunmap --sync $TBW";
			} else {
				$icon->set_from_pixbuf($icon{'tbrd'});
			}
			system "xdotool windowsize $TBW 100% 100%";
			last;
		}
		if ($exit>120) {
			# Could not be found, aborted
			last;
		}
		$exit++;
		select(undef, undef, undef, 0.25);
	}
	return $r;
}
