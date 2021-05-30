# khadasvim3-install
Khadas VIM3 Pro setup procedure.

# khadas vim3 pro performance overview

|  behchmark in usertime(m) |  Khadas VIM3 Pro(*) | EC2 T4G medium |
| --------------------------| ------------------- | -------------- |
|  clang-12.0.0 buuild & install  |  TD           | 185.0          |
|  flang_20210324 build & install |  TD           | TD             |

(*) Reducing CPU FREQ=1.4GHz to avoid thermal issue

# Running x86 docker on aarch64 linux

The goal is running x86 linux apps on aarch64 HW platform. To make it happen, using "x86_64 docker container on aarch64" method.

This example is tested with,

- Khadas VIM3 Pro Hardware
- aarch664 v8.0-A
- Ubuntu 20.04.1 LTS(focal)
- Docker version 20.10.5, build 55c4c88

## 0. Preparation. 

At first, let's install docker-ce on your Ubuntu 20.04 VIM3 Pro.

```
# -------------------------------------
# remove old docker versions
# -------------------------------------
sudo dpkg --remove --force-remove-reinstreq docker-ce docker-ce-rootless-extras
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt -y autoremove

# -------------------------------------
# set environment and install docker-ce
# -------------------------------------
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
	"deb [arch=arm64] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) \
	stable"
sudo apt update
sudo apt-cache policy docker-ce
sudo apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io

# -------------------------------------
# add users and systemctl, then hello-world
# -------------------------------------
sudo systemctl start docker
sudo systemctl enable docker
sudo gpasswd -a $USER docker
sudo chmod 666 /var/run/docker.sock
docker images -aq | xargs docker rmi
docker run --rm -it hello-world
```

After docker installation, let's set aptman/qus. This is framework to emualte x86_64 on aarch64 hardware platform.

```
sudo apt install -y qemu-user-static
docker run --rm --privileged aptman/qus -- -r
docker run --rm --privileged aptman/qus -s -- -p x86_64
```

You can find detailed user man in github.

- https://github.com/dbhi/qus


Similar mechanism is given by docker multuiarch, however it has known issue in libc-bin install for Ubuntu Bionic(18.04) and Focal(20.04) build. It works only for Uubntu Xenial(16.04). So if you are intending to use Xenial only, docker multiarch is alternative option to you. 

- https://hub.docker.com/r/multiarch/qemu-user-static

If you don't like to use Ubuntu repository to apt install qemu-user-static, you can compile from source. Setup your build environment first,

```
sudo apt install -y pkg-config
sudo apt install -y libglib2.0-0
sudo apt install -y libglib2.0-dev
git clone git://git.qemu.org/qemu.git
cd qemu
git submodule update --init --recursive
```

Then configure/build/install qemu with --static, --disable-system, and --enable-linux-user.

```
$ CPU=`nproc --all`
$ ./configure --prefix=${HOME}/tmp/qemu-user-static \
    --static --disable-system --enable-linux-user
$ make -j${CPU}
$ make install
$ cd ${HOME}/tmp/qemu-user-static/bin
$ for i in qemu-*; do mv $i $i-static; done
```

Make sure you have a set of qemu-<architecture>-static under ${HOME}/tmp. To let docker refer qemu-<architecture>-static, copy these binary fiels under /usr/bin.

```
$ sudo cp ${HOME}/tmp/qemu-user-static/bin/qemu-*-static /usr/bin
$ sudo chmod +x /usr/bin/qemu-*-static
```
## 1. Test your multiarch container on aarch64

If you set dbhi-qus properly, this test should pass.

```
docker system prune -f
docker run --rm -t multiarch/ubuntu-core:amd64-bionic uname -m
```

Return is x86_64. You can set various ISA type by switching ***-p [TARGET_ARCH]***.

If you would like to test aarch64 on x86_64 platform, you can do similar way, swithing ***-p aarch64*** in aptman/qus argument.

```
sudo apt install -y qemu-user-static
docker run --rm --privileged aptman/qus -- -r
docker run --rm --privileged aptman/qus -s -- -p aarch64
docker system prune -f
docker run --rm -t multiarch/ubuntu-core:arm64-bionic uname -m
```

Return is aarch64.

The points are,

- You need to switch ***-p [TARGET_ARCH]*** everytime when you change ISA type of docker container. 
- You need to use [Multiarch](https://hub.docker.com/u/multiarch/) image to build your own container, the normal image does not work. 

