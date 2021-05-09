#!bin/bash
#
# If you are missing binfmt_misc.ko under /lib/modules,
# you need to build LK with "CONFIG_BINFMT_MISC=y" in .config.
# This is how to do that.
#
# Reference:
# https://wiki.archlinux.jp/index.php/%E3%82%AB%E3%83%BC%E3%83%8D%E3%83%AB%E3%83%A2%E3%82%B8%E3%83%A5%E3%83%BC%E3%83%AB%E3%81%AE%E3%82%B3%E3%83%B3%E3%83%91%E3%82%A4%E3%83%AB
#

#
# Step.0 expand swap x2
#
sudo apt-get -y install zram-config
swapon -s 
ZRAM_SIZE=`swapon -s | grep zram0 | awk '{ print $3 }'`
#$> cat /sys/block/zram1/disksize 
#268435456
if [ $ZRAM_SIZE -lt 500000 ]; then
  sudo sed -i -e 's/1024))/2048))/' /usr/bin/init-zram-swapping
  sudo reboot
fi

#
# Step.1 Prepare source and dependencied
#
CPU=`nproc`
LK=`uname -r | awk -F'.' '{printf $1"."$2}'`
sudo apt -y update
sudo apt -y upgrade
sudo apt -y install linux-source
sudo apt -y install build-essential libncurses-dev flex bison openssl \
  libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf

#
# Step.2 Prepare kernel build bench(~/work/LK$LK)
#
WORK_DIR=${HOME}/work/LK$LK
#WORK_DIR=/usr/src
mkdir -p ${WORK_DIR}
if [ ! -f ${WORK_DIR}/linux*.tar.bz2 ]; then
  cp /usr/src/linux*.tar.bz2 ${WORK_DIR}
fi
chmod -R 777 ${WORK_DIR}
cd ${WORK_DIR} && tar jxvf linux*.tar.bz2
cd `ls | grep -v tar.bz2` && cp /boot/config-`uname -r` ./.config
echo "#MODIFY to compile BINFMT_MISC module(fs/binfmt_misc.ko)." >> .config
echo "CONFIG_BINFMT_MISC=y" >> .config
yes "" | make oldconfig
# modify params in .config?

#
# Step.3 make module
#
make -j$CPU
# or to shoot all modules
# make EXTRAVERSION=`uname -r` modules_prepare
# make modules -j$CPU

#
# Step.4 check your binfmt_misc.ko then move to /fs
#
