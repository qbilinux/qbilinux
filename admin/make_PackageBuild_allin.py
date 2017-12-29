#! /usr/bin/python
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
pkgbase=%s
vers=%s
url=%s
commitid=
apply_arch="x86_64 i686 armv7l"
arch=`uname -m`
build=P0m1
src=%s-${vers}
OPT_CONFIG=''
DOCS='%s'
patchfiles='%s'
compress=txz
SRC_URL="http://circle2.org/pub/source/"
SRC_DIR="/home/archives/source/"
##############################################################

''' % (pkgname, vers, url, filename, docs, patchs)
    return header


def make_body1():
    body='''
W=`pwd`
for i in `seq 0 $((${#src[@]} - 1))` ; do
  S[$i]=$W/source/${src[$i]}
  B[$i]=$W/build/$arch/build`test ${#src[@]} -eq 1 || echo $i`
done
P=$W/work/$arch ; C=$W/pivot
infodir=$P/usr/share/info
mandir=$P/usr/share/man
xmandir=$P/usr/X11R7/share/man
docdir=$P/usr/share/doc
myname=`basename $0`
pkg=$pkgbase-$vers-$arch-$build

case $arch in
  x86_64)  libdir="lib64"; suffix="64" ;;
  *)       libdir="lib";   suffix="" ;;
esac
'''
    return body

def make_config(type, instdir):
    if type == "config":
        config = '''
############# begin user function

do_config() {
    if [ -d ${B[$1]} ] ; then rm -rf ${B[$1]} ; fi
    # cp -a ${S[$1]} ${B[$1]}
    mkdir ${B[$1]}
    cd ${B[$1]}
    # if [ -f autogen.sh ] ; then
    #   sh ./autogen.sh
    # fi
    if [ -x ${S[$1]}/configure ] ; then
      export PKG_CONFIG_PATH=/usr/${libdir}/pkgconfig:/usr/share/pkgconfig:/opt/kde/${libdir}/pkgconfig
      export LDFLAGS='-Wl,--as-needed' 
      ${S[$1]}/configure --prefix=%s --libdir=%s/${libdir} --sysconfdir=/etc --localstatedir=/var --mandir='${prefix}'/share/man ${OPT_CONFIG[$1]}
    fi
}''' % (instdir, instdir)
    elif type == "cmake":
        config = '''
do_config() {
    if [ -d ${B[$1]} ] ; then rm -rf ${B[$1]} ; fi
    # cp -a ${S[$1]} ${B[$1]}
    mkdir ${B[$1]}
    cd ${B[$1]}
    if [ -f ${S[$1]}/CMakeLists.txt ]; then
      export PKG_CONFIG_PATH=/opt/kde/${libdir}/pkgconfig:/usr/${libdir}/pkgconfig:/usr/share/pkgconfig
      export LDFLAGS='-Wl,--as-needed' 
      cmake -DCMAKE_INSTALL_PREFIX:PATH=%s -DLIB_INSTALL_DIR:PATH=%s/${libdir} -DLIB_SUFFIX=$suffix ${OPT_CONFIG} ${S[$1]}
    fi
}''' % (instdir, instdir)

    return config

def make_body2():
    body='''
do_build() {
    cd ${B[$1]}
    if [ -f Makefile ] ; then
      export LDFLAGS='-Wl,--as-needed'
      make
    fi
}

do_install() {
    cd ${B[$1]}
    for mk in `find . -name "[Mm]akefile" ` ; do
      sed -i -e 's|GCONFTOOL = /usr/bin/gconftool-2|GCONFTOOL = echo|' $mk
    done
    if [ -f Makefile ] ; then
      export LDFLAGS='-Wl,--as-needed'
      make install DESTDIR=$P
    fi
}

do_package() {
    echo "this is use function for package."
}

############# end user function

