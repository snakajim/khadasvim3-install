#!/bin/bash
# This script is only tested in Aarch64 & x86_64 Ubuntu 20.04 LTS
# How to run:
# $> chmod +x * && sudo sh -c ./install_basic.sh
#
#
# install several tools by apt-get
# make sure you have set your keyboard. 
# $> sudo dpkg-reconfigure keyboard-configuration
#
apt-get upgrade -y
iam=`echo ${USER}`
if [ $iam != "root" ]; then
  echo "i am not root, please exec me in root."
  exit
fi
apt-get install -y default-jre default-jdk
apt-get install -y curl cmake ninja-build z3 sudo
apt-get install -y firewalld
apt-get install -y autoconf flex bison apt-utils
apt-get install -y python3 python3-dev python3-pip
apt-get install -y openssh-server x11-apps at
apt-get install -y xserver-xorg xterm telnet
apt-get install -y unzip htop gettext aria2
apt-get install -y locales-all cpanminus
apt-get install -y avahi-daemon firewalld avahi-utils
apt-get install -y scons libomp-dev evince time hwinfo
apt-get install -y gcc-7 g++-7
apt-get install -y gcc-8 g++-8
#gpasswd -a $USER docker
#chmod 666 /var/run/docker.sock
sleep 10
#
# addgroup wheel and grant sudo authority
#
addgroup wheel
sed -i -E \
  's/\#\s+auth\s+required\s+pam_wheel\.so$/auth      required      pam_wheel\.so/' \
  /etc/pam.d/su


# enable avahi-daemon and firewall for mDNS
systemctl start  avahi-daemon
systemctl enable avahi-daemon
sleep 10

#systemctl start firewalld
#systemctl enable firewalld
#firewall-cmd --add-service=mdns  --permanent
#firewall-cmd --reload
#systemctl daemon-reload
#sleep 10

# set CLI as default
systemctl set-default multi-user.target
#systemctl set-default graphical.target
sleep 10


# Change sshd_config file
# SSH poicy is as root login.
#
sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^#X11DisplayOffset 10/X11DisplayOffset 10/' /etc/ssh/sshd_config
systemctl restart sshd
sleep 10


# add "user0" without passward.
# you can replace "user0" to your favorite user account later.
#
grep user0 /etc/passwd
ret=$?
if [ $ret -eq 1 ]; then
  useradd -m user0 && passwd -d user0
  gpasswd -a user0 wheel
  gpasswd -a user0 docker
  gpasswd -a user0 sudo
  chsh -s /bin/bash user0
  echo "# Privilege specification for user0" >> /etc/sudoers
  echo "user0    ALL=NOPASSWD: ALL" >> /etc/sudoers
fi
mkdir -p /home/user0/tmp && mkdir -p /home/user0/work && mkdir -p /home/user0/.ssh
if [ -f /home/user0/.ssh/authorized_keys ]; then
  echo "autholized_keys exists."
else
  touch /home/user0/.ssh/authorized_keys
fi
chown -R user0:user0 /home/user0
apt-get autoremove -y
apt-get clean
#
echo "Set system time timedatectl to Asia/Tokyo."
timedatectl set-timezone Asia/Tokyo --no-ask-password

# check hw type and rename hostname
/sbin/hwinfo | grep -i khadas
ret=$?
if [ $ret -eq 0 ]; then
  echo "Khadas is detected."
  echo "Khadasarmkk" > /etc/hostname
  sleep 10
fi
#
echo "install_basic.sh completed, system reboot."
sleep 10
reboot
