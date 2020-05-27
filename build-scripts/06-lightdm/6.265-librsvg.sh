#!/bin/bash
source /opt/physix/include.sh || exit 1
cd $SOURCE_DIR/$1 || exit 1

su physix -c 'source ~/.profile && ./configure --prefix=/usr --enable-vala --disable-static --libdir=/usr/lib64'
chroot_check $? 'configure'

su physix -c ". /etc/profile && make -j$NPROC"
chroot_check $? "make "

make install
chroot_check $? 'make install'
