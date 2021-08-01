#!/bin/bash
# ---------------------------------------------------------------------------
# vmstat-logging.sh
#
# Copyright (c) 2021 Satoshi Fujii
#
# This software is released under the MIT license.
# See https://opensource.org/licenses/MIT .
# ---------------------------------------------------------------------------

# SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
SCRIPT_DIR=/opt/vmstat-logging

function read-config {
  INTERVAL=$(grep INTERVAL $SCRIPT_DIR/config 2>/dev/null | head -n1 | awk '{print $2}')
  INTERVAL=${INTERVAL:-15}

  LOGFILE=$(grep LOGFILE $SCRIPT_DIR/config 2>/dev/null | head -n1 | awk '{print $2}')
  LOGFILE=${LOGFILE:-vmstat.log}

  PIDFILE=$(grep PIDFILE $SCRIPT_DIR/config 2>/dev/null | head -n1 | awk '{print $2}')
  PIDFILE=${PIDFILE:-vmstat-logging.pid}
}

function dateecho {
  echo "$(date --iso=s) $*"
}

function quit {
  dateecho "SIGTERM received."
  kill $PID
  dateecho "PID $PID killed."
  rm -f $PIDFILE
  dateecho "exiting"
  exit 0
}

trap quit TERM
dateecho "-"
dateecho "vmstat-logging started."

while true; do
  read-config
  dateecho "config: INTERVAL=${INTERVAL}"
  dateecho "config: LOGFILE=${LOGFILE}"
  dateecho "config: PIDFILE=${PIDFILE}"
  vmstat -w -t -n $INTERVAL >> $LOGFILE 2>&1 &
  PID=$!
  echo "$PID" > $PIDFILE
  dateecho "Started vmstat (PID=$PID)"
  wait $PID
  dateecho "PID $PID terminated"
  rm -f $PIDFILE
  sleep 5
  dateecho "Restarting ..."
done
