#!/bin/sh
#
# pon: Start ppp connection
#

usage () {
	cat <<-EOF
		usage: pon [-i|-ix|config] [pppdopts]

		  -i        select setting with tty menu
		  -ix       select setting with X menu
		  config    setting name of target connection
		  (none)    use "default" setting

		  pppdopts  options list for pppd
	EOF

	exit 0
}

CONFIG=
INTERACTIVE=

case "$1" in
-i)
	INTERACTIVE="tty"
	;;
-ix)
	if [ -n "$DISPLAY" ]; then
		INTERACTIVE="x"
	else
		INTERACTIVE="tty"
	fi
	;;
-*)
	usage
	;;
*)
	CONFIG="${1:-default}"
	;;
esac
shift

case "$INTERACTIVE" in
tty)
	CONFIG=`/usr/bin/pppselect` || exit 0
	;;
x)
	CONFIG=`/usr/bin/xpppselect` || exit 0
	;;
esac

if [ ! -r "/etc/ppp/peers/$CONFIG" ]; then
	echo "pon: setting \"$CONFIG\" not found."
	exit 1
fi

exec /usr/sbin/pppd call "$CONFIG" "$@"

# Local Variables:
# tab-width: 2
# sh-indentation: 2
# End:
