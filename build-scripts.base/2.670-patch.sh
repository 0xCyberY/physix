#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2019 Travis Davies
source /physix/include.sh || exit 1
cd /sources/$1 || exit 1

./configure --prefix=/usr
chroot_check $? "patch configure"

make
chroot_check $? "patch make "

make check
chroot_check $? "patch make check" NOEXIT

make install
chroot_check $? "patch make install "

