#!/bin/sh
set -e # Die if a command fails


force='n'
scriptdir="$(dirname "$0")"

if [ "$(id -u)" -ne 0 ]; then
	echo 'Script must be run as root.' >&2
	exit 1
fi

patch "/boot/config.txt" <"$scriptdir/config.txt.piper.patch"

echo 'System patched successfully.'
