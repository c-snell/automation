If timedatectl is not reporting, “System clock synchronized: no”. 

```
[root@workstation ~]# timedatectl
               Local time: Wed 2021-04-14 11:10:55 MDT
           Universal time: Wed 2021-04-14 17:10:55 UTC
                 RTC time: Wed 2021-04-14 17:10:55
                Time zone: America/Boise (MDT, -0600)
System clock synchronized: no
              NTP service: inactive
          RTC in local TZ: no
```

Verify that NTP is configured correctly. By default, Ubuntu 18.04 & 20.04, CentOS 8, and RHEL 8 use chrony for the NTP service and chrony will sync with timedatectl.

If chrony is not installed, install it using: 

```
sudo apt install chrony -y (Ubuntu)
sudo dnf install chrony -y (CentOS,RHEL)
```

Check activity

```
[root@workstation ~]# chronyc activity
506 Cannot talk to daemon
```

Start the NTP service

```
[root@workstation ~]# systemctl start chronyd.service && systemctl enable chronyd.service

At this point you should see timedatectl reporting the NTP service active.
[root@workstation ~]# timedatectl
               Local time: Wed 2021-04-14 11:12:55 MDT
           Universal time: Wed 2021-04-14 17:12:55 UTC
                 RTC time: Wed 2021-04-14 17:12:55
                Time zone: America/Boise (MDT, -0600)
System clock synchronized: no
              NTP service: active
          RTC in local TZ: no
```

Next configure chrony. Edit `/etc/chrony.conf` and add your NTP server of choice. Disable the default NTP pool by commenting out the line. 

```
[root@workstation ~]# vi /etc/chrony.conf
# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
# pool 2.centos.pool.ntp.org iburst (CentOS)
# pool 2.rhel.pool.ntp.org iburst (RHEL)
# pool 0.ubuntu.pool.ntp.org iburst (Ubuntu)
server ntp.example.com iburst
```

Save and exit.

NOTE:
If you are behind a corporate proxy, it is best to use an internal NTP server rather than using a publicly hosted NTP server pool. Public pool IPs can change and get caught in your proxy causing the NTP service to fail to synchronize. Also make sure to add your NTP server to your NOPROXY list.

Upon saving `/etc/chrony.conf`, if the NTP service is able to talk to the NTP server successfully, NTP should sync immediately without a restart of the service and timedatectl should report "System clock synchronized: yes".

```
[root@workstation ~]# timedatectl
               Local time: Wed 2021-04-14 11:33:54 MDT
           Universal time: Wed 2021-04-14 17:33:54 UTC
                 RTC time: Wed 2021-04-14 17:33:54
                Time zone: America/Boise (MDT, -0600)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no
```

To restart chrony:

```
systemctl restart chronyd.service
```
