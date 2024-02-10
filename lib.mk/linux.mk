build/linux/Makefile:
	git -C build clone https://github.com/raspberrypi/linux

build/linux/.config: build/linux/Makefile
	ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make -C build/linux bcm2711_defconfig

.PHONY: linux-config
linux-config: build/linux/.config
	echo "CONFIG_VIRTIO_CONSOLE=y" >> build/linux/.config
	echo "CONFIG_VIRTIO_BLK=y" >> build/linux/.config
	echo "CONFIG_VIRTIO_NET=y" >> build/linux/.config
	echo "CONFIG_VIRTIO_PCI=y" >> build/linux/.config
	echo "CONFIG_VIRTIO_BALLOON=y" >> build/linux/.config
	echo "CONFIG_VIRTIO_MMIO=y" >> build/linux/.config
	echo "CONFIG_IKCONFIG=y" >> build/linux/.config
	ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make -C build/linux olddefconfig

build/linux/arch/arm64/boot/Image.gz: build/linux/.config
	if ! grep -q CONFIG_VIRTIO_CONSOLE=y build/linux/.config; then \
		make linux-config ; \
	fi
	ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make -C build/linux -j $(shell nproc) Image.gz modules dtbs
	ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make -C build/linux -j $(shell nproc) modules_install INSTALL_MOD_PATH=$(TOP)/build/staging
