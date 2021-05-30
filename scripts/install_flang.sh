#!/bin/bash
#
# This script is tested on Aarch64 Ubuntu18.04 LTS LK4.9 Khadas VIM3 only. 
# How to run:
# $> \time -ao install_flang.log ./install_flang.sh >& install_flang.log &
#

CPU=`getconf _NPROCESSORS_ONLN`

MEMSIZE=`cat /proc/meminfo  | grep MemTotal | awk '{ print $2 }'`
if [ $MEMSIZE -lt "5963000" ]; then
  echo "------------------WARNING--------------------"
  echo "$MEMSIZE(byte) is detected in your memory."
  echo "You need more than 6GByte to build flang."
  echo "Build process may fail during compilation."
  echo "---------------------------------------------"
fi

# -----------
# reduce MAX_SPEED down to 1.0GHz, 
# otherwize compile will stop during process.
# -----------
mkdir -p ${HOME}/tmp
hostname | grep -i Khadas
ret=$?
if [ $ret -eq "0" ]; then
  echo "Host HW is Khadas."
  sudo apt-get install -y aptitude
  sudo apt-get install -y lm-sensors hardinfo
  #watch -n 10 cat /sys/class/thermal/thermal_zone*/temp
  MAX_SPEED=`grep MAX_SPEED /etc/default/cpufrequtils | sed -e 's/MAX_SPEED=//'`
  if [ $MAX_SPEED -gt 1600000 ]; then 
    sudo perl -pi -e 's/MAX_SPEED=\d+/MAX_SPEED=1400000/' /etc/default/cpufrequtils
    echo "/etc/default/cpufrequtils MAX_SPEED is changed, reboot in 10sec"
    sleep 10
    sudo reboot
  else
    echo "MAX_SPEED is set to ${MAX_SPEED}. It is safe to proceed LLVM compile."
    echo ""
    sleep 2
  fi
else
  echo "Host HW is not Khadas."
fi

# ---------------------------
# Confirm which OS you are in 
# ---------------------------
if [ -e "/etc/lsb-release" ]; then
  OSNOW=UBUNTU
  echo "RUN" && echo "OS $OSNOW is set"
elif [ -e "/etc/redhat-release" ]; then
  OSNOW=CENTOS
  echo "RUN" && echo "OS $OSNOW is set"
elif [ -e "/etc/os-release" ]; then
  OSNOW=DEBIAN
  echo "RUN" && echo "OS $OSNOW is set"
else
  echo "RUN" && echo "OS should be one of UBUNTU, CENTOS or DEBIAN, stop..."
fi

