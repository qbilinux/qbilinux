#!/bin/sh
##                            Time-stamp: <2017-08-16 12:43:35 toshi>

# 2004-08-07 added support of "AlwaysCore" mouse setting for laptop.
# 2004-08-04 added support for Plamo-4.01.
# 2004-07-16 added support for changing the resolution of an available vbios
#            mode for the 855 Intel graphic chipset.
# 2004-07-09 fixed LINE_BEGIN="..." bug when scanpci returns more than one
#            "CLASS 0x03".
# 2004-06-28 Multiple modes are set when 4:3 or 5:4 screen.
# 2004-06-22 added Section "DRI".
# 2004-06-21 added gpm support.
# 2004-06-20 added USB mouse auto detection.
#            added maxhsync, wheel and xkbmodel parameters.
# 2004-06-18 improvements on laptop.
# 2004-06-11 could be run without "bc" command.

# ������ϡ�
#   XFree86-4.4.0 �� getconfig �����Ѥ��ơ�KNOPPIX �饤���� X �μ�ư�����Ԥ�
#   CDplamo �ѤΥ�����ץȤǤ���
#
# ��������ˡ
#   /sbin �ʲ��˼¹�°����Ĥ��� xfplamoconfig.sh �ȡ����Υ���ܥ�å����
#   gpmplamoconfig.sh �Ȥ��������rc.S ������ǰʲ��Τ褦��ư����Ƥ���������
#  ��������������������������������������������������������������������
#  ��XFPLAMO_OPTIONS="`cat /proc/cmdline`"                           ��
#  ��/sbin/gpmplamoconfig.sh $XFPLAMO_OPTIONS > /etc/rc.d/rc.gpm     ��
#  ��chmod 755 /etc/rc.d/rc.gpm                                      ��
#  ��/sbin/xfplamoconfig.sh $XFPLAMO_OPTIONS > /etc/X11/XF86Config   ��
#  ��������������������������������������������������������������������
#   `cat /proc/cmdline` �ǡ�syslinux ���� boot: �ץ��ץȤǤΥ��ץ����ʸ����
#   �����ޤ����ϡ��ɥǥ������� rc.S �˻Ź���ʤ顤���������Ǥ�(�㤨��
#   XFPLAMO_OPTIONS="xscreen=1400x1050")�ˤ����⤢��ޤ���
#
# �����ץ����λ���
#   ��xscreen=��
#     �ǥ����ץ쥤�β����٤���ꤷ�ޤ���CDplamo �� Plamo 4.0 �Ǥϰʲ��β����٤�
#     �����ǽ�Ǥ���
#      - 4:3,5:4�⡼�� 800x600,1024x768,1152x864,1280x960,1280x1024,1400x1050,
#                      1600x1200,1792x1344,1856x1392,1920x1440
#      - �磻�ɥ⡼��  1024x600,1280x600,1280x768,1280x800,1680x1050,1920x1200
#     �ǥ����ȥåץޥ���䡤�ǥ����ץ쥤���磻�ɥ⡼�ɤ˳���������ϡ�ɬ��
#     xscreen �ǲ����٤���ꤷ�ޤ����ǥ����ȥåץޥ����̵����ξ��� 1024x768
#     �β����٤Ȥʤ�ޤ�����åץȥåפξ�硤�ǥ����ץ쥤�β����٤θ��Ф� X ��
#     Ǥ���Ƥ��ꡤX �ϸ��Ф��������٤˹�碌�Ƽ�ưŪ�� Modes �����򤷤ޤ����⤷
#     X �������٤θ��Ф˼��Ԥ���ȡ��ޤ����ޤ�ɽ���Ǥ��ʤ��Ǥ��礦�����ξ���
#     �Ϥ�ꡤxscreen �ǲ����٤���ꤹ��ɬ�פ�����ޤ���
#   ��xdepth=��
#     bpp�ͤǤ�������Ū�� 16 ���ǥե���ȤǤ��Τǡ�ɬ�פ˱����� xdepth=24 ���
#     �ꤷ�Ƥ���������
#   ��xvrefresh=��
#     ��ľƱ�����ȿ�����ꤷ�ޤ���4:3,5:4�⡼�ɤǤ� 60,70,72,75 �����٤ޤ�����
#     ���ɥ⡼�ɤǤ� 60 �����������ǽ�Ǥ���
#   ��xmodule=��
#     �ɥ饤�Х⥸�塼�����ꤷ�ޤ����ɥ饤�Х⥸�塼��� pci �ξ��󤫤�
#     getconfig �Ǽ�ư���򤷤ޤ������ȥ�֥뤬��������� xmodule=vesa �Τ褦
#     �˻��ꤷ�ޤ���
#   ��maxhsync=��
#     �ǥ����ץ쥤�ο�ʿƱ���κ�����ȿ�(kHz)����ꤷ�ޤ���
#   ��xkbmodel=��
#     �����ܡ��ɤμ�������ꤷ�ޤ���jp �� us �����Ǥ��ޤ���̵����ξ��ϡ�
#     rc.keymap �����꤫�鼫ư���ꤷ�ޤ���
#   ��xmouse=��
#     �ޥ���������򤷤ޤ���xmouse=wheel �ǥ���ƥ�ޥ����Υۥ����뤬�Ȥ���褦
#     �ˤʤ�ޤ���xmouse=gpm �� gpm ��ͳ�� PS/2 �ޥ����� USB �ޥ�����ξ���� X
#     ��ǻȤ���褦�ˤʤ�ޤ�(�������ۥ�����ϻȤ��ޤ���)��
#
# ��X����ư���ʤ������뤤���Զ�礬��������
#   �ۤȤ�ɤξ�硤xscreen=�� ����ꤹ��Ȳ�褹��Ȼפ��ޤ���
#   ����åץȥåץޥ���ξ��
#     ��åץȥåפǡֲ��̤����ðšפȤ������ϡ������餯 X ���ǥ����ץ쥤�β�
#     ���٤򤦤ޤ����ФǤ��Ƥ��ޤ���xscreen=�� �ǲ����٤���ꤷ�ޤ��礦��
#   ���ǥ����ץ쥤�� out of range �ˤʤ�
#     xscreen�ǲ����٤򲼤��뤫��xvrefresh�ǿ�ľƱ���򲼤��ޤ��礦��
#   ���ɤ��ˤ�Ǥ�ʤ�! �䤿�� X ���԰���!!
#     xmodule=vesa �Ȥ��ޤ��礦���Ǥ����������ϰʲ����̤�Ǥ��Τǡ��ɤ����褦
#     ��ʤ����ˤϻ�Ƥߤޤ��礦��
#    ����������������������������������������������
#    ��xscreen=1024x768 xmodule=vesa xvrefresh=60��
#    ����������������������������������������������
#
# ����������
#   ������ xfplamoconfig.sh ����������� XF86Config �ǡ�
#        Option     "NoDoublescan" "True"
#        Option     "NoInterlace" "True"
#     �Ȥ������ץ��������ޤ�����������Ǥ� XFree86 �� Xorg �Ǥϸ����ʤ����
#     �ǡ�Plamo �ȼ��Τ�ΤǤ�(�ѥå��� Plamo-src �ʲ��� XFree86 �Υ�����������
#     ���֤ˤ���ޤ�)�����Υ��ץ���󤬻��ꤵ���� XFree86 �����Ф� ���֥륹
#     �����⡼�ɤȥ��󥿥졼���⡼�ɤ�̵�뤹��褦�ˤʤ�ޤ�������ˤ�äơ�
#     �ۤܿ�ʿƱ�����ȿ� �� ������ �ˤʤ�Τǡ��ǥ����ץ쥤����out of range�פ�
#     ���˲����٤򲼤���гμ¤˿�ʿ���ȿ�������Ȳ�����Ȥ����櫓�Ǥ���
#   ��XFree86 �����Ф� VESA �� ModeLine �ΤۤȤ�ɤ���äƤ��ޤ��������������
#     �Ϥ���Խ�ʬ�ʤΤǡ�������ȼ��˥ѥå����Ƥ����Ĥ��� ModeLine ���ɲä���
#     ���ޤ����磻�ɥ⡼�ɤ� ModeLine �� xfplamoconfig.sh �����äƤ��ơ������
#     �� XFree86 �����Фˤ��ɲä��Ƥ��ޤ���
#   ����ľ���ȿ��� xvrefresh ��̵����ξ�硤�ǥ����ȥå׵��ξ��� 75Hz �ˡ���
#     �åץȥå׵��ξ��� 60Hz �˥��åȤ����褦�ˤʤäƤ��ޤ����ǥ����ȥå�/
#     ��åץȥåפ�Ƚ��ϡ�PCMCIA�����åȤ�̵ͭ�����Ѥ��Ƥ��ޤ���
#   ��USB �ޥ�����¸�ߥ����å��� /proc/bus/usb/devices ��ߤƤ��ơ�USB �ޥ�����
#     ��³����Ƥ������ USB �ޥ��������Ѥ�������� XF86Config ���������ޤ���
#   ��gpmplamoconfig.sh �Ȥ��Ƽ¹Ԥ����ȡ�rc.gpm ��ư�������ޤ���xmouse=��
#     �ˤ��б����Ƥ��ơ�xmouse=gpm �Ȥ������� PS/2 �� USB ��ξ���Υޥ�����
#     �Ȥ���褦�ˤ��ޤ���USB �ޥ�����¸�ߤ��ʤ����� xmouse=gpm �Ȥ��Ƥ� PS/2
#     only ������ˤʤ�ޤ���
#

