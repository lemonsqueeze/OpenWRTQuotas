
VERSION=0.1.1
NAME=download-quotas
PKG=$(NAME)_$(VERSION).ipk
DEPENDS=ipset, tc, iptables-mod-ipopt, kmod-sched
PKG_SRC=src
ARCH=all
RELEASE_VERS=15.05.1

# Make self-contained package ?
# ie no dependencies, include needed binaries from other packages.
# Uncomment this and set router arch, target and release below.
# SELFCONTAINED=1

ifdef SELFCONTAINED
  # opkg info busybox | grep Architecture
  ARCH=ramips_24kec

  # values from /etc/openwrt_release:
  TARGET=ramips/rt305x
  RELEASE_NAME=chaos_calmer
  RELEASE_VERS=15.05.1

  RELEASE=$(RELEASE_NAME)/$(RELEASE_VERS)
  RELEASE_SHORT=$(shell echo -n $(RELEASE_VERS) | cut -d. -f1-2 )
  PKG=$(NAME)_$(VERSION)_$(ARCH)_$(RELEASE_SHORT).ipk
  PKG_SRC+=src_extra
  DEPENDS=
endif

MAKEFLAGS += --no-print-directory

#########################################################################

all: $(PKG)

selfcontained self: FORCE
	@make SELFCONTAINED=1

#########################################################################

$(PKG): pkg/data.tar.gz  pkg/control.tar.gz  
	@echo gen $(PKG)
	@cd pkg ; tar -czf ../$@ control.tar.gz  data.tar.gz 

pkg/control.tar.gz: pkg/control pkg/postinst pkg/prerm
	@echo gen control.tar.gz
	@fakeroot -- sh -c "cd pkg ; chown root: * ; tar -czf control.tar.gz control postinst prerm"

pkg/data.tar.gz: $(PKG_SRC) FORCE
	@echo gen data.tar.gz
	@cd src ; find . -name "*~" | xargs -r rm
	@fakeroot -- sh -c "cd src       ; chown -R root: * ; tar -cf ../pkg/data.tar . "
ifdef SELFCONTAINED
	@fakeroot -- sh -c "cd src_extra ; chown -R root: * ; tar -rf ../pkg/data.tar . "
endif
	@gzip -f pkg/data.tar

pkg/size: FORCE		# divide real size by 3 to approx compression
	@du -csb $(PKG_SRC) | tail -1 | sed -e 's|\([0-9]\+\).*|\1|' | \
           ( read f; echo "$$(($$f / 3))" ) > pkg/size

pkg/control: pkg/control.in pkg/size FORCE
	@cd pkg ; cat control.in | \
         sed -e 's/VERSION/$(VERSION)/' -e 's/DEPENDS/$(DEPENDS)/' \
	     -e 's/ARCH/$(ARCH)/'       -e "s/SIZE/`cat size`/"    \
	     -e 's/RELEASE_VERS/$(RELEASE_VERS)/' > control

#############################################################################
# selfcontained build

src_extra:
	selfcontained/get_files $(RELEASE) $(TARGET)

#############################################################################

clean: FORCE
	-@rm *.ipk pkg/*.tar.gz pkg/control pkg/size  2>/dev/null
	-@cd selfcontained; rm Packages filenames  2>/dev/null
	-@cd selfcontained; rm -rf data tmp packages  2>/dev/null
	-@rm -rf src_extra

FORCE:
