#!/bin/bash
# This script is only tested in Aarch64 Ubuntu 20.04 LTS LK 4.9. 
# How to run:
# $> chmod +x * && sudo sh -c ./install_ub_ssd.sh

# --------------------------------------------------
#   HOW THIS SCRIPT WORKS:
# - Detect USB Storage, and mark it as USBD_ID
# - Reformat USBD_ID to ex4 and make partition into 4
# - Format to ex4 for each new partition
# - Mkdir new dirs under /mnt, then mount new partitions for each.
# - Copy original directory to /mnt/ for each.
# - Generate /etc/fstab.add and merge it in original /etc/fstab
# - Reboot 
# --------------------------------------------------

USBD_ON=`sudo fdisk -l | grep sd | wc -l`
if [ ${USBD_ON} -eq 0 ]; then
  echo "No USD storage found. Did you connect USB storage in USB port?"
  echo "Program exit."
  sleep 5
  exit
fi

if [ ${USBD_ON} -eq 1 ]; then
  USBD_ID=`sudo fdisk -l | grep sd | sed -r 's/^.*(\/dev\/sd\w+)(\s|:).*$/\1/'`
  echo "USB storage device detected. Target is set to ${USBD_ID}."
  sleep 2
fi

if [ ${USBD_ON} -gt 1 ]; then
  echo "2 or more USB storage device detected. "
  echo "Please delete partision by fdisk command, ie sudo fdisk /dev/sd[x]."
  echo "Program exit."
  sleep 5
  exit
fi

echo "You have USBD under ${USBD_ID}, format to ex4 first."
echo -n "This will completeley erase your data under ${USBD_ID}, [y/N]: "
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
# part 1  /var at least 50G or 1/4 of total
# part 2  /tmp at least 50G or 1/4 of total
# part 3  /home at least 50G or 1/4 of total
# part 4  /usr lest of size or 1/4 of total
echo ""
echo "${USBD_ID}1 format"
sudo mkfs -t ext4  ${USBD_ID}1
sleep 5
echo ""
echo "${USBD_ID}2 format"
sudo mkfs -t ext4  ${USBD_ID}2
sleep 5
echo ""
echo "${USBD_ID}3 format"
sudo mkfs -t ext4  ${USBD_ID}3
sleep 5
echo ""
echo "${USBD_ID}4 format"
sudo mkfs -t ext4  ${USBD_ID}4
echo ""
echo "all format done."
lsblk -o +UUID
sleep 5
USBD_ID_NAME=`echo ${USBD_ID} | sed "s#^\/dev/##"`
UUID_P1=`lsblk -o +UUID | grep ${USBD_ID_NAME}1 | sed -E 's/^.+part\s+(.+)$/\1/'`
UUID_P2=`lsblk -o +UUID | grep ${USBD_ID_NAME}2 | sed -E 's/^.+part\s+(.+)$/\1/'`
UUID_P3=`lsblk -o +UUID | grep ${USBD_ID_NAME}3 | sed -E 's/^.+part\s+(.+)$/\1/'`
UUID_P4=`lsblk -o +UUID | grep ${USBD_ID_NAME}4 | sed -E 's/^.+part\s+(.+)$/\1/'`

# 1. mkdir (temporary) mount directories
sudo rm -rf /mnt/var_tmp /mnt/tmp_tmp /mnt/home_tmp /mnt/usr_tmp
sudo mkdir -p /mnt/var_tmp /mnt/tmp_tmp /mnt/home_tmp /mnt/usr_tmp

# 2. mount directories
echo ""
echo "all mount done."
sudo mount ${USBD_ID}1 /mnt/var_tmp 
sudo mount ${USBD_ID}2 /mnt/tmp_tmp 
sudo mount ${USBD_ID}3 /mnt/home_tmp 
sudo mount ${USBD_ID}4 /mnt/usr_tmp 
lsblk
  
# 3. Copy original to mount directories
df /mnt/*_tmp
echo ""
echo "/var copy."
cd /var  && sudo tar vcpf - . | sudo tar xpf - -C /mnt/var_tmp
echo "/var copy done."
sleep 5
echo ""
echo "/tmp copy."
cd /tmp  && sudo tar vcpf - . | sudo tar xpf - -C /mnt/tmp_tmp
echo "/tmp copy done."
echo ""
echo "/home copy."
cd /home && sudo tar vcpf - . | sudo tar xpf - -C /mnt/home_tmp
echo "/home copy done."
echo ""
echo "/usr copy."
cd /usr  && sudo tar vcpf - . | sudo tar xpf - -C /mnt/usr_tmp
echo "/usr copy done."
sleep 5
echo ""
echo "all copy done. See copied disk size under /mnt/*_tmp."
df /mnt/*_tmp
sleep 5

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

  
  
