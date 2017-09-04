#!/bin/bash -
#===============================================================================
#
#          FILE: build.sh
#
#         USAGE: ./build.sh
#
#   DESCRIPTION:
#
#       OPTIONS: ---
#        AUTHOR: Wei-Lun Hsu (WL),
#  ORGANIZATION:
#       CREATED: 08/31/2017
#      REVISION:  ---
#===============================================================================

set -o nounset                                  # Treat unset variables as an error
set -e

#export toolchain_path=work/gcc-arm-none-eabi-5_4-2016q3
export toolchain_path=gcc-arm-none-eabi-4_9-2015q1

export ARCH=arm
export CROSS_COMPILE=$HOME/${toolchain_path}/bin/arm-none-eabi-

# newlib
export PATH=$HOME/${toolchain_path}/arm-none-eabi/include:$PATH
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/${toolchain_path}/arm-none-eabi/lib
export LD_LIBRARY_PATH=$HOME/${toolchain_path}/arm-none-eabi/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

echo $PATH

cur_dir=`pwd`
cd ../
# cp -fr ~/sf_share/kbuild/ ./
echo $cur_dir
cd $cur_dir

if [ -z .config ]; then
    make menuconfig
fi

make

