#!/bin/bash
progname=$(basename $0)
cmddir=$(dirname $0)
basedir=$cmddir/../
bootdir=${basedir}/boot

W=`pwd`

contain_firm=0
pkgdir=.
arch=x86_64
dest=.

pkg="
	busybox
	dosfstools
	udev"
dist_pkg="
	00_base/btrfs_progs
	00_base/attr
	00_base/acl
	00_base/bzip2
	00_base/coreutils
	00_base/dialog
	00_base/e2fsprogs
	00_base/glibc
	00_base/libgcc
	00_base/lvm2
	00_base/lzo
	00_base/mdadm
	00_base/ncurses
	00_base/net_tools
	00_base/readline
	00_base/util_linux
	00_base/xz
	00_base/gzip
	00_base/tar
	00_base/kbd
	00_base/kmod
	00_base/file
	00_base/libseccomp
	00_base/libcap
	00_base/sysfsutils
	00_base/zlib
	00_base/reiserfsprogs
	00_base/pciutils
	01_minimum/devel.txz/binutils
	01_minimum/nilfs_utils
	01_minimum/nfs.txz/nfs_utils
	01_minimum/usbutils
	05_ext/fuse
	05_ext/ntfs_3g_ntfsprogs"
dist_firmware="
	00_base/linux_firmware"

usage() {
    echo
    echo "Usage: $progname [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help      : help."
    echo "  -f, --firm      : contain firmware file."
    echo "  -p, --pkg ARG   : set package directory. (default: $pkgdir)"
    echo "  -a, --arch ARG  : set architecture. x86, x86_64, armv7l or aarch64. (default: $arch)"
    echo "  -d, --dest ARG  : set dest directory. (default: $dest)"
    echo
    echo "Example:"
    echo "  $progname -a i686 -d test"
    echo "  -> output: test/i686/boot.."
    echo
    exit 1
}

for OPT in "$@" ; do
    case "$OPT" in
        '-h'|'--help' )
            usage
            exit 1
            ;;
        '-f'|'--firm' )
	    contain_firm=1
            shift 1
            ;;
	'-p'|'--pkg' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$progname: option requires an argument -- $1" 1>&2
                exit 1
            fi
            pkgdir=$2
            shift 2
            ;;
	'-a'|'--arch' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$progname: option requires an argument -- $1" 1>&2
                exit 1
            fi
            arch=$2
	    if [ $arch = x86 ] ; then
		pkg_arch=i686
	    else
		pkg_arch=$arch
	    fi
            shift 2
            ;;
	'-d'|'--dest' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$progname: option requires an argument -- $1" 1>&2
                exit 1
            fi
            dest=$2
            shift 2
            ;;
        -*)
            echo "$progname: illegal option -- '$(echo $1 | sed 's/^-*//')'" 1>&2
	    echo
	    usage
            exit 1
            ;;
    esac
done

inst_pkg() {
    if [ -f ${pkgdir}/$1/$2-*-${pkg_arch}-*.txz ] ; then
	installpkg -root $W/initrd ${pkgdir}/$1/$2-*-${pkg_arch}-*.txz
    elif [ -f ${pkgdir}/$1/$2-*-noarch-*.txz ] ; then
	installpkg -root $W/initrd ${pkgdir}/$1/$2-*-noarch-*.txz
    else
	"required package does not exist. (${pkgdir}/$1/$2-*-${pkg_arch}-*.txz)"
	exit 1
    fi
}

