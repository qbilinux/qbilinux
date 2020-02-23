#!/bin/sh
#
# ip-down: Hook on interface down
#

DEVICE="$1"
CONFIG="$6"

RESOLV=/etc/resolv.conf

if [ -x /sbin/planetplugin ]; then
  /sbin/planetplugin "$DEVICE" "$CONFIG" down
fi

sed -e "/# $DEVICE:PPP begin/,/# $DEVICE:PPP end/d" $RESOLV > $RESOLV.N
chmod 644 $RESOLV.N
mv $RESOLV.N $RESOLV
