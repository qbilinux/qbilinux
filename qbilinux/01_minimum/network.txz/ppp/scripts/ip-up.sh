#!/bin/sh
#
# ip-up: Hook on interface up
#

DEVICE="$1"
CONFIG="$6"

PPP_RESOLV=/etc/ppp/resolv/$CONFIG
RESOLV=/etc/resolv.conf

if [ -s "$PPP_RESOLV" ] || [ -n "$USEPEERDNS" -a -n "$DNS1$DNS2" ]; then
  echo "# $DEVICE:PPP begin" > $RESOLV.N
  chmod 644 $RESOLV.N
  if [ -n "$USEPEERDNS" ]; then
    for s in $DNS1 $DNS2; do
      echo "nameserver $s" >> $RESOLV.N
    done
  else
    grep '^nameserver ' $PPP_RESOLV >> $RESOLV.N
  fi
  echo "# $DEVICE:PPP end" >> $RESOLV.N
  sed -e "/# $DEVICE:PPP begin/,/# $DEVICE:PPP end/d" $RESOLV >> $RESOLV.N
  echo "# $DEVICE:PPP begin" >> $RESOLV.N
  grep '^search ' $PPP_RESOLV >> $RESOLV.N
  echo "# $DEVICE:PPP end" >> $RESOLV.N
else
  sed -e "/# $DEVICE:PPP begin/,/# $DEVICE:PPP end/d" $RESOLV > $RESOLV.N
fi
mv $RESOLV.N $RESOLV

if [ -x /sbin/planetplugin ]; then
  /sbin/planetplugin "$DEVICE" "$CONFIG" up
fi
