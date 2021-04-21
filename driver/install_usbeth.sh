#!/bin/bash
# To install USB-Ether adapter
# 
# This script is only tested in Aarch64 Ubuntu 20.04 
# LK 4.9
# 
# Buffalo LUA4-U3-AGTE-WH USB3.0-GigaEther.
# To confirm device type,
# $> sudo dmesg | grep usb
# Linux driver source is available from
# https://www.asix.com.tw/en/support/download
# AX88179_178A_LINUX_DRIVER_v1.20.0_SOURCE.tar.bz2
#
tar jxf AX88179_178A_LINUX_DRIVER_v1.20.0_SOURCE.tar.bz2
cd AX88179_178A_Linux_Driver_v1.20.0_source && make
sudo make install
