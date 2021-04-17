#!/bin/bash
# This script is only tested in Aarch64 Ubuntu 20.04 LTS LK 5.7. 
# LK4.9 has some issue to mount nvme device, so please choose LK 5.x.
# How to run:
# $> chmod +x * && sudo sh -c ./install_nvme.sh
# see 
# "Setup the PCIe / USB3.0 port using the Android/Ubuntu command line" 
# https://docs.khadas.com/vim3/HowToSetupPcieUsbPort.html
#
PCI_ON=`cat /sys/class/mcu/usb_pcie_switch_mode`

if [${PCI_ON} -eq 1]; then
  echo "Your PCI port is on"
  sudo apt install -y nvme-cli
else
  echo "Your PCI port is off(USB mode), switch to PCI"
  echo 1 > /sys/class/mcu/usb_pcie_switch_mode
  echo "system reboot to reflect changes"
  sleep 5
  sudo reboot
  #echo 1 > /sys/class/mcu/poweroff 
fi

# --------------------------------------------------
#
# --------------------------------------------------

fdisk -l | grep nvme
NVME_ON=$?
if [${PCI_ON} -eq 1]; then
  echo "NVME device is not recognized, program exit"
  sleep 10
  exit
else
  NVME_ID=`fdisk -l | grep nvme | sed -r 's/^.*(\/dev\/nvme\w+)(\s|:).*$/\1/'`
  echo "you have NVME under ${NVME_ID}"
  # please make partition in 1-4
  sudo fdisk $NVME_ID
  # Then format to ext4
  sudo mkfs -t ext4 /dev/nvme0n1p1
  sudo mkfs -t ext4 /dev/nvme0n1p2
  sudo mkfs -t ext4 /dev/nvme0n1p3
  sudo mkfs -t ext4 /dev/nvme0n1p4
  su root
  cd /root
  # 1. 
  # Copy /var to /dev/nvme0n1p1, 100G
  mkdir -p /var_tmp && mount /dev/nvme0n1p1 /var_tmp 
  mv /var/* /var_tmp
  echo “/dev/nvme0n1p1 /var  ext4    defaults 1 1” >> /etc/fstab
  mount -a
  lsblk
  # 2. 
  # Copy /tmp to /dev/nvme0n1p2, 50G
  mkdir -p /tmp_tmp && mount /dev/nvme0n1p2 /tmp_tmp
  mv /tmp/* /tmp_tmp
  echo “/dev/nvme0n1p2 /tmp  ext4    defaults 1 1” >> /etc/fstab
  mount -a
  lsblk
  # 3.
  # Copy /home to /dev/nvme0n1p3, 50G
  mkdir -p /home_tmp && mount /dev/nvme0n1p3 /home_tmp
  mv /home/* /home_tmp/
  chown -R khadas:khadas /home_tmp/khadas
  echo “/dev/nvme0n1p3 /home  ext4    defaults 1 1” >> /etc/fstab
  mount -a
  lsblk
  # 4.
  # Copy /usr to /dev/nvme0n1p4, ~30G
  mkdir -p /usr_tmp && mount /dev/nvme0n1p4 /usr_tmp
  cp -r /usr/* /usr_tmp/
  echo “/dev/nvme0n1p4 /usr  ext4    defaults 1 1” >> /etc/fstab
  mount -a
  lsblk
  reboot
fi  
  
  