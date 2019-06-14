#!/bin/bash

set -e

#### Hack RaspberryPi (Zero W bcm43430's) or (3B+ bcm43455c0's) driver for WiFi
##   Author: Maximus Baton

is_pizero() {
   grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]0[9cC][0-9a-fA-F]$" /proc/cpuinfo
   return $?
}

echo -e "== [$(date '+%Y-%m-%d %H:%M:%S')] ============= HACK brcmfmac === START ="


# Install the kernel headers to build the driver and some dependencies
apt-get update -y
apt install -y raspberrypi-kernel-headers git libgmp3-dev gawk qpdf bison flex make
apt-get install -y autoconf automake build-essential libtool

cd ~ && rm -f -r brcmfmac_driverHack
cd ~ && mkdir -p brcmfmac_driverHack && cd brcmfmac_driverHack

# I use my repo as made some mutes&fixes on warnings
git clone https://github.com/MaximusBaton/nexmon.git

# Go into the root directory of our repository
cd nexmon

# Check if /usr/lib/arm-linux-gnueabihf/libisl.so.10 exists
if [[ -e "/usr/lib/arm-linux-gnueabihf/libisl.so.10" ]]; then
    echo "libisl.so.10 exists. skipping"
else 
    cd buildtools/isl-0.10
    autoreconf -f -i
    ./configure
    make
    make install
    ln -s /usr/local/lib/libisl.so /usr/lib/arm-linux-gnueabihf/libisl.so.10
    cd ../..
fi


# Compile some build tools and extract the ucode and flashpatches from the original firmware files
make

# Go to the patches folder for the bcm43430a1/bcm43455c0 chipset
if is_pizero ; then
    cd patches/bcm43430a1/7_45_41_46/nexmon/
else
    cd patches/bcm43455c0/7_45_154/nexmon/
fi

# Compile a patched firmware
make

# Generate a backup of your original firmware file (e.g. will run: cp /lib/firmware/brcm/brcmfmac43430-sdio.bin brcmfmac43430-sdio.bin.orig)
make backup-firmware

# Install the patched firmware on your RPI3
make install-firmware

# Install nexutil
#   from the root directory of our repository switch to the nexutil folder
cd ../../../../utilities/nexutil/
#   Compile and install nexutil
make && make install

# Return back to root nexmon directory
cd ../..


# Optional: remove wpa_supplicant for better control over the WiFi interface
# apt-get remove -y wpasupplicant


# Setup a new 'monitor mode' interface 'mon0'
iw phy `iw dev wlan0 info | gawk '/wiphy/ {printf "phy" $2}'` interface add mon0 type monitor
# Set the interface up to activate monitor mode in the firmware
ifconfig mon0 up
#   At this point, monitor mode is active. There is no need to call airmon-ng.
#   The interface already set the Radiotap header, therefore, tools like tcpdump or airodump-ng can be used out of the box: tcpdump -i mon0


## To make the RPi load the modified driver after reboot
# Find the path of the default driver at reboot
# e.g. '/lib/modules/4.14.71-v7+/kernel/drivers/net/wireless/broadcom/brcm80211/brcmfmac/brcmfmac.ko'
PATH_OF_DEFAULT_DRIVER_AT_REBOOT=$(modinfo brcmfmac | grep -m 1 -oP "^filename:(\s*?)(.*)$" | sed -e 's/^filename:\(\s*\)\(.*\)$/\2/g')
# Backup the original driver
mv $PATH_OF_DEFAULT_DRIVER_AT_REBOOT "$PATH_OF_DEFAULT_DRIVER_AT_REBOOT.orig"
# Copy the modified driver (Kernel 4.14)
if is_pizero ; then
    cp ./patches/bcm43430a1/7_45_41_46/nexmon/brcmfmac_4.14.y-nexmon/brcmfmac.ko $PATH_OF_DEFAULT_DRIVER_AT_REBOOT
else
    cp ./patches/bcm43455c0/7_45_154/nexmon/brcmfmac_4.14.y-nexmon/brcmfmac.ko $PATH_OF_DEFAULT_DRIVER_AT_REBOOT
fi
# Probe all modules and generate new dependency
depmod -a


sleep 1

cd ~ && rm -r brcmfmac_driverHack

echo -e "== [$(date '+%Y-%m-%d %H:%M:%S')] ============= HACK brcmfmac === END ==="
