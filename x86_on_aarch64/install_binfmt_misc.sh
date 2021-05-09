#!bin/bash
#
# If you are missing binfmt_misc.ko under /lib/modules,
# you need to build LK with "CONFIG_BINFMT_MISC=y" in .config.
# This is how to do that.
#
# Reference:
# https://qiita.com/progrunner/items/d2ab0a85b3881a4b7ed8#ubuntu%E5%90%91%E3%81%91%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%AE%E5%8F%96%E5%BE%97
#

# -----------
# reduce MAX_SPEED down to 1.0GHz, 
# otherwize compile will stop during process.
# -----------
MAX_SPEED=`grep MAX_SPEED /etc/default/cpufrequtils | sed -e 's/MAX_SPEED=//'`
if [ $MAX_SPEED -gt 1200000 ]; then 
  sudo perl -pi -e 's/MAX_SPEED=\d+/MAX_SPEED=1200000/' /etc/default/cpufrequtils
  echo "/etc/default/cpufrequtils MAX_SPEED is changed, reboot in 10sec"
  sleep 10
  sudo reboot
else
  echo "MAX_SPEED is set to ${MAX_SPEED}. It is safe to proceed kernel compile."
  echo ""
  sleep 2
fi


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
WORK_DIR=/tmp/LK$LK
if [ ! -d $WORK_DIR ]; then
  mkdir -p $WORK_DIR 
fi

# --------------------------------------------------
# change /etc/apt/sources.list to aceess source
# --------------------------------------------------
sudo sed -i -e "s/^#\s*deb-src /deb-src /" /etc/apt/sources.list 
sudo apt -y update
sudo apt -y upgrade

# --------------------------------------------------
# install dependencies and source
# --------------------------------------------------
sudo apt -y install build-essential libncurses-dev flex bison openssl \
  libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf

# git pull source code
cd $WORK_DIR

if [ $LK == 4.9 ]; then
  aria2c -x2 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/snapshot/linux-4.9.268.tar.gz
  tar -zxvf linux-4.9.268.tar.gz
  ln -sf linux-4.9.268 linux
else
  git clone --depth 1 https://github.com/torvalds/linux.git -b v$LK
fi

mkdir -p $WORK_DIR/build

# --------------------------------------------------
# Step.2 Prepare kernel build bench(~/work/LK$LK)
# --------------------------------------------------
cp /boot/config-`uname -r` $WORK_DIR/build/.config
echo "#MODIFY to compile BINFMT_MISC module(fs/binfmt_misc.ko)." >> $WORK_DIR/build/.config
echo "CONFIG_BINFMT_MISC=y" >> $WORK_DIR/build/.config
cd $WORK_DIR/linux &&  make olddefconfig O=../build
cd $WORK_DIR/build &&  yes "" | make oldconfig
# modify params in .config?

#
# Step.3 make module
#
cd $WORK_DIR/build &&  LOCALVERSION=-mybuild make -j$CPU
#cd $WORK_DIR/build &&  sudo make modules_install

# or to shoot all modules
# make EXTRAVERSION=`uname -r` modules_prepare
# make modules -j$CPU

#
# Step.4 check your binfmt_misc.ko then move to /fs
#
