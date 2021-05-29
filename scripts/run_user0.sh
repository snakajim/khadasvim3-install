#!/bin/bash
#
# batch for install_xx.sh
# 
# How to run:
# $> source ./run_user0.sh
# To use at command:
# $> echo "./run_user0.sh > /dev/null 2>&1" | at now
#
\time -ao install_llvm.log ./install_llvm.sh >& install_llvm.log
\time -ao install_flang.log ./install_flang.sh >& install_flang.log
