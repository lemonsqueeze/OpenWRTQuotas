
VERSION=0.1.1
NAME=download-quotas
PKG=$(NAME)_$(VERSION).ipk
DEPENDS=ipset, iptables-mod-ipopt, tc
PKG_SRC=src
ARCH=all

# Make self-contained package ?
# ie no dependencies, include needed binaries from other packages
# SELFCONTAINED=1

ifdef SELFCONTAINED
  # Need to set arch target and release for self-contained build
  ARCH=ramips_24kec
  TARGET=ramips/rt305x
  RELEASE=chaos_calmer/15.05.1

  PKG=$(NAME)_$(VERSION)_$(ARCH).ipk
  PKG_SRC+=src_extra
  DEPENDS=
endif

MAKEFLAGS += --no-print-directory

#########################################################################

all: $(PKG)
	@[ `id -u` != 0 ] && echo "Warning: build package as root for package files to be owned by root ..."

selfcontained self: FORCE
	@make SELFCONTAINED=1

#########################################################################

$(PKG): pkg/data.tar.gz  pkg/control.tar.gz  
	@echo gen $(PKG)
	@cd pkg ; tar -czf ../$@ control.tar.gz  data.tar.gz 

pkg/control.tar.gz: pkg/control pkg/postinst pkg/prerm
	@echo gen control.tar.gz
	@cd pkg ; tar -czf control.tar.gz control postinst prerm

pkg/data.tar.gz: $(PKG_SRC) FORCE
	@echo gen data.tar.gz
	@cd src ; find . -name "*~" | xargs -r rm
	@cd src       ; tar -cf ../pkg/data.tar .
ifdef SELFCONTAINED
	@cd src_extra ; tar -rf ../pkg/data.tar .
endif
	@gzip -f pkg/data.tar

pkg/size: FORCE		# divide real size by 3 to approx compression
	@du -csb $(PKG_SRC) | tail -1 | sed -e 's|\([0-9]\+\).*|\1|' | \
           ( read f; echo "$$(($$f / 3))" ) > pkg/size

pkg/control: pkg/control.in pkg/size FORCE
	@cd pkg ; cat control.in | \
         sed -e 's/VERSION/$(VERSION)/' -e 's/DEPENDS/$(DEPENDS)/' \
	     -e 's/ARCH/$(ARCH)/'       -e "s/SIZE/`cat size`/" > control

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
