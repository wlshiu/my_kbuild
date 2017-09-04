#############################################################################
# USER_TARGET
#############################################################################

# if_dir_exist = $(if $(wildcard $(srctree)/$(1)), $(1))
# if_exist = $(if $(wildcard $(srctree)/$(1)), $(1))
# if_mk_exist = $(if $(wildcard $(srctree)/$(1)/Makefile), $(1))


# cmd_KOUT = $(srctree)/$(lastword $(subst /, ,$(subst /.,,$(1))))
# cmd_mk = $(if $(KBUILD_VERBOSE:1=),@)$(MAKE) $(if $(O),-C $(call cmd_KOUT,$(O)) KBUILD_SRC=$(srctree) -f $(srctree)/Makefile) $(1)

# cmd_cleandep = for i in $(1); do $(MAKE) $${i}-clean; done
##################################


# Default kernel image to build when no specific target is given.
# KBUILD_IMAGE may be overruled on the command line or
# set in the environment
# Also any assignments in arch/$(ARCH)/Makefile take precedence over
# this default value
export KBUILD_IMAGE ?= vmlinux

#
# INSTALL_PATH specifies where to place the updated kernel and system map
# images. Default is /boot, but you can set it to other values
export	INSTALL_PATH ?= /out

core-y		:= project/ # middleware/

user-dirs	:= $(patsubst %/,%,$(filter %/, \
		     $(core-y) $(core-m) \
		     $(libs-y) $(libs-m)))

user-alldirs	:= $(sort $(user-dirs) $(patsubst %/,%,$(filter %/, \
		     $(core-n) $(core-) \
		     $(libs-n)    $(libs-))))


core-y		:= $(patsubst %/, %/built-in.o, $(core-y))
# libs-y1		:= $(patsubst %/, %/lib.a, $(libs-y))
# libs-y2		:= $(patsubst %/, %/built-in.o, $(libs-y))
# libs-y		:= $(libs-y1) $(libs-y2)

# Externally visible symbols (used by link-vmlinux.sh)
export KBUILD_VMLINUX_INIT :=
export KBUILD_VMLINUX_MAIN := $(core-y) $(libs-y)
export KBUILD_LDS          := -T project/armelf.lds
export LDFLAGS_vmlinux
# used by scripts/pacmage/Makefile
export KBUILD_ALLDIRS := $(sort $(filter-out arch/%,$(user-alldirs)) arch include scripts)

user-deps := $(KBUILD_LDS) $(KBUILD_VMLINUX_INIT) $(KBUILD_VMLINUX_MAIN)

# Final link of vmlinux
      cmd_link-vmlinux = $(CONFIG_SHELL) $< $(LD) $(LDFLAGS) $(LDFLAGS_vmlinux)
quiet_cmd_link-vmlinux = LINK    $@

# Include targets which we want to
# execute if the rest of the kernel build went well.

user_all: scripts/link-vmlinux.sh $(user-deps) FORCE
ifdef CONFIG_HEADERS_CHECK
	$(Q)$(MAKE) -f $(srctree)/Makefile headers_check
endif
	+$(call if_changed,link-vmlinux)

# The actual objects are generated when descending,
# make sure no implicit rule kicks in
$(sort $(user-deps)): $(user-dirs) ;

# Handle descending into subdirectories listed in $(vmlinux-dirs)
# Preset locale variables to speed up the build process. Limit locale
# tweaks to this spot to avoid wrong language settings when running
# make menuconfig etc.
# Error messages still appears in the original language

PHONY += $(user-dirs)
$(user-dirs): prepare scripts
	$(Q)$(MAKE) $(build)=$@


# Store (new) KERNELRELEASE string in include/config/kernel.release
include/config/kernel.release: include/config/auto.conf FORCE
	$(call filechk,kernel.release)


# Things we need to do before we recursively start building the kernel
# or the modules are listed in "prepare".
# A multi level approach is used. prepareN is processed before prepareN-1.
# archprepare is used in arch Makefiles and when processed asm symlink,
# version.h and scripts_basic is processed / created.

# Listed in dependency order
PHONY += prepare archprepare prepare0 prepare1 prepare2 prepare3

