#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2019 Travis Davies
source ../../physix/include.sh || exit 1
cd $BUILDROOT/sources/$1 || exit 1
source ~/.bashrc


./configure --prefix=/tools
check $? "bison Configre"

make
check $? "bison make"

make check
check $? "bison make chck" NOEXIT

make install
check $? "bison  make install"

