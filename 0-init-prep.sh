#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2019 Travis Davies

source ./include.sh
source ./build.conf

PWD=`pwd`

user=`whoami`
if [ $user != 'root' ] ; then
	echo "Must run this as user: root. Exiting..."
	exit 1
fi


# ---------------------------------------------------------------
# Create 3 partitions
#  - 1: 1GB Future EFI boot partition (not implemented)
#  - 2: 1GB boot partition
#  - 3: LVM partition
#       - /dev/mapper/physix-root
#       - /dev/mapper/physix-home
#-----------------------------------------------------------------
function init_storage_lvm() {

        local NUM_PARTITIONS=`ls /dev/ | grep $CONF_ROOT_DEVICE | wc -l`
        if [ $NUM_PARTITIONS -gt 1 ] ; then
                lsblk -f
		echo ""
		echo "[ERROR] Found existing partitions on /dev/$CONF_ROOT_DEVICE"
                echo "  If this is the device you wish to install to, Please remove all"
		echo "  Partitions from /dev/$CONF_ROOT_DEVICE, first."
                echo "Exiting."
                exit 1
        fi

	local FSF=`echo $CONF_FS_FORMAT | cut -d'=' -f2`
	local MKFS=`which mkfs.$FSF`
	if [ ! -e $MKFS ] ; then
        	echo "[ERROR] mkfs.$FSF NOT FOUND. exiting..."
        	exit 1
	fi

        report "Creating Partitions"
	/sbin/parted /dev/sda mklabel msdos 1
        /sbin/parted /dev/sda mkpart primary 1 1024
        if [ $? -ne 0 ] ; then
                report "[ERROR] create primary 1 1024"
                exit 1
        fi

        /sbin/parted /dev/sda mkpart primary 1024 2025
        if [ $? -ne 0 ] ; then
                report "[ERROR] create primary 1024 2025"
                exit 1
        fi

        /sbin/parted /dev/sda mkpart primary 2025 497000
        if [ $? -ne 0 ] ; then
                report "[ERROR] create primary 2025 497000"
                exit 1
        fi

        /sbin/parted /dev/sda set 1 boot on
        if [ $? -ne 0 ] ; then
                report "[ERROR] parted /dev/sda set 1 boot on"
                exit 1
        fi

	if [ "$CONF_FORMAT_UEFI"=="y" ] ; then
		/sbin/mkfs.fat  /dev/"$CONF_ROOT_DEVICE"1
		if [ $? -ne 0 ] ; then
			report "[ERROR] mkfs.fat  /dev/$CONF_ROOT_DEVICE'1'"
			exit 1
		fi
	fi

	if [ "$CONF_FORMAT_BOOT"=="y" ] ; then
		/sbin/mkfs.ext2 /dev/"$CONF_ROOT_DEVICE"2
		if [ $? -ne 0 ] ; then
			report "[ERROR] mkfs.ext2 /dev/$CONF_ROOT_DEVICE'2'"
			exit 1
		fi
	fi

        pvcreate -ff /dev/"$CONF_ROOT_DEVICE"3
        if [ $? -ne 0 ] ; then
                report "[ERROR] Createing Physical Volume $CONF_ROOT_DEVICE'3'. exiting..."
                exit 1
        fi

        vgcreate physix /dev/"$CONF_ROOT_DEVICE"3
        if [ $? -ne 0 ] ; then
                report "[ERROR] vgcreate physix /dev/$CONF_ROOT_DEVICE'3'"
                exit 1
        fi

        lvcreate -L 100G -n root physix
        if [ $? -ne 0 ] ; then
                report "[ERROR] lvcreate -L 100G -n root physix"
                exit 1
        fi

        lvcreate -L 150G -n home physix
        if [ $? -ne 0 ] ; then
                report "[ERROR] lvcreate -L 150G -n home physix"
                exit 1
        fi

        eval $MKFS /dev/mapper/physix-root
        if [ $? -ne 0 ] ; then
                report "[ERROR] $MKFS /dev/mapper/physix-root"
                exit 1
        fi

	#lvcreate -L 150G -n var physix
	#if [ $? -ne 0 ] ; then
	 #      report "[ERROR] lvcreate -L 150G -n home physix"
	 #      exit 1
	#fi

        eval $MKFS /dev/mapper/physix-home
        if [ $? -ne 0 ] ; then
                report "[ERROR] $MKFS /dev/mapper/physix-home"
                exit 1
        fi

        mkdir -p $BUILDROOT
        mount /dev/mapper/physix-root $BUILDROOT
        if [ $? -ne 0 ] ; then
                report "[ERROR] mounting $DEVICE"
                exit 1
        fi

        mkdir -p $BUILDROOT/home
        mount /dev/mapper/physix-home $BUILDROOT/home
        if [ $? -ne 0 ] ; then
                report "[ERROR] mounting $BUILDROOT/home"
                exit 1
        fi

        mkdir -p $BUILDROOT/boot
        mount /dev/sda2 $BUILDROOT/boot
        if [ $? -ne 0 ] ; then
                report "[ERROR] mounting $BUILDROOT/boot"
                exit 1
        fi
}


