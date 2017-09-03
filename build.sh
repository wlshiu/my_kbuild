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

export ARCH=arm
export CROSS_COMPILE=/home/wl/work/gcc-arm-none-eabi-5_4-2016q3/bin/arm-none-eabi-

export PATH=/home/wl/work/gcc-arm-none-eabi-5_4-2016q3/arm-none-eabi/include:$PATH
export LD_LIBRARY_PATH=/home/wl/work/gcc-arm-none-eabi-5_4-2016q3/arm-none-eabi/lib


cur_dir=`pwd`
cd ../
# cp -fr ~/sf_share/kbuild/ ./
cd $cur_dir

if [ -z .config ]; then
    make menuconfig
fi

make

