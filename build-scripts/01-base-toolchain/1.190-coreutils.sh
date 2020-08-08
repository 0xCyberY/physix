#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2019 Tree Davies
source /mnt/physix/opt/admin/physix/include.sh || exit 1
source ~/.bashrc

prep() {
	exit 0
}

config() {
	./configure --prefix=/tools --enable-install-program=hostname
	check $? "coreutils configure"
}

build() {
	make -j8
	check $? "coreutils make"
}

build_install() {
	make RUN_EXPENSIVE_TESTS=yes check
	check $? "coreutils make RUN_EXPENSIVE_TESTS=yes check" NOEXIT

	make install
	check $? "coreutils make install"
}

[ $1 == 'prep' ]   && prep   && exit $?
[ $1 == 'config' ] && config && exit $?
[ $1 == 'build' ]  && build  && exit $?
[ $1 == 'build_install' ] && build_install && exit $?



