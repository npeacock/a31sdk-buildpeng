#!/bin/bash
set -e

echo "Building Android for device=$1"


if [ -z $1 ] ; then
	BUILDDEVICE="fiber_3g"
	echo "No device entered, using default device=$BUILDDEVICE"
else
	BUILDDEVICE=$1
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

echo "Pack Android"
pack

echo "Android build finished"



