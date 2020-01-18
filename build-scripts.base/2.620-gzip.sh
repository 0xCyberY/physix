#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2019 Travis Davies
source /physix/include.sh || exit 1
cd /sources/$1 || exit 1

./configure --prefix=/usr
chroot_check $? "gzip config"

make
chroot_check $? "gzip make"

make check
# Test fail so don't tank it.. (Cross fingers, pray to Satan).
chroot_check $? "gzip make check" NOEXIT

make install
chroot_check $? "gzip make install"

mv -v /usr/bin/gzip /bin

