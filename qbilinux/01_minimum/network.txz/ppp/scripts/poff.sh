#!/bin/sh
#
# poff: Shut down ppp connection
#

usage () {
	cat <<-EOF
		usage: poff [-r|-d|-c] [config]
		       poff -a

		  -r        redial
		  -d        toggle debug option
		  -c        renegotiate compression
		  -a        shut down all connections
		  (none)    shut down

		  config    setting name of target connection
		  (none)    operate only one existing connection
	EOF

	exit 0
}

SIGNALS="TERM KILL"
MODE="any"

case "$1" in
-r)
	SIGNALS="HUP"
	;;
-d)
	SIGNALS="USR1"
	;;
-c)
	SIGNALS="USR2"
	;;
-a)
	MODE="all"
	;;
-*)
	usage
	;;
esac
shift

if [ -n "$1" ]; then
	case "$1" in
	-*)
		usage
		;;
	*)
		if [ "$MODE" = "all" ]; then
			usage
		fi
		MODE=
		CONFIG=$1
		;;
	esac
fi

PIDS="`pidof pppd`"

if [ -z "$PIDS" ]; then
	echo "poff: no ppp connections found."
	exit 1
else
	case "$PIDS" in
	*\ *)
		MULTI="yes"
		;;
	*)
		MULTI=
		;;
	esac
fi

if [ "$MODE" = "any" -a -n "$MULTI" ]; then
	echo "poff: cannot decide which ppp connection to operate."
	exit 1
fi

if [ -n "$CONFIG" ]; then
	PIDS=`ps w $PIDS | grep " call $CONFIG *\$" | awk '{ print $1 }'`
	if [ -z "$PIDS" ]; then
		echo "poff: no ppp connection with setting name \"$CONFIG\"."
		exit 1
	fi
fi

(
	for s in $SIGNALS; do
		kill -$s $PIDS > /dev/null 2>&1 || break
		sleep 10
	done
) &

while ps $PIDS > /dev/null 2>&1; do
	sleep 1
done

# Local Variables:
# tab-width: 2
# sh-indentation: 2
# End:
