# Toolchain prefix (i.e arm-elf- -> arm-elf-gcc.exe)
TCHAIN_PREFIX ?= arm-none-eabi-

CCACHE :=

ifeq ($(FLIGHT_BUILD_CONF), debug)
export DEBUG:=YES
CCACHE := $(CCACHE_BIN)
else ifeq ($(FLIGHT_BUILD_CONF), default)
# In the default case, keep the old "DEBUG"  variable handling
CCACHE := $(CCACHE_BIN)
else ifeq ($(FLIGHT_BUILD_CONF), release)
export DEBUG:=NO
else
$(error Only debug, release, or default allowed for FLIGHT_BUILD_CONF)
endif

# Define toolchain component names.
CC      = $(CCACHE) $(TCHAIN_PREFIX)gcc
CXX     = $(CCACHE) $(TCHAIN_PREFIX)g++
AR      = $(TCHAIN_PREFIX)ar
OBJCOPY = $(TCHAIN_PREFIX)objcopy
OBJDUMP = $(TCHAIN_PREFIX)objdump
SIZE    = $(TCHAIN_PREFIX)size
NM      = $(TCHAIN_PREFIX)nm
STRIP   = $(TCHAIN_PREFIX)strip
GCOV    = $(TCHAIN_PREFIX)gcov
INSTALL = install

THUMB   = -mthumb

CFLAGS += '-DDRONIN_TARGET="$(BOARD_NAME)"'

# Test if quotes are needed for the echo-command
result = ${shell echo "test"}
ifeq (${result}, test)
	quote = '
# This line is just to clear out the single quote above '
else
	quote =
endif

# Add a board designator to the terse message text
ifeq ($(ENABLE_MSG_EXTRA),yes)
	MSG_EXTRA = [$(BUILD_TYPE)|$(BOARD_SHORT_NAME)]
else
	MSG_EXTRA :=
endif

# Define Messages
# English
MSG_FORMATERROR      = ${quote} Can not handle output-format${quote}
MSG_MODINIT          = ${quote} MODINIT   $(MSG_EXTRA) ${quote}
MSG_SIZE             = ${quote} SIZE      $(MSG_EXTRA) ${quote}
MSG_LOAD_FILE        = ${quote} BIN/HEX   $(MSG_EXTRA) ${quote}
MSG_STRIP_FILE       = ${quote} STRIP     $(MSG_EXTRA) ${quote}
MSG_EXTENDED_LISTING = ${quote} LIS       $(MSG_EXTRA) ${quote}
MSG_SYMBOL_TABLE     = ${quote} NM        $(MSG_EXTRA) ${quote}
MSG_LINKING          = ${quote} LD        $(MSG_EXTRA) ${quote}
MSG_COMPILING        = ${quote} CC        ${MSG_EXTRA} ${quote}
MSG_COMPILING_ARM    = ${quote} CC-ARM    $(MSG_EXTRA) ${quote}
MSG_COMPILINGCXX     = ${quote} CXX       $(MSG_EXTRA) ${quote}
MSG_COMPILINGCXX_ARM = ${quote} CXX-ARM   $(MSG_EXTRA) ${quote}
MSG_ASSEMBLING       = ${quote} AS        $(MSG_EXTRA) ${quote}
MSG_ASSEMBLING_ARM   = ${quote} AS-ARM    $(MSG_EXTRA) ${quote}
MSG_CLEANING         = ${quote} CLEAN     $(MSG_EXTRA) ${quote}
MSG_ASMFROMC         = ${quote} AS(C)     $(MSG_EXTRA) ${quote}
MSG_ASMFROMC_ARM     = ${quote} AS(C)-ARM $(MSG_EXTRA) ${quote}
MSG_PYMITEINIT       = ${quote} PY        $(MSG_EXTRA) ${quote}
MSG_INSTALLING       = ${quote} INSTALL   $(MSG_EXTRA) ${quote}
MSG_TLFIRMWARE       = ${quote} TLFW      $(MSG_EXTRA) ${quote}
MSG_FWINFO           = ${quote} FWINFO    $(MSG_EXTRA) ${quote}
MSG_JTAG_PROGRAM     = ${quote} JTAG-PGM  $(MSG_EXTRA) ${quote}
MSG_JTAG_WIPE        = ${quote} JTAG-WIPE $(MSG_EXTRA) ${quote}
MSG_JTAG_DEBUG       = ${quote} JTAG-DBG  $(MSG_EXTRA) ${quote}
MSG_PADDING          = ${quote} PADDING   $(MSG_EXTRA) ${quote}
MSG_FLASH_IMG        = ${quote} FLASH_IMG $(MSG_EXTRA) ${quote}
MSG_GCOV             = ${quote} GCOV      $(MSG_EXTRA) ${quote}
MSG_AR               = ${quote} AR        $(MSG_EXTRA) ${quote}
MSG_DEBUG_SYMBOLS    = ${quote} DBG-SYM   $(MSG_EXTRA) ${quote}

