#!/bin/bash

# lock dirs/files
LOCKDIR="/tmp/runbackup-lock"
PIDFILE="${LOCKDIR}/PID"

# exit codes and text for them - additional features nobody needs :-)
ENO_SUCCESS=0; ETXT[0]="ENO_SUCCESS"
ENO_GENERAL=1; ETXT[1]="ENO_GENERAL"
ENO_LOCKFAIL=2; ETXT[2]="ENO_LOCKFAIL"
ENO_RECVSIG=3; ETXT[3]="ENO_RECVSIG"

###
### start locking attempt
###

trap 'ECODE=$?; echo "[runbackup] Exit: ${ETXT[ECODE]}($ECODE)" >&2' 0
echo -n "[runbackup] Locking: " >&2

if mkdir "${LOCKDIR}" &>/dev/null; then

    # lock succeeded, install signal handlers before storing the PID just in case
    # storing the PID fails
    trap 'ECODE=$?;
          echo "[runbackup] Removing lock. Exit: ${ETXT[ECODE]}($ECODE)" >&2
          rm -rf "${LOCKDIR}"' 0
    echo "$$" >"${PIDFILE}"
    # the following handler will exit the script on receiving these signals
    # the trap on "0" (EXIT) from above will be triggered by this trap's "exit" command!
    trap 'echo "[runbackup] Killed by a signal." >&2
          exit ${ENO_RECVSIG}' 1 2 3 15
    echo "success, installed signal handlers"

# Remove Backup after 7 days
rm -rf /backup/`date +%Y%m%d -d "7 day ago"`

# Create folder with current day for Backup
mkdir -p /backup/`date "+%Y%m%d"`

# Creating backup for running VPS with --snapshot without suspend
# For --snapshot working should be:
# 1. Free space with pvs -a
# umount /vz
# lvresize --resizefs --size -1G /dev/mapper/openvz-vz
# mount -a
# 2. Patch Vzdump.pm link: https://wiki.openvz.org/Backup_of_a_running_container_with_vzdump
# Fixing VZDump.pm
# When trying to backup a virtual machine, creation of the snapshot can fail. This is because of a bug in VZDump.pm. In CentOS (and other RHEL derivatives), this file is located in /usr/share/perl5/PVE/VZDump.pm.
# On line 622, you will find the following:
# if ($line =~ m|^\s*(\S+):(\S+):(\d+(\.\d+))M$|) {
# Replace this with:
# if ($line =~ m|^\s*(\S+):(\S+):(\d+([\.,]\d+))[mM]$|) {
# Save and close the file. Snapshots will now work with vzdump

for VE in `/usr/sbin/vzlist -H -o veid`
do
/usr/sbin/vzdump --snapshot --compress --stdexcludes --bwlimit 1024000 $VE --mailto bezhav@gmail.com --dumpdir /backup/`date "+%Y%m%d"`/
done

else

    # lock failed, now check if the other PID is alive
    OTHERPID="$(cat "${PIDFILE}")"

    # if cat wasn't able to read the file anymore, another instance probably is
    # about to remove the lock -- exit, we're *still* locked
    #  Thanks to Grzegorz Wierzowiecki for pointing this race condition out on
    #  http://wiki.grzegorz.wierzowiecki.pl/code:mutex-in-bash
    if [ $? != 0 ]; then
      echo "lock failed, PID ${OTHERPID} is active" >&2
      exit ${ENO_LOCKFAIL}
    fi

    if ! kill -0 $OTHERPID &>/dev/null; then
        # lock is stale, remove it and restart
        echo "removing stale lock of nonexistant PID ${OTHERPID}" >&2
        rm -rf "${LOCKDIR}"
        echo "[runbackup] restarting myself" >&2
        exec "$0" "$@"
    else
        # lock is valid and OTHERPID is active - exit, we're locked!
        echo "lock failed, PID ${OTHERPID} is active" >&2
        exit ${ENO_LOCKFAIL}
    fi

fi