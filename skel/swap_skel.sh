#!/bin/bash

#$1 = name of rootfs

if [  -x $1-rootfs.cpio.gz ] ; then
	echo "*** Rootfs file $1-rootfs.cpio.gz not found in skel, quitting ***"
	exit -1
else
	echo "Rootfs file $1-rootfs.cpio.gz found, copying"
	rm ../../linux-3.3/rootfs/rootfs.cpio.gz
	cp $1-rootfs.cpio.gz ../../linux-3.3/rootfs/rootfs.cpio.gz
fi