#
# Update CMake > 3.15
#
CMAKE_VERSION=$(cmake --version | awk 'NR<2 { print $3 }' | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')
if [ $CMAKE_VERSION -lt "31500" ]; then
  echo "-------------------------------------------------------------"
  echo "Your cmake is too old to compile FLANG. Let's renew it."
  echo "-------------------------------------------------------------"
  cd ${HOME}/tmp && aria2c -x10 https://github.com/Kitware/CMake/releases/download/v3.20.1/cmake-3.20.1.tar.gz
  cd ${HOME}/tmp && tar zxvf cmake-3.20.1.tar.gz
  cd ${HOME}/tmp/cmake-3.20.1 && ./bootstrap && make -j${CPU} && sudo make install
else
  echo "-------------------------------------------------------------"
  echo "cmake is already the new version."
  echo "-------------------------------------------------------------"
fi

#
# Update gcc > 8.0
# Ubuntu bionic supports up to gcc10.
#
sudo apt-get -y install g++-8
sudo apt-get -y autoremove

# ---------------------------------------
# set flang install directory, 
# ---------------------------------------
#INSTALL_PREFIX=${LLVM_DIR}
cd ${HOME}/tmp
INSTALL_PREFIX="/usr/local/flang_20210324"

if [ ! -d ${INSTALL_PREFIX} ]; then 
  echo "Path \$INSTALL_PREFIX does not exist. "
  sudo mkdir -p ${INSTALL_PREFIX}
else
  echo "clean up before installation."
  sudo rm -rf ${INSTALL_PREFIX}/*
fi

# ---------------------------------------
# set cmake option
# ---------------------------------------
CMAKE_OPTIONS="-DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
    -DLLVM_CONFIG=${INSTALL_PREFIX}/bin/llvm-config \
    -DCMAKE_Fortran_COMPILER=${INSTALL_PREFIX}/bin/flang \
    -DCMAKE_Fortran_COMPILER_ID=Flang \
    -DLLVM_TARGETS_TO_BUILD=AArch64" 

echo `date`

# ---------------------------------------
# remake clang with -DLLVM_ENABLE_CLASSIC_FLANG=ON
# ---------------------------------------
if [ ! -d ${HOME}/tmp/classic-flang-llvm-project ]; then
    cd ${HOME}/tmp
    git clone --depth 1 -b release_100 https://github.com/flang-compiler/classic-flang-llvm-project.git
fi
echo "#-------------------------------------------------------------"
echo "classic-flang-llvm-project build starts."
cd ${HOME}/tmp/classic-flang-llvm-project
sudo rm -rf build && mkdir -p build && cd build
cmake -G Ninja -G "Unix Makefiles"\
  $CMAKE_OPTIONS \
  -DCMAKE_C_COMPILER=`which gcc-8` \
  -DCMAKE_CXX_COMPILER=`which g++-8` \
  -DLLVM_ENABLE_CLASSIC_FLANG=ON \
  -DLLVM_ENABLE_PROJECTS="clang;openmp" \
  ../llvm
make -j$CPU && sudo make install
make clean
echo "classic-flang-llvm-project is successfully done."
echo "#-------------------------------------------------------------"

# ---------------------------------------
# Config and compile runtime first
# then
# Confing and compile flang
# --------------------------------------
cd ${HOME}/tmp
if [ ! -d flang ]; then
    git clone --depth 1 -b flang_20210324 https://github.com/flang-compiler/flang.git
fi

(cd flang/runtime/libpgmath
 mkdir -p build && cd build
 cmake -G Ninja -G "Unix Makefiles" \
 $CMAKE_OPTIONS \
 -DCMAKE_CXX_COMPILER=${INSTALL_PREFIX}/bin/clang++ \
 -DCMAKE_C_COMPILER=${INSTALL_PREFIX}/bin/clang \
 ..
 make -j$CPU
 sudo make install
 make clean
 echo "libpgmath is successfully done")

echo "#-------------------------------------------------------------"
echo "flang build starts."
cd flang
mkdir -p build && cd build
cmake -G Ninja -G "Unix Makefiles" \
$CMAKE_OPTIONS \
-DCMAKE_CXX_COMPILER=${INSTALL_PREFIX}/bin/clang++ \
-DCMAKE_C_COMPILER=${INSTALL_PREFIX}/bin/clang \
-DFLANG_LLVM_EXTENSIONS=ON \
..
make -j$CPU
sudo make install
make clean
echo "flang is successfully done"
echo "#-------------------------------------------------------------"

#
# post install processing
#
echo ""
echo "#-------------------------------------------------------------"
echo "post install processing."
grep FLANG_DIR ${HOME}/.bashrc
ret=$?
if [ $ret -eq 1 ] && [ -d ${INSTALL_PREFIX} ]; then
  echo "Updating ${HOME}/.bashrc"
  echo "# " >> ${HOME}/.bashrc
  echo "# flang setting for binary and LD_ & LIBRARY_PATH" >> ${HOME}/.bashrc
  echo "export FLANG_DIR=${INSTALL_PREFIX}">> ${HOME}/.bashrc
  echo "export PATH=\$PATH:\$FLANG_DIR/bin" >>  ${HOME}/.bashrc
  echo "export LIBRARY_PATH=\$LIBRARY_PATH:\$FLANG_DIR/lib" >>  ${HOME}/.bashrc
  echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$FLANG_DIR/lib" >>  ${HOME}/.bashrc
  echo "# " >> ${HOME}/.bashrc
  echo "# " >> ${HOME}/.bashrc
fi

if [ -d ${INSTALL_PREFIX} ]; then
  echo "flang compile done."
  echo "Now you have flag under ${INSTALL_PREFIX}."
  echo "Now you have libpgmath.[so/a] under ${INSTALL_PREFIX}/lib."
  echo "Please check and try flang -help."
  echo ""
else
  echo "[WARNING]"
  echo "flag installation is fail. Check logs."
  echo ""
fi

source ${HOME}/.bashrc

echo "install_flang.sh completed. See the path & version."
echo `which flang`
echo `flang --version`
echo `date`
echo ""
echo ""
echo ""
