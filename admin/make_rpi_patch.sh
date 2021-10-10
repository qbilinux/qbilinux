#!/bin/bash

version=$1
tree_version=${version%.*}
base_version=${tree_version%.*}
date_rev=`date +%Y%m%d`

source_dir=/home/archives/source/

if [ "$1" == "" ] ; then
    echo "usage: $0 revision"
    exit;
fi

get_file() {
    if [ -f ${source_dir}/$1 ] ; then
	cp -p ${source_dir}/$1 .
    else
	wget -nc https://cdn.kernel.org/pub/linux/kernel/v${base_version}.x/$1
    fi
}

get_file linux-${tree_version}.tar.xz
get_file patch-${version}.xz

if [ -f rpi-${version} ] ; then
    git clone --depth=1 --branch rpi-${tree_version}.y https://github.com/raspberrypi/linux rpi-${version}
fi
git_rev=`(cd rpi-${version}; git rev-parse HEAD | head -c 7)`

rm -rf linux-${tree_version}
tar xvf linux-${tree_version}.tar.xz
(cd linux-${tree_version}; xz -dc ../patch-${version}.xz | patch -p1)

diff -Nrc --exclude .git --exclude include-prefixes linux-${tree_version} rpi-${version} > rpi-${version}-${date_rev}-${git_rev}.patch
