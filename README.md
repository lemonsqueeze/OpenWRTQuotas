OpenWRT Download Quotas
=======================

Implements download quotas per mac address on a Linux router.  
At the moment it focuses on [OpenWrt](http://openwrt.org) but shouldn't be hard to port to other distributions.

### Scenario

You have an open wifi with many guests, your internet connection's
monthly allowance is getting eaten up fast (or some guests are hogging
the bandwidth) and you need to limit downloads somehow.

Usual solution is to setup a captive portal: guests will need to authenticate and you can have download quotas.  
Heavy and not so user friendly. You'll probably need extra hardware to run the portal.

How about this instead: keep wifi open but
1. Limit each guest to say, 50k/s max.
2. Each guest starts with 100 Mb download quota.
3. Once overquota download speed is throttled to 10k/s.

This way kids going on youtube can't eat up all the bandwidth, network remains
open, and in the worst case if someone goes overquota he can still check email etc.
You can also adapt to circumstances by tweaking the limits : Expect huge number of guests
for the weekend ? Lower speed and quota. Lots of bandwidth remaining ? Relax the rules etc.

------------------------------------------------------------------------------------

### Installation

You need:  
- Router supported by [OpenWrt](http://openwrt.org) with at least 8Mb flash.
- Ipset support (tested with OpenWRT 15.05 and 16.xx, but other releases should do. LEDE untested).

I'm using a TP-Link TL-WR810N with 16.xx here: small form factor, costs about $30 and works nicely.

**Setup:**
- Flash OpenWrt firmware and configure router.  
  Read the [wiki](https://wiki.openwrt.org/), [docs](https://openwrt.org/docs),
  go to the [downloads](https://openwrt.org/downloads), find the firmware for your router
  and follow the instructions there.
- Log into the router admin interface, update package database:  
  `Browser -> Router IP -> Login -> System -> Software -> Actions -> Update Lists`
- Install `luci-ssl` from available software (https support)
- Add package repository:  
  Under `System -> Software -> Configuration -> Custom Feeds` add:  
  `src/gz download-quotas https://lemonsqueeze.github.io/OpenWRTQuotas/releases/openwrt/generic`
- Update package database again:  
  `System -> Software -> Actions -> Update Lists`
- Install `download-quota` from available software.
- Done !

Tips:
- If web interface is missing after flashing openwrt you need to
  [install luci](https://wiki.openwrt.org/doc/howto/luci.essentials).
- If you need more range / your fancy wifi router isn't supported you can also chain the two:
  For example, TP-Link in ethernet-only mode between WAN and wifi router (it has 2 sockets),
  the other router does the wifi. Best of both worlds.
- This won't work for 4Mb flash routers. You might be able to hack around but it won't be pretty,
  device is too space-constrained. No https support. You'll need a custom build and install
  package manually.

------------------------------------------------------------------------------------

### Interface

Package adds a `Quotas` tab to openwrt's admin interface.
Login and tweak settings from there:

![]()
![]()
![]()

### Notes

At the moment it's not possible to use OpenWrt's firewall and download-quotas at the same time:
download-quotas will wipe firewall rules when it starts and vice-versa.
Currently firewall service is disabled when installing download-quotas.
If you have have custom rules or create some through web interface they will not take effect.
(TODO: integrate the two ...)

------------------------------------------------------------------------------------

### Security

This is by no means absolutely secure, however with a typical group of non-hostile guests it works pretty well:  

- Mac addresses can be changed, if a guest does so he'll get a brand new quota.  
- Limits only kick in for ip range specified in `enable_quota`. If you left addresses out
  a guest can bypass limits by using one of these ips (could be a feature too if you need
  priviledged users. A better way would be to add special rules for them)  
- The mac/ip tracking logic runs every minute so when a pairing changes there's a window of
  at most 1 minute where a guest could be running on someone else's quota. Pairing changes are
  rare enough and in the worst case, at 100k/s the potential for abuse is small enough that
  it doesn't matter here.

------------------------------------------------------------------------------------

### Source

- `base` branch: minimal scripts which are not openwrt specific. No ui.
  Should be fairly easy to port to other distros.
- `openwrt` branch adds admin interface and some extra features.
  openwrt specific.

See [HACKING](HACKING.md) for details.
