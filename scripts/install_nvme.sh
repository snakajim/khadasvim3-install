#!/bin/bash
# This script is only tested in Aarch64 Ubuntu 20.04 LTS LK 5.7. 
# LK4.9 has some issue to mount nvme device, so please choose LK 5.x.
# How to run:
# $> chmod +x * && sudo sh -c ./install_nvme.sh
# see 
# "Setup the PCIe / USB3.0 port using the Android/Ubuntu command line" 
# https://docs.khadas.com/vim3/HowToSetupPcieUsbPort.html
#
# -----------
# reduce MAX_SPEED down to 1.0GHz, 
# otherwize nvme write will stop during process.
# -----------
sudo apt install -y aptitude
sudo apt install -y lm-sensors hardinfo
#watch -n 10 cat /sys/class/thermal/thermal_zone*/temp
MAX_SPEED=`grep MAX_SPEED /etc/default/cpufrequtils | sed -e 's/MAX_SPEED=//'`
if [ $MAX_SPEED -gt 1000000 ]; then 
  sudo perl -pi -e 's/MAX_SPEED=\d+/MAX_SPEED=1000000/' /etc/default/cpufrequtils
  echo "/etc/default/cpufrequtils MAX_SPEED is changed, reboot in 10sec"
  sleep 10
  sudo reboot
else
  echo "MAX_SPEED is set to ${MAX_SPEED}. It is safe to proceed NVME write."
  echo ""
  sleep 2
fi


# --------------------------------------------------
#
# --------------------------------------------------

NVME_ON=`sudo fdisk -l | grep nvme | wc -l`
if [${NVME_ON} -eq 0]; then
  echo "NVME device is not recognized, program exit."
  sleep 10
  exit
else
if [${NVME_ON} -gt 1]; then
  echo "2 or more NVME device detected. "
  echo "Please re-partition by fdisk command, program exit."
  sleep 10
  exit
else
  NVME_ID=`sudo fdisk -l | grep nvme | sed -r 's/^.*(\/dev\/nvme\w+)(\s|:).*$/\1/'`
  echo "you have NVME under ${NVME_ID}, format first"
  sudo mkfs -t ext4 ${NVME_ID}
  sleep 5
  # please make partition in 1-4
  echo ""
  echo "${NVME_ID} partitioning start."
  sudo fdisk $NVME_ID
  # Then format to ext4
  # part 1  /var 50G
  # part 2  /tmp 50G
  # part 3  /home 50G
  # part 4  /usr lest of size
  echo ""
  echo "${NVME_ID}p1 format"
  sudo mkfs -t ext4  ${NVME_ID}p1
  sleep 5
  echo ""
  echo "${NVME_ID}p2 format"
  sudo mkfs -t ext4  ${NVME_ID}p2
  sleep 5
  echo ""
  echo "${NVME_ID}p3 format"
  sudo mkfs -t ext4  ${NVME_ID}p3
  sleep 5
  echo ""
  echo "${NVME_ID}p4 format"
  sudo mkfs -t ext4  ${NVME_ID}p4
  echo ""
  echo "all format done."
  lsblk -o +UUID
  sleep 5
  UUID_P1=`lsblk -o +UUID | grep nvme | grep p1 | sed -E 's/^.+part\s+(.+)$/\1/'`
  UUID_P2=`lsblk -o +UUID | grep nvme | grep p2 | sed -E 's/^.+part\s+(.+)$/\1/'`
  UUID_P3=`lsblk -o +UUID | grep nvme | grep p3 | sed -E 's/^.+part\s+(.+)$/\1/'`
  UUID_P4=`lsblk -o +UUID | grep nvme | grep p4 | sed -E 's/^.+part\s+(.+)$/\1/'`

  # 1. mkdir (temporary) mount directories
  sudo rm -rf /mnt/var_tmp /mnt/tmp_tmp /mnt/home_tmp /mnt/usr_tmp
  sudo mkdir -p /mnt/var_tmp /mnt/tmp_tmp /mnt/home_tmp /mnt/usr_tmp

  # 2. mount directories
  echo ""
  echo "all mount done."
  sudo mount ${NVME_ID}p1 /mnt/var_tmp 
  sudo mount ${NVME_ID}p2 /mnt/tmp_tmp 
  sudo mount ${NVME_ID}p3 /mnt/home_tmp 
  sudo mount ${NVME_ID}p4 /mnt/usr_tmp 
  lsblk
  
  # 3. Copy original to mount directories
  df /mnt/*_tmp
  echo ""
  echo "/var copy."
  cd /var  && sudo tar cpf - . | sudo tar xpf - -C /mnt/var_tmp
  echo ""
  echo "/tmp copy."
  cd /tmp  && sudo tar cpf - . | sudo tar xpf - -C /mnt/tmp_tmp
  echo ""
  echo "/home copy."
  cd /home && sudo tar cpf - . | sudo tar xpf - -C /mnt/home_tmp
  echo ""
  echo "/usr copy."
  cd /usr  && sudo tar cpf - . | sudo tar xpf - -C /mnt/usr_tmp
  echo ""
  echo "all copy done."
  df /mnt/*_tmp

  # 4. unmount
  sudo umount /mnt/var_tmp /mnt/tmp_tmp /mnt/home_tmp /mnt/usr_tmp

  # 5. make additional fstab
  echo "#UUID=${UUID_P1}   /var      ext4    defaults     1   1" | sudo sh -c "cat >  /etc/fstab.add"
  echo "#UUID=${UUID_P2}   /tmp      ext4    defaults     1   1" | sudo sh -c "cat >> /etc/fstab.add"
  echo "#UUID=${UUID_P3}   /home     ext4    defaults     1   1" | sudo sh -c "cat >> /etc/fstab.add"
  echo "#UUID=${UUID_P4}   /usr      ext4    defaults     1   1" | sudo sh -c "cat >> /etc/fstab.add"

  # 5. merge into main /etc/fstab
  sudo sh -c "cat /etc/fstab.add >> /etc/fstab"
  echo "change candidate to /etc/fstab is available"
  cat /etc/fstab.add
  echo ""
  sleep 1
  # 6. disalble tmpfs file system
  #sudo sed -i 's/^tmpfs/#tmpfs/' /etc/fstab

  # 7. Reboot to refresh changes.
  echo "reboot in 5 sec"
  sleep 5
  sudo reboot
  fi
fi
  
  
