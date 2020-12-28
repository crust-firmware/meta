#
# Copyright © 2017-2020 Samuel Holland <samuel@sholland.org>
# SPDX-License-Identifier: BSD-3-Clause
#

# File locations
ATF		 = arm-trusted-firmware
ATF_URL		 = https://github.com/crust-firmware/arm-trusted-firmware
SCP		 = crust
SCP_URL		 = https://github.com/crust-firmware/crust
U-BOOT		 = u-boot
U-BOOT_URL	 = https://github.com/crust-firmware/u-boot

BUILDDIR	?= build
OUTDIR		 = $(BUILDDIR)/$(BOARD)

# Cross compiler
CROSS_aarch32	 = arm-linux-musleabi-
CROSS_aarch64	 = aarch64-linux-musl-
CROSS_or1k	 = or1k-linux-musl-

# General options
DEBUG		?= 0
REPRODUCIBLE	?= 1

# Board selection
BOARD		?= pinebook

# Board-specific options
ARCH		 = $(or $(ARCH_$(BOARD)),aarch64)
PLAT		 = $(or $(PLAT_$(BOARD)),sun50i_a64)
FLASH_SIZE_KB	 = $(or $(FLASH_SIZE_KB_$(BOARD)),2048)
SPL_SIZE_KB	 = $(or $(SPL_SIZE_KB_$(BOARD)),32)

# Board-specific overrides
PLAT_orangepi_3			 = sun50i_h6
PLAT_pine_h64			 = sun50i_h6
FLASH_SIZE_KB_pine_h64		 = 16384

###############################################################################

BUILD_TYPE = $(if $(filter-out 0,$(DEBUG)),debug,release)

BL3X = $(if $(findstring aarch64,$(ARCH)),bl31,bl32).bin
DATE = $(if $(filter-out 0,$(REPRODUCIBLE)),0,$(shell stat -c '%Y' .config))

M := @$(if $(filter-out 0,$(V)),:,printf '  %-7s %s\n')
Q :=  $(if $(filter-out 0,$(V)),,@)

all: $(OUTDIR)/sha256sums $(OUTDIR)/sha512sums
	$(M) DONE

clean:
	$(Q) $(MAKE) -C $(ATF) clean
	$(Q) $(MAKE) -C $(SCP) clean
	$(Q) $(MAKE) -C $(U-BOOT) clean
	$(Q) rm -fr $(OUTDIR)
	$(Q) rmdir $(BUILDDIR) 2>/dev/null || true

distclean:
	$(Q) $(MAKE) -C $(ATF) distclean
	$(Q) $(MAKE) -C $(SCP) distclean
	$(Q) $(MAKE) -C $(U-BOOT) distclean
	$(Q) rm -fr .config $(BUILDDIR)

.config: FORCE
	$(M) CHECK board
	$(Q) grep -Fqsx BOARD=$(BOARD) $@ || printf 'BOARD=%s\n' $(BOARD) >$@

$(ATF):
	$(M) CLONE $@
	$(Q) git clone $(ATF_URL) $@

$(SCP):
	$(M) CLONE $@
	$(Q) git clone $(SCP_URL) $@

$(U-BOOT):
	$(M) CLONE $@
	$(Q) git clone $(U-BOOT_URL) $@

%_defconfig:;

%/.config: .config %/configs/$(BOARD)_defconfig | %
	$(M) CONFIG $|
	$(Q) $(MAKE) -C $| $(BOARD)_defconfig

$(ATF)/build/$(PLAT)/$(BUILD_TYPE)/$(BL3X): .config FORCE | $(ATF)
	$(M) MAKE $@
	$(Q) $(MAKE) -C $| CROSS_COMPILE=$(CROSS_$(ARCH)) \
		ARCH=$(ARCH) \
		BUILD_MESSAGE_TIMESTAMP='"$(DATE)"' \
		DEBUG=$(DEBUG) \
		PLAT=$(PLAT) \
		$(basename $(BL3X))

$(SCP)/build/scp/scp.bin: $(SCP)/.config FORCE | $(SCP)
	$(M) MAKE $@
	$(Q) $(MAKE) -C $| CROSS_COMPILE=$(CROSS_or1k) \
		HOST_COMPILE=$(CROSS_$(ARCH)) \
		build/scp/scp.bin

