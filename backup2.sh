#!/bin/bash
echo "[ Disk Space Information ]"
df -h | grep backup;
echo
echo "[ Expected Number of VPS ]"
/usr/sbin/vzlist -a | grep run | wc -l
echo
echo "[ A count of VPS ]"
du -sh /backup/`date "+%Y%m%d"`/* | grep tgz | wc -l
echo
echo "[ VPS Backup Folder ]"
du -sh /backup/*