set_vendor_and_device() {
  VENDOR=$1
  DEVICE=$2
}
set_CardVendor_and_card() {
  CARD_VENDOR=$1
  CARD=$2
}
set_REVISION() {
  REVISION=$1
}


THISCOMMAND="`basename $0`"

FALLBACK_XMODULE="vesa"
DEFAULT_XSCREEN="1024x768"
VERTRANGE="54.5 - 75.5"
DEFAULT_MAXHSYNC="137.0"
HORIZRANGE="31.5 - ${DEFAULT_MAXHSYNC}"
XKBMODEL=
LCDXVREFRESH="60"
XSCREEN=""
XVREFRESH=""
XMODULE=""
XDEPTH="24"
#XMOUSE="gpm"
XMOUSE=""
XSERVER="xorg"
DEVUSBMOUSE="/dev/input/mice"
DEVPS2MOUSE="/dev/psaux"

MODES43[0]="640x480"
MODES43[1]="800x600"
MODES43[2]="1024x768"
MODES43[3]="1152x864"
MODES43[4]="1280x960"
MODES43[5]="1280x1024"
MODES43[6]="1400x1050"
MODES43[7]="1600x1200"
MODES43[8]="1792x1344"
MODES43[9]="1856x1392"
MODES43[10]="1920x1440"
MODES43[11]=""

