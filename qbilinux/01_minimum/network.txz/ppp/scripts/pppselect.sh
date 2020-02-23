#!/bin/sh

# Select connection

PPPDIR="/etc/ppp"
CONFDIR="$PPPDIR/peers"
DEFNAME="default"
DEFCOMM="標準の接続"

ERRTITLE="ERROR"
ERRMSG="PPP がインストールされていません。"
SELTITLE="PPP 接続"
SELMSG="接続を選択してください。"

read_config () {
	CONFIG="$1"
	COMMENT=
	HIDDEN="Off"

	eval `sed -e "/^#:/!d" -e "s/^#://" < $PPPDIR/peers/$CONFIG`
}

if [ ! -d "$PPPDIR" ]; then
	dialog --title "$ERRTITLE" --msgbox "\n$ERRMSG\n" 7 70
	exit 1
fi

ARGS=()
for f in $CONFDIR/*; do
	if [ -f "$f" ]; then
		CONFIG="${f##*/}"
		read_config "$CONFIG"
		if [ "$HIDDEN" != "On" ]; then
			case "$CONFIG" in
			*~|*.orig|*.bak)
				;;
			"$DEFNAME")
				if [ -n "$COMMENT" ]; then
					COMMENT="$COMMENT ($DEFCOMM)"
				else
					COMMENT="$DEFCOMM"
				fi
				ARGS=("default" "$COMMENT" "${ARGS[@]}")
				;;
			*)
				ARGS[${#ARGS[@]}]="$CONFIG"
				ARGS[${#ARGS[@]}]="$COMMENT"
				;;
			esac
		fi
	fi
done
if [ ${#ARGS[@]} -eq 0 ]; then
	exit 0
fi

ENTRIES=`expr ${#ARGS[@]} / 2`
if [ $ENTRIES -eq 1 ]; then
	echo "${ARGS[0]}"
	exit 0
fi
if [ $ENTRIES -gt 16 ]; then
	ENTRIES=16
fi
SELECT=$(dialog --title "$SELTITLE" --menu "\n$SELMSG\n" \
	`expr $ENTRIES + 9` 72 `expr $ENTRIES` "${ARGS[@]}" 3>&1 1>&2 2>&3) || exit

echo "$SELECT"

# Local Variables:
# tab-width: 2
# sh-indentation: 2
# End:
