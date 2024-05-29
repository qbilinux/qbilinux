#! /usr/bin/python3
# -*- coding: utf-8 -*-;

import getopt, sys, os, tarfile

def usage():
    print("Usage:")
    print(sys.argv[0],": make PackageBuild script for archive file or source tree (directory)")
    print(sys.argv[0],"[-hv] [-t type] <archive_file | directory>")
    print("")
    print("          -h, --help : help (show this message)")
    print("          -v, --verbose : verbose (not implemented yet)")
    print("          -u, --url= : source code url (need citation)")
    print("          -p, --prefix= : set prefix directorey. (default is /usr)")
    print("          -t, --type= : select script type. Script types are follows:")
    print("                cmake : using cmake")
    print("                meson : using meson")
    print("                  otherwise using configure")
    print("  archive_file is a source archive in tar.gz or tar.bz2 format")
    print("  directory is a source code directory")
    print("")
    print(" example: ", sys.argv[0], "myprogs.tar.bz2")
    print("          ", sys.argv[0], "mycode_directory")

    sys.exit(2)

def get_parms():
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hvt:u:p:", ["help", "verbose", "type=", "url=", "prefix="])
    except getopt.GetoptError:
        usage()
        sys.exit(2)

    result = [opts, args]
    return result

def tar_expand(archive):
    tar = tarfile.open(archive, 'r')
    for i in tar:
        tar.extract(i)

def tar_top(archive):
    tar = tarfile.open(archive, 'r')
    (dirname, trash) = archive.split('.tar')
    print("in tar_top, dirname = ", dirname)
    tarlist = []
    for i in tar:
        tarlist.append(i.name)
    
    return tarlist[0]

def get_readmes(files):
    keywords = ['ABOUT', 'AUTHOR', 'COPYING', 'CHANGELOG', 'HACKING', 'HISTORY', 'INSTALL', 'LICENSE', 'LSM', 'MAINTAINERS', 'NEWS', 'README', 'RELEASE', 'THANKS', 'THANKYOU', 'TODO',  'TXT']
    exceptions = ['CMakeLists.txt', 'install-sh', 'mkinstalldirs', 'install.sh', '.in']

    tmplist = []
    newlist = [];
    for i in files:
        check = i.upper()
        for j in keywords:
            if check.find(j) >= 0:
                tmplist.append(i)
                break

    for i in tmplist:
        match = False
        for j in exceptions:
            if i.find(j) >= 0:
                match = True
                break
                
        if match == False:
            newlist.append(i)
                
    return newlist

def get_patchfiles(files):
    keywords = ['PATCH', 'DIFF']
    patchlist = []
    for i in files:
        check = i.upper()
        for j in keywords:
            if check.find(j) >= 0:
                patchlist.append(i)

    return patchlist

def make_headers(url, filename, vers, readme, patchfiles):
    pkgname = filename.replace('-', '_')
    readme.sort()
    docs = " ".join(readme)
    patchs = " ".join(patchfiles)
    header = '''#!/bin/sh
##############################################################
pkgbase="%s"
vers=%s
url=%s
commitid=
apply_arch="x86_64 i686 armv7l aarch64"
arch=`uname -m`
build=1
src=%s-${vers}
OPT_CONFIG=''
DOCS='%s'
patchfiles='%s'
compress=txz
SRC_URL=${SRC_URL:-"https://qbilinux.org/pub/source/"}
SRC_DIR=${SRC_DIR:-"/home/archives/source/"}
##############################################################

''' % (pkgname, vers, url, filename, docs, patchs)
    return header


def make_body1():
    body='''
source /usr/src/qbilinux/PackageBuild.def

do_prepare() {
    cd ${S[$1]}
    for patch in $patchfiles ; do
	patch -p1 < $W/$patch
    done
}

'''
    return body

def make_config(type, instdir):
    if type == "config":
        config = '''
do_config() {
    if [ -d ${B[$1]} ] ; then rm -rf ${B[$1]} ; fi

    mkdir ${B[$1]}
    cd ${B[$1]}
    if [ -x ${S[$1]}/configure ] ; then
      export PKG_CONFIG_PATH=/usr/${libdir}/pkgconfig:/usr/share/pkgconfig
      export LDFLAGS='-Wl,--as-needed' 
      ${S[$1]}/configure --prefix=%s --libdir=%s/${libdir} --sysconfdir=/etc --localstatedir=/var --mandir='${prefix}'/share/man ${OPT_CONFIG[$1]}
    fi
    if [ $? != 0 ]; then
	echo "configure error. $0 script stop"
	exit 255
    fi
}
''' % (instdir, instdir)
    elif type == "meson":
        config = '''
do_config() {
    if [ -d ${B[$1]} ] ; then rm -rf ${B[$1]} ; fi

    mkdir ${B[$1]}
    cd ${B[$1]}
    if [ -f ${S[$1]}/meson.build ] ; then
      export PKG_CONFIG_PATH=/usr/${libdir}/pkgconfig:/usr/share/pkgconfig:/opt/kde/${libdir}/pkgconfig
      export LDFLAGS='-Wl,--as-needed' 
      meson setup --prefix=%s --libdir=%s/${libdir} --sysconfdir=/etc --localstatedir=/var --mandir=/usr/share/man ${OPT_CONFIG[$1]} ${S[$1]}
    fi
    if [ $? != 0 ]; then
	echo "configure error. $0 script stop"
	exit 255
    fi
}
''' % (instdir, instdir)
    elif type == "cmake":
        config = '''
do_config() {
    if [ -d ${B[$1]} ] ; then rm -rf ${B[$1]} ; fi

    mkdir ${B[$1]}
    cd ${B[$1]}
    if [ -f ${S[$1]}/CMakeLists.txt ]; then
      export PKG_CONFIG_PATH=/usr/${libdir}/pkgconfig:/usr/share/pkgconfig
      export LDFLAGS='-Wl,--as-needed' 
      cmake -DCMAKE_INSTALL_PREFIX:PATH=%s -DLIB_INSTALL_DIR:PATH=%s/${libdir} -DLIB_SUFFIX=$suffix ${OPT_CONFIG} ${S[$1]}
    fi
    if [ $? != 0 ]; then
	echo "configure error. $0 script stop"
	exit 255
    fi
}
''' % (instdir, instdir)

    return config