MODESWIDE[0]="1024x600"
MODESWIDE[1]="1280x600"
MODESWIDE[2]="1280x768"
MODESWIDE[3]="1366x768"
MODESWIDE[4]="1280x800"
MODESWIDE[5]="1680x1050"
MODESWIDE[6]="1920x1024"
MODESWIDE[7]="1920x1080"
MODESWIDE[8]="1920x1200"
MODESWIDE[9]="2560x1440"
MODESWIDE[10]=""

if [ "`cat /etc/rc.d/rc.keymap | sed -e 's/#.*//g' | grep jp106`" ]; then
  XKBMODEL="jp"
else
  XKBMODEL="us"
fi

LCD_CHK=`/usr/sbin/lspci -n | grep "Class 060[57]"`
#LCD_CHK="DUMMY"

CDPLAMO_CHK="`ls /usr/lib/setup/ | grep cdplamo`"


TMPFILE=`mktemp /tmp/tmp_xfplamoconfig_$$.XXXXXX`

#LINE_BEGIN=`/usr/X11R7/bin/scanpci -v|nl -b a|grep '	  CLASS     0x03 0x'|awk 'NR==1{print $1}'`
# 
# �Ƕ�� xserver �ϼ����ǥϡ��ɥ�������ǧ������scanpci �����פˤʤäƤ���Τǡ�
# �ɥ饤�и��н����� xserver �ˤ�餻�뤳�Ȥˤ���

LINE_BEGIN=''
if [ "$LINE_BEGIN" = "" ] ; then
  echo -n "" > $TMPFILE
