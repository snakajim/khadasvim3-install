#!/bin/bash
# This script is only tested in Aarch64 Ubuntu 20.04 LTS LK 4.9. 
# How to run:
# $> chmod +x * && sudo sh -c ./install_ub_ssd.sh

# --------------------------------------------------
# 1. Detect USB Storage(USBD)
# 2. Partition into 4
# 3. Format to ex4
# 4. Mkdir and Mount new dirs under /mnt and copy from original directory
# 5. Change /etc/fstab
# 6. Reboot 
# --------------------------------------------------

USBD_ON=`sudo fdisk -l | grep sd | wc -l`
if [${USBD_ON} -eq 0]; then
  echo "No USD storage found. Did you connect USB storage in USB port?"
  echo "Program exit."
  sleep 10
  exit
else
if [${USBD_ON} -gt 1]; then
  echo "2 or more USB storage device detected. "
  echo "Please re-partition by fdisk command, program exit."
  sleep 10
  exit
else
  USBD_ID=`sudo fdisk -l | grep sd | sed -r 's/^.*(\/dev\/sd\w+)(\s|:).*$/\1/'`
  echo "you have USBD under ${USBD_ID}, format first."
  echo -n "This will completeley erase data under ${USBD_ID}, [y/N]: "
  read ANS
  case $ANS in
    [Yy]* )
    # ここに「Yes」の時の処理を書く
    echo "Yes"
    sudo mkfs -t ext4 ${USBD_ID}
    ;;
    * )
    # ここに「No」の時の処理を書く
    echo "No. Program Exit"
    exit
    ;;
  esac
  sleep 5
  # please make partition in 1-4
  echo ""
  echo "${USBD_ID} partitioning start."
  sudo fdisk $USBD_ID
  # Then format to ext4
  # part 1  /var 50G or 1/4 of total
  # part 2  /tmp 50G or 1/4 of total
  # part 3  /home 50G or 1/4 of total
  # part 4  /usr lest of size or 1/4 of total
  echo ""
  echo "${USBD_ID}p1 format"
  sudo mkfs -t ext4  ${USBD_ID}p1
  sleep 5
  echo ""
  echo "${USBD_ID}p2 format"
  sudo mkfs -t ext4  ${USBD_ID}p2
  sleep 5
  echo ""
  echo "${USBD_ID}p3 format"
  sudo mkfs -t ext4  ${USBD_ID}p3
  sleep 5
  echo ""
  echo "${USBD_ID}p4 format"
  sudo mkfs -t ext4  ${USBD_ID}p4
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
  sudo mount ${USBD_ID}p1 /mnt/var_tmp 
  sudo mount ${USBD_ID}p2 /mnt/tmp_tmp 
  sudo mount ${USBD_ID}p3 /mnt/home_tmp 
  sudo mount ${USBD_ID}p4 /mnt/usr_tmp 
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
  #echo "reboot in 5 sec"
  #sleep 5
  #sudo reboot
  fi
fi
  
  
