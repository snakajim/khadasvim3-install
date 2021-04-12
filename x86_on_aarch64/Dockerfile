# 2021-Apr-11 snakajim@arm.com
#
# Example Dockerfile to test multiarch.
#
# -------------------------------------
# Dynamic Binary Hardware Injection (DBHI) qemu-user-static (qus)
# https://github.com/dbhi/qus
#
# This is alternative way to emulate x86_64 on aarch64. 
# If docker multiarch does not work properly, use this instead. 
# -------------------------------------
# BEFORE YOU BUILD,
# sudo apt install -y qemu-user-static
# docker run --rm --privileged aptman/qus -- -r
# docker run --rm --privileged aptman/qus -s -- -p x86_64
# -------------------------------------
# To build
# $> docker build --rm -t test .
# To test
# $> docker run --rm -it test uname -m
# To run
# $> docker pull nsatoshi/tensorflow-lite-micro-rtos-fvp:gcc 
# $> docker run -it --name eda -u user1 --privileged --restart=always -d --net host nsatoshi/tensorflow-lite-micro-rtos-fvp:gcc sh
#

FROM multiarch/ubuntu-core:amd64-bionic
SHELL ["/bin/bash", "-c"]
RUN apt-get -y update && apt-get -y upgrade && \
  apt-get install -y build-essential software-properties-common
RUN apt-get -y install --no-install-recommends \
    sudo git wget make gcc curl \
    zip unzip libatomic1 ca-certificates \
    xxd imagemagick \
    python3 python3-venv python3-dev python3-pip
RUN rm -rf /var/lib/apt/lists/*

# ----------------------------------------------
# adding user0 without passwd, 
# it is a litte bit tricky in Ubuntu 18.04 
# ----------------------------------------------
RUN addgroup wheel
RUN sed -i -E \
  's/\#\s+auth\s+required\s+pam_wheel\.so$/auth      required      pam_wheel\.so group=wheel/' \
  /etc/pam.d/su
RUN useradd -m user0 
# enable empty passwd for user0, but this is not enough.
RUN passwd  -d user0
RUN sed -i 's/nullok_secure/nullok/' /etc/pam.d/common-auth
RUN gpasswd -a user0 wheel
RUN gpasswd -a user0 sudo
RUN chsh -s /bin/bash user0
RUN echo "# Privilege specification for user0" >> /etc/sudoers
RUN echo "user0    ALL=NOPASSWD: ALL" >> /etc/sudoers
RUN sed -i 's/^# auth       sufficient pam_wheel.so trust/auth       sufficient pam_wheel.so trust grouop=wheel/' /etc/pam.d/su
