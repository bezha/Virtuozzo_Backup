Backup OpenVZ (Virtuozzo) VPS

https://wiki.openvz.org/Releases

- [x] yum install cstream perl-LockFile-Simple.noarch
- [x] rpm -Uvh https://download.openvz.org/contrib/utils/vzdump/vzdump-1.2-4.noarch.rpm

For --snapshot working should be:

- [x] Free space with pvs -a
  -  umount /vz
  -  lvresize --resizefs --size -1G /dev/mapper/openvz-vz
  -  mount -a
&nbsp;  
- [x] Patch vzdump.pm https://wiki.openvz.org/Backup_of_a_running_container_with_vzdump

When trying to backup a virtual machine, creation of the snapshot can fail. 
This is because of a bug in VZDump.pm. 
In CentOS (and other RHEL derivatives), this file is located in /usr/share/perl5/PVE/VZDump.pm.
  
On line 622, you will find the following:

if ($line =~ m|^\s*(\S+):(\S+):(\d+(\.\d+))M$|) {

Replace this with:

if ($line =~ m|^\s*(\S+):(\S+):(\d+([\.,]\d+))[mM]$|) {

Save and close the file. Snapshots will now work with vzdump
&nbsp;
- [x] Set up Cron job: 15 00 * * * /root/backup.sh > /dev/null 2>&1