#!/bin/sh
##############################################################
pkgbase=py3_gyp
vers=20210831
url="https://chromium.googlesource.com/external/gyp.git"
apply_arch="x86_64 i686 armv7l aarch64"
arch=${arch:-`uname -m`}
build=3
src=gyp
OPT_CONFIG=''
DOCS='AUTHORS LICENSE README.md'
patchfiles=''
compress=txz
SRC_URL=${SRC_URL:-"https://qbilinux.org/pub/source/"}
SRC_DIR=${SRC_DIR:-"/home/archives/source/"}
##############################################################

source /usr/src/qbilinux/PackageBuild.def

do_prepare() {
    cd ${S[$i]}
    for patch in $patchfiles ; do
	patch -p1 < $W/$patch
    done
}

do_config() {
    if [ -d ${B[$1]} ] ; then rm -rf ${B[$1]} ; fi

    cp -a ${S[$1]} ${B[$1]}
}

do_build() {
    cd ${B[$1]}
}

do_install() {
    cd ${B[$1]}
    python3 setup.py install --root $P
    if [ $? != 0 ]; then
	echo "make install error. $0 script stop"
	exit 255
    fi
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
