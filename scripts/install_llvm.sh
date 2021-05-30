#!/bin/bash
#
# This script is tested on Aarch64 Ubuntu20.04 LTS only. 
# How to run:
# $> \time -ao install_llvm.log ./install_llvm.sh >& install_llvm.log &
#

CPU=`getconf _NPROCESSORS_ONLN`

# -----------
# reduce MAX_SPEED down to 1.0GHz, 
# otherwize compile will stop during process.
# -----------
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

# ------------------------
# check your clang version
# ------------------------
which clang
ret=$?
if [ $ret -eq "0" ]; then
  CLANG_VERSION=$(clang --version | awk 'NR<2 { print $3 }' | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')
  if [ $CLANG_VERSION -eq "120000" ]; then
    echo "#-------------------------------------------------------------"
    echo "You have already had LLVM-12.0.0."
    echo "Skip installation. Program exit."
    echo "#-------------------------------------------------------------"
    exit
  else
    echo "#-------------------------------------------------------------"
    echo "You have already had LLVM clang but it is not target version=$CLANG_VERSION."
    echo "Proceed LLVM-12.0.0 install."
    echo "#-------------------------------------------------------------"
    echo ""
  fi
else
  echo "#-------------------------------------------------------------"
  echo "LLVM-clang is not found in your system."
  echo "Proceed LLVM-12.0.0 install."
  echo "#-------------------------------------------------------------"
  echo ""
fi

sudo apt-get install -y clang-10
export CXX=`which clang++-10`
export CC=`which clang-10`
sudo apt-get -y autoremove

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
# install LLVM 1200
#
mkdir -p ${HOME}/tmp
cd ${HOME}/tmp && rm -rf llvm-project
cd ${HOME}/tmp && git clone --depth 1 https://github.com/llvm/llvm-project.git -b llvmorg-12.0.0 && \
  cd llvm-project && rm -rf build && mkdir -p build && cd build
echo "start LLVM1200 build"
date
if [ $OSNOW = "UBUNTU" ] ||  [ $OSNOW = "DEBIAN" ]; then 
  cmake -G Ninja -G "Unix Makefiles"\
    -DCMAKE_C_COMPILER=$CC \
    -DCMAKE_CXX_COMPILER=$CXX \
    -DLLVM_ENABLE_PROJECTS="clang;libcxx;libcxxabi;lld;openmp" \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DLLVM_TARGETS_TO_BUILD="ARM;AArch64" \
    -DCMAKE_INSTALL_PREFIX="/usr/local/llvm_1200" \
    ../llvm
    make -j${CPU} && sudo make install
    make clean
  echo "end LLVM1200 build"  
elif [ $OSNOW = "CENTOS" ]; then
  cmake -G Ninja -G "Unix Makefiles" \
    -DCMAKE_C_COMPILER=$CC \
    -DCMAKE_CXX_COMPILER=$CXX \
    -DLLVM_ENABLE_PROJECTS="clang;libcxx;libcxxabi;lld;openmp" \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DLLVM_TARGETS_TO_BUILD="ARM;AArch64" \
    -DCMAKE_INSTALL_PREFIX="/usr/local/llvm_1200" \
    ../llvm
    make -j${CPU} && sudo make install
    make clean
  echo "end LLVM1200 build"    
else
  echo "please set right choise in OS=$OSNOW.."
  echo "Program exit"
  exit
fi

#
# post install processing
#
echo ""
echo "Start post install processing."
grep LLVM_DIR ${HOME}/.bashrc
ret=$?
if [ $ret -eq "1" ] && [ -d /usr/local/llvm_1200/bin ]; then
  echo "Updating ${HOME}/.bashrc"
  echo "# " >> ${HOME}/.bashrc
  echo "# LLVM setting for binary and LD_ & LIBRARY_PATH" >> ${HOME}/.bashrc
  echo "export LLVM_DIR=/usr/local/llvm_1200">> ${HOME}/.bashrc
  echo "export PATH=\$LLVM_DIR/bin:\$PATH" >>  ${HOME}/.bashrc
  echo "export LIBRARY_PATH=\$LLVM_DIR/lib:\$LIBRARY_PATH" >>  ${HOME}/.bashrc
  echo "export LD_LIBRARY_PATH=\$LLVM_DIR/lib:\$LD_LIBRARY_PATH" >>  ${HOME}/.bashrc
  sudo ln -sf /usr/local/llvm_1200/bin/clang++ /usr/local/llvm_1200/bin/clang++-12 
fi

if [ -f /usr/local/llvm_1200/bin/lld ]; then
  sudo rm /usr/bin/ld
  sudo ln -s /usr/local/llvm_1200/bin/lld /usr/bin/ld
  echo "/usr/bin/ld is replaced by lld."
else
  echo "ERROR : lld not found under /usr/local/llvm_1200/bin/"
  echo "ERROR : Please check if your llvm build is ok. Program exit."
  exit
fi

# ------------------------------------------------------
# Refresh your shell and check your clang version again
# ------------------------------------------------------
exec $SHELL -l
sudo ldconfig -v
CLANG_VERSION=$(/usr/local/llvm_1200/bin/clang --version | awk 'NR<2 { print $3 }' | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')
if [ $CLANG_VERSION -eq "120000" ]; then
  echo "You have LLVM-12.0.0 under /usr/local/llvm_1200/."
  echo "Conguraturations."
  echo "LLVM compile & install done."
  date
else
  echo "ERROR: Some issues. LLVM-12.00 was not successfully built."
  echo "ERROR: Please check build log. Program exit"
  date
  exit
fi