install2() {
  install -d ${2%/*} ; install -m 644 $1 $2
}

strip_all() {
  for chk in `find . ` ; do
    chk_elf=`file $chk | grep ELF`
    if [ "$chk_elf.x" != ".x" ]; then
      chk_lib=`echo $chk | grep lib`
      if [ "$chk_lib.x" != ".x" ]; then
        echo "stripping $chk with -g "
        strip -g $chk
      else
        echo "stripping $chk"
        strip $chk
      fi
    fi
  done
}

gzip_dir() {
  echo "compressing in $1"
  if [ -d $1 ] ; then (
    cd $1
    files=`ls -f --indicator-style=none | sed '/^\.\{1,2\}$/d'`
    # files=`ls -a --indicator-style=none | tail -n+3`
    for i in $files ; do
      echo "$i"
      if [ ! -f $i -a ! -h $i -o $i != ${i%.gz} ] ; then continue ; fi
      lnks=`ls -l $i | awk '{print $2}'`
      if [ $lnks -gt 1 ] ; then
        inum=`ls -i $i | awk '{print $1}'`
        for j in `find . -maxdepth 1 -inum $inum` ; do
          if [ ${j#./} == $i ] ; then
            gzip -f $i
          else
            rm -f ${j#./} ; ln $i.gz ${j#./}.gz
          fi
        done
      elif [ -h $i ] ; then
        target=`readlink $i` ; rm -f $i ; ln -s $target.gz $i.gz
      else
        gzip $i
      fi
    done
    for i in $files ; do mv ${i%.gz}.gz $C ; done
    for i in $files ; do mv $C/${i%.gz}.gz . ; done
  ) fi
}

gzip_one() {
  gzip $1 ; mv $1.gz $C ; mv $C/${1##*/}.gz ${1%/*}
}

compress_all() {
  cd $P
  strip_all
}  

if [ ! -d $SRC_DIR ]       ; then mkdir -p $SRC_DIR       ; fi
if [ ! -d $W/source ]      ; then mkdir -p $W/source      ; fi
if [ ! -d $W/build/$arch ] ; then mkdir -p $W/build/$arch ; fi

if  ! `echo ${apply_arch[@]} | grep -q "$arch"`  ; then
    echo "This package is not supported: $arch"
    break;
fi

if [ $# -eq 0 ] ; then
  opt_download=0 ; opt_patch=1 ; opt_config=1 ; opt_build=1 ; opt_package=1
else
  opt_download=0 ; opt_patch=0 ; opt_config=0 ; opt_build=0 ; opt_package=0
  for i in $@ ; do
    case $i in
    download) opt_download=1 ;;
    patch) opt_patch=1 ;;
    config) opt_config=1 ;;
    build) opt_build=1 ;;
    package) opt_package=1 ;;
    esac
  done
fi

if [ $opt_download -eq 1 ] ; then
  for i in $url ; do
    case ${i##*.} in
    git)
      if [ ! -d `basename ${i##*/} .git` ] ; then
        git clone $i
      else
        ( cd `basename ${i##*/} .git` ; git pull origin master )
      fi
      ;;
    *)
      if [ ! -f ${i##*/} ] ; then
        if [ -f ${SRC_DIR}/${i##*/} ] ;then
          cp ${SRC_DIR}/${i##*/} .
        else
          wget ${SRC_URL}/${i##*/}
        fi
      fi
      if [ ! -f ${i##*/} ] ; then
        wget $i
        for sig in asc sig{,n} {md5,sha{1,256}}{,sum} ; do
          if wget --spider $i.$sig ; then wget $i.$sig ; break ; fi
        done
        if [ -f ${i##*/}.$sig ] ; then
          case $sig in
            asc|sig) gpg --verify ${i##*/}.$sig ;;
            md5|sha1|sha256) ${sig}sum -c ${i##*/}.$sig ;;
            *) $sig -c ${i##*/}.$sig ;;
          esac
          if [ $? -ne 0 ] ; then echo "archive verify failed" ; exit ; fi
        fi
      fi
      if [ ! -f ${SRC_DIR}/${i##*/} ] ; then cp -p ${i##*/} ${SRC_DIR} ; fi
      ;;
    esac
  done
  for i in $url ; do
    case ${i##*.} in
    git)
      ( cd $W/source
        rm -rf clone $W/`basename ${i##*/} .git`
        git clone $W/`basename ${i##*/} .git`
        ( cd $W/source/`basename ${i##*/} .git`
          if [ -n "$commitid" ] ; then
            git reset --hard $commitid
          fi
          git set-file-times
        )) ;;
    zip)
      ( cd $W/source ; unzip -o $W/${i##*/} ) ;;
    *)
      ( cd $W/source ; tar xpf $W/${i##*/} )  ;;
    esac
  done
fi

if [ $opt_patch -eq 1 ] ; then
  for i in `seq 0 $((${#B[@]} - 1))` ; do
    if [ -d ${B[$i]} ] ; then rm -rf ${B[$i]} ; fi ; cp -a ${S[$i]} ${B[$i]}
  done
  ######################################################################
  # * ./configure を行う前に適用したい設定やパッチなどがある場合はここに
  #   記述します。
  ######################################################################
  for i in `seq 0 $((${#B[@]} - 1))` ; do
    cd ${B[$i]}
    for patch in $patchfiles ; do
      patch -p1 < $W/$patch
    done
  done
fi

if [ $opt_config -eq 1 ] ; then
  for i in `seq 0 $((${#B[@]} - 1))` ; do
    do_config $i
    if [ $? != 0 ]; then
      echo "configure error. $0 script stop"
      exit 255
    fi
  done
fi

if [ $opt_build -eq 1 ] ; then
  for i in `seq 0 $((${#B[@]} - 1))` ; do
    do_build $i
    if [ $? != 0 ]; then
      echo "make error. $0 script stop"
      exit 255
    fi
  done
fi

if [ $opt_package -eq 1 ] ; then
  if [ `id -u` -ne 0 ] ; then
    read -p "Do you want to package as root? [y/N] " ans
    if [ "x$ans" == "xY" -o "x$ans" == "xy" ] ; then
      cd $W ; /bin/su -c "$0 package" ; exit
    fi
  fi
  if [ -d $P ] ; then rm -rf $P ; fi ; mkdir -p $P
  if [ -d $C ] ; then rm -rf $C ; fi ; mkdir -p $C
  for i in `seq 0 $((${#B[@]} - 1))` ; do
    do_install $i
    if [ $? != 0 ]; then
      echo "make install error. $0 script stop"
      exit 255
    fi
  done
######################################################################
# * make install でコピーされないファイルがある場合はここに記述します。
######################################################################
  do_package
  mkdir -p $docdir/$src
  if [ -d $P/usr/share/omf ]; then
    mkdir -p $P/install
    for omf in $P/usr/share/omf/* ; do
      omf_name=`basename $omf`
      cat << EOF >> $P/install/initpkg
if [ -x /usr/bin/scrollkeeper-update ]; then
  scrollkeeper-update -p /var/lib/rarian -o /usr/share/omf/$omf_name
fi
EOF
    done
  fi

  if [ -d $P/etc/gconf/schemas ]; then
    mkdir -p $P/install
    for schema in $P/etc/gconf/schemas/* ; do
      cat << EOF >> $P/install/initpkg
if [ -x /usr/bin/gconftool-2 ]; then
  ( cd /etc/gconf/schemas ; GCONF_CONFIG_SOURCE=xml:merged:/etc/gconf/gconf.xml.defaults /usr/bin/gconftool-2 --makefile-install-rule `basename $schema` )
fi
EOF
    done
  fi

# remove locales except ja
# 
  for loc_dir in `find $P -name locale` ; do
    pushd $loc_dir
    for loc in * ; do
      if [ "$loc" != "ja" ]; then
        rm -rf $loc
      fi
    done
    popd
  done      

######################################################################
# path に lib があるバイナリは strip -g, ないバイナリは strip する
######################################################################
  cd $P
  compress_all
  if [ -d $P/usr/share/man ]; then
    for mdir in `find $P/usr/share/man -name man[0-9mno] -type d`; do
      gzip_dir $mdir
    done
  fi
######################################################################
# * compress 対象以外で圧縮したいディレクトリやファイルがある場合はここ
#   に記述します(strip_{bin,lib}dir や gzip_{dir,one} を使います)。
# * 他のアーカイブから追加したいファイルがある場合はここに記述します。
######################################################################
  cd $W
  for i in `seq 0 $((${#DOCS[@]} - 1))` ; do
    for j in ${DOCS[$i]} ; do
      for k in ${S[$i]}/$j ; do
        install2 $k $docdir/${src[$i]}/${k#${S[$i]}/}
        touch -r $k $docdir/${src[$i]}/${k#${S[$i]}/}
        gzip_one $docdir/${src[$i]}/${k#${S[$i]}/}
      done
    done
    if [ $i -eq 0 ] ; then
      install $myname $docdir/$src
      gzip_one $docdir/$src/$myname
    else
      ln $docdir/$src/$myname.gz $docdir/${src[$i]}
    fi
    ( cd $docdir ; find ${src[$i]} -type d -exec touch -r $W/{} {} \; )
  done

  for patch in $patchfiles ; do
    cp $W/$patch $docdir/$src/$patch
    gzip_one $docdir/$src/$patch
  done

############################################################
#   /usr/share/doc 以下には一般ユーザのIDのままのファイルが
#   紛れこみがちなので
############################################################

  chk_me=`whoami | grep root`
  if [ "$chk_me.x" != ".x" ]; then
    chown -R root.root $P/usr/share/doc
  fi

######################################################################
# * convert 対象以外で刈り取りたいシンボリックリンクがある場合はここに
#   記述します(prune_symlink を使います)。
# * 完成した作業ディレクトリから tar イメージを作成する手順を以降に記述
#   します(こだわりを求めないなら単に makepkg でも良いです)。
######################################################################
# tar cvpf $pkg.tar -C $P `cd $P ; find usr/bin | tail -n+2`
# tar rvpf $pkg.tar -C $P `cd $P ; find usr/share/man/man1 | tail -n+2`
# tar rvpf $pkg.tar -C $P usr/share/doc/$src
# touch -t `date '+%m%d0900'` $pkg.tar ; gzip $pkg.tar ; touch $pkg.tar.gz
# mv $pkg.tar.gz $pkg.tgz
  cd $P
  /sbin/makepkg $W/$pkg.$compress <<EOF
y
1
EOF

fi
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
    body2 = make_body2()
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
