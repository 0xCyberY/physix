#!/bin/bash
source /opt/physix/include.sh || exit 1
cd $SOURCE_DIR/$1 || exit 1

su physix -c './configure'
chroot_check $? "tmux : configure"

su physix -c "make -j$NPROC"
chroot_check $? "tmux : make"

make install
chroot_check $? "tmux : make install"

