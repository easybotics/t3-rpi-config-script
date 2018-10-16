#declare a list of config archives we prepared earlier 
configFiles="https://u.teknik.io/loP2U.gz https://u.teknik.io/3gNJJ.gz" 

#declare a list of npm packages we want to dump into the ~/.node-red folder 
nodePackages=\
"node-red-contrib-camerapi node-red-node-pi-neopixel node-red-node-pisrf node-red-contrib-easybotics-led-matrix"

#some flags to set which configuration we'll do, most are true by default
verbose=false
configCopy=false
node=false
ledMatrix=false
wifi=false


while getopts ":v:c:n:m:w" opt; 
do 
	case $opt in 
		v)
			echo "enabling verbosity" >&2
			verbose=true 
			;;
		c)
			if verbose then echo "enabling easybotics configs for chrome ect" >&2 fi
			configCopy=true 
			;;
		n)
			if verbose then echo "installing node-red nodes and sensor libraries" >&2 fi
			node=true 
			;;
		m)
			if verbose then echo "installing led-matrix libraries and nodes" >&2 fi
			ledMatrix=true 
			;;
		w)
			if verbose then echo "appending default wifi connection" >&2 fi
			wifi=true 
			;;

		\?)
			echo "invalid option: -$OPTARG" >&2
			;;
	esac 
done 

if $configCopy 
then
	#loop over the archives, curl each one and pipe it into tar to unpack them 
	for i in $configFiles
	do
		echo "downloading and unpacking $i"
		curl "$i" | tar -xzf - -C / 
	done 
fi
			
if $ledMatrix 
then

	#TODO: setup icons and menu items 
	echo "installing node-red stuff" 
	setup node-red autostart 
	systemctl enable nodered.service 
	npm config set unsafe-perm true 
	d=/lib/systemd/system/nodered.service && sudo sed "s/User=pi/User=root/;s/Group=pi/Group=root/" $d > tmp && sudo mv -f tmp $d
	d=/root/.node-red/settings.js && sudo sed "/.*userDir:*./c\userDir: '\/home\/pi\/.node-red\/'," $d > tmp && sudo mv -f tmp $d
	d=/boot/config.txt && sudo sed "/.*dtparam=audio=on*./c\dtparam=audio=off" $d > tmp && sudo cp -f tmp $d
fi

if $node 
then 
	#loop over the npm packages, install each one in the ~/.node-red 
	for i in $nodePackages 
	do 
		echo "installing $i" 
	#	npm i --prefix /home/pi/.node-red $i
	done 
fi

if $wifi 
then
	echo "setting up a wifi connection : rpi" 
	echo 'network={
			ssid="rpi"
			psk="raspberry"
			key_mgmt=WPKA-PSK
		}'>>/etc/wpa_supplicant/wpa_supplicant.conf  
fi
