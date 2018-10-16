# t3-rpi-config-script
script to help setup some useful options on a rpi, especially with the T3/easybotics kit

This script accepts 5 flags 

**-v** Enable extra verbosity

**-c** install easybotics configs for chrome, set the wallpaper, and add desktop icons 

**-n** install node-red nodes, and libraries to support them such as bme280 and neopixel nodes 

**-m** install easybotics led-matrix nodes, and setup node-red to run as root on startup by default 

example usage:
sudo ./imageBuild.sh -vcn 

sets up google chrome configs, sets the wallpaper, and installs a bunch of nodes 