# prepare3 is used to check if we are building in a separate output directory,
# and if so do:
# 1) Check that make has not been executed in the kernel src $(srctree)
prepare3: include/config/kernel.release
ifneq ($(KBUILD_SRC),)
	@$(kecho) '  Using $(srctree) as source for kernel'
	$(Q)if [ -f $(srctree)/.config -o -d $(srctree)/include/config ]; then \
		echo >&2 "  $(srctree) is not clean, please run 'make mrproper'"; \
		echo >&2 "  in the '$(srctree)' directory.";\
		/bin/false; \
	fi;
endif

# prepare2 creates a makefile if using a separate output directory
prepare2: prepare3 outputmakefile

prepare1: prepare2 $(version_h) include/config/auto.conf
	$(cmd_crmodverdir)

archprepare: archheaders archscripts prepare1 scripts_basic

prepare0: archprepare FORCE
	$(Q)$(MAKE) $(build)=.

# All the preparing..
prepare: prepare0

# Generate some files
# ---------------------------------------------------------------------------

# KERNELRELEASE can change from a few different places, meaning version.h
# needs to be updated, so this check is forced on all builds

uts_len := 64
define filechk_utsrelease.h
	if [ `echo -n "$(KERNELRELEASE)" | wc -c ` -gt $(uts_len) ]; then \
	  echo '"$(KERNELRELEASE)" exceeds $(uts_len) characters' >&2;    \
	  exit 1;                                                         \
	fi;                                                               \
	(echo \#define UTS_RELEASE \"$(KERNELRELEASE)\";)
endef

define filechk_version.h
	(echo \#define LINUX_VERSION_CODE $(shell                         \
	expr $(VERSION) \* 65536 + 0$(PATCHLEVEL) \* 256 + 0$(SUBLEVEL)); \
	echo '#define KERNEL_VERSION(a,b,c) (((a) << 16) + ((b) << 8) + (c))';)
endef

$(version_h): $(srctree)/Makefile FORCE
	$(call filechk,version.h)

include/generated/utsrelease.h: include/config/kernel.release FORCE
	$(call filechk,utsrelease.h)

PHONY += headerdep
headerdep:
	$(Q)find $(srctree)/include/ -name '*.h' | xargs --max-args 1 \
	$(srctree)/scripts/headerdep.pl -I$(srctree)/include

# ---------------------------------------------------------------------------

PHONY += depend dep
depend dep:
	@echo '*** Warning: make $@ is unnecessary now.'

# ---------------------------------------------------------------------------
# Firmware install
INSTALL_FW_PATH=$(INSTALL_MOD_PATH)/lib/firmware
export INSTALL_FW_PATH

PHONY += firmware_install
firmware_install: FORCE
	@mkdir -p $(objtree)/firmware
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.fwinst obj=firmware __fw_install

# ---------------------------------------------------------------------------
# Kernel headers

#Default location for installed headers
export INSTALL_HDR_PATH = $(objtree)/usr

hdr-inst := -rR -f $(srctree)/scripts/Makefile.headersinst obj

# If we do an all arch process set dst to asm-$(hdr-arch)
hdr-dst = $(if $(KBUILD_HEADERS), dst=include/asm-$(hdr-arch), dst=include/asm)

PHONY += archheaders
archheaders:

PHONY += archscripts
archscripts:

PHONY += __headers
__headers: $(version_h) scripts_basic archheaders archscripts FORCE
	$(Q)$(MAKE) $(build)=scripts build_unifdef

PHONY += headers_install_all
headers_install_all:
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/headers.sh install

PHONY += headers_install
headers_install: __headers
	@echo 'headers_install ....do nothing'

PHONY += headers_check_all
headers_check_all: headers_install_all
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/headers.sh check

PHONY += headers_check
headers_check: headers_install
	@echo  'headers_check ...... do nothing'

#================================================
# Clean
# PHONY += $(clean-dirs) clean vmlinuxclean
# $(clean-dirs):
# 	$(Q)$(MAKE) $(clean)=$(patsubst _clean_%,%,$@)
# 
# vmlinuxclean:
# 	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/link-vmlinux.sh clean
# 
# clean: vmlinuxclean


