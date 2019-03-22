#!/bin/bash

print_usage() {
    echo ""
    echo "usage: $0 topdir ver arch" ;
    echo ""
    echo "    topdir: binary directory (contains x86, x86_64)"
    echo "    ver:    version number"
    echo "    arch:   x86 or x86_64"
    echo ""
    echo "    ex) "
    echo "      using qbilinux-1.0/x86 and makes qbilinux-1.0_{date}_dvd.iso file."
    echo "            ============ ===                    ==="
    echo "            ->topdir     ->arch                 ->ver"
    echo ""
    echo "       % $0 qbilinux-1.0 1.0 x86"
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
if [ $3 != "x86" -a  $3 != "x86_64" ] ; then
    echo ""
    echo "error: arch is x86 or x86_64." ;
    echo ""
    print_usage
    exit ;
fi

topdir=$1
ver=$2
arch=$3
dt=`date +%Y%m%d`
xorrisofs -o qbilinux-${ver}_${arch}_${dt}_dvd.iso \
   -isohybrid-mbr /usr/share/syslinux/isohdpfx.bin \
   -c isolinux/boot.cat \
   -b isolinux/isolinux.bin \
   -no-emul-boot \
   -boot-load-size 4 \
   -boot-info-table \
   -eltorito-alt-boot \
   -e isolinux/efiboot.img \
   -no-emul-boot \
   -isohybrid-gpt-basdat \
   -append_partition 2 0xef ./${topdir}/${arch}/isolinux/efiboot.img \
   ${topdir}/${arch}
sha256sum qbilinux-${ver}_${arch}_${dt}_dvd.iso > qbilinux-${ver}_${arch}_${dt}_dvd.iso.sha256
