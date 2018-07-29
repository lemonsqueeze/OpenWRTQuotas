Open wifi download quotas
=========================

Implements download quotas per mac address on a Linux router.  
At the moment it focuses on [OpenWrt](http://openwrt.org) but shouldn't be hard to adapt to other distributions.

### Scenario

You have a linux router on an open wifi network with many guests,
your internet connection's monthly allowance is getting eaten up fast
(or some users are taking a disproportionate amount of resources),
and you need to limit downloads somehow. 

Usual solution is to setup a captive portal: guests will need to authenticate and you can have download quotas.  
Heavy and not so user friendly. You'll probably need extra hardware to run the portal.

How about this instead: keep wifi open but
1. Limit each guest to say, 50k/s max.
2. Each guest starts with 100 Mb download quota.
3. Once overquota download speed is throttled to 10k/s.

This way kids going on youtube can't eat up all the bandwidth, network remains
open, and in the worst case if someone goes overquota he can still check email etc.
You can also adapt to circumstances by tweaking the limits : Expecting huge number of guests ?
Lower speed and quota. Lots of bandwidth remaining ? Relax the rules etc.

------------------------------------------------------------------------------------

### Installation

You need:  
- Router supported by [OpenWrt](http://openwrt.org) (8Mb flash better)
  I'm using a TP-Link TL-WR810N here: small, costs $30 and works like a charm.
- Ipset support (tested with OpenWRT Chaos Calmer 15.05 and Designated Driver 16.xx,
  but other releases should do).

If you have 4Mb flash only you **need** a custom build, skip below.

**Setup:**
- Flash OpenWrt firmware and configure router.
  New to openwrt ? Check out [openwrt wiki](https://wiki.openwrt.org/) and 
 [openwrt docs](https://openwrt.org/docs). Go to the [downloads](https://openwrt.org/downloads),
 find the firmware for your router and follow the instructions there. 

- Log into the router admin interface, and add package repository:
  Browser -> Router IP -> Login -> System -> Software -> Configuration -> Custom Feeds
  add:
```
src/gz download-quotas http://lemonsqueeze.github.io/OpenWRTQuotas/releases/openwrt/generic
```

- Update package database:
  System -> Software -> Actions -> Update Lists
- Select 'download-quota' from available software.
- Install, Done !

Note:  
- If web interface is missing after flashing openwrt you need to [install luci](https://wiki.openwrt.org/doc/howto/luci.essentials).

------------------------------------------------------------------------------------

### Interface

Package adds a `Quotas` tab to openwrt's admin interface.
Login and tweak settings from there:

![]()
![]()
![]()



------------------------------------------------------------------------------------


------------------------------------------------------------------------------------

### Build

- Clone repository, build package:

        make

**Notes:**

If you have 4Mb flash you'll most likely run out of space with the default package, the dependencies are too big.  
You probably have enough for a selfcontained build though:  

- Edit Makefile and set `ARCH` `TARGET` and `RELEASE` for your router.  
  Values can be found in `/etc/openwrt_release`.  
  For `ARCH` try `opkg info busybox | grep Architecture`

- instead of `make` type

        make selfcontained

- scp and install self-contained package instead (`download-quotas_0.1.1_ramips_24kec.ipk` for example)


------------------------------------------------------------------------------------


- Either install package directly from web interface:
  Browser -> Router IP -> Login -> Software -> Install Package
  using package url from [Release](https://github.com/lemonsqueeze/OpenWRTQuotas/releases)
  section.

- Or through ssh:

```
        $ ssh root@192.168.1.1
        # wget 
        cd /tmp
        opkg update
        opkg install download-quotas_0.1.1.ipk

```

- Download package from Release section.  
  If you have only 4Mb flash you need a custom build, see below.


- send package to the router:

        scp download-quotas_0.1.1.ipk 

- Login through ssh and install package:

        cd /tmp
        opkg update
        opkg install download-quotas_0.1.1.ipk

- Edit `/etc/download_quotas.conf`, set limits and lan ip address range (should include your dhcp range, preferrably the whole local network)

- reboot

------------------------------------------------------------------------------------

### Implementation

- 1 is straightforward to implement with netfilter.
- For 2 and 3 we need **download quotas per mac address**,
which is possible with ipset and some bookkeeping:  
ipset + iptables gives us download quotas by ip, 
we just need to keep track of mac/ip pairs (track_mac_usage, which runs every minute)

For netfilter / iptables rules details see this SE [question](https://unix.stackexchange.com/a/375705) and
[enable_quotas](https://github.com/lemonsqueeze/OpenWRTQuotas/blob/master/src/usr/share/download_quotas/enable_quotas) source.


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