def make_body2(type):
    if type == "meson":
        body='''
do_build() {
    cd ${B[$1]}
    export LDFLAGS='-Wl,--as-needed'
    ninja
    if [ $? != 0 ]; then
	echo "make error. $0 script stop"
	exit 255
    fi
}

do_install() {
    cd ${B[$1]}
    export LDFLAGS='-Wl,--as-needed'
    DESTDIR=$P ninja install
    if [ $? != 0 ]; then
	echo "make install error. $0 script stop"
	exit 255
    fi

    # add extra func
    # mkdir -p $P2/hoge
    # cp hoge.txt $P2/hoge
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
'''
    else:
        body='''
do_build() {
    cd ${B[$1]}
    export LDFLAGS='-Wl,--as-needed'
    make
    if [ $? != 0 ]; then
	echo "make error. $0 script stop"
	exit 255
    fi
}

do_install() {
    cd ${B[$1]}
    export LDFLAGS='-Wl,--as-needed'
    make install DESTDIR=$P
    if [ $? != 0 ]; then
	echo "make install error. $0 script stop"
	exit 255
    fi

    # add extra func
    # mkdir -p $P2/hoge
    # cp hoge.txt $P2/hoge
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
'''
    return body

def make_desc(pkgname):
    header = '''%s & y & y & y & y
&
%s
&
&
%s
&
''' % (pkgname, pkgname, pkgname)
    return header

###########

def main():
    opts, filelist = get_parms()

    verbose = False
    type = "config"
    instdir = "/usr"
    url = "'input sourcecode url here'"
    for o, a in opts:
        if o == "-v":
            verbose = True
        elif o in ("-h", "--help"):
            usage()
        elif o in ("-t", "--type"):
            type = a
        elif o in ("-p", "--prefix"):
            instdir = a
        elif o in ("-u", "--url"):
            url = "'" + a + "'"

    filetmp = filelist[0]
    file = filetmp.rstrip("/")
    if file.find('.tar') >= 0:
        archive = os.path.basename(file)
        if verbose == True:
            print("unpacking :", archive)
        tar_expand(archive)

# tmpname = tar_top(archive)
        (dirname, trash) = archive.split('.tar')
        print("dirname = ", dirname)
    elif os.path.isdir(file) == True:
        dirname = file
    elif len(sys.argv) == 1:
        files = os.listdir('.')
        for i in files:
            if i.find('.tar') >= 0:
                archive = i
                break
            tar_expand(archive)
            (dirname, trash) = archive.split('.tar')
            if verbose == True:
                print("dirname = ", dirname)
        else:
            usage()

    listparts = dirname.split('-')
    vers = listparts[-1]

    if verbose == True:
        print("version:", vers)

    fileparts = listparts[0:len(listparts)-1]
    filename = '-'.join(fileparts)
    pkgname = filename.replace('-', '_')

    if verbose == True:
        print("filename, pkgname:", filename, pkgname)

# newfiles = os.listdir(dirname)
    READMEs = get_readmes(os.listdir(dirname))
    patches = get_patchfiles(os.listdir(os.getcwd()))
    if verbose == True:
        print("patches:", patches)

   # url = 'ftp://ftp.kddlabs.co.jp/pub/GNOME/desktop/2.26/2.26.2/sources/'+filename+'-'+vers+'.tar.bz2'
    header = make_headers(url, filename, vers, READMEs, patches)
    body1 = make_body1()
    config = make_config(type, instdir)
    body2 = make_body2(type)
    body = body1 + config + body2

    scriptname = 'PackageBuild.' + dirname
    print("making %s ..." % scriptname)

    out = open(scriptname, 'w')
    out.write(header)
    out.write(body)
    out.close()

    os.chmod(scriptname, 0o755)

    # making desc file
    
    scriptname = pkgname + '.desc'
    print("making %s ..." % scriptname)

    out = open(scriptname, 'w')
    out.write(make_desc(pkgname))
    out.close()

    
#for i in dt.splitlines():
#    print i

if __name__ == "__main__":
    main()
