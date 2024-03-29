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

Made for use with this base image: https://www.google.com/url?q=https://downloads.raspberrypi.org/raspbian/images/raspbian-2018-06-29/&sa=D&source=hangouts&ust=1542944842860000&usg=AFQjCNGR9aADpKWaoRwloDp-G8cnk1xt_w

First navigate to the folder where you downloaded this repo then:
`./imageBuild.sh -vcnm`

The exact paramaters to build the image being used by T3 is 
`./imageBuild.sh -vcnprbi`
which is enabling everything except the led matrix specific config 

Make sure to watch the script because there are a few prompts you have to say 'yes' too, but make sure to say 'no' to all reboot prompts, some installers try and get you to reboot before the imageBuild is done 

script works better if **not** run as root! 

After the script is finalized, shutdown the pi and grab the image; if you do restart then don't close the 'first boot' help service because it deletes itself after running once; this process also expands the image if it was shrunk.

## How to get started!

try these commands (in order) 
```
sudo apt-get install git -y  
git clone https://github.com/easybotics/t3-rpi-config-script 
cd t3-rpi-config-script 
./imageBuild.sh -vcnprbi
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

## Image checklist

* go through setup screen & choose keyboard
* apt update && apt full-upgrade
* run t3 script with -vcni
* reboot
* make sure node-red is set up correctly
* set wallpaper
* run t3 script with -prb
* rm t3 setup repo
* clear browser and bash history
* empty trash
* power off
* dd:
  ```sh
  sudo dd if=/dev/sdX of=t3.img status=progress
  ```
* pishrink:
  ```sh
  sudo ./pishrink.sh -v t3.img
  ```

## Creating piper images from T3 images

The piper images just need a small modification in `/boot/config.txt` to fix the
display resolution. This can be patched on a running image with the
`piper_patch_running.sh` script:

```
sudo ./piper_patch_running.sh
```

Alternatively, this can be done on an existing image file to create a piper
version of that exact image with the `piper_patch_img.sh` script (requires
parted to be installed):

```
sudo ./piper_patch_img.sh t3_image_file.img t3_image_file_patched.img
```
