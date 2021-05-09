#!/bin/bash
#
# https://docs.khadas.com/vim3/UpgradeViaUSBCable.html
#

ARCH=amd64
#ARCH=arm64v8

if [ -f /etc/lsb-release ]; then
  DISTRIB_CODENAME=`cat /etc/lsb-release | grep DISTRIB_CODENAME | sed -E "s/^DISTRIB_CODENAME=//"`
  #DISTRIB_CODENAME=xenial
  DISTRIB_CODENAME=groovy
else
  echo "Please choose Ubuntu host."
  echo "This script only supports Ubuntu Container on Ubuntu Host."
  exit
fi

# ----------------------------------
# Step 1. USB connection check
# ----------------------------------

lsusb | grep Amlogic
RET=$?
if [ $RET -eq 1 ]; then
  echo "Kahdas board is not connected in USB port."
  echo "Please see man in https://docs.khadas.com/vim3/UpgradeViaUSBCable.html"
  echo "Program exit"
  exit
fi

# ----------------------------------
# Step 2. Download Burning Tool on x86_docker, but not install(does not work!)
# ----------------------------------

# Ubuntu 20.04 LTS
docker system prune -f 
docker pull multiarch/ubuntu-core:$ARCH-$DISTRIB_CODENAME
docker run --rm --privileged aptman/qus -- -r
docker run --rm --privileged aptman/qus -s -- -p x86_64

# docker build
docker rmi -f usbc_writer:$ARCH
docker system prune -f
docker build -t usbc_writer:$ARCH -<<EOF
#FROM multiarch/ubuntu-core:$ARCH-$DISTRIB_CODENAME
FROM $ARCH/ubuntu:$DISTRIB_CODENAME
ENV TZ Asia/Tokyo
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]
RUN apt-get -y update && apt-get install -y tzdata
RUN apt-get -y upgrade
RUN apt-get -y install usbutils udev
RUN apt-get -y install git
RUN apt-get -y install build-essential sudo aria2
RUN apt-get -y install libusb-dev parted
RUN mkdir -p /root/tmp
RUN cd /root/tmp && \
  git clone https://github.com/khadas/utils
RUN mkdir -p /root/images
RUN aria2c -x2 http://www.linux-usb.org/usb.ids -o /var/lib/usbutils/usb.ids.new
RUN cp -rf /var/lib/usbutils/usb.ids.new /var/lib/usbutils/usb.ids
EOF


# ----------------------------------
# Step 3. Run container and make sure USB access, then install burning tool
# ----------------------------------
#docker run --privileged --device=/dev/usb:/dev/usb --rm -it usbc_writer /bin/bash
docker run --rm --privileged aptman/qus -- -r
docker run --rm --privileged aptman/qus -s -- -p x86_64
docker run -itd --privileged --device=/dev:/dev --name "writer_$ARCH" usbc_writer:$ARCH /bin/bash
#docker exec writer_$ARCH sudo touch /etc/udev/rules.d/70-persistent-usb.rules
#docker exec writer_$ARCH sudo sh -c 'echo "SUBSYSTEMS=="usb",ATTRS{idVendor}=="1b8e",ATTRS{idProduct}=="c003",OWNER="yourUserName",MODE="0666",SYMLINK+="worldcup"" > /etc/udev/rules.d/70-persistent-usb.rules'
docker exec writer_$ARCH sudo service udev restart
docker exec writer_$ARCH sudo udevadm control --reload-rules
if [ $ARCH == "amd64" ];  then
  docker exec writer_$ARCH sh -c "cd /root/tmp/utils && sudo ./INSTALL"
  docker exec writer_$ARCH sh -c "echo 'aml-burn-tool install is done'"
  docker exec writer_$ARCH sh -c "which aml-burn-tool"
fi
docker exec writer_$ARCH sh -c "lsusb"
docker exec writer_$ARCH sh -c "lsusb | grep Amlogic"
docker exec writer_$ARCH sh -c "lsusb -t"


# ----------------------------------
# Step 4. Image burning and close
# ----------------------------------
# Burn images
if [ ! -f VIM3_Ubuntu-gnome-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz ];then
  aria2c -x2 https://downloads.khadas.com/Firmware/Krescue/images/VIM3_Ubuntu-gnome-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz
fi

if [ ! -f VIM3_Ubuntu-server-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz ]; then
  aria2c -x2 https://downloads.khadas.com/Firmware/Krescue/images/VIM3_Ubuntu-server-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz
fi

if [ ! -f VIM3_Ubuntu-server-focal_Linux-4.9_arm64_EMMC_V1.0.5-210430.raw.img.xz ]; then
  aria2c -x2 https://downloads.khadas.com/Firmware/Krescue/images/VIM3_Ubuntu-server-focal_Linux-4.9_arm64_EMMC_V1.0.5-210430.raw.img.xz
fi

if [ ! -f VIM3_Ubuntu-gnome-focal_Linux-4.9_arm64_EMMC_V1.0.5-210430.raw.img.xz ]; then
  aria2c -x2 https://downloads.khadas.com/Firmware/Krescue/images/VIM3_Ubuntu-gnome-focal_Linux-4.9_arm64_EMMC_V1.0.5-210430.raw.img.xz
fi

docker cp ./VIM3_Ubuntu-gnome-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz \
  writer_$ARCH:/root/images/VIM3_Ubuntu-gnome-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz
docker cp ./VIM3_Ubuntu-server-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz \
  writer_$ARCH:/root/images/VIM3_Ubuntu-server-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz
docker exec writer_$ARCH sh -c "echo 'Copying img file in docker.'"
docker exec writer_$ARCH sh -c "ls -la /root/images/"
if [ $ARCH == "amd64" ];  then
  docker exec writer_$ARCH sh -c "aml-burn-tool -b VIM3 -i /root/images/VIM3_Ubuntu-server-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz"
fi

#
# If aml-burn-tool does not work, use network -> mmcu writing tool instead.
#
#curl Krescue.local/shell/write | sh -s - VIM3_Ubuntu-server-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz
#