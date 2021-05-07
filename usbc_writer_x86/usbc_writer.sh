#!/bin/bash
#
# https://docs.khadas.com/vim3/UpgradeViaUSBCable.html
#

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
docker pull multiarch/ubuntu-core:amd64-focal
docker run --rm --privileged aptman/qus -- -r
docker run --rm --privileged aptman/qus -s -- -p x86_64

# docker build
docker rmi -f usbc_writer:latest
docker system prune -f
docker build -t usbc_writer -<<EOF
FROM multiarch/ubuntu-core:amd64-focal
ENV TZ Asia/Tokyo
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]
RUN apt-get -y update && apt-get install -y tzdata
RUN apt-get -y upgrade
RUN apt-get -y install usbutils udev
RUN apt-get -y install git
RUN apt-get -y install build-essential sudo aria2
RUN apt-get -y install libusb-dev parted
RUN apt-get -y install lib32gcc-s1 lib32tinfo6 libc6-i386 libtinfo5
RUN apt-get -y install ccache lib32ncurses6 lib32stdc++6 lib32z1 libncurses5 \
  libusb-1.0-0-dev linux-base pv
RUN mkdir -p /root/tmp
RUN cd /root/tmp && \
  git clone https://github.com/khadas/utils
RUN mkdir pp /root/images
EOF


# ----------------------------------
# Step 2. Run container and make sure USB access, then install burning tool
# ----------------------------------
#docker run --privileged --device=/dev/usb:/dev/usb --rm -it usbc_writer /bin/bash
docker run --rm --privileged aptman/qus -- -r
docker run --rm --privileged aptman/qus -s -- -p x86_64
docker stop writer
docker rm writer
docker run -itd --privileged --device=/dev:/dev --name "writer" usbc_writer /bin/bash
docker exec writer sudo touch /etc/udev/rules.d/70-persistent-usb.rules
docker exec writer sudo sh -c 'echo "SUBSYSTEMS=="usb",ATTRS{idVendor}=="1b8e",ATTRS{idProduct}=="c003",OWNER="yourUserName",MODE="0666",SY
MLINK+="worldcup"" > /etc/udev/rules.d/70-persistent-usb.rules'
docker exec writer sudo service udev restart
docker exec writer sudo udevadm control --reload-rules
docker exec writer sh -c "cd /root/tmp/utils && sudo ./INSTALL"
docker exec writer sh -c "lsusb | grep Amlogic"

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
  writer:/root/images/VIM3_Ubuntu-gnome-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz
docker cp ./VIM3_Ubuntu-server-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz \
  writer:/root/images/VIM3_Ubuntu-server-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz
docker exec writer sh -c "aml-burn-tool -b VIM3 -i /root/images/VIM3_Ubuntu-server-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz"