toprel = $(subst $(realpath $(ROOT_DIR))/,,$(abspath $(1)))

# Display compiler version information.
.PHONY: gccversion
gccversion :
	@$(CC) --version

# Create final output file (.hex) from ELF output file.
%.hex: %.elf
	@echo $(MSG_LOAD_FILE) $(call toprel, $@)
	$(V1) $(OBJCOPY) -O ihex $< $@

# Create stripped output file (.elf.stripped) from ELF output file.
%.elf.stripped: %.elf
	@echo $(MSG_STRIP_FILE) $(call toprel, $@)
	$(V1) $(STRIP) --strip-unneeded $< -o $@

# Create final output file (.bin) from ELF output file.
%.bin: %.elf
	@echo $(MSG_LOAD_FILE) $(call toprel, $@)
	$(V1) $(OBJCOPY) -O binary $< $@

%.bin: %.o
	@echo $(MSG_LOAD_FILE) $(call toprel, $@)
	$(V1) $(OBJCOPY) -O binary $< $@

# Create extended listing file/disassambly from ELF output file.
# using objdump testing: option -C
%.lss: %.elf
	@echo $(MSG_EXTENDED_LISTING) $(call toprel, $@)
	$(V1) $(OBJDUMP) -h -S -C -r $< > $@

# Create a symbol table from ELF output file.
%.sym: %.elf
	@echo $(MSG_SYMBOL_TABLE) $(call toprel, $@)
	$(V1) $(NM) -n $< > $@

define SIZE_TEMPLATE
.PHONY: size
size: $(1)_size

.PHONY: $(1)_size
$(1)_size: $(1)
	@echo $(MSG_SIZE) $$(call toprel, $$<)
	$(V1) $(SIZE) -A $$<
endef

# OpenPilot firmware image template
#  $(1) = path to bin file
#  $(2) = boardtype in hex
#  $(3) = board revision in hex
#  $(4) = address to pad firmware bin before appending info blob
define TLFW_TEMPLATE
FORCE:

$(1).firmwareinfo.c: $(1) $(ROOT_DIR)/make/templates/firmwareinfotemplate.c FORCE
	@echo $(MSG_FWINFO) $$(call toprel, $$@)
	$(V1) $(PYTHON) $(ROOT_DIR)/make/scripts/version-info.py \
		--path=$(ROOT_DIR) \
		--template=$(ROOT_DIR)/make/templates/firmwareinfotemplate.c \
		--outfile=$$@ \
		--image=$(1) \
		--type=$(2) \
		--revision=$(3) \
		--uavodir=$(ROOT_DIR)/shared/uavobjectdefinition

$(eval $(call COMPILE_C_TEMPLATE, $(1).firmwareinfo.c))

$(OUTDIR)/$(notdir $(basename $(1))).tlfw: $(1:.bin=.padded.bin) $(1).firmwareinfo.bin
	@echo $(MSG_TLFIRMWARE) $$(call toprel, $$@)
	$(V1) cat $$^ > $$@