else
  LINE_BEGIN=`expr $LINE_BEGIN - 4`
  LINE_END=`expr $LINE_BEGIN + 10`
  #echo $LINE_BEGIN
  /usr/X11R7/bin/scanpci -v | awk ${LINE_BEGIN}'<=NR&&NR<='${LINE_END}'{print}' > $TMPFILE
  #echo $SCANRESULT
  if [ "`cat $TMPFILE | awk 'NR==1{print}'`" = "" ] ; then
    set_vendor_and_device `cat $TMPFILE | awk 'NR==2{print $9" "$11}'`
    set_REVISION `cat $TMPFILE | awk 'NR==5{print $6}'`
  else
    set_vendor_and_device `cat $TMPFILE | awk 'NR==1{print $9" "$11}'`
    set_CardVendor_and_card `cat $TMPFILE | awk 'NR==3{print $2" "$4}'`
    set_REVISION `cat $TMPFILE | awk 'NR==5{print $6}'`
  fi
  #echo VENDOR: $VENDOR
  #echo DEVICE: $DEVICE
  #echo CARD_VENDOR: $CARD_VENDOR
  #echo CARD: $CARD
fi
rm -f $TMPFILE

if [ "$1" == "--initonly" ] ; then
  return 0
fi
if [ "$1" == "--no855test" ] ; then
  NO855TEST=True
fi

ARGS=""
while [ $1 ] ; do
  ARGS="$ARGS `echo $1|tr ',' ' '`"
  shift
done

for i in $ARGS ; do
  ARG=`echo $i|sed -e 's/=.*//g'`
  VAL=`echo $i|sed -e 's/.*=//g'`
  if [ "$ARG" = "xserver" ] ; then
    XSERVER="$VAL"
  elif [ "$ARG" = "xscreen" ] ; then
    XSCREEN="$VAL"
  elif [ "$ARG" = "xmodule" ] ; then
    XMODULE="$VAL"
  elif [ "$ARG" = "xdepth" ] ; then
    XDEPTH="$VAL"
  elif [ "$ARG" = "maxhsync" ] ; then
    HORIZRANGE="31.5 - $VAL"
  elif [ "$ARG" = "xvrefresh" ] ; then
    XVREFRESH="$VAL"
    LCDXVREFRESH="$VAL"
  elif [ "$ARG" = "xmouse" ] ; then
    VAL="`echo $VAL | tr A-Z a-z`"
    XMOUSE="$VAL"
    if [ "$XMOUSE" = "imps/2" -o "$XMOUSE" = "imps2" -o "$XMOUSE" = "imps" ] ; then
      XMOUSE="wheel"
    fi
  elif [ "$ARG" = "xkbmodel" ] ; then
    VAL="`echo $VAL | tr A-Z a-z`"
    if [ "$VAL" = "jp" -o "$VAL" = "jp106" -o "$VAL" = "106jp" -o "$VAL" = "106" ] ; then
      XKBMODEL="jp"
    else
      XKBMODEL="us"
    fi
  fi
done

#if [ "$XSERVER" = "xorg" ]; then
#  X11DIR=/usr/X11R7
#  CONFIGOPT="-config"
#  ( cd /usr/X11R7/bin ; rm -f X )
#  ( cd /usr/X11R7/bin ; ln -s Xorg X )
#else
#  X11DIR=/usr/XFree86
#  CONFIGOPT="-xf86config"
#  ( cd /usr/X11R7/bin ; rm -f X )
#  ( cd /usr/X11R7/bin ; ln -s ../../XFree86/bin/XFree86 X )
#fi
#PATH=$X11DIR:$PATH

if [ "$CDPLAMO_CHK" != "" ] ; then
  #USBMOUSE_CHK="`/sbin/lsmod | awk '{print $1}' | grep '^usbmouse'`"
  if [ -f /proc/bus/usb/devices ] ; then
    USBMOUSE_CHK="`cat /proc/bus/usb/devices | grep 'Driver=usbmouse'`"
  else
    USBMOUSE_CHK=""
  fi
fi

if [ "$XMOUSE" = "gpm" ] ; then
  DEVMOUSE="/dev/gpmdata"