function complete_setup() {

	mkdir -vp $BUILDROOT/var/physix/system-build-logs
	#mkdir -v $BUILDROOT/system-build-logs
	mkdir -vp $BUILDROOT/usr/src/physix/sources

	# TODO tighten these perms
	chmod 777 $BUILDROOT/system-build-logs
	mv -v /tmp/physix-init-host-build.log $BUILDROOT/system-build-logs/build.log
	chmod 666 $BUILDROOT/system-build-logs/build.log

	echo "Downloading src-list.base"
	pull_sources ./src-list.base $BUILDROOT/sources

	CONF_UTILS=`cat ./build.conf | grep CONF_UTILS | cut -d'=' -f2`
	if [ "$CONF_UTILS" == "y" ] ; then
		pull_sources ./src-list.utils $BUILDROOT/sources
	fi

	CONF_DEVEL=`cat ./build.conf | grep CONF_DEVEL | cut -d'=' -f2`
	if [ "$CONF_DEVEL" == "y" ] ; then
		pull_sources ./src-list.devel $BUILDROOT/sources
	fi

	ln -sfv /usr/bin/bash /usr/bin/sh
	ln -sfv /usr/bin/gawk /usr/bin/awk

	if [ -e /tools ] ; then
		rm -rf /tools
	fi
	mkdir -v $BUILDROOT/tools
	ln -sfv $BUILDROOT/tools /

	groupadd physix

	grep -q physix /etc/passwd
	if [ $? -ne 0 ] ; then
		useradd -s /bin/bash -g physix -m -k /dev/null physix
	fi

	LOOP=0
	while [ $LOOP -eq 0 ] ; do
		report "Please Set passwd for 'physix' user"
		passwd physix
		if [ $? -eq 0 ] ; then LOOP=1; fi
	done

	cp -v configs/physix-bash-profile /home/physix/.bash_profile
	if [ $? -ne 0 ] ; then
		echo "Error Creating /home/physix/.bash_profile"
		exit 1
	fi
	cp -v configs/physix-bashrc /home/physix/.bashrc
	if [ $? -ne 0 ] ; then
		echo "Error Creating /home/physix/.bashrc"
		exit 1
	fi

	chown -v physix $BUILDROOT/tools
	chown -v physix $BUILDROOT/sources

	DPATH=$(dirname `pwd`)
	cp -r $PWD $BUILDROOT
	chmod 777 $BUILDROOT/physix
}

function check_build_conf() {
        ERRORS=0
        for VAL in `cat ./build.conf | cut -d'=' -f2` ; do
                case "$VAL" in
                        hostname)
                                ERRORS=$((ERRORS+1))
                                ;;
                        /dev/SDX)
                                ERRORS=$((ERRORS+1))
                                ;;
                        /dev/SDYZ)
                                ERRORS=$((ERRORS+1))
                                ;;
                        w.x.y.z)
                                ERRORS=$((ERRORS+1))
                                ;;
			FORMAT)
				ERRORS=$((ERRORS+1))
				;;
                esac
        done

        if [ $ERRORS -ne 0 ] ; then
                echo "[ERROR] $ERRORS build.conf"
                exit 1
        fi
}

#####  MAIN  ######
#check_build_conf

verify_tools
if [ $? -eq 0 ] ; then
	echo "[ OK ] HOst tools verification"
else
	echo "[ FAIL ] HOst tools verification"
	exit 1
fi

if [ -e /dev/$CONF_ROOT_DEVICE ] ; then
	if [ "$CONF_USE_LVM" == "y" ] ; then
		init_storage_lvm
	fi
else
        echo "[ERROR] Could not find $CONF_ROOT_DEVICE"
        exit 1
fi

complete_setup

report "--------------------------------"
report "- Disk Partitioning complete.  -"
report "- Next Steps:                  -"
report "-   cd /mnt/physix/physix      -"
report "-   ./1-build_toolchain.sh     -"
report "--------------------------------"

exit 0
