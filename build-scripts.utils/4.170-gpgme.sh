#!/bin/bash
source /physix/include.sh || exit 1
source /physix/build.conf || exit 1
cd /sources/$1 || exit 1

./configure --prefix=/usr --disable-gpg-test
chroot_check $? "gpgme : configure"

make
chroot_check $? "gpgme : make"

make install
chroot_check $? "gpgme : make install"