endef

# Assemble: create object files from assembler source files.
define ASSEMBLE_TEMPLATE
$(OUTDIR)/$(notdir $(basename $(1))).o : $(1)
	@echo $(MSG_ASSEMBLING) $$(call toprel, $$<)
	$(V1) $(CC) -c $(THUMB) $$(ASFLAGS) $$< -o $$@
endef

# Assemble: create object files from assembler source files. ARM-only
define ASSEMBLE_ARM_TEMPLATE
$(OUTDIR)/$(notdir $(basename $(1))).o : $(1)
	@echo $(MSG_ASSEMBLING_ARM) $$(call toprel, $$<)
	$(V1) $(CC) -c $$(ASFLAGS) $$< -o $$@
endef

# Compile: create object files from C source files.
define COMPILE_C_TEMPLATE
$(OUTDIR)/$(notdir $(basename $(1))).o : EXTRA_FLAGS := $(2)
$(OUTDIR)/$(notdir $(basename $(1))).o : $(1)
	@echo $(MSG_COMPILING) $$(call toprel, $$<)
	$(V1) $(CC) -c $(THUMB) $$(CFLAGS) $$(CONLYFLAGS) $$(EXTRA_FLAGS) $$< -o $$@
endef

# Compile: create object files from C source files. ARM-only
define COMPILE_C_ARM_TEMPLATE
$(OUTDIR)/$(notdir $(basename $(1))).o : EXTRA_FLAGS := $(2)
$(OUTDIR)/$(notdir $(basename $(1))).o : $(1)
	@echo $(MSG_COMPILING_ARM) $$(call toprel, $$<)
	$(V1) $(CC) -c $$(CFLAGS) $$(CONLYFLAGS) $$(EXTRA_FLAGS) $$< -o $$@
endef

# Compile: create object files from C++ source files.
define COMPILE_CXX_TEMPLATE
$(OUTDIR)/$(notdir $(basename $(1))).o : EXTRA_FLAGS := $(2)
$(OUTDIR)/$(notdir $(basename $(1))).o : $(1)
	@echo $(MSG_COMPILINGCXX) $$(call toprel, $$<)
	$(V1) $(CXX) -c $(THUMB) $$(CFLAGS) $$(CPPFLAGS) $$(CXXFLAGS) $$(EXTRA_FLAGS) $$< -o $$@
endef

# Compile: create object files from C++ source files. ARM-only
define COMPILE_CXX_ARM_TEMPLATE
$(OUTDIR)/$(notdir $(basename $(1))).o : $(1)
$(OUTDIR)/$(notdir $(basename $(1))).o : EXTRA_FLAGS := $(2)
	@echo $(MSG_COMPILINGCXX_ARM) $$(call toprel, $$<)
	$(V1) $(CPP) -c $$(CFLAGS) $$(CPPFLAGS) $$(CXXFLAGS) $$(EXTRA_FLAGS) $$< -o $$@
endef

# Link: create ELF output file from object files.
#   $1 = elf file to produce
#   $2 = list of object files that make up the elf file
# Note: OSX doesn't have objcopy out-of-box so we can't use it native builds (e.g. sim)
# Note: header include flags are filtered out to avoid Windows CreateProcess char limit (32768)
define LINK_TEMPLATE
.SECONDARY: $(1)
.PRECIOUS: $(2)
$(1): CFLAGS_LINK = $$(filter-out -I%,$$(CFLAGS))
$(1): $(2)
	@echo $(MSG_LINKING) $$(call toprel, $$@)
	$(V1) $(CC) $(THUMB) $$(CFLAGS_LINK) $(2) --output $$@ $$(LDFLAGS)
ifneq ($(TCHAIN_PREFIX),)
	@echo $(MSG_DEBUG_SYMBOLS) $$(call toprel, $$@)
	$(V1) $(OBJCOPY) --only-keep-debug $$@ $$(addsuffix .debug, $$(@:.elf=))
