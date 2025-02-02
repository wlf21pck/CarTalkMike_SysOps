#!/bin/bash
#
# Init file for Monit system monitor
# Written by Stewart Adam <s.adam@diffingo.com>
# based on script by Dag Wieers <dag@wieers.com>.
#
# chkconfig: - 98 02
# description: Utility for monitoring services on a Unix system
#
# processname: monit
# config: /etc/monit.conf
# pidfile: /var/run/monit.pid
# Short-Description: Monit is a system monitor

# Source function library.
. /etc/init.d/functions

### Default variables
BIN="/usr/bin/monit"
CONFIG="/etc/monit.conf"
pidfile="/var/run/monit.pid"
prog="monit"

# Check if requirements are met
[ -x "$BIN" ] || exit 1
[ -r "$CONFIG" ] || exit 1

RETVAL=0

start() {
	echo -n $"Starting $prog: "
	daemon "$prog > /dev/null"
	RETVAL=$?
	echo
	[ $RETVAL -eq 0 ] && touch /var/lock/subsys/$prog
	return $RETVAL
}

stop() {
	echo -n $"Shutting down $prog: "
	killproc -p ${pidfile}
	RETVAL=$?
	echo
	[ $RETVAL -eq 0 ] && rm -f /var/lock/subsys/$prog
	return $RETVAL
}

restart() {
	stop
	start
}

reload() {
	echo -n $"Reloading $prog: "
	monit -c "$CONFIG" reload
	RETVAL=$?
	echo
	return $RETVAL
}

case "$1" in
  start)
	start
	;;
  stop)
	stop
	;;
  restart)
	restart
	;;
  reload)
	reload
	;;
  condrestart)
	[ -e /var/lock/subsys/$prog ] && restart
	RETVAL=$?
	;;
  status)
	status $prog
	RETVAL=$?
	;;
  *)
	echo $"Usage: $0 {start|stop|restart|reload|condrestart|status}"
	RETVAL=1
esac

exit $RETVAL
