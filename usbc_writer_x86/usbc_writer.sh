#!/bin/bash
#
# https://docs.khadas.com/vim3/UpgradeViaUSBCable.html
#

ARCH=arm64

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
# Step 1. Download Burning Tool on x86_docker, but not install(does not work!)
# ----------------------------------

# Ubuntu 20.04 LTS
docker system prune -f 
docker pull multiarch/ubuntu-core:$ARCH-focal
docker run --rm --privileged aptman/qus -- -r
docker run --rm --privileged aptman/qus -s -- -p x86_64

# docker build
docker rmi -f usbc_writer:$ARCH
docker system prune -f
docker build -t usbc_writer:$ARCH -<<EOF
FROM multiarch/ubuntu-core:$ARCH-focal
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
EOF


# ----------------------------------
# Step 2. Run container and make sure USB access, then install burning tool
# ----------------------------------
#docker run --privileged --device=/dev/usb:/dev/usb --rm -it usbc_writer /bin/bash
docker run --rm --privileged aptman/qus -- -r
docker run --rm --privileged aptman/qus -s -- -p x86_64
docker stop writer_$ARCH
docker rm writer_$ARCH
docker run -itd --privileged --device=/dev:/dev --name "writer_$ARCH" usbc_writer:$ARCH /bin/bash
docker exec writer_$ARCH sudo touch /etc/udev/rules.d/70-persistent-usb.rules
docker exec writer_$ARCH sudo sh -c 'echo "SUBSYSTEMS=="usb",ATTRS{idVendor}=="1b8e",ATTRS{idProduct}=="c003",OWNER="yourUserName",MODE="0666",SY
MLINK+="worldcup"" > /etc/udev/rules.d/70-persistent-usb.rules'
docker exec writer_$ARCH sudo service udev restart
docker exec writer_$ARCH sudo udevadm control --reload-rules
if [ $ARCH == "amd64" ];  then
  docker exec writer_$ARCH sh -c "cd /root/tmp/utils && sudo ./INSTALL"
fi
docker exec writer_$ARCH sh -c "lsusb"
docker exec writer_$ARCH sh -c "lsusb | grep Amlogic"
docker exec writer_$ARCH sh -c "lsusb -t"


# ----------------------------------
# Step 3. Image burning and close
# ----------------------------------
# Burn images
if [ ! -f VIM3_Ubuntu-gnome-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz ];then
  aria2c -x2 https://downloads.khadas.com/Firmware/Krescue/images/VIM3_Ubuntu-gnome-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz
fi

if [ ! -f VIM3_Ubuntu-server-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz ]; then
  aria2c -x2 https://downloads.khadas.com/Firmware/Krescue/images/VIM3_Ubuntu-server-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz
fi
docker cp ./VIM3_Ubuntu-gnome-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz \
  writer_$ARCH:/root/images/VIM3_Ubuntu-gnome-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz
docker cp ./VIM3_Ubuntu-server-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz \
  writer_$ARCH:/root/images/VIM3_Ubuntu-server-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz
if [ $ARCH == "amd64" ];  then
  docker exec writer_$ARCH sh -c "aml-burn-tool -b VIM3 -i /root/images/VIM3_Ubuntu-server-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz"
fi