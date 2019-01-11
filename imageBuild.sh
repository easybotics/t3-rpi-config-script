#!/bin/bash

#declare a list of config archives we prepared earlier 
configFiles="google_chrome_config.tar.gz desktop_config.tar.gz xconfig.tar.gz rootFM.tar.gz bar.tar.gz" 

piwiz="piwiz.tar.gz"
flows="node_red_root_config.tar.gz"
rootRed="node_red_root_config.tar.gz"

#declare a list of npm packages we want to dump into the ~/.node-red folder 
nodePackages=\
"node-red-contrib-camerapi node-red-node-pi-neopixel node-red-node-pisrf\
 node-red-dashboard node-red-contrib-oled\
 node-red-contrib-bme280 node-red-contrib-cpu node-red-contrib-hostip\
 node-red-node-ping node-red-contrib-thingspeak42\
 node-red-contrib-easybotics-air-quality"

#some flags to set which configuration we'll do, most are true by default
verbose=false
configCopy=false
node=false
ledMatrix=false
wifi=false
piwizFlag=false
bootResizeFlag=false
interfaceFlag=false
piwizBinFlag=false


while getopts "vcnmwprib" opt; 
do 
	case $opt in 
		v)
			echo "enabling verbosity" >&2
			verbose=true 
			;;
		c)
			if $verbose; then echo "enabling easybotics configs for chrome ect" >&2 
			fi
			configCopy=true 
			;;
		n)
			if $verbose; then echo "installing node-red nodes and sensor libraries" >&2 
			fi
			node=true 
			;;
		m)
			if $verbose; then echo "installing led-matrix libraries and nodes" >&2 
			fi
			ledMatrix=true 
			;;
		w)
			if $verbose; then echo "appending default wifi connection" >&2 
			fi
			wifi=true 
			;;
		p) 
			if $verbose; then echo "enabling the user-friendly autostart service" >&2 
			fi 
			piwizFlag=true 
			;;

		r) 
			if $verbose; then echo "enabling image expansion on reboot" >&2 
			fi
			bootResizeFlag=true 
			piwizFlag=true
			piwizBinFlag=true
			;;

		i) 
			if $verbose; then echo "enabling hardware interfaces" >&2 
			fi
			interfaceFlag=true 
			;;

		b) 
			if $verbose; then echo "replacing piwiz binary with cut one" >&2
			fi
			piwizBinFlag=true
			;;

		\?)
			echo "invalid option: -$OPTARG" >&2
			;;
	esac 
done 

read -p "Would you like to update packages before starting (recommended) Y/N" -n 1 -r 
echo 
if [[ $REPLY =~ ^[Yy]$ ]] 
then 
	sudo apt-mark hold raspberrypi-kernel
	sudo apt-get update -y
	sudo apt-get upgrade -y --fix-missing 
	sudo apt-get install -y npm
	sudo apt-get install -y xscreensaver
	sudo apt-get install -y python-games
	sudo apt-get install -y ntfs-3g
	sudo npm install npm@latest --unsafe-perm -g

fi


if $configCopy 
then
	#force hdmi audio 
	sudo amixer cset numid=3 2

	#loop over the archives, curl each one and pipe it into tar to unpack them 
	for i in $configFiles
	do
		echo "downloading and unpacking $i"
		sudo tar -xzf $i -C / 
	done 

	#give ownership of root settings for node-red..
	sudo chown pi /root/.node-red/settings.js

	#install imagemagick 
	sudo apt-get update
	sudo apt-get install -y imagemagick 

	#loop over wallpapers and super-impose t3 logo 
	for i in /usr/share/rpd-wallpaper/*.jpg 
	do
		echo "imposing wallpaper on: $i"
		sudo composite placeholder.png $i -alpha Set $i
	done
fi

if $piwizFlag
then 
	sudo tar -xzf piwiz.tar.gz -C /
fi

if $piwizBinFLag
then
	mkdir /home/pi/piwiz
	tar -xzf piwiz_stand.tar.gz -C /home/pi/
	location=/usr/bin/piwiz
	sudo mv $location $location.old
	sudo ln -s	/home/pi/.piwiz/run.sh $location
	chmod +x /home/pi/.piwiz/run.sh
fi
			
if $ledMatrix 
then

	#TODO: setup icons and menu items 
	echo "installing node-red stuff" 
	#setup node-red autostart 
	sudo systemctl enable nodered.service 
	sudo npm config set unsafe-perm true 
	npm i --save --prefix /home/pi/.node-red node-red-contrib-easybotics-led-matrix

	d=/lib/systemd/system/nodered.service && sudo sed "s/User=pi/User=root/;s/Group=pi/Group=root/" $d > tmp && sudo mv -f tmp $d
#	d=/root/.node-red/settings.js && sudo sed "/.*userDir:*./c\userDir: '\/home\/pi\/.node-red\/'," $d > tmp && sudo mv -f tmp $d
	d=/boot/config.txt && sudo sed "/.*dtparam=audio=on*./c\dtparam=audio=off" $d > tmp && sudo cp -f tmp $d


	sudo tar -xzf $flows -C /
	sudo tar -xzf $rootRed -C /
fi

if $node 
then 
	echo "install node-red and nodejs"
	bash node-install-script.sh
	echo "presetup, neopixel and dht"

	#neopixel setup 
	curl -sS get.pimoroni.com/unicornhat | bash

	#dht setup
	bash akil_dht.sh

	npm update --save --prefix /home/pi/.node-red 
	#loop over the npm packages, install each one in the ~/.node-red 
	for i in $nodePackages 
	do 
		echo "installing $i" 
		npm i --save --prefix /home/pi/.node-red $i
	done 
fi

if $wifi 
then
	echo "setting up a wifi connection : rpi" 
	sudo echo 'network={
			ssid="rpi"
			psk="raspberry"
			key_mgmt=WPA-PSK
		}'| sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf  
fi




if $interfaceFlag 
then 
	echo "enabling interfaces" 
	sudo raspi-config nonint do_camera 0 
	sudo raspi-config nonint do_i2c 0 
	sudo raspi-config nonint do_serial 2
	sudo raspi-config nonint do_ssh 1
	sudo raspi-config nonint do_resolution 2 27
	echo "enabled interfaces"
fi 

read -p "Would you like to reboot now (recommended) Y/N" -n 1 -r 
echo 
if [[ $REPLY =~ ^[Yy]$ ]] 
then 
	sudo reboot

fi