make_initrd() {
    if [ -d initrd ] ; then
	rm -f initrd
    fi
    if [ -d kernel ] ; then
	rm -f kernel
    fi
    mkdir initrd
    tar -C initrd -xvf ${bootdir}/initrd_plain.tar

    # initrd_plain.tar 中の kbd の一部ファイルも差し替える必要ありそう．

    for i in $pkg; do
	inst_pkg boot/package $i ;
    done
    for i in $dist_pkg; do
	inst_pkg qbilinux $i ;
    done
    if [ $contain_firm = 1 ] ; then
	for i in $dist_firmware; do
	    inst_pkg qbilinux $i ;
	done
    fi
    case $arch in
	x86_64 | x86)
	    inst_pkg qbilinux 00_base/kernel
	    ;;
	armv7l)
	    inst_pkg qbilinux 00_base/kernel7_rpi2
	    inst_pkg qbilinux 00_base/kernel7l_rpi4
	    ;;
	aarch64)
	    inst_pkg qbilinux 00_base/kernel8_rpi3
	    inst_pkg qbilinux 00_base/kernel8_rpi4
	    ;;
	*)
            echo "this arch is not supported: $arch" 1>&2
	    echo
	    ;;
    esac

    cp -a ${bootdir}/installer/* initrd/
    (cd initrd/usr/lib/setup/; ln -sf setup2 setup)
    (cd initrd/usr/lib/setup/; ln -sf fdsetupj setupj)
    mv initrd/boot kernel

    # remove files
    pushd initrd
    find lib lib64 usr/lib usr/lib64 -name "*.a" -exec rm {} \;
    rm -rf usr/include usr/src/qbilinux
    pushd usr/share/locale
    for loc in * ; do
    	if [ "$loc" != "ja" -a "$loc" != "ja_JP" -a "$loc" != "ja_JP.UTF-8" -a "$loc" != "ja_JP.eucJP" -a "$loc" != "locale.alias" ]; then
    	    rm -rf $loc
    	fi
    done
    popd
    popd
    
    (cd initrd ; find . | tail -n+2 | cpio -o -H newc | gzip -n ) > initrd.gz
}

case $arch in
    x86_64 | x86)
	make_initrd
	
	media=$dest/$arch
	if [ ! -d $media ] ; then
	    mkdir -p $media
	fi

	cp -a ${bootdir}/DVD32/* $media

	# K=$media/isolinux
	# mkdir -p $K
	# mkdir -p __tmpdir__
	# innstallpkg -root __tmpdir__ ${pkgdir}/qbilinux/00_base/syslinux-*-${pkg_arch}-*.txz
	# cp -p __tmpdir__/usr/share/syslinux/isolinux.bin $K
	# cp -p __tmpdir__/usr/share/syslinux/{ldlinux,menu,vesamenu,lib{util,com32}}.c32 $K
	# rm -rf __tmpdir__
	# cp -p ${bootdir}/isolinux/{isolinux.cfg,sample.msg,qbilinux.lss} $K
	# chown root.root $K/{isolinux.cfg,sample.msg,qbilinux.lss}

	# mkdir -p $media/EFI/BOOT
	# # execute in each architecture.
	# # grub-mkimage -p '' -o $media/EFI/BOOT/bootia32.efi -O i386-efi fat \
	# # 	     part_msdos iso9660 gzio all_video gfxterm font terminal normal \
	# # 	     linux echo test search configfile cpuid minicmd
	# # grub-mkimage -p '' -o $media/EFI/BOOT/BOOTx64.efi -O x86_64-efi fat \
	# # 	     part_msdos iso9660 gzio all_video gfxterm font terminal normal \
	# # 	     linux echo test search configfile cpuid minicmd
	# cp ${bootdir}/efi/BOOTx64.efi $media/EFI/BOOT
	# cp ${bootdir}/efi/bootia32.efi $media/EFI/BOOT
	# cat <<- "EOF" > $media/EFI/BOOT/GRUB.CFG
	# 	menuentry "UEFI Qbilinux install from DVD" {
	# 	  linux (cd0)/isolinux/vmlinuz root=/dev/ram0 rw nomodeset vga16 kbd=usbkbd
	# 	  initrd (cd0)/isolinux/initrd.gz
	# 	}
	# 	menuentry "UEFI Qbilinux install from USB DVD" {
	# 	  linux (hd0)/isolinux/vmlinuz root=/dev/ram0 rw nomodeset vga16 kbd=usbkbd
	# 	  initrd (hd0)/isolinux/initrd.gz
	# 	}
	# 	menuentry "UEFI Qbilinux install from USB memory" {
	# 	  linux (hd0,msdos1)/isolinux/vmlinuz root=/dev/ram0 rw nomodeset vga16 kbd=usbkbd
	# 	  initrd (hd0,msdos1)/isolinux/initrd.gz
	# 	}
	# 	menuentry "UEFI Qbilinux install on VirtualBox" {
	# 	  linux (hd1)/isolinux/vmlinuz root=/dev/ram0 rw nomodeset vga16 kbd=usbkbd
	# 	  initrd (hd1)/isolinux/initrd.gz
	# 	}
	# 	EOF

	if [ $arch = x86 ] ; then
	    mv $media/isolinux/efiboot.img.x86 $media/isolinux/efiboot.img
	    rm $media/isolinux/efiboot.img.x86_64
	else
	    mv $media/isolinux/efiboot.img.x86_64 $media/isolinux/efiboot.img
	    rm $media/isolinux/efiboot.img.x86
	fi
	# mkdir efiboot
	# fallocate -l 1440K $K/efiboot.img
	# mkfs.fat -F32 $K/efiboot.img
	# mount -o loop $K/efiboot.img efiboot
	# mkdir -p efiboot/EFI/BOOT
	# cp -p $media/EFI/BOOT/{BOOTx64,bootia32}.efi efiboot/EFI/BOOT
	# cat <<- "EOF" > efiboot/EFI/BOOT/GRUB.CFG
	# 	menuentry "Qbilinux install from DVD" {
	# 	  linux (cd0)/isolinux/vmlinuz root=/dev/ram0 rw
	# 	  initrd (cd0)/isolinux/initrd.gz
	# 	}
	# 	EOF
	# umount efiboot

	cp kernel/{System.map,vmlinuz,config} $media/isolinux/
	cp initrd.gz $media/isolinux/
	;;
    armv7l | aarch64)
	make_initrd

	media=$dest/$arch
	if [ ! -d $media ] ; then
	    mkdir -p $media
	fi

	#cp kernel/{System.map,vmlinuz,config} $media
	cp -r kernel/* $media
	cp initrd.gz $media
	cp ${bootdir}/rpi_firmware/* $media
	;;
    *)
        echo "$progname: no such architechture -- $arch" 1>&2
	echo
	usage
	;;
esac
