#!/bin/sh
set -e # Die if a command fails


cleanup()
{
	if [ -n "$loopdev" ]; then
		set +e # Don't die if one of these commands fails. Do as much cleanup as possible.
		sleep 1 # Without this, umount sometimes fails, I guess we're mounting and unmounting too fast or something
		umount "$mntdir"
		losetup -d "$loopdev"
		rmdir "$mntdir"
	fi
}


# Run cleanup function when we exit, whether it's a clean exit or due to an issue
trap cleanup EXIT


mntdir='tmp_mount'
scriptdir="$(dirname "$0")"


if [ "$(id -u)" -ne 0 ]; then
	echo 'Script must be run as root.' >&2
	exit 1
fi

if [ "$#" -eq 2 ]; then
	if [ -e "$2" ]; then
		echo "Destination file $2 already exists." >&2
		exit 2
	fi
	echo "Copying $1 to $2"
	cp "$1" "$2"
	if [ -n "$SUDO_USER" ] && [ -n "$SUDO_GID" ]; then
		chown "$SUDO_USER:$SUDO_GID" "$2"
	fi
	img="$2"
elif [ "$#" -eq 1 ]; then
	img="$1"
else
	echo "Usage: $0 in_img [out_img]" >&2
	exit 1
fi


parted_output="$(parted -ms "$img" unit B print)"
partnum="$(echo "$parted_output" | grep fat32 | head -n 1 | cut -d ':' -f 1)"
partoffset="$(echo "$parted_output" | grep fat32 | head -n 1 | cut -d ':' -f 2 | tr -d 'B')"


loopdev="$(losetup -f --show -o "$partoffset" "$img")"
mkdir "$mntdir"
mount "$loopdev" "$mntdir"

patch "$mntdir/config.txt" <"$scriptdir/config.txt.piper.patch"

echo 'Image patched successfully.'
# Note: cleanup (umount, losetup, rmdir) handled by cleanup function on exit
