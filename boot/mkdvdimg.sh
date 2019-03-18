#!/bin/bash
progname=$(basename $0)
cmddir=$(dirname $0)
basedir=$cmddir/../

W=`pwd`

contain_pkg=0
contain_firm=0
arch=x86_64
ver=0.0
dest=.
make_img=0

usage() {
    echo "Usage: $progname [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help      : help."
    echo "  -p, --pkg       : contain package file."
    echo "  -f, --firm      : contain firmware file."
    echo "  -a, --arch ARG  : set architecture. i686, x86_64, armv7l or aarch."
    echo "  -v, --vers ARG  : set iso/image version."
    echo "  -d, --dest ARG  : set dest directory."
    echo "  -i, --image     : make image file (iso/sd image)."
    echo
    echo "Example:"
    echo "  $progname -a i686 -v 1.0 -d test"
    echo "  -> output: qbilinux-1.0_{date}-i686.iso"
    echo "             test/i686/.."
    echo
    exit 1
}

for OPT in "$@" ; do
    case "$OPT" in
        '-h'|'--help' )
            usage
            exit 1
            ;;
        '-p'|'--pkg' )
	    contain_pkg=1
            shift 1
            ;;
        '-f'|'--firm' )
	    contain_firm=1
            shift 1
            ;;
	'-a'|'--arch' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$progname: option requires an argument -- $1" 1>&2
                exit 1
            fi
            arch=$2
            shift 2
            ;;
	'-v'|'--vers' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$progname: option requires an argument -- $1" 1>&2
                exit 1
            fi
            ver=$2
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
        '-i'|'--image' )
	    make_img=1
            shift 1
            ;;
        -*)
            echo "$progname: illegal option -- '$(echo $1 | sed 's/^-*//')'" 1>&2
	    echo
	    usage
            exit 1
            ;;
    esac
done

img_base_name=qbilinux-${ver}_`date '+%y%m%d'`-${arch}

pkg="
	busybox
	udev"
dist_pkg="
	00_base/btrfs_progs
	00_base/attr
	00_base/acl
	00_base/bzip2
	00_base/coreutils
	00_base/dialog
	00_base/dosfstools
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

