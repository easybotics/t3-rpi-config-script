# Teaching Through Technology (T3) Raspberry Pi (RPi) Configuration Script

Configuration script to help setup some useful options on a new Raspberry Pi, especially with the [T3/easybotics RPi kit](https://www.easybotics.com/product/rpi-kit-10inch/).  The script customizes a Raspbian image by making the follow changes: 
* google chrome config with default bookmarks
* sets the desktop wallpaper
* installs node-red nodes required by the [T3 Raspberry Pi curriculum](https://t3alliance.org/raspberry-pi-overview-page/)

Script is a work in progress.  
TODO List:
* Must install node-red first - not pre-installed on new default images
* needs sudo apt-get install npm
* needs to add 127.0.0.1:1880 to the browser shortcuts
* needs to update node-red

## `t3-rpi-config-script`

This script accepts 5 flags 

**-v** Enable extra verbosity

**-c** install easybotics configs for chrome, set the wallpaper, and add desktop icons 

**-n** install node-red nodes, and libraries to support them such as bme280 and neopixel nodes 

**-m** install easybotics led-matrix nodes, and setup node-red to run as root on startup by default 

## example usage:
First navigate to the folder where you downloaded this repo then:
`sudo sh imageBuild.sh -vcn`
