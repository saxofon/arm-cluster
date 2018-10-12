# Reference build of qemuarm64 platform for container cluster
#
# Author : Per Hallsmark <per.hallsmark@windriver.com>
#
#

TOP 		?= $(shell pwd)
#SHELL		?= /bin/bash

# Define V=1 to echo everything
V ?= 1
ifneq ($(V),1)
	Q=@
endif

RM = $(Q)rm -f

BASE_REL = sumo

POKY_URL = git://git.yoctoproject.org/poky.git
POKY_REL = $(BASE_REL)

OE_URL = https://github.com/openembedded/meta-openembedded.git
OE_REL = $(BASE_REL)
LAYERS += $(TOP)/build/layers/meta-openembedded/meta-oe
LAYERS += $(TOP)/build/layers/meta-openembedded/meta-python
LAYERS += $(TOP)/build/layers/meta-openembedded/meta-networking
LAYERS += $(TOP)/build/layers/meta-openembedded/meta-filesystems
LAYERS += $(TOP)/layers/meta-addons
#LAYERS += $(TOP)/layers/meta-downloads

VIRT_URL = git://git.yoctoproject.org/meta-virtualization
VIRT_REL = $(BASE_REL)
LAYERS += $(TOP)/build/layers/meta-virtualization

MACHINE=qemuarm64

IMAGE=core-image-full-cmdline

define bitbake
	cd build ; \
	. poky/oe-init-build-env ; \
	bitbake $(1)
endef

define bitbake-task
	cd build ; \
	. poky/oe-init-build-env ; \
	bitbake $(1) -c $(2)
endef

all: fs

$(TOP)/build/layers/meta-openembedded:
	git -C $(TOP)/build/layers clone $(OE_URL)
	git -C $@ checkout $(VIRT_REL)

$(TOP)/build/layers/meta-openembedded/meta-oe: $(TOP)/build/layers/meta-openembedded
$(TOP)/build/layers/meta-openembedded/meta-python: $(TOP)/build/layers/meta-openembedded
$(TOP)/build/layers/meta-openembedded/meta-networking: $(TOP)/build/layers/meta-openembedded
$(TOP)/build/layers/meta-openembedded/meta-filesystems: $(TOP)/build/layers/meta-openembedded

$(TOP)/build/layers/meta-virtualization:
	git -C $(TOP)/build/layers clone $(VIRT_URL)
	git -C $@ checkout $(VIRT_REL)

# create wrlinux platform
.PHONY: build
build:
	$(Q)if [ ! -d $@ ]; then \
		mkdir -p $@/layers ; \
		cd $@ ; \
		git clone $(POKY_URL) ; \
		git -C poky checkout $(POKY_REL) ; \
	fi

# create bitbake build
#		$(foreach layer, $(LAYERS), bitbake-layers add-layer $(layer);)
.PHONY: build/build
build/build: build $(LAYERS)
	$(Q)if [ ! -d $@ ]; then \
		cd build ; \
		. poky/oe-init-build-env ; \
		bitbake-layers add-layer $(LAYERS) ; \
		sed -i s/^MACHINE.*/MACHINE\ =\ \"$(MACHINE)\"/g conf/local.conf ; \
		echo "DISTRO_FEATURES_append = \" virtualization\"" >> conf/local.conf ; \
	fi

bbs: build/build
	$(Q)cd build ; \
	. poky/oe-init-build-env ; \
	bash || true

fs: build/build
	$(call bitbake, $(IMAGE))

sdk: build/build
	$(call bitbake-task, $(IMAGE), populate_sdk)

esdk: build/build
	$(call bitbake-task, $(IMAGE), populate_sdk_ext)

clean:
	$(RM) -r build/build

distclean:
	$(RM) -r build
