# vmstat-logging

This script set up logging vmstat for long-span recording cpu, memory, i/o statistics.

* Easy to setup, just run the installer script.
* Running in the background like a daemon, even if you logged out from shell.
* Automatically start up after machine rebooted.
* Configurable logging interval. Can apply config by controller script.
* Log rotation enabled.

## Requirements
The following softwares must be installed before running vmstat-logging.
* vmstat
* logrotate

Tested environment:
* Ubuntu 18.04 LTS

## Installation
```
git clone https://github.com/s4fujii/vmstat-logging.git
cd vmstat-logging

sudo ./install-vmstat-logging.sh install
```
Files will be copied into `/opt/vmstat-logging` directory.

## Files
* `/var/log/vmstat.log` -- Output of vmstat.
  * Log rotation enabled by logrotate service. Controlled by `/etc/logrotate.d/vmstat-logging` .
* `/var/log/vmstat-logging.log` -- Service daemon output (for debug usage)
* `/opt/vmstat-logging/config` -- Configuration file

## Customization
To customize log-rotation, edit `/etc/logrotate.d/vmstat-logging` .

To change logging interval, edit `/opt/vmstat-logging/config` file and modify `INTERVAL` value (unit: second).
For example, to record stats every 5 seconds:
```
INTERVAL 5
```

## Operation

| Operation                              | Command to execute               |
| -------------------------------------- | -------------------------------- |
| Stop vmstat-logging service            | `sudo ctl-vmstat-logging stop`   |
| Start vmstat-logging service           | `sudo ctl-vmstat-logging start`  |
| Reload /opt/vmstat-logging/config file | `sudo ctl-vmstat-logging reload` |
| Show the service status                | `sudo ctl-vmstat-logging status` |

Note that the service automatically resumes after the machine has been rebooted. (Controlled by cron)

## Uninstall
```
cd vmstat-logging
sudo ./install-vmstat-logging.sh uninstall
```

## License
This software is released under the MIT license.
See https://opensource.org/licenses/MIT .
