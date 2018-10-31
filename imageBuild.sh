#!/bin/bash

#declare a list of config archives we prepared earlier 
configFiles="google_chrome_config.tar.gz desktop_config.tar.gz" 

piwiz="piwiz.tar.gz"
flows="node_red_root_config.tar.gz"
rootRed="node_red_root_config.tar.gz"

#declare a list of npm packages we want to dump into the ~/.node-red folder 
nodePackages=\
"node-red-contrib-camerapi node-red-node-pi-neopixel node-red-node-pisrf\
 node-red-dashboard node-red-contrib-dht-sensor node-red-contrib-oled\
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


while getopts "vcnmwpri" opt; 
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
			;;

		i) 
			if $verbose; then echo "enabling hardware interfaces" >&2 
			fi
			interfaceFlag=true 
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
	sudo apt-get update -y
	sudo apt-get upgrade -y --fix-missing 
	sudo apt-get install -y npm 
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
fi

if $piwizFlat
then 
	sudo tar -xzf $piwiz -C /
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
	bash <(curl -sL https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/update-nodejs-and-nodered)
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
			key_mgmt=WPKA-PSK
		}'>>/etc/wpa_supplicant/wpa_supplicant.conf  
fi

read -p "Would you like to reboot now (recommended) Y/N" -n 1 -r 
echo 
if [[ $REPLY =~ ^[Yy]$ ]] 
then 
	sudo reboot

fi

if $bootResizeFlag 
then 
	echo "enabling boot-resize" 
	sudo echo 'init=/usr/lib/raspi-config/init_resize.sh' >> /boot/cmdline.txt
fi

if $interfaceFlag 
then 
	echo "enabling interfaces" 
	sudo raspi-config nonint do_camera 0 
	sudo raspi-config nonint do_i2c 0 
	sudo raspi-config nonint do_serial 2
fi 

	
