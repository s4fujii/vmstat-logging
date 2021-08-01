#!/bin/bash
# ---------------------------------------------------------------------------
# install-vmstat-logging.sh
#
# Copyright (c) 2021 Satoshi Fujii
#
# This software is released under the MIT license.
# See https://opensource.org/licenses/MIT .
# ---------------------------------------------------------------------------

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
INSTALL_DIR=${INSTALL_DIR:-/opt/vmstat-logging}

function root-check {
    if [ "$(id -u)" -ne 0 ]; then
        echo "error: please run as root"
        return 1
    fi
    return 0
}

function check-files {
    FILES=(vmstat-logging.sh ctl-vmstat-logging.sh logrotate.conf config)
    RET=0
    for f in ${FILES[*]}; do
        [ ! -r $SCRIPT_DIR/$f ] && echo "error: $SCRIPT_DIR/$f not found." && RET=1
    done
    return $RET
}

function check-installed {
    [ ! -r $INSTALL_DIR/vmstat-logging.sh ] && return 1
    return 0
}

function ask-proceed {
    echo "This script is going to $1 vmstat-logging."
    echo "  Target directory = $INSTALL_DIR"
    read -p 'Is it okay (y/n) ' ANS
    [ "$ANS" = y -o "$ANS" = Y -o "$ANS" = yes -o "$ANS" = YES ] && return 0
    echo "Aborted by user"
    return 1
}

function do-install {
    check-files
    if [ "$?" -ne 0 ]; then return 1; fi
    if check-installed; then
        echo "error: it seems vmstat-logging is already installed."
        return 3
    fi
    ask-proceed install || return 2
    mkdir -p $INSTALL_DIR
    install -m 755 $SCRIPT_DIR/vmstat-logging.sh $INSTALL_DIR/vmstat-logging.sh
    install -m 755 $SCRIPT_DIR/ctl-vmstat-logging.sh $INSTALL_DIR/ctl-vmstat-logging.sh
    ln -s $INSTALL_DIR/ctl-vmstat-logging.sh /usr/local/sbin/ctl-vmstat-logging
    install -m 644 $SCRIPT_DIR/config $INSTALL_DIR/config
    if [ -d /etc/logrotate.d ]; then
        install -m 644 $SCRIPT_DIR/logrotate.conf /etc/logrotate.d/vmstat-logging
    else
        echo "warning: logrotate config dir not found. logrotation disabled."
    fi
    (crontab -l 2>/dev/null; echo "@reboot /usr/local/sbin/ctl-vmstat-logging start >/dev/null 2>&1") | crontab -
    /usr/local/sbin/ctl-vmstat-logging start
    echo "Installation completed."
    return 0
}

function do-uninstall {
    if ! check-installed; then
        echo "error: it seems vmstat-logging is NOT installed."
        return 4
    fi
    ask-proceed uninstall || return 2
    crontab -l 2>/dev/null | sed -e '/ctl-vmstat-logging/d' | crontab -
    /usr/local/sbin/ctl-vmstat-logging stop
    rm -f $INSTALL_DIR/vmstat-logging.sh $INSTALL_DIR/ctl-vmstat-logging.sh $INSTALL_DIR/config
    # do not use 'rm -rf' to prevent delete user-created files under $INSTALL_DIR
    rmdir $INSTALL_DIR
    rm -f /usr/local/sbin/ctl-vmstat-logging
    rm -f /etc/logrotate.d/vmstat-logging
    echo "Uninstallation completed."
    return 0
}

function show-usage {
    echo "usage: $0 { install | uninstall }"
    return 127
}

case $1 in
    install)
        root-check && do-install
        ;;
    uninstall)
        root-check && do-uninstall
        ;;
    *)
        show-usage
        ;;
esac

exit $?
