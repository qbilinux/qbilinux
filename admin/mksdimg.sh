#!/bin/bash

print_usage() {
    echo ""
    echo "usage: $0 topdir ver arch" ;
    echo ""
    echo "    topdir: binary directory (contains armv7l, aarch64)"
    echo "    ver:    version number"
    echo "    arch:   armv7l or aarch64"
    echo ""
    echo "    ex) "
    echo "      using qbilinux-current/armv7l and makes qbilinux-1.0_{date}_sd.img file."
    echo "            ================ ======                    ==="
    echo "            ->topdir         ->arch                    ->ver"
    echo ""
    echo "       % $0 qbilinux-current 1.0 armv7l"
    echo ""
    echo ""
}

if [ $# -ne 3 ] ; then
    print_usage
    exit ;
fi
if [ ! -d $1 ] ; then
    echo ""
    echo "error; $1 is not directory."
    echo ""
    print_usage
    exit ;
fi
if [ ! -d $1/$3 ] ; then
    echo ""
    echo "error: $1/$3 is not exist."
    echo ""
    print_usage
    exit ;
fi
if [ $3 != "armv7l" -a  $3 != "aarch64" ] ; then
    echo ""
    echo "error: arch is armv7l or aarch64." ;
    echo ""
    print_usage
    exit ;
fi

topdir=$1
ver=$2
arch=$3
dt=`date +%Y%m%d`

imgdir=__tmp__
if [ ! -d $imgdir ] ; then
    mkdir $imgdir
fi

# make img file
img=qbilinux-${ver}_${arch}_${dt}_sd.img
#size=3840 ; fallocate -l ${size}M $img
size=5200 ; fallocate -l ${size}M $img
cat <<- EOF | sfdisk $img
8192,$(((size - 4) * 2048)),c,*
EOF
loop=`losetup -f`
losetup -P $loop $img
mkfs.fat -F32 ${loop}p1
mount ${loop}p1 $imgdir

cp -r ${topdir}/${arch}/* $imgdir

umount $imgdir
losetup -d $loop
sha256sum qbilinux-${ver}_${arch}_${dt}_sd.img > qbilinux-${ver}_${arch}_${dt}_sd.img.sha256