else
  if [ "$USBMOUSE_CHK" != "" ] ; then
    DEVMOUSE="$DEVUSBMOUSE"
  else
    DEVMOUSE="$DEVPS2MOUSE"
  fi
fi

if [ "$THISCOMMAND" = "gpmplamoconfig.sh" ] ; then
    cat <<EOF
#!/bin/sh
# Start/stop the GPM mouse server:

if [ "\$1" = "stop" ]; then
  echo "Stopping gpm..."
  gpm -k
else
  echo "Starting gpm..."
EOF
  if [ "$XMOUSE" = "gpm" ] ; then
    if [ "$USBMOUSE_CHK" != "" ] ; then
      echo "  gpm -m $DEVPS2MOUSE -t ps2 -M -m $DEVUSBMOUSE -t ps2 -R raw"
    else
      echo "  gpm -m $DEVPS2MOUSE -t ps2 -R raw"
    fi
  else
    echo "  gpm -m $DEVMOUSE -t ps2"
  fi
  cat <<EOF
fi

EOF
  exit
fi

WIDEMODE=""

I=0
while [ ${MODES43[$I]} ] ; do
  if [ "$XSCREEN" = "${MODES43[$I]}" ] ; then
    MODENUM=$I
    WIDEMODE="False"
    break
  fi
  let I=I+1
done

I=0
while [ ${MODESWIDE[$I]} ] ; do
  if [ "$XSCREEN" = "${MODESWIDE[$I]}" ] ; then
    MODENUM=$I
    WIDEMODE="True"
    break
  fi
  let I=I+1
done

if [ "$WIDEMODE" = "" ] ; then
  # invaild mode!
  if [ "$XSCREEN" != "" ] ; then
    XSCREEN="$DEFAULT_XSCREEN"
  fi
  I=0
  while [ ${MODES43[$I]} ] ; do
    if [ "${MODES43[$I]}" = "$DEFAULT_XSCREEN" ] ; then
      MODENUM=$I
      WIDEMODE="False"
      break
    fi
    let I=I+1
  done
fi

#echo $WIDEMODE $MODENUM
#exit

# TMPFILE=`mktemp /tmp/tmp_xfplamoconfig_$$.XXXXXX`
TMPDRIVER=`mktemp /tmp/tmp_tmpdriver_$$.XXXXXX`

# if [ "$VENDOR" != "" ] ; then
#  if [ "$CARD_VENDOR" != "" ] ; then
#    $X11DIR/bin/getconfig -I $X11DIR/lib/X11/getconfig -v $VENDOR -d $DEVICE -r $REVISION 1> $TMPFILE 2>/dev/null
#  else
#    $X11DIR/bin/getconfig -I $X11DIR/lib/X11/getconfig -v $VENDOR -d $DEVICE -r $REVISION -s $CARD_VENDOR -b $CARD 1> $TMPFILE 2>/dev/null
#  fi
#fi

moved_flag=0
if [ -f /etc/X11/xorg.conf ]; then
    mv /etc/X11/xorg.conf /etc/X11/xorg.conf.orig
    moved_flag=1
fi
# /usr/X11R7/bin/Xorg -probeonly > /dev/null
# newdriver=`/usr/X11R7/bin/Xorg -probeonly 2>&1 | grep 'New driver' | cut -d' ' -f4 | sed -e 's/"//g'`
#newdriver=`grep Driver /var/log/Xorg.0.log | grep -v 'Driver:' | head -n1 | gawk '{print $2}' | sed 's/"//g'`
newdriver='vesa'
echo $newdriver > $TMPDRIVER
if [ $moved_flag = "1" ]; then
    mv /etc/X11/xorg.conf.orig /etc/X11/xorg.conf
fi


