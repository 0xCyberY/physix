#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2019 Travis Davies
source ../../physix/include.sh || exit 1
cd $BUILDROOT/sources/$1 || exit 1
source ~/.bashrc

./configure --prefix=/tools
check $? "patch: Configure"

make
check $? "patch: make"

make check
check $? "patch make check" NOEXIT

make install
check $? "patch make install"

