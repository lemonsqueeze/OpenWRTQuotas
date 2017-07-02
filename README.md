Shared wifi download quotas
===========================

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
- 1 is straightforward with netfilter, we create one class per ip.  
- For 2 and 3 we need **download quotas per mac address**,
which is possible with ipset and some bookkeeping:  
  ipset + iptables gives us download quotas by ip, 
we just need to keep track of mac-ip pairs (track_mac_usage, which runs every minute)

------------------------------------------------------------------------------------

### Installation

At the moment it focuses on [OpenWrt](http://openwrt.org) but shouldn't be hard to make it work on other distributions.

What you need:  
- Wifi router supported by OpenWrt (8Mb flash better)
- Ipset support (tested with Chaos Calmer 15.05 but any release should do)

Installation:
- Flash OpenWrt firmware, configure router
- Login through ssh and install packages on the router:

        opkg update
        opkg install tc
        opkg install ipset
        opkg install ip       # optional, for testing

- Edit `quotas.config`, set limits and lan ip address range (should include your dhcp range, preferrably the whole local network)

- Install files in /root:

        scp *_quotas quotas.config track_mac_usage root@192.168.1.1:~/

- Create [crontab](https://raw.githubusercontent.com/lemonsqueeze/WifiDownloadQuotas/master/conf/crontab)
  either from web interface or `crontab -e`
- Start and enable crontab with:

        /etc/init.d/cron start
        /etc/init.d/cron enable

Notes:

If you have 4Mb flash don't use opkg, you'll most likely run out of space.  
You probably have enough to store just the
[needed files](https://github.com/lemonsqueeze/WifiDownloadQuotas/tree/master/extra_files) though.  
These are for Chaos Calmer 15.05 ramips/rt305x, for other versions/arch extract them from their resp. packages:

    ipset
    iptables-mod-ipopt
    kmod-ipt-ipopt
    kmod-ipt-ipset
    kmod-nfnetlink
    kmod-sched-core
    kmod-sched
    libmnl
    tc

------------------------------------------------------------------------------------

### Usage

    enable_quotas         Enable limits and quotas  
    disable_quotas        Disable limits and quotas  (current usage is lost!)
    save_quotas           Backup current quotas to stdout
    load_quotas  <file>   Restore quotas saved with save_quotas
    reset_quotas          Clear everyone's quotas
    list_quotas           Show current usage  

Start quotas with `enable_quota`

`disable_quotas` + `enable_quotas` can be used to temporarily suspend limits (quotas are not reset)

------------------------------------------------------------------------------------

### Notes

Currently replaces OpenWrt's firewall rules. if you have have custom rules or create some through
web interface they will get wiped out. It makes sense to disable the firewall service in OpenWrt's interface.

Quotas are lost on reboot. Save / restore them with save_quotas / load_quotas.

This is by no means completely secure:  
- Mac addresses can be changed, if a guest does so he'll get a brand new quota.  
- Limits only kick in for ip range specified in `enable_quota`. If you left addresses out
  a guest can bypass limits by using one of these ips (could be a feature too if you need
  priviledged users. A better way would be to add special rules for them)

[Gargoyle](https://www.gargoyle-router.com/) can do download quotas,
  interface is very nice and users can see their quota usage on the front page.
  On the version i checked though (1.4.7, old ...) quotas are per ip, 
  if user changes ip address quota is lost...

![Gargoyle quotas](http://www.ai.net.nz/images/gargoyle/screen04.png)


