#!/bin/sh
# SeTpartition user-friendly rewrite Fri Dec 15 13:17:40 CST 1995 pjv
crunch () { # remove extra whitespace
 read STRING;
 echo $STRING
}
T_PX=/mnt
if [ ! -r /tmp/SeTplist ]; then
 # Give warning?
  exit
fi
  dialog --title "�ϡ��ɥǥ������Υ��������" --infobox \
"Plamo ���åȥ��åפ�Linux�ѡ��ƥ�������õ������� \n\
�ϡ��ɥǥ������򥹥������Ǥ����������Ԥ�����������" 6 60

