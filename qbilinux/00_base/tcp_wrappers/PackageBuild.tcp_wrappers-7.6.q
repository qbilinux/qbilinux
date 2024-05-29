#!/bin/sh

######################################################################
pkgbase=tcp_wrappers
vers=7.6.q
url="http://archive.debian.org/debian/pool/main/t/tcp-wrappers/tcp-wrappers_7.6.q.orig.tar.gz
    http://archive.debian.org/debian/pool/main/t/tcp-wrappers/tcp-wrappers_7.6.q-16.diff.gz"
apply_arch="x86_64 i686 armv7l aarch64"
arch=${arch:-`uname -m`}
build=2
src=tcp_wrappers_7.6
OPT_CONFIG=""
DOCS="README BLURB DISCLAIMER CHANGES README.IRIX README.NIS"
compress=txz
SRC_URL=${SRC_URL:-"https://qbilinux.org/pub/source/"}
SRC_DIR=${SRC_DIR:-"/home/archives/source/"}
######################################################################

source /usr/src/qbilinux/PackageBuild.def

do_prepare() {
    cd ${S[$i]}
    for patch in $patchfiles ; do
	patch -p1 < $W/$patch
    done
    gunzip -c $W/tcp-wrappers_7.6.q-16.diff.gz | patch -Np1 -i -
    for i in `cat debian/patches/series` ; do
	patch -Np1 -i debian/patches/$i
    done
}

do_config() {
    if [ -d ${B[$1]} ] ; then rm -rf ${B[$1]} ; fi

    cp -a ${S[$1]} ${B[$1]}
    cd ${B[$1]}
}

do_build() {
    cd ${B[$1]}
    if [ -f Makefile ] ; then
	export LDFLAGS='-Wl,--as-needed'
	make linux
    fi
    if [ $? != 0 ]; then
	echo "make error. $0 script stop"
	exit 255
    fi
}

do_install() {
    cd ${B[$1]}

    # add extra func
  install -d $P/usr/sbin
  for i in tcpd tcpdmatch try-from safe_finger tcpdchk ; do
    install $i $P/usr/sbin
  done
  install -d $P/usr/$libdir
  install shared/libwrap.so.0.7.6 $P/usr/$libdir
  install -m 644 libwrap.a $P/usr/$libdir
  ln -s libwrap.so.0.7.6 $P/usr/$libdir/libwrap.so.0
  ln -s libwrap.so.0.7.6 $P/usr/$libdir/libwrap.so
  install -d $P/usr/include
  install -m 644 tcpd.h $P/usr/include
  install -d $mandir/man{3,5,8}
  install -m 644 hosts_access.3 $mandir/man3
  for i in hosts_access hosts_options ; do
    install -m 644 $i.5 $mandir/man5
  done
  for i in tcpd tcpdmatch try-from safe_finger tcpdchk ; do
    install -m 644 $i.8 $mandir/man8
  done
  install -d $P/etc
  cat <<- "EOF" > $P/etc/hosts.allow.new
	#
	# hosts.allow	This file describes the names of the hosts which are
	#		allowed to use the local INET services, as decided by
	#		the '/usr/sbin/tcpd' server.
	#
	# Version:	@(#)/etc/hosts.allow	1.00	05/28/93
	#
	# Author:	Fred N. van Kempen, <waltje@uwalt.nl.mugnet.org
	#
	#
	ALL : LOCAL
	# End of hosts.allow.
	EOF
  cat <<- "EOF" > $P/etc/hosts.deny.new
	#
	# hosts.deny	This file describes the names of the hosts which are
	#		*not* allowed to use the local INET services, as decided
	#		by the '/usr/sbin/tcpd' server.
	#
	# Version:	@(#)/etc/hosts.deny	1.00	05/28/93
	#
	# Author:	Fred N. van Kempen, <waltje@uwalt.nl.mugnet.org
	#
	#
	ALL : ALL EXCEPT LOCAL
	# End of hosts.deny.
	EOF
  install -d $P/install
  cat <<- "EOF" >> $P/install/doinst.sh
	
	hosts_config() {
	  mv etc/hosts.$1.new /tmp
	  if [ -f etc/hosts.$1 ] ; then
	    mv /tmp/hosts.$1.new etc/hosts.$1.dist
	  else
	    mv /tmp/hosts.$1.new etc/hosts.$1
	  fi
	}
	
	for i in allow deny ; do hosts_config $i ; done
	EOF
}

do_package() {
    for i in $pkgbase ; do
        cd $P
        /sbin/makepkg $W/$pkg.$compress <<EOF
y
1
EOF
    done
}

source /usr/src/qbilinux/PackageBuild.func
