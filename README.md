Shared wifi download quotas
===========================

Implements download quotas per mac address on a Linux router.  
At the moment it focuses on [OpenWrt](http://openwrt.org) but shouldn't be hard to make it work on other distributions.

### Scenario

You have a linux router on shared wifi with many guests,
your internet connection's monthly allowance is getting eaten up fast,
you need to limit downloads somehow. 

Usual solution is to use a captive portal: guests need to authenticate and you can setup download quotas.  
Heavy and not so user friendly. You'll probably need extra hardware to run the portal.

How about this instead: keep wifi open but
1. Limit each guest download speed to 100k/s max.
2. Each guest starts with 150 Mb download quota.
3. Once overquota download speed is throttled to 50k/s.

This is what this project does:  
- 1 is straightforward with netfilter, we create one tc class per ip.  
- For 2 and 3 we need **download quotas per mac address**,
which is possible with ipset and some bookkeeping:  
  ipset + iptables gives us download quotas by ip, 
we just need to keep track of mac-ip pairs (track_mac_usage, which runs every minute)

For tc / iptables rules details see this SE [question](https://unix.stackexchange.com/a/375705) and
[enable_quotas](https://github.com/lemonsqueeze/WifiDownloadQuotas/blob/master/src/usr/share/download_quotas/enable_quotas) source.

------------------------------------------------------------------------------------

### Installation


What you need:  
- Wifi router supported by OpenWrt (8Mb flash better)
- Ipset support (tested with Chaos Calmer 15.05 but any release should do)

Installation:
- Flash OpenWrt firmware, configure router
- clone repository, build package:

        make

- send package to the router:

        scp download-quotas_0.1.1.ipk root@192.168.1.1:/tmp/

- Login through ssh and install package:

        cd /tmp
        opkg update
        opkg install download-quotas_0.1.1.ipk

- Edit `/etc/download_quotas.conf`, set limits and lan ip address range (should include your dhcp range, preferrably the whole local network)

- reboot


Notes:

If you have 4Mb flash you'll most likely run out of space with the default package, the dependencies are too big.  
You probably have enough for a selfcontained build though:  

- Edit Makefile and set `ARCH` `TARGET` and `RELEASE` for your router.  
  Values can be found in `/etc/openwrt_release`.  
  For `ARCH` try `opkg info busybox | grep Architecture`

- instead of `make` type

        make selfcontained

- scp and install self-contained package instead (`download-quotas_0.1.1_ramips_24kec.ipk` for example)


------------------------------------------------------------------------------------

### Usage

    /etc/init.d/download-quotas start    Enable limits and quotas and load saved usage
    /etc/init.d/download-quotas stop     Disable limits and quotas and save current usage
    /etc/init.d/download-quotas save     Backup current usage to /root/.download_quotas
    /etc/init.d/download-quotas load     Restore saved usage
    /etc/init.d/download-quotas reset    Clear everyone's quotas
    /etc/init.d/download-quotas list     Show current usage  

By default quotas start automatically on boot, are saved every 30 mins and reset once a month (see crontab)


------------------------------------------------------------------------------------

### Notes

At the moment it's not possible to use OpenWrt's firewall and download-quotas at the same time:
download-quotas will wipe firewall rules when it starts and vice-versa.
Currently firewall service is disabled when installing download-quotas.
If you have have custom rules or create some through web interface they will not take effect.

This is by no means absolutely secure, however with a typical group of non-hostile guests it works pretty well:  

- Mac addresses can be changed, if a guest does so he'll get a brand new quota.  
- Limits only kick in for ip range specified in `enable_quota`. If you left addresses out
  a guest can bypass limits by using one of these ips (could be a feature too if you need
  priviledged users. A better way would be to add special rules for them)  
- The mac/ip tracking logic runs every minute so when a pairing changes there's a window of
  at most 1 minute where a guest could be running on someone else's quota. Pairing changes are
  rare enough and in the worst case, at 100k/s the potential for abuse is small enough that
  it doesn't matter here.


[Gargoyle](https://www.gargoyle-router.com/) can do download quotas,
  interface is very nice and users can see their quota usage on the front page.
  On the version i checked though (1.4.7, old ...) quotas are per ip, 
  if user changes ip address quota is lost...

![Gargoyle quotas](http://www.ai.net.nz/images/gargoyle/screen04.png)


