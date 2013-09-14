#!/bin/bash

echo "Updating initrd with fixes for Tizen"

MOD_FOLDER=../../linux-3.3/output/lib/modules/3.3.0
INITRD_TEMP_FOLDER=initrd_temp
INITRD_TEMP_MOD=ramdisk/lib/modules/3.3.0
INITRD_FOLDER=../../linux-3.3/output
INIT_FILE=init
INIT_NEW_IMAGE=new-boot.img

mod[0]='cfbcopyarea.ko'
mod[1]='cfbfillrect.ko'
mod[2]='cfbimgblt.ko'	
mod[3]='softcursor.ko'
mod[4]='bitblit.ko'
mod[5]='font.ko'
mod[6]='fbcon.ko'
mod[7]='disp.ko'
mod[8]='hdmi.ko'
mod[9]='lcd.ko'
mod[10]='nand.ko'

echo " Clear old work"

if [ -x "$INITRD_TEMP_FOLDER" ]; then
	rm -r $INITRD_TEMP_FOLDER/*
else
	mkdir initrd_temp
fi

echo " Copy new modules"

# Tizen has a special initrd with more drivers packed in...
cp $INITRD_FOLDER/boot.img $INITRD_TEMP_FOLDER
cd $INITRD_TEMP_FOLDER
unpack boot.img
cd ..

for t in "${mod[@]}"
do
	cp $MOD_FOLDER/$t $INITRD_TEMP_FOLDER/$INITRD_TEMP_MOD
done

# And an init to load them
echo " Copy Tizen init file to load extra drivers"
cp $INIT_FILE $INITRD_TEMP_FOLDER/ramdisk

# repack
echo "Repacking..."
cd $INITRD_TEMP_FOLDER
#rm $INIT_NEW_IMAGE
echo "PWD1=$PWD"
repacklin boot.img
cd ..
echo "PWD2=$PWD"

if [ -e $INITRD_TEMP_FOLDER/$INIT_NEW_IMAGE ] ; then
	echo "New image is ready"
	cp $INITRD_TEMP_FOLDER/$INIT_NEW_IMAGE $INITRD_FOLDER/boot.img
else
	echo "Error, the new image was not created... "
fi

