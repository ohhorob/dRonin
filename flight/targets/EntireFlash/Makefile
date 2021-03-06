#####
# Makefile for Entire Flash (EF) images
#
# The OpenPilot Team, http://www.openpilot.org, Copyright (C) 2012.
# dRonin, http://dronin.org Copyright (C) 2015
#
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, see <http://www.gnu.org/licenses/>
#####

###############################################################################
# This makefile requires bash
###############################################################################

# Set bash shell for all OSs except MS Windows
ifndef COMSPEC
SHELL := bash
endif

include $(MAKE_INC_DIR)/firmware-defs.mk
include $(BOARD_INFO_DIR)/board-info.mk

toprel = $(subst $(realpath $(ROOT_DIR))/,,$(abspath $(1)))

.PHONY: FORCE
FORCE:

.PHONY: bin
bin: $(OUTDIR)/$(TARGET).bin
hex: $(OUTDIR)/$(TARGET).hex

FW_BIN := $(ROOT_DIR)/build/fw_$(BOARD_NAME)/fw_$(BOARD_NAME).bin
FWINFO_BIN := $(FW_BIN).firmwareinfo.bin
INCLUDE_BOOTLOADER ?= yes

ifeq ($(INCLUDE_BOOTLOADER),no)
BL_BIN :=
FW_PRE_PAD := $(shell echo $$[$(FW_BANK_BASE)-$(EF_BANK_BASE)])
else
BL_BIN := $(ROOT_DIR)/build/bl_$(BOARD_NAME)/bl_$(BOARD_NAME).bin
FW_PRE_PAD := $(shell echo $$[$(FW_BANK_BASE)-$(BL_BANK_BASE)-$(BL_BANK_SIZE)])
endif # INCLUDE_BOOTLOADER

# force this target as FW_PRE_PAD could have been changed without us knowing
$(OUTDIR)/$(TARGET).fw_pre.pad: FORCE
	$(V0) @echo $(MSG_PADDING) $(call toprel, $@)
	$(V1) dd if=/dev/zero count=$(FW_PRE_PAD) bs=1 2> /dev/null | LC_CTYPE=c tr '\000' '\377' > $@ && [ $${PIPESTATUS[0]} -eq "0" ]

# force this target as FW_POST_PAD could have been changed without us knowing
FW_POST_PAD := $(shell echo $$[$(FW_BANK_SIZE)-$(FW_DESC_SIZE)-$(FW_DESC_SIZE)-$(shell wc -c < $(FW_BIN))])
$(OUTDIR)/$(TARGET).fw_post.pad: FORCE
	$(V0) @echo $(MSG_PADDING) $(call toprel, $@)
	$(V1) dd if=/dev/zero count=$(FW_POST_PAD) bs=1 2> /dev/null | LC_CTYPE=c tr '\000' '\377' > $@ && [ $${PIPESTATUS[0]} -eq "0" ]

# force this target as $(BL_BIN), $(FW_BIN) and $(FWINFO_BIN) could have been changed without us knowing
# add $(FWINFO_BIN) after $(FW_BIN) to imitate flash contents after manual firmware upload via gcs
$(OUTDIR)/$(TARGET).bin: $(BL_BIN) $(FW_BIN) $(OUTDIR)/$(TARGET).fw_pre.pad $(OUTDIR)/$(TARGET).fw_post.pad FORCE
	$(V0) @echo $(MSG_FLASH_IMG) $(call toprel, $@)
	$(V1) cat $(BL_BIN) $(OUTDIR)/$(TARGET).fw_pre.pad $(FW_BIN) $(FWINFO_BIN) $(OUTDIR)/$(TARGET).fw_post.pad $(FWINFO_BIN) > $@

$(OUTDIR)/$(TARGET).hex: $(OUTDIR)/$(TARGET).bin
	$(V0) @echo $(MSG_FLASH_IMG) $(call toprel, $@)
	$(V1) $(OBJCOPY) --change-addresses=$(EF_BANK_BASE) -I binary -O ihex $^ $@


.PHONY: dfu
dfu: $(OUTDIR)/$(TARGET).bin
	$(V0) @echo " DFU RESCUE $<"
	$(V1) ( \
		sudo $(DFU_CMD) -l && \
		sudo $(DFU_CMD) -d 0483:df11 -c 1 -i 0 -a 0 -D $< -s $(BL_BANK_BASE) ; \
		)

# Add jtag targets (program and wipe)
$(eval $(call JTAG_TEMPLATE,$(OUTDIR)/$(TARGET).bin,$(EF_BANK_BASE),$(EF_BANK_SIZE),$(OPENOCD_JTAG_CONFIG),$(OPENOCD_CONFIG)))
