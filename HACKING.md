HACKING
=======

### Build

- Clone repository, build package:

        make

**Notes:**

If you have 4Mb flash you'll most likely run out of space with the default package,
the dependencies are too big.  
You might have enough for a selfcontained build though:  

- Edit Makefile and set `ARCH` `TARGET` and `RELEASE` for your router.  
  Values can be found in `/etc/openwrt_release`.  
  For `ARCH` try `opkg info busybox | grep Architecture`

- instead of `make` type

        make selfcontained

- scp and install self-contained package instead (`download-quotas_0.1.1_ramips_24kec.ipk` for example)


------------------------------------------------------------------------------------

### Implementation

- [1](README.md) is straightforward with netfilter.
- For [2](README.md) and [3](README.md) we need **download quotas per mac address**,
which is possible with ipset and some bookkeeping:  
ipset + iptables gives us download quotas by ip, 
we just need to keep track of mac/ip pairs (track_mac_usage, which runs every minute)

For netfilter / iptables rules details see this SE [question](https://unix.stackexchange.com/a/375705) and
[enable_quotas](https://github.com/lemonsqueeze/OpenWRTQuotas/blob/master/src/usr/share/download_quotas/enable_quotas) source.


------------------------------------------------------------------------------------

### Main scripts

    /etc/init.d/download-quotas start    Enable limits and quotas and load saved usage
    /etc/init.d/download-quotas stop     Disable limits and quotas and save current usage
    /etc/init.d/download-quotas save     Backup current usage to /root/.download_quotas
    /etc/init.d/download-quotas load     Restore saved usage
    /etc/init.d/download-quotas reset    Clear everyone's quotas
    /etc/init.d/download-quotas list     Show current usage  

By default quotas start automatically on boot, are saved every 30 mins and reset once a month (see crontab)


------------------------------------------------------------------------------------

[Gargoyle](https://www.gargoyle-router.com/) can do download quotas,
  interface is very nice and users can see their quota usage on the front page.
  On the version i checked though (1.4.7, old ...) quotas are per ip, 
  if user changes ip address quota is lost...

![Gargoyle quotas](http://www.ai.net.nz/images/gargoyle/screen04.png)