# 855GM �ʥޥ���� VBIOS �������������٤��֤��ʤ���åץȥåץޥ����Ѥ��к�
# See http://wiki.0-24.jp/?Linux%2FY2%A4%C7SXGA%2B
if [ "$CDPLAMO_CHK" != "" -a "$LCD_CHK" != "" -a "$NO855TEST" = "" ]; then
  # Intel Corp. 82852/855GM Integrated Graphics Device
  if [ "$VENDOR" = "0x8086" -a "$DEVICE" = "0x3582" ]; then
    if [ "$XSCREEN" = "" ]; then
      $0 --no855test > /etc/X11/XF86Config.test
      $X11DIR/bin/X -probeonly $CONFIGOPT /etc/X11/XF86Config.test 1> /dev/null 2> /dev/null
      LFP_RESOLUTION="`cat /var/log/XFree86.0.log | grep 'Size of device LFP (local flat panel) is' | sed -e 's/.*is //g' -e 's/ //g' | awk 'NR==1'`"
    else
      LFP_RESOLUTION="$XSCREEN"
    fi
    if [ "$LFP_RESOLUTION" != "" ]; then
      TMP855FILE=`mktemp /tmp/tmp855_xfplamoconfig_$$.XXXXXX`
      /usr/bin/855resolution -l | grep 'Mode ' > $TMP855FILE
      MODE_CHK="`cat $TMP855FILE | grep \" ${LFP_RESOLUTION},\"`"
      if [ "$MODE_CHK" = "" ]; then
        MODE_LIST="`cat $TMP855FILE | grep ' 800x600,' | awk '{print $2}'`"
        for i in $MODE_LIST ; do
          /usr/bin/855resolution $i `echo $LFP_RESOLUTION | tr 'x' ' '` 1> /dev/null
        done
      fi
      rm -f $TMP855FILE
    fi
  fi
fi

cat <<EOF
Section "ServerLayout"
        Identifier     "Layout0"
        Screen      0  "Screen0" 0 0
        InputDevice    "Keyboard0" "CoreKeyboard"
        InputDevice    "Mouse0" "CorePointer"
EOF
if [ "$XMOUSE" = "laptop+wheel" -o "$XMOUSE" = "laptop+ps2" ] ; then
  echo '        InputDevice    "Mouse1" "AlwaysCore"'
fi
cat <<EOF
EndSection

Section "Files"
	# FontPath     "unix/:7100"
        FontPath     "/usr/share/fonts/Bitmap/:unscaled"
        FontPath     "/usr/share/fonts/X11/misc/:unscaled"
        FontPath     "/usr/share/fonts/X11/100dpi/:unscaled"
        FontPath     "/usr/share/fonts/X11/75dpi/:unscaled"
        FontPath     "/usr/share/fonts/X11/cyrillic/:unscaled"

        FontPath     "/usr/share/fonts/X11/TTF/"
        FontPath     "/usr/share/fonts/X11/Type1/"
        FontPath     "/usr/share/fonts/freefont/"
        FontPath     "/usr/share/fonts/TrueType/"
        FontPath     "/usr/share/fonts/ghostscript/"

        FontPath     "/usr/share/fonts/Bitmap/"
        FontPath     "/usr/share/fonts/X11/misc/"
        FontPath     "/usr/share/fonts/X11/100dpi/"
        FontPath     "/usr/share/fonts/X11/75dpi/"
        FontPath     "/usr/share/fonts/X11/cyrillic/"

EndSection

Section "Module"
        Load  "extmod"
        Load  "glx"
        Load  "dbe"
        Load  "dri"
        Load  "dri2"
        Load  "record"
EndSection

EOF

if [ "$XKBMODEL" = "jp" ]; then
  echo 'Section "InputDevice"'
  echo '        Identifier  "Keyboard0"'
  echo '        Driver      "keyboard"'
  echo '        Option      "XkbModel" "jp106"'
  echo '        Option      "XkbLayout" "jp"'
  echo 'EndSection'
  echo ''
else
  echo 'Section "InputDevice"'
  echo '        Identifier  "Keyboard0"'
  echo '        Driver      "keyboard"'
  echo '        Option      "XkbModel" "pc101"'
  echo '        Option      "XkbLayout" "us"'
  echo 'EndSection'
  echo ''
fi

if [ "$XMOUSE" = "laptop+wheel" -o "$XMOUSE" = "laptop+ps2" ] ; then
  DEVMOUSE="$DEVPS2MOUSE"
fi

cat <<EOF
Section "InputDevice"
        Identifier  "Mouse0"
        Driver      "mouse"
EOF

