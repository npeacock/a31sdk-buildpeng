#!/bin/bash
set -e


PLATFORM=""
MODULE=""
CUR_DIR=$PWD
OUT_DIR=$CUR_DIR/out
#KERN_VER=3.4.29
#KERN_VER_RELEASE=3.4.29
KERN_VER=3.3
KERN_VER_RELEASE=3.3
KERN_DIR=$CUR_DIR/linux-${KERN_VER}
KERN_OUT_DIR=$KERN_DIR/output
BR_DIR=$CUR_DIR/buildroot
BR_OUT_DIR=$BR_DIR/output
U_BOOT_DIR=$CUR_DIR/u-boot


PR_DIR=$CUR_DIR/../rootfs
#ROOTFS_NAME=linaro-min-orig
#ROOTFS_NAME=linaro-nano
#ROOTFS_NAME=linaro-min
ROOTFS_NAME=tizen
#ROOTFS_NAME=nemo
PR_OUT_DIR=$PR_DIR/$ROOTFS_NAME
ROOTFS_SIZE=1250000
#ROOTFS_SIZE=2100000

OUT_DIR_LIN=$CUR_DIR/out_linux
OUT_DIR_AND=$CUR_DIR/out_android

#BOOT_ANDROID_DIR=/media/Storage/allwinner/a31/SDK/android/android4.1/out/target/product/fiber-3g/root
#BOOT_ANDROID_OUT_DIR=/media/Storage/allwinner/a31/SDK/android/android4.1/out/target/product/fiber-3g
#BOOT_ANDROID_SIZE=25000

update_kdir()
{
	KERN_VER=$1
	KERN_DIR=${CUR_DIR}/linux-${KERN_VER}
	KERN_OUT_DIR=$KERN_DIR/output
}

show_help()
{
printf "
NAME
	build - The top level build script for Lichee Linux BSP

SYNOPSIS
	build [-h] | [-p platform] [-k kern_version] [-m module] | pack

OPTIONS
	-h             Display help message
	-p [platform]  platform, e.g. sun6i, sun6i_dragonboard, sun6i_fiber
                   sun6i: full linux bsp
                   sun6i_dragonboard: board test packages
                   sun6i_fiber: android kernel

	-k [kern_ver]  3.3(default)                          [OPTIONAL]

	-m [module]    Use this option when you dont want to build all. [OPTIONAL]
                   e.g. kernel, buildroot, uboot, all(default)...
	pack           To start pack program
	pengpack       To start pack program for pengpod with a custom rootfs

Examples:
	./build.sh -p sun6i
	./build.sh -p sun6i_dragonboard
	./build.sh -p sun6i_fiber
	./build.sh pack

"

}

update_kern_ver()
{
	if [ -r ${KERN_DIR}/include/generated/utsrelease.h ]; then
		KERN_VER_RELEASE=`cat include/generated/utsrelease.h |awk -F\" '{print $2}'`
	fi
}


