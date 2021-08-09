#!/bin/sh

yum install -y chrony
  
rm -f /etc/localtime
ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
 
mkdir -p /var/lib/chrony
echo > /var/lib/chrony/driftfile
 
cat <<ENDFILE >/etc/chrony.conf
server ntp.softwaregrp.net iburst
driftfile /var/lib/chrony/driftfile
stratumweight 0
rtcsync
makestep 0.1 3
ENDFILE
  
systemctl enable chronyd
systemctl start chronyd
  
chronyc -a makestep
  
systemctl restart chronyd
  
hwclock -w
  
timedatectl