if [ "$XMOUSE" = "gpm" ] ; then
  echo '        Option      "Protocol" "MouseSystems"'
  echo '        Option      "Device" "'${DEVMOUSE}'"'
  echo '        Option      "Emulate3Buttons"'
  echo '        #Option      "Emulate3Timeout" "50"'
elif [ "$XMOUSE" = "wheel" ] ; then
  echo '        Option      "Protocol" "IMPS/2"'
  echo '        Option      "Device" "'${DEVMOUSE}'"'
  echo '        #Option      "Emulate3Buttons"'
  echo '        #Option      "Emulate3Timeout" "50"'
  echo '        #Option      "Resolution" "256"'
  echo '        Option      "ZAxisMapping" "4 5"'
else
  echo '        Option      "Protocol" "PS/2"'
  echo '        Option      "Device" "'${DEVMOUSE}'"'
  echo '        Option      "Emulate3Buttons"'
  echo '        #Option      "Emulate3Timeout" "50"'
  echo '        #Option      "Resolution" "256"'
  echo '        #Option      "ZAxisMapping" "4 5"'
fi
cat <<EOF
EndSection

EOF

if [ "$XMOUSE" = "laptop+wheel" ] ; then
cat <<EOF
Section "InputDevice"
        Identifier  "Mouse1"
        Driver      "mouse"
        Option      "AlwaysCore"
        Option      "Protocol" "IMPS/2"
        Option      "Device" "$DEVUSBMOUSE"
        #Option      "Emulate3Buttons"
        #Option      "Emulate3Timeout" "50"
        #Option      "Resolution" "256"
        Option      "ZAxisMapping" "4 5"
EndSection

EOF
elif [ "$XMOUSE" = "laptop+ps2" ] ; then
cat <<EOF
Section "InputDevice"
        Identifier  "Mouse1"
        Driver      "mouse"
        Option      "AlwaysCore"
        Option      "Protocol" "PS/2"
        Option      "Device" "$DEVUSBMOUSE"
        Option      "Emulate3Buttons"
        #Option      "Emulate3Timeout" "50"
        #Option      "Resolution" "256"
        #Option      "ZAxisMapping" "4 5"
EndSection

EOF
fi

if [ "$LCD_CHK" != "" -a "$XSCREEN" = "" ]; then
# Laptop PC auto
  echo 'Section "Monitor"'
  echo '        Identifier   "Monitor0"'
  echo '        HorizSync    '"$HORIZRANGE"
  if [ "$XVREFRESH" = "" ] ; then
    LOW_HIGH=`echo $LCDXVREFRESH | awk '{printf("%.1f - %.1f\n",$1-0.9,$1+0.9)}'`
  else
    LOW_HIGH=`echo $XVREFRESH | awk '{printf("%.1f - %.1f\n",$1-0.9,$1+0.9)}'`
  fi
  echo "        VertRefresh  $LOW_HIGH"
  echo '        Option       "TargetRefresh" "'${LCDXVREFRESH}'"'
  echo 'EndSection'
  echo ''
else
# Desktop PC / Laptop PC manual
  if [ "$LCD_CHK" != "" ] ; then
    VERTRANGE=`echo $LCDXVREFRESH | awk '{printf("%.1f - %.1f\n",$1-0.9,$1+0.9)}'`
  fi
  echo 'Section "Monitor"'
  echo '        Identifier   "Monitor0"'
  echo '        HorizSync    '"$HORIZRANGE"
  if [ "$XVREFRESH" = "" ] ; then
    echo '        VertRefresh  '"$VERTRANGE"
  else
    LOW_HIGH=`echo $XVREFRESH | awk '{printf("%.1f - %.1f\n",$1-0.9,$1+0.9)}'`
    echo "        VertRefresh  $LOW_HIGH"
  fi
  if [ $WIDEMODE = "True" ] ; then
    echo '        # 1024x600 @ 60.06 Hz   TOSHIBA PORTAGE 300CT'
    echo '        Modeline "1024x600" 49.93 1024 1040 1216 1328 600 600 605 626'
    echo '        # 1280x600 @ 60.00 Hz   FUJITSU FMV BIBLO LOOX'
    echo '        Modeline "1280x600" 63.61 1280 1280 1384 1688 600 600 604 628 -HSync -VSync'
    echo '        # 1280x768 @ 60.00 Hz WXGA(GTF) FUJITSU Lifebook P5020D, SONY VAIO TR1MP, etc.'
    echo '        Modeline "1280x768" 80.14 1280 1344 1480 1680 768 769 772 795'
    echo '        # 1280x800 @ 60.00 Hz (GTF) hsync: 49.68 kHz'
    echo '        ModeLine "1280x800" 83.46 1280 1344 1480 1680 800 801 804 828'
    echo '        # 1680x1050 @ 60.00 Hz (GTF) hsync: 65.22 kHz'
    echo '        Modeline "1680x1050"  147.14  1680 1784 1968 2256  1050 1051 1054 1087'
    echo '        # 1920x1200 @ 60.00 Hz (GTF) hsync: 74.52 kHz'
    echo '        Modeline "1920x1200" 193.16 1920 2048 2256 2592 1200 1201 1204 1242'
  fi
  echo 'EndSection'
  echo ''
