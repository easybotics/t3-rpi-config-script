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

**-b** replace piwiz binary with a cutdown one

**-i** enable camera, I2c, and serial UART

## example usage:

Use 8GB SD Card - makes the DD and Pishrink process faster

First navigate to the folder where you downloaded this repo then:
`./imageBuild.sh -vcnm`

The exact paramaters to build the image being used by T3 is 
`./imageBuild.sh -vcnprbi`
which is enabling everything except the led matrix specific config 

script works better if **not** run as root! 

## How to get started!

try these commands (in order) 
```
sudo apt-get install git -y  
git clone https://github.com/easybotics/t3-rpi-config-script 
cd t3-rpi-config-script 
./imageBuild.sh -vcnm
``` 

## Extra!

To backup the image you created, insert the SD card into a device running linux with enough free storage space to comfortably hold the full size of your pi. Then find the device name by running 
sudo fdisk -l and looking for something like:
```
Disk /dev/sda: 14.9 GiB, 15931539456 bytes, 31116288 sectors
Disk model: STORAGE DEVICE  
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xafe59c2e

Device     Boot Start      End  Sectors  Size Id Type
/dev/sda1        8192    96663    88472 43.2M  c W95 FAT32 (LBA)
/dev/sda2       98304 14434303 14336000  6.9G 83 Linux 
```

in this case the device name is sda, and it has 2 partitions sda1 and sda2
to clone theis device into an image file use the command

`sudo dd if=/dev/sda of=/home/pi/backup.img bs=1M progress=status`
this will clone the device *sda* into the file *backup.img* in your home folder

To collect a shrinked image you can use the shrink.sh script hosted here: 
https://github.com/qrti/shrink

uses nice onscreem instructions and some light configuration.
The extent of the configuation is finding your drive name using the fdisk -l trick from above, and inserting it into the shrink.sh file as described in their readme

