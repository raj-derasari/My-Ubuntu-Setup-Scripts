#!/bin/bash 
. br_util.sh ${*}

disp "GNOME Bloat Removal Script"

splash_msg="
----------------------------------------------
Removing unneeded packages, followed by default software:
----------------------------------------------

"
pprint "$splash_msg"

pkgs="
account-plugin-* \
aisleriot \
brltty \
brltty-x11 \
deja-dup \
deja-dup-backend-gvfs \
diveintopython \
duplicity \
empathy \
empathy-common \
evolution \
evolution-common \
evolution-data-server-online-accounts \
example-content \
fortune-mod \
friends \
friends-dispatcher \
friends-facebook \
friends-twitter \
gbrainy \
gnome-cards-data \
gnome-contacts \
gnome-games \
gnome-mahjongg \
gnome-mines \
gnome-orca \
gnome-orca \
gnome-screensaver \
gnome-sudoku \
gnome-video-effects \
gnomine \
landscape-common \
libevolution \
libreoffice-avmedia-backend-gstreamer \
libreoffice-ogltrans \
libsane \
libsane-common \
mcp-account-manager-uoa \
mono-common \
nautilus-sendto-empathy \
ppp \
pppconfig \
pppoeconf \
python3-uno \
rhythmbox \
rhythmbox-plugin-zeitgeist \
rhythmbox-plugins \
sane-utils \
shotwell \
shotwell-common \
telepathy-gabble \
telepathy-haze \
telepathy-idle \
telepathy-indicator \
telepathy-logger \
telepathy-mission-control-5 \
telepathy-salut \
thunderbird \
thunderbird-gnome-support \
transmission-common \
transmission-gtk \
ubuntu-artwork \
ubuntu-software \
ubuntu-touch-sounds \
ubuntu-wallpapers-xenial \
unity-scope-audacious \
unity-scope-chromiumbookmarks \
unity-scope-clementine \
unity-scope-colourlovers \
unity-scope-devhelp \
unity-scope-firefoxbookmarks \
unity-scope-gdrive \
unity-scope-gmusicbrowser \
unity-scope-gourmet \
unity-scope-manpages \
unity-scope-musicstores \
unity-scope-musique \
unity-scope-openclipart \
unity-scope-texdoc \
unity-scope-tomboy \
unity-scope-video-remote \
unity-scope-virtualbox \
unity-scope-yelp \
unity-scope-zotero \
wvdial"

sws="
totem* \
ubuntu-desktop* \
remmina* \
unity-webapps-*"

pprint "Packages: "$pkgs
pprint "Softwares: "$sws

$br_purge $pkgs
$br_purge $sws

log $INFO "<dpkg conf>"
$dry_echo sudo dpkg --configure -a

log $INFO "stage 2: autoremove"
$dry_echo sudo apt -y autoremove
# these did not work at all: package did not exist : hence keeping these lines commented
#log $INFO "beagle:"
#sudo apt-get purge -y libbeagle1
#log $INFO "contact bs:"
#sudo apt-get purge -y contact-lookup-applet
#log $INFO "openoffice:"
#sudo apt-get purge -y openoffice.org-calc openoffice.org-draw openoffice.org-impress openoffice.org-writer openoffice.org-base-core


## disables evolution services that are not too helpful anyway
log $INFO "stage 3: Disable evolution-services"
$dry_echo cd /usr/share/dbus-1/services
$dry_echo sudo ln -snf /dev/null  org.gnome.evolution.dataserver.AddressBook.service  
$dry_echo sudo ln -snf /dev/null  org.gnome.evolution.dataserver.Calendar.service 
$dry_echo sudo ln -snf /dev/null  org.gnome.evolution.dataserver.Sources.service 
$dry_echo sudo ln -snf /dev/null  org.gnome.evolution.dataserver.UserPrompter.service

## clicking on dock icons toggles minimizes the application
$dry_echo gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'

exit 0