$(U-BOOT)/spl/sunxi-spl.bin: $(U-BOOT)/u-boot-sunxi-with-spl.bin;

$(U-BOOT)/u-boot-sunxi-with-spl.bin: $(U-BOOT)/.config \
		$(OUTDIR)/$(BL3X) $(OUTDIR)/scp.bin FORCE | $(U-BOOT)
	$(M) MAKE $@
	$(Q) $(MAKE) -C $| CROSS_COMPILE=$(CROSS_$(ARCH)) \
		BL31=$(abspath $(OUTDIR)/$(BL3X)) \
		SCP=$(abspath $(OUTDIR)/scp.bin) \
		SOURCE_DATE_EPOCH=$(DATE) \
		all

$(U-BOOT)/u-boot-sunxi-with-spl.fit.fit: $(U-BOOT)/u-boot-sunxi-with-spl.bin;

$(BUILDDIR) $(OUTDIR):
	$(M) MKDIR $@
	$(Q) mkdir -p $@

$(OUTDIR)/$(BL3X): $(ATF)/build/$(PLAT)/$(BUILD_TYPE)/$(BL3X) | $(OUTDIR)
	$(M) CP $@
	$(Q) cp -f $< $@

$(OUTDIR)/scp.bin: $(SCP)/build/scp/scp.bin | $(OUTDIR)
	$(M) CP $@
	$(Q) cp -f $< $@

$(OUTDIR)/scp.config: $(SCP)/.config | $(OUTDIR)
	$(M) CP $@
	$(Q) cp -f $< $@

$(OUTDIR)/sunxi-spl.bin: $(U-BOOT)/spl/sunxi-spl.bin | $(OUTDIR)
	$(M) CP $@
	$(Q) cp -f $< $@

$(OUTDIR)/u-boot.config: $(U-BOOT)/.config | $(OUTDIR)
	$(M) CP $@
	$(Q) cp -f $< $@

$(OUTDIR)/u-boot.itb: $(U-BOOT)/u-boot-sunxi-with-spl.fit.fit | $(OUTDIR)
	$(M) CP $@
	$(Q) cp -f $< $@

$(OUTDIR)/u-boot-sunxi-spi.img: \
		$(OUTDIR)/sunxi-spl.bin $(OUTDIR)/u-boot.itb | $(OUTDIR)
	$(M) DD $@
	$(Q) dd bs=$(FLASH_SIZE_KB)k count=1 if=/dev/zero 2>/dev/null | \
		tr '\0' '\377' >$@.tmp
	$(Q) dd bs=$(SPL_SIZE_KB)k conv=notrunc \
		if=$(OUTDIR)/sunxi-spl.bin of=$@.tmp 2>/dev/null
	$(Q) dd bs=$(SPL_SIZE_KB)k conv=notrunc \
		if=$(OUTDIR)/u-boot.itb of=$@.tmp seek=1 2>/dev/null
	$(Q) mv -f $@.tmp $@

$(OUTDIR)/u-boot-sunxi-with-spl.bin: $(U-BOOT)/u-boot-sunxi-with-spl.bin | \
		$(OUTDIR)
	$(M) CP $@
	$(Q) cp -f $< $@

%/sha256sums: %/$(BL3X) %/scp.bin %/scp.config \
		%/sunxi-spl.bin %/u-boot.config %/u-boot.itb \
		%/u-boot-sunxi-spi.img %/u-boot-sunxi-with-spl.bin
	$(M) SHA256 $@
	$(Q) cd $(dir $@) && sha256sum -b $(notdir $^) > $(notdir $@).tmp
	$(Q) mv -f $@.tmp $@

%/sha512sums: %/$(BL3X) %/scp.bin %/scp.config \
		%/sunxi-spl.bin %/u-boot.config %/u-boot.itb \
		%/u-boot-sunxi-spi.img %/u-boot-sunxi-with-spl.bin
	$(M) SHA512 $@
	$(Q) cd $(dir $@) && sha512sum -b $(notdir $^) > $(notdir $@).tmp
	$(Q) mv -f $@.tmp $@

FORCE:

.PHONY: all clean distclean FORCE
.SECONDARY:
.SUFFIXES:
