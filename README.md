# Teaching Through Technology (T3) Raspberry Pi (RPi) Configuration Script

Configuration script to help setup some useful options on a new Raspberry Pi, especially with the [T3/easybotics RPi kit](https://www.easybotics.com/product/rpi-kit-10inch/).  The script customizes a Raspbian image by making the follow changes: 
* google chrome config with default bookmarks
* sets the desktop wallpaper
* installs node-red nodes required by the [T3 Raspberry Pi curriculum](https://t3alliance.org/raspberry-pi-overview-page/)

Script is a work in progress.  

## `t3-rpi-config-script`

This script accepts 5 flags 

**-v** Enable extra verbosity

**-c** install easybotics configs for chrome, set the wallpaper, and add desktop icons 

**-n** install node-red nodes, and libraries to support them such as bme280 and neopixel nodes 

**-m** install easybotics led-matrix nodes, and setup node-red to run as root on startup by default 

**-p** reenable the user friendly 'first boot' service 

**-r** enable boot time resizing of the sd image 

**-i** enable camera, I2c, and serial UART

## example usage:

Use 8GB SD Card - makes the DD and Pishrink process faster

First navigate to the folder where you downloaded this repo then:
`./imageBuild.sh -vcnm`

script works better if **not** run as root! 

## How to get started!

try these commands (in order) 
```
sudo apt-get install git -y  
git clone https://github.com/easybotics/t3-rpi-config-script 
cd t3-rpi-config-script 
./imageBuild.sh -vcnm
``` 