fi

echo 'Section "Device"'
echo '        Identifier  "Card0"'
if [ "$XMODULE" = "" ] ; then
  echo -n '        Driver      '
  echo -n '"'
  #GETCONF_MODULE="`cat $TMPFILE | awk 'NR==1{print $1}'`"
  GETCONF_MODULE="`cat $TMPDRIVER`"
  if [ "$GETCONF_MODULE" = "" ] ; then
    echo -n "$FALLBACK_XMODULE"
  else
    echo -n "$GETCONF_MODULE"
  fi
  echo '"'
  if [ "$XDEPTH" != "" ] ; then
    cat $TMPFILE | awk '2<=NR{print}' | grep -v "DefaultDepth"
    echo '        Option      "DefaultDepth" "'${XDEPTH}'"'
  else
    cat $TMPFILE | awk '2<=NR{print}'
  fi
else
  echo '        Driver      "'"${XMODULE}"'"'
  if [ "$XDEPTH" != "" ] ; then
    echo '        Option      "DefaultDepth" "'${XDEPTH}'"'
  fi
fi
echo 'EndSection'
echo ''

if [ "$LCD_CHK" != "" -a "$XSCREEN" = "" ]; then
# Laptop PC auto
  echo 'Section "Screen"'
  echo '        Identifier "Screen0"'
  echo '        Device     "Card0"'
  echo '        Monitor    "Monitor0"'
#  echo '        Option     "NoDoublescan" "True"'
#  echo '        Option     "NoInterlace" "True"'
  echo 'EndSection'
  echo ''
else
# Desktop PC / Laptop PC manual
  if [ $WIDEMODE = "True" ] ; then
    if [ "$XSCREEN" = "" ]; then
      MODES='"'"$DEFAULT_XSCREEN"'"'
    else
      MODES='"'"$XSCREEN"'"'
    fi
  else
    MODES=""
    I=0
    while (( $I <= $MODENUM )) ; do
      MODES='"'"${MODES43[$I]}"'"'" $MODES"
      let I=I+1
    done
  fi
  echo 'Section "Screen"'
  echo '        Identifier "Screen0"'
  echo '        Device     "Card0"'
  echo '        Monitor    "Monitor0"'
  echo '        Option     "NoDoublescan" "True"'
  echo '        Option     "NoInterlace" "True"'
  echo '        SubSection "Display"'
  echo '                Viewport   0 0'
  echo '                Depth     24'
  echo '                Modes    '"${MODES}"
  echo '        EndSubSection'
  echo '        SubSection "Display"'
  echo '                Viewport   0 0'
  echo '                Depth     16'
  echo '                Modes    '"${MODES}"
  echo '        EndSubSection'
  echo '        SubSection "Display"'
  echo '                Viewport   0 0'
  echo '                Depth     8'
  echo '                Modes    '"${MODES}"
  echo '        EndSubSection'
  echo 'EndSection'
  echo ''
fi

cat <<EOF
Section "DRI"
        Mode 0666
EndSection

Section "ServerFlags"
 Option "AutoAddDevices" "false"
EndSection

EOF

 rm -f $TMPFILE $TMPDRIVER

