#!/bin/bash
set -e

echo "Building Android dual boot for device=$1 with Linux rootfs $2"


if [ -z $1 ] ; then
	BUILDDEVICE="fiber_3g"
	echo "No device entered, using default device=$BUILDDEVICE"
else
	BUILDDEVICE=$1
fi

if [ -z $2 ] ; then
	BUILDROOTFS="linaro-peng"
	echo "No device entered, using default device=$BUILDROOTFS"
else
	BUILDROOTFS=$2
fi

echo "Building Kernel for Android"
cd ..
build_peng.sh -p sun6i_fiber

echo "Setup Android build environment"
cd ../../android
source build/envsetup.sh
lunch "$1-eng"

echo "Copy in kernel and modules"
extract-bsp

echo "Build Android"
make -j8

echo "Build Linux Kernel"
cd ../lichee
buildpeng/build_peng.sh -p sun6i

echo "Prepare Linux rootfs"
buildpeng/build_peng.sh pengpackname $BUILDROOTFS

echo "Add dual-boot recovery"
cp buildpeng/and/recovery.img out_android

echo "Pack Android"
pack

echo "Android build finished"



