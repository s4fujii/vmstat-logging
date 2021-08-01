#!/bin/bash
# ---------------------------------------------------------------------------
# ctl-vmstat-logging.sh
#
# Copyright (c) 2021 Satoshi Fujii
#
# This software is released under the MIT license.
# See https://opensource.org/licenses/MIT .
# ---------------------------------------------------------------------------

# SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
SCRIPT_DIR=/opt/vmstat-logging
SCRIPT="$SCRIPT_DIR/vmstat-logging.sh"
PIDFILE="/var/run/vmstat-logging.pid"
LOGFILE="/var/log/vmstat-logging.log"

if [ ! -x $SCRIPT ]; then
    echo "error: script file $SCRIPT not found or not executable."
    exit 1
fi

if ! hash vmstat >/dev/null 2>&1; then
    echo "error: vmstat not found."
    exit 2
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "error: please run as root"
    exit 3
fi

if [ ! -w "$(dirname $PIDFILE)" ]; then
    echo "error: PID file $PIDFILE is not writable"
    exit 6
fi

function start-logging {
    # Check if already running
    STATUS=$(status-logging | awk '{print $1}')
    if [ "$STATUS" = Running ]; then
        PID=$(cat $PIDFILE)
        echo "error: vmstat-logging is already running. (PID=$PID)"
        return 4
    fi
    # Start the script in the background
    nohup bash $SCRIPT >> "$LOGFILE" 2>&1 </dev/null &
    PID=$!
    # Create PID file
    echo $PID > $PIDFILE
    echo "vmstat-logging started. PID=$PID"
    return 0
}

function stop-logging {
    # Check if running
    STATUS=$(status-logging | awk '{print $1}')
    if [ "$STATUS" = Running ]; then
        # Send SIGTERM to the process
        PID=$(cat $PIDFILE)
        kill -TERM $PID
        echo "PID $PID terminated."
        # Clean up PID file
        rm -f $PIDFILE
        return 0
    else
        echo "error: not running."
        return 5
    fi
}

function status-logging {
    if [ -r "$PIDFILE" ]; then
        PID=$(cat $PIDFILE)
        if [ ! -r /proc/$PID/cmdline ]; then
            echo "Stopped (PID=$PID does not exist)"
            return 0
        fi
        CMDNAME=$(basename $(cut -d '' -f2 /proc/$PID/cmdline) )
        if [ "$CMDNAME" = vmstat-logging.sh ]; then
            echo "Running (PID=$PID)"
            return 0
        else
            echo "Stopped (PID=$PID exists but it is not vmstat-logging)"
            return 0
        fi
    else
        echo "Stopped (No pid file)"
        return 0
    fi
}

function reload-config {
    # Check if running
    STATUS=$(status-logging | awk '{print $1}')
    if [ "$STATUS" != Running ]; then
        echo "error: not running."
        return 5
    fi
    # Get vmstat's PID file path from config
    PIDFILE_V=$(grep PIDFILE $SCRIPT_DIR/config 2>/dev/null | head -n1 | awk '{print $2}')
    PIDFILE_V=${PIDFILE_V:-vmstat-logging.pid}
    PID_V=$(cat $PIDFILE_V 2>/dev/null)
    if [ -z "$PID_V" ]; then
        echo "error: vmstat PID not found"
        return 7
    fi
    echo "killing vmstat PID=$PID_V to trigger config reload"
    kill -TERM $PID_V
}

function show-usage {
    echo "usage: $0 { start | stop | status | reload }"
}

case $1 in
    start)
        start-logging
        ;;
    stop)
        stop-logging
        ;;
    status)
        status-logging
        ;;
    reload)
        reload-config
        ;;
    *)
        show-usage
        exit 127
        ;;
esac

exit $?
