prune_symlink() {
  echo "pruning symlink in $1"
  if [ -d $1 ] ; then (
    cd $P
    rm -f /tmp/iNsT-a.$$ ; touch /tmp/iNsT-a.$$
    for i in `find ${1#$P/} -type l` ; do
      target=`readlink $i`
      echo "$i -> $target"
      echo $i$'
'$target >> /tmp/iNsT-a.$$
    done
    COUNT=1
    LINE=`sed -n "${COUNT}p" /tmp/iNsT-a.$$`
    while [ -n "$LINE" ] ; do
      LINKGOESIN=`dirname $LINE`
      LINKNAMEIS=`basename $LINE`
      COUNT=$(($COUNT + 1))
      LINKPOINTSTO=`sed -n "${COUNT}p" /tmp/iNsT-a.$$`
      if [ ! -d install ] ; then mkdir install ; fi
      cat <<- EOF >> install/doinst.sh
	( cd $LINKGOESIN ; rm -rf $LINKNAMEIS )
	( cd $LINKGOESIN ; ln -sf $LINKPOINTSTO $LINKNAMEIS )
	EOF
      rm -rf $LINE ; touch -t `date '+%m%d0900'` install/doinst.sh $LINE
      COUNT=$(($COUNT + 1))
      LINE=`sed -n "${COUNT}p" /tmp/iNsT-a.$$`
    done
    rm -f /tmp/iNsT-a.$$
  ) fi
}

convert_links() {
  for i in {$P,$P/usr}/{sbin,bin} ; do prune_symlink $i ; done
  for i in {$P,$P/usr}/lib ; do prune_symlink $i ; done
  for i in {$P,$P/usr}/lib64 ; do prune_symlink $i ; done
  prune_symlink $infodir
  for i in `seq 9` n ; do prune_symlink $mandir/man$i ; done
}


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
  ) fi
}

gzip_one() {
  gzip $1
}


download_sources() {
  case ${url##*.} in
  git)
    if [ ! -d $(basename ${url##*/} .git) ] ; then
      git clone $url
    else
      ( cd $(basename ${url##*/} .git) ; git pull origin master )
    fi
    ;;
  *)
    if [ ! -f ${url##*/} ] ; then
      wget $url
      j=${url%.*}
      for sig in asc sig{,n} {sha{256,1},md5}{,sum} ; do
        if wget --spider $url.$sig ; then
          wget $url.$sig
          break
        fi
        if wget --spider $j.$sig ; then
          case ${url##*.} in
          gz) gunzip -c ${url##*/} > ${j##*/} ;;
          bz2) bunzip2 -c ${url##*/} > ${j##*/} ;;
          xz) unxz -c ${url##*/} > ${j##*/} ;;
          esac
          touch -r ${url##*/} ${j##*/} ; url=$j ; wget $url.$sig ; break
        fi
      done
      if [ -f ${url##*/}.$sig ] ; then
        case $sig in
        asc|sig|sign) gpg2 --verify ${url##*/}.$sig ;;
        sha256|sha1|md5) ${sig}sum -c ${url##*/}.$sig ;;
        *) $sig -c ${url##*/}.$sig ;;
        esac
        if [ $? -ne 0 ] ; then echo "archive verify failed" ; exit ; fi
      fi
    fi
    ;;
  esac
  case ${url##*/} in
  *.tar*) tar xvf ${url##*/} ;;
  *.zip) unzip ${url##*/} ;;
  git)
    ( cd $(basename ${url##*/} .git)
      git checkout master
      if [ -n "$commitid" ]; then
        git checkout -b build $commitid
      fi
    ) ;;
  esac
}

verify_checksum() {
  echo "Verify Checksum..."
  checksum_command=$1
  verify_file=${verify##*/}
  for s in $url ; do
    srcsum=`$checksum_command ${s##*/}`
    verifysum=`grep ${s##*/} $verify_file`
    if [ x"$srcsum" != x"$verifysum" ]; then
      exit 1
    fi
  done
  exit 0
}


check_root() {
  if [ `id -u` -ne 0 ] ; then
    read -p "Do you want to package as root? [y/N] " ans
    if [ "x$ans" == "xY" -o "x$ans" == "xy" ] ; then
      cd $W ; /bin/su -c "$0 package" ; exit
    fi
  fi
}

# ���󥹥ȡ����γƼ�Ĵ��
install_tweak() {
  # �Х��ʥ�ե������ strip
  cd $P
  strip_all

  # dir �ե�����κ��
  if [ -d $infodir ]; then
    rm -f $infodir/dir
    for info in $infodir/*
    do
      gzip_one $info
    done
  fi

  # ja �ʳ���locale�ե��������
  for loc_dir in `find $P/usr/share -name locale` ; do
    pushd $loc_dir
    for loc in * ; do
      if [ "$loc" != "ja" ]; then
        rm -rf $loc
      fi
    done
    popd
  done

  #  man �ڡ����򰵽�
  if [ -d $P/usr/share/man ]; then
    for mdir in `find $P/usr/share/man -name man[0-9mno] -type d`; do
      gzip_dir $mdir
    done
  fi

  # doc �ե�����Υ��󥹥ȡ���Ȱ���
  cd $W
  for doc in $DOCS ; do
    install2 $S/$doc $docdir/$src/$doc
    touch -r $S/$doc $docdir/$src/$doc
    gzip_one $docdir/$src/$doc
  done
  install $myname $docdir/$src
  gzip_one $docdir/$src/$myname

  # �ѥå��ե�����Υ��󥹥ȡ���
  for patch in $patchfiles ; do
    cp $W/$patch $docdir/$src/$patch
    gzip_one $docdir/$src/$patch
  done

  # /usr/share/doc �ʲ���owner.group����
  chk_me=`whoami | grep root`
  if [ "$chk_me.x" != ".x" ]; then
    chown -R root.root $P/usr/share/doc
  fi

}

#####
# set working directories

W=`pwd`
WD=/tmp
S=$W/$src
B=$WD/build
P=$W/work
C=$W/pivot

infodir=$P/usr/share/info
mandir=$P/usr/share/man
xmandir=$P/usr/X11R7/share/man
docdir=$P/usr/share/doc
myname=`basename $0`
pkg=$pkgbase-$vers-$arch-$build

if [ $arch = "x86_64" ]; then
  target="-m64"
  libdir="lib"
  suffix=""
else
  target="-m32"
  libdir="lib"
  suffix=""
fi
