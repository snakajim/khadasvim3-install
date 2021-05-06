#!/bin/bash
#
# https://docs.khadas.com/vim3/UpgradeViaUSBCable.html
#

# ----------------------------------
# Step 1. Download Burning Tool on x86_docker, but not install(does not work!)
# ----------------------------------

# Ubuntu 20.04 LTS
docker pull multiarch/ubuntu-core:amd64-focal
docker run --rm --privileged aptman/qus -- -r
docker run --rm --privileged aptman/qus -s -- -p x86_64
docker system prune -f 

if [ ! -f VIM3_Ubuntu-gnome-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz ];then
  aria2c -x2 https://downloads.khadas.com/Firmware/Krescue/images/VIM3_Ubuntu-gnome-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz
fi

if [ ! -f VIM3_Ubuntu-server-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz ]; then
  aria2c -x2 https://downloads.khadas.com/Firmware/Krescue/images/VIM3_Ubuntu-server-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz
fi

# docker build
docker rmi usbc_writer:latest
docker build -t usbc_writer -<<EOF
FROM multiarch/ubuntu-core:amd64-focal
ENV TZ Asia/Tokyo
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]
RUN apt-get -y update && apt-get install -y tzdata
RUN apt-get -y upgrade
RUN apt-get -y install git
RUN apt-get -y install build-essential sudo aria2
RUN apt-get -y install libusb-dev parted
RUN mkdir -p /root/tmp
COPY ./VIM3_Ubuntu-gnome-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz \
  /root/tmp/
COPY ./VIM3_Ubuntu-server-focal_Linux-5.12_arm64_SD-USB_V1.0.5-210430.img.xz \
  /root/tmp/
RUN cd /root/tmp && \
  git clone https://github.com/khadas/utils
EOF


# ----------------------------------
# Step 2. Run container and make sure USB access, then install burning tool
# ----------------------------------


# ----------------------------------
# Step 3. Image burning and close
# ----------------------------------