make_initrd() {
    if [ -d initrd ] ; then
	rm -f initrd
    fi
    if [ -d kernel ] ; then
	rm -f kernel
    fi
    mkdir initrd
    tar -C initrd -xvf ${cmddir}/initrd_plain.tar

    # initrd_plain.tar 中の kbd の一部ファイルも差し替える必要ありそう．

    for i in $dist_pkg; do
	echo ${basedir}/qbilinux/$i/*.txz
	installpkg -root $W/initrd ${basedir}/qbilinux/$i/*.txz  ;
    done
    for i in $pkg; do
	installpkg -root $W/initrd ${cmddir}/package/$i/$i*.txz  ;
    done
    if [ $contain_firm = 1 ] ; then
	for i in $dist_firmware; do
	    installpkg -root $W/initrd ${basedir}/qbilinux/$i/*.txz  ;
	done
    fi
    installpkg -root $W/initrd ${basedir}/qbilinux/00_base/kernel/kernel-*-${arch}-*.txz

    cp -a ${cmddir}/installer/* initrd/
    (cd initrd/usr/lib/setup/; ln -sf setup2 setup)
    (cd initrd/usr/lib/setup/; ln -sf fdsetupj setupj)
    mv initrd/boot kernel

    (cd initrd ; find . | tail -n+2 | cpio -o -H newc | gzip -n ) > initrd.gz
}

copy_pkg() {
    if [ $contain_pkg = 1 ] ; then
	${basedir}/admin/makedist.py ${basedir}/qbilinux $1 $2
	${basedir}/admin/makedist.py ${basedir}/contrib $1 $2
    fi
}


case $arch in
    x86_64 | i686)
	make_initrd
	
	media=$dest/$arch
	if [ ! -d $media ] ; then
	    mkdir -p $media
	fi
	cp -a ${cmddir}/DVD32/* $media

	# K=$media/isolinux
	# mkdir -p $K
	# cp -p /usr/share/syslinux/isolinux.bin $K
	# cp -p /usr/share/syslinux/{ldlinux,menu,vesamenu,lib{util,com32}}.c32 $K
	# cp -p isolinux/{isolinux.cfg,sample.msg,qbilinux.lss} $K
	# chown root.root $K/{isolinux.cfg,sample.msg,qbilinux.lss}
	# mkdir -p $media/EFI/BOOT
	# if [ $arch == i686 ] ; then
	#     grub-mkimage -p '' -o $media/EFI/BOOT/BOOTIA32.EFI -O i386-efi fat \
	# 		 part_msdos iso9660 gzio all_video gfxterm font terminal normal \
	# 		 linux echo test search configfile cpuid minicmd
	#     wget -P $media/EFI/BOOT \
	#          ftp://plamo.linet.gr.jp/pub/Plamo-src/plamo/99_test/installer/BOOTX64.EFI
	# else
	#     wget -P $media/EFI/BOOT \
	#          ftp://plamo.linet.gr.jp/pub/Plamo-src/plamo/99_test/installer/BOOTIA32.EFI
	#     grub-mkimage -p '' -o $media/EFI/BOOT/BOOTX64.EFI -O x86_64-efi fat \
	# 		 part_msdos iso9660 gzio all_video gfxterm font terminal normal \
	# 		 linux echo test search configfile cpuid minicmd
	# fi
	# cat <<- "EOF" > $media/EFI/BOOT/GRUB.CFG
	# 	menuentry "UEFI Plamo Linux install from DVD" {
	# 	  linux (cd0)/isolinux/vmlinuz root=/dev/ram0 rw nomodeset vga16 kbd=usbkbd
	# 	  initrd (cd0)/isolinux/initrd.gz
	# 	}
	# 	menuentry "UEFI Plamo Linux install from USB DVD" {
	# 	  linux (hd0)/isolinux/vmlinuz root=/dev/ram0 rw nomodeset vga16 kbd=usbkbd
	# 	  initrd (hd0)/isolinux/initrd.gz
	# 	}
	# 	menuentry "UEFI Plamo Linux install from USB memory" {
	# 	  linux (hd0,msdos1)/isolinux/vmlinuz root=/dev/ram0 rw nomodeset vga16 kbd=usbkbd
	# 	  initrd (hd0,msdos1)/isolinux/initrd.gz
	# 	}
	# 	menuentry "UEFI Plamo Linux install on VirtualBox" {
	# 	  linux (hd1)/isolinux/vmlinuz root=/dev/ram0 rw nomodeset vga16 kbd=usbkbd
	# 	  initrd (hd1)/isolinux/initrd.gz
	# 	}
	# 	EOF
	# find $media/EFI -exec touch -t `date '+%m%d0900'` {} \;
	# mkdir efiboot
	# fallocate -l 1440K $K/efiboot.img
	# /sbin/mkfs -t fat $K/efiboot.img
	# mount -o loop $K/efiboot.img efiboot
	# mkdir -p efiboot/EFI/BOOT
	# cp -p $media/EFI/BOOT/BOOT{IA32,X64}.EFI efiboot/EFI/BOOT
	# cat <<- "EOF" > efiboot/EFI/BOOT/GRUB.CFG
	# 	menuentry "Plamo Linux install from DVD" {
	# 	  linux (cd0)/isolinux/vmlinuz root=/dev/ram0 rw
	# 	  initrd (cd0)/isolinux/initrd.gz
	# 	}
	# 	EOF
	# find efiboot/EFI -exec touch -t `date '+%m%d0900'` {} \;
	# umount efiboot
	# touch -t `date '+%m%d0900'` $K/efiboot.img

	cp kernel/{System.map,vmlinuz,config} $media/isolinux/
	cp initrd.gz $media/isolinux/

	copy_pkg $media $arch

	if [ $make_img = 1 ] ; then
	    pushd $media
	    xorrisofs -o $W/${img_base_name}_dvd.iso \
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
		      -append_partition 2 0xef DVD/isolinux/efiboot.img \
		      $media
	    popd
	fi
	;;
    armv7l | aarch64)
	make_initrd

	media=$dest/$arch
	if [ ! -d $media ] ; then
	    mkdir -p $media
	fi

	#cp kernel/{System.map,vmlinuz,config} $media
	cp kernel/* $media
	cp initrd.gz $media
	cp ${cmddir}/rpi_firmware/* $media

	copy_pkg $media $arch
	
	if [ $make_img = 1 ] ; then
	    imgdir=__tmp__
	    if [ ! -d $imdir ] ; then
		mkdir $imgdir
	    fi
	    
	    # make img file
	    img=${img_base_name}_sd.img
	    size=3840 ; fallocate -l ${size}M $img
	    cat <<- EOF | sfdisk $img
		8192,$(((size - 4) * 2048)),c,*
		EOF
	    loop=`losetup -f`
	    losetup -P $loop $img
	    /sbin/mkfs -t fat ${loop}p1
	    mount ${loop}p1 $imgdir

	    cp -a $media $imgdir
	    
	    umount $imgdir
	    losetup -d $loop
	fi
	;;
    *)
        echo "$progname: no such architechture -- $arch" 1>&2
	echo
	usage
	;;
esac