regen_rootfs()
{
	if [ -d ${BR_OUT_DIR}/target ]; then
		echo "Copy modules to target..."
		mkdir -p ${BR_OUT_DIR}/target/lib/modules

		rm -rf ${BR_OUT_DIR}/target/lib/modules/*
		cp -rf ${KERN_OUT_DIR}/lib/modules/* ${BR_OUT_DIR}/target/lib/modules/

		if [ "$PLATFORM" = "sun4i-debug" ]; then
			cp -rf ${KERN_DIR}/vmlinux ${BR_OUT_DIR}/target
		fi
	fi


	if [ "$PLATFORM" != "sun6i_fiber" ]; then
		echo "Regenerating Rootfs..."
		(cd ${BR_DIR}; make target-generic-getty-busybox; make target-finalize)
        	(cd ${BR_DIR};  make LICHEE_GEN_ROOTFS=y rootfs-ext4)
	else
		echo "Skip Regenerating Rootfs..."
	fi
}

regen_peng_rootfs()
{
	if [ -d ${BR_OUT_DIR}/target ]; then
		echo "Copy modules to target..."
		sudo mkdir -p ${PR_OUT_DIR}/lib/modules

		sudo rm -rf ${PR_OUT_DIR}/lib/modules/*
		sudo cp -rf ${KERN_OUT_DIR}/lib/modules/* ${PR_OUT_DIR}/lib/modules/
		# this is a hacky way to do this
		sudo cp -rf ${PR_OUT_DIR}/etc/modules.dep ${PR_OUT_DIR}/lib/modules/3.3.0 

	fi

	# make it here
	sudo genext2fs -b $ROOTFS_SIZE -N 100000 -d ${PR_DIR}/$ROOTFS_NAME ${PR_DIR}/$ROOTFS_NAME-rootfs.ext4

	#sudo genext2fs -b 480000 -N 100000 -d ${PR_DIR}/linaro-usr ${PR_DIR}/linaro-usr-rootfs.ext4
}

regen_peng_rootfs_named()
{
ROOTFS_NAME=$1
PR_OUT_DIR=$PR_DIR/$ROOTFS_NAME
	if [ -d ${BR_OUT_DIR}/target ]; then
		echo "Copy modules to target..."
		sudo mkdir -p ${PR_OUT_DIR}/lib/modules

		sudo rm -rf ${PR_OUT_DIR}/lib/modules/*
		sudo cp -rf ${KERN_OUT_DIR}/lib/modules/* ${PR_OUT_DIR}/lib/modules/
		# this is a hacky way to do this
		sudo cp -rf ${PR_OUT_DIR}/etc/modules.dep ${PR_OUT_DIR}/lib/modules/3.3.0 

	fi

	# make it here
	sudo genext2fs -b $ROOTFS_SIZE -N 100000 -d ${PR_DIR}/$ROOTFS_NAME ${PR_DIR}/$ROOTFS_NAME-rootfs.ext4

	#sudo genext2fs -b 480000 -N 100000 -d ${PR_DIR}/linaro-usr ${PR_DIR}/linaro-usr-rootfs.ext4
}

#regen_peng_initrd2()
#{
#	if [ -d ${BR_OUT_DIR}/target ]; then
#		echo "Copy modules to target..."
#		mkdir -p ${PR_OUT_DIR}/lib/modules

#		rm -rf ${PR_OUT_DIR}/lib/modules/*
#		cp -rf ${KERN_OUT_DIR}/lib/modules/* ${PR_OUT_DIR}/lib/modules/
		# this is a hacky way to do this
#		cp -rf ${PR_OUT_DIR}/etc/modules.dep ${PR_OUT_DIR}/lib/modules/3.3.0 

#	fi

	# make it here
#	sudo genext2fs -b $BOOT_ANDROID_SIZE -N 20000 -d ${BOOT_ANDROID_DIR} ${BOOT_ANDROID_OUT_DIR}/bootandroid.img

	#sudo genext2fs -b 480000 -N 100000 -d ${PR_DIR}/linaro-usr ${PR_DIR}/linaro-usr-rootfs.ext4
#}

regen_dragonboard_rootfs()
{
    (cd ${BR_DIR}/target/dragonboard; if [ ! -d "./rootfs" ]; then echo "extract rootfs.tar.gz"; tar -zxf rootfs.tar.gz; fi)
    mkdir -p ${BR_DIR}/target/dragonboard/rootfs/lib/modules
    rm -rf ${BR_DIR}/target/dragonboard/rootfs/lib/modules/${KERN_VER}*
    cp -rf ${KERN_OUT_DIR}/lib/modules/* ${BR_DIR}/target/dragonboard/rootfs/lib/modules/
    (cd ${BR_DIR}/target/dragonboard; ./build.sh)
    return 0
}

gen_output_sun3i()
{
	echo "output sun3i"
}

gen_output_generic()
{
	cp -v ${BR_OUT_DIR}/images/* ${OUT_DIR}/
	cp -r ${KERN_OUT_DIR}/* ${OUT_DIR}/
	if [ -e ${U_BOOT_DIR}/u-boot.bin ]; then
		cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR}/
	fi
}

gen_output_pengpod()
{
	cp -v ${PR_DIR}/$ROOTFS_NAME-rootfs.ext4 ${OUT_DIR}/rootfs.ext4
	cp -r ${KERN_OUT_DIR}/* ${OUT_DIR}/
	if [ -e ${U_BOOT_DIR}/u-boot.bin ]; then
		cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR}/
	fi
}

gen_output_pengpod_linux()
{
	cp -v ${PR_DIR}/$ROOTFS_NAME-rootfs.ext4 ${OUT_DIR_LIN}/rootfs.ext4
	cp -r ${KERN_OUT_DIR}/* ${OUT_DIR_LIN}/
	if [ -e ${U_BOOT_DIR}/u-boot.bin ]; then
		cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR_LIN}/
	fi
}

gen_output_pengpod_android()
{
	cp -v ${PR_DIR}/$ROOTFS_NAME-rootfs.ext4 ${OUT_DIR_AND}/rootfs.ext4
	cp -r ${KERN_OUT_DIR}/* ${OUT_DIR_AND}/
	if [ -e ${U_BOOT_DIR}/u-boot.bin ]; then
		cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR}/
	fi
}

gen_output_sun4i()
{
	gen_output_generic
}

gen_output_sun4i-lite()
{
	gen_output_generic
}

gen_output_sun4i-debug()
{
	gen_output_generic
}

gen_output_a13-test()
{
	if [ ! -d "${OUT_DIR}" ]; then
		mkdir -pv ${OUT_DIR}
	fi

	#cp -v ${BR_OUT_DIR}/images/* ${OUT_DIR}/
	cp -r ${KERN_OUT_DIR}/* ${OUT_DIR}/

	if [ -e ${U_BOOT_DIR}/u-boot.bin ]; then
		cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR}/
	fi

	(cd $BR_DIR/target/test; fakeroot ./create_module_image.sh)
}

gen_output_sun5i()
{
	gen_output_generic
}

gen_output_a12()
{
	gen_output_generic
}

gen_output_a13()
{
	gen_output_generic
}

gen_output_sun4i_crane()
{
	if [ ! -d "${OUT_DIR}" ]; then
		mkdir -pv ${OUT_DIR}
	fi

	if [ ! -d "${OUT_DIR}/android" ]; then
		mkdir -p ${OUT_DIR}/android
	fi

	cp -r ${KERN_OUT_DIR}/* ${OUT_DIR}/android/
	mkdir -p ${OUT_DIR}/android/toolchain/
	cp ${BR_DIR}/dl/arm-2010.09-50-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2 ${OUT_DIR}/android/toolchain/

	if [ -e ${U_BOOT_DIR}/u-boot.bin ]; then
		cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR}/android
	fi
}

gen_output_a13_nuclear()
{
	if [ ! -d "${OUT_DIR}" ]; then
		mkdir -pv ${OUT_DIR}
	fi

	if [ ! -d "${OUT_DIR}/android" ]; then
		mkdir -p ${OUT_DIR}/android
	fi

	cp -r ${KERN_OUT_DIR}/* ${OUT_DIR}/android/
		mkdir -p ${OUT_DIR}/android/toolchain/
	cp ${BR_DIR}/dl/arm-2010.09-50-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2 ${OUT_DIR}/android/toolchain/

	if [ -e ${U_BOOT_DIR}/u-boot.bin ]; then
		cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR}/android
	fi
}

gen_output_a12_nuclear()
{
	gen_output_a13_nuclear
}

gen_output_sun6i()
{
	gen_output_generic
}

gen_output_sun6i_fiber()
{
	if [ ! -d "${OUT_DIR}" ]; then
		mkdir -pv ${OUT_DIR}
	fi

	if [ ! -d "${OUT_DIR}/android" ]; then
		mkdir -p ${OUT_DIR}/android
	fi


	cp -r ${KERN_OUT_DIR}/* ${OUT_DIR}/android
	if [ -e ${U_BOOT_DIR}/u-boot.bin ]; then
		cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR}/android
	fi
}

gen_output_sun6i_dragonboard()
{
    if [ ! -d "${OUT_DIR}/dragonboard" ]; then
        mkdir -p ${OUT_DIR}/dragonboard
    fi

    cp -v ${KERN_OUT_DIR}/boot.img ${OUT_DIR}/dragonboard/
    cp -v ${BR_DIR}/target/dragonboard/rootfs.ext4 ${OUT_DIR}/dragonboard/
    cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR}/dragonboard/
}

clean_output()
{
	rm -rf ${OUT_DIR}/*
	rm -rf ${BR_OUT_DIR}/images/*
	rm -rf ${KERN_OUT_DIR}/*
}

if [ "$1" = "pack" ]; then
   	echo "generate rootfs now, it will takes several minutes and log in out/"
	if [ ! -d "${OUT_DIR}" ]; then
		mkdir -pv ${OUT_DIR}
	fi
	regen_rootfs > out/gen_rootfs_log.txt 2>&1
	gen_output_sun6i >> out/gen_rootfs_log.txt 2>&1
	echo "generate rootfs has finished!"
    ${BR_DIR}/scripts/build_pack.sh
	exit 0
elif [ "$1" = "pengpack" ]; then
	# HERE WE NEED TO STOP OVERWRITING OR JUST DO OUR MODULES COPY AND CALL OUR OWN MKEXT4

   	echo "generate Pengpod rootfs now, it will takes several minutes and log in out/"
	if [ ! -d "${OUT_DIR}" ]; then
		mkdir -pv ${OUT_DIR}
	fi
	regen_peng_rootfs > out/gen_peng_rootfs_log.txt 2>&1
#	regen_peng_initrd2 > out/gen_peng_rootfs_log.txt 2>&1
	gen_output_pengpod >> out/gen_peng_rootfs_log.txt 2>&1
	echo "generate rootfs has finished!"
    ${BR_DIR}/scripts/build_pack.sh
	exit 0
elif [ "$1" = "pengpackname" ]; then
	# HERE WE NEED TO STOP OVERWRITING OR JUST DO OUR MODULES COPY AND CALL OUR OWN MKEXT4

   	echo "generate Pengpod rootfs now from '$2', it will takes several minutes and log in out/"
	if [ ! -d "${OUT_DIR}" ]; then
		mkdir -pv ${OUT_DIR}
	fi
	regen_peng_rootfs_named $2 > out/gen_peng_rootfs_log.txt 2>&1
#	regen_peng_initrd2 > out/gen_peng_rootfs_log.txt 2>&1
	gen_output_pengpod >> out/gen_peng_rootfs_log.txt 2>&1
	echo "generate rootfs has finished!"
    ${BR_DIR}/scripts/build_pack.sh
	exit 0
elif [ "$1" = "pengpackfast" ]; then
	# HERE WE NEED TO STOP OVERWRITING OR JUST DO OUR MODULES COPY AND CALL OUR OWN MKEXT4

   	echo "Just packing without recreating rootfs/"
	if [ ! -d "${OUT_DIR}" ]; then
		mkdir -pv ${OUT_DIR}
	fi
#	regen_peng_initrd2 > out/gen_peng_rootfs_log.txt 2>&1
	gen_output_pengpod >> out/gen_peng_rootfs_log.txt 2>&1
	echo "generate rootfs has finished!"
    ${BR_DIR}/scripts/build_pack.sh
	exit 0
elif [ "$1" = "penglin" ]; then
	rm -rf ${OUT_DIR_LIN}/*
 	echo "Create a Linux image for later Dual boot image"
	if [ ! -d "${OUT_DIR_LIN}" ]; then
		mkdir -pv ${OUT_DIR_LIN}
	fi
	regen_peng_rootfs_named $2 > out/gen_peng_rootfs_log.txt 2>&1
	gen_output_pengpod_linux >> out/gen_penglin_log.txt 2>&1
	echo "generate rootfs has finished!"
	exit 0 
elif [ "$1" = "penglinfast" ]; then
	rm -rf ${OUT_DIR_LIN}/*
 	echo "Store the Linux image for later Dual boot image"
	if [ ! -d "${OUT_DIR_LIN}" ]; then
		mkdir -pv ${OUT_DIR_LIN}
	fi
	gen_output_pengpod_linux >> out/gen_penglin_log.txt 2>&1
	echo "generate rootfs has finished!"
	exit 0
elif [ "$1" = "pack_dragonboard" ]; then
        regen_dragonboard_rootfs
        gen_output_sun6i_dragonboard
        ${BR_DIR}/scripts/build_pack.sh
	    exit 0
elif [ "$1" = "pack_prvt" ]; then
        ${BR_DIR}/scripts/build_prvt.sh
	    exit 0
fi

while getopts hp:m:k: OPTION
do
	case $OPTION in
	h) show_help
	exit 0
	;;
	p) PLATFORM=$OPTARG
	;;
	m) MODULE=$OPTARG
	;;
	k) KERN_VER=$OPTARG
	update_kdir $KERN_VER
	;;
	*) show_help
	exit 1
	;;
esac
done

if [ -z "$PLATFORM" ]; then
	show_help
	exit 1
fi


if [ -z "$PLATFORM" ]; then
	show_help
	exit 1
fi



clean_output

if [ "$MODULE" = buildroot ]; then
	cd ${BR_DIR} && ./build.sh -p ${PLATFORM}
elif [ "$MODULE" = kernel ]; then
	export PATH=${BR_OUT_DIR}/external-toolchain/bin:$PATH
	cd ${KERN_DIR} && ./build.sh -p ${PLATFORM}
elif [ "$MODULE" = "uboot" ]; then
	case ${PLATFORM} in
	a12_nuclear*)
			echo "build uboot for sun5i_a12"
		cd ${U_BOOT_DIR} && ./build.sh -p sun5i_a12
		;;
	a12*)
		echo "build uboot for sun5i_a12"
		cd ${U_BOOT_DIR} && ./build.sh -p sun5i_a12
		;;
	a13_nuclear*)
			echo "build uboot for sun5i_a12"
		cd ${U_BOOT_DIR} && ./build.sh -p sun5i_a13
		;;
	a13*)
		echo "build uboot for sun5i_a13"
		cd ${U_BOOT_DIR} && ./build.sh -p sun5i_a13
		;;
	*)
		echo "build uboot for ${PLATFORM}"
		cd ${U_BOOT_DIR} && ./build.sh -p ${PLATFORM}
		;;
	esac
else
	cd ${BR_DIR} && ./build.sh -p ${PLATFORM}
	export PATH=${BR_OUT_DIR}/external-toolchain/bin:$PATH
	cd ${KERN_DIR} && ./build.sh -p ${PLATFORM}

	case ${PLATFORM} in
		a12_nuclear*)
		echo "build uboot for sun5i_a12"
                cd ${U_BOOT_DIR} && ./build.sh -p sun5i_a12
		;;
        a12*)
                echo "build uboot for sun5i_a12"
                cd ${U_BOOT_DIR} && ./build.sh -p sun5i_a12
                ;;
        a13_nuclear*)
        echo "build uboot for sun5i_a12"
                cd ${U_BOOT_DIR} && ./build.sh -p sun5i_a13
		;;
		a13*)
                echo "build uboot for sun5i_a13"
                cd ${U_BOOT_DIR} && ./build.sh -p sun5i_a13
                ;;
		sun6i)
				echo "build uboot for sun6i"
				cd ${U_BOOT_DIR} && ./build.sh -p sun6i
		;;
		sun6i_fiber)
				echo "build uboot for sun6i_fiber"
				cd ${U_BOOT_DIR} && ./build.sh -p sun6i
				gen_output_${PLATFORM}
		;;
        sun6i_dragonboard)
                echo "build uboot for sun6i_dragonboard"
				cd ${U_BOOT_DIR} && ./build.sh -p sun6i

         ;;
		*)
                echo "build uboot for ${PLATFORM}"
                cd ${U_BOOT_DIR} && ./build.sh -p ${PLATFORM}
                ;;
        esac

	#regen_rootfs

	#gen_output_${PLATFORM}

	echo -e "\033[0;31;1m###############################\033[0m"
	echo -e "\033[0;31;1m#         compile success     #\033[0m"
	echo -e "\033[0;31;1m###############################\033[0m"
	fi


