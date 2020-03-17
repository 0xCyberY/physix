#!/bin/bash
source /opt/physix/include.sh || exit 1
source /etc/profile.d/xorg.sh || exit 2
cd $SOURCE_DIR/$1 || exit 3

su physix -c "./configure $XORG_CONFIG"
chroot_check $? "xcb: configure and make"

su physix -c "make -j$NPROC"
chroot_check $? "xcb : make"

make install
chroot_check $? "xcb : make install"