endif
endef

# Link: create ELF output file from object files.
#   $1 = elf file to produce
#   $2 = list of object files that make up the elf file
# Note: OSX doesn't have objcopy out-of-box so we can't use it native builds (e.g. sim)
define LINK_CXX_TEMPLATE
.SECONDARY : $(1)
.PRECIOUS : $(2)
$(1):  $(2)
	@echo $(MSG_LINKING) $$(call toprel, $$@)
	$(V1) $(CXX) $(THUMB) $$(CFLAGS) $(2) --output $$@ $$(LDFLAGS)
ifneq ($(TCHAIN_PREFIX),)
	@echo $(MSG_DEBUG_SYMBOLS) $$(call toprel, $$@)
	$(V1) $(OBJCOPY) --only-keep-debug $$@ $$(addsuffix .debug, $$(@:.elf=))
endif
endef

# $(1) = Name of binary image to write
# $(2) = Base of flash region to write/wipe
# $(3) = Size of flash region to write/wipe
# $(4) = OpenOCD JTAG interface configuration file to use
# $(5) = OpenOCD configuration file to use
define JTAG_TEMPLATE
# ---------------------------------------------------------------------------
# Options for OpenOCD flash-programming
# see openocd.pdf/openocd.texi for further information

# if OpenOCD is in the $PATH just set OPENOCDEXE=openocd
OOCD_EXE ?= openocd

# debug level
OOCD_JTAG_SETUP  = -d0
# interface and board/target settings (using the OOCD target-library here)
OOCD_JTAG_SETUP += -s $(ROOT_DIR)/flight/Project/OpenOCD
OOCD_JTAG_SETUP += -f $(4) -f $(5)

# initialize
OOCD_BOARD_RESET = -c init
# show the targets
#OOCD_BOARD_RESET += -c targets
# commands to prepare flash-write
OOCD_BOARD_RESET += -c "reset halt"

.PHONY: program
program: $(1)
	@echo $(MSG_JTAG_PROGRAM) $$(call toprel, $$<)
	$(V1) $(OOCD_EXE) \
		$$(OOCD_JTAG_SETUP) \
		-c "program $$< verify reset exit"

.PHONY: wipe
wipe:
	@echo $(MSG_JTAG_WIPE) wiping $(3) bytes starting from $(2)
	$(V1) $(OOCD_EXE) \
		$$(OOCD_JTAG_SETUP) \
		$$(OOCD_BOARD_RESET) \
		-c "flash erase_address pad $(2) $(3)" \
		-c "reset run" \
		-c "shutdown"

.PHONY: debug
debug: $(1)
	@echo $(MSG_JTAG_DEBUG) $$(call toprel, $$<)
	$(V1) $(OOCD_EXE) \
		$$(OOCD_JTAG_SETUP) \
		-c "program $$< verify"
		-c "reset init"

endef # JTAG_TEMPLATE

# Generate GCOV summary
#  $(1) = name of source file to analyze with gcov
define GCOV_TEMPLATE
$(OUTDIR)/$(1).gcov: $(OUTDIR)/$$(basename $(1)).gcda
	$(V0) @echo $(MSG_GCOV) $$(call toprel, $$@)
	$(V1) ( \
	  cd $(OUTDIR) && \
	  $(GCOV) $(1) 2>&1 > /dev/null ; \
	)
endef

ifneq ($(BUILD_TYPE),bu)
# This pads the bin up to the firmware description blob base
# Required for boards which don't use the TL bootloader to put
# the blob at the correct location, if pad location($(4)) is
# less than bin length this is ineffective
%.padded.bin: %.bin
	$(V1) $(OBJCOPY) --pad-to=$(FW_DESC_BASE) -I binary -O binary $< $@
endif

EXTRAINCDIRS += $(SHAREDUSBIDDIR)
