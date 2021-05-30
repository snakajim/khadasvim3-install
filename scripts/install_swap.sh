#!/bin/bash
#
# Adding extra 4GByte swap under /swapfile
#

#
# check available space under /
#
SWAPABLE=`df -h / | grep -e "\/" | awk '{ print $4 }' | sed "s/G//"`

if [ $SWAPABLE -ge "16" ] && [ ! -f /swapfile ]; then
  sudo swapon -show | grep swapfile
  ret=$?
  if [ $ret -eq "0" ]; then
    echo "You have already had /swapfile."
    echo "Program exit."
    sleep 10
    exit
  fi
  echo "Make 4GByte SWAP under /dev/rootfs."
else
  echo "Not enough space left for SWAP under /, or,"
  echo "/swapfile is already existing."
  echo "Program exit."
  sleep 10
  exit 
fi

sudo fallocate -l 4G /swapfile
if [ ! -f /swapfile ]; then
  echo "/swapfile was not created. Program exit."
  sleep 10
  exit
fi

sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
SWAPSIZE=`sudo swapon --show | grep /swapfile | awk '{ print $3 }'`
sudo sh -c \
  "echo '#/swapfile     none     swap     sw     0 0' > /etc/fstab.swap"
if [ $SWAPSIZE = "4G" ]; then
  echo "4GByte SWAP is generated under /swapfile."
else
  echo "/swapfile is not generated for SWAP."
  echo "Program exit."
  sleep 10
  exit 
fi

grep swapfile /etc/fstab
ret=$?
if [ $ret -eq "1" ]; then
  sudo sh -c \
    "cat /etc/fstab.swap >> /etc/fstab"
  echo "To perpetualize your /swapfile, please update /etc/fstab."
fi
