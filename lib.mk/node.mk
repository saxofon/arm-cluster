OS_IMG_URL = https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2023-12-11/2023-12-11-raspios-bookworm-arm64-lite.img.xz

QEMU = qemu-system-aarch64

QEMU_OPTS += -name node$(IDX)
QEMU_OPTS += -M virt -cpu cortex-a53 -smp 4
QEMU_OPTS += -m 1024
QEMU_OPTS += -nographic -monitor none -serial mon:stdio
QEMU_OPTS += -no-reboot
#QEMU_OPTS += -device virtio-serial-device
#QEMU_OPTS += -device virtconsole,chardev=ser0
#QEMU_OPTS += -chardev stdio,id=ser0,signal=off
# network devices get enumerated in opposite order here
QEMU_OPTS += -netdev user,id=cluster-internet,ipv4=on,ipv6=off
QEMU_OPTS += -device virtio-net-device,netdev=cluster-internet,mac=00:01:02:03:02:$(shell printf "%2.2x" $(IDX))
QEMU_OPTS += -netdev tap,id=cluster-data,script=build/network/cluster-data.ifup,downscript=build/network/cluster-data.ifdown,ifname=data-$(IDX)
QEMU_OPTS += -device virtio-net-device,netdev=cluster-data,mac=00:01:02:03:01:$(shell printf "%2.2x" $(IDX))
QEMU_OPTS += -netdev tap,id=cluster-mgmt,script=build/network/cluster-mgmt.ifup,downscript=build/network/cluster-mgmt.ifdown,ifname=mgmt-$(IDX)
QEMU_OPTS += -device virtio-net-device,netdev=cluster-mgmt,mac=00:01:02:03:00:$(shell printf "%2.2x" $(IDX))
QEMU_OPTS += -drive id=disk0,file=build/node/$(IDX)/disk,if=none,format=raw
QEMU_OPTS += -device virtio-blk-device,drive=disk0
QEMU_OPTS += -kernel build/kernel
QEMU_OPTS += -initrd build/initrd

QEMU_APPEND += console=ttyAMA0
QEMU_APPEND += root=/dev/vda2 rw rootwait
QEMU_APPEND += highres=off
QEMU_APPEND += hostname=node$(IDX)

.PRECIOUS: build/os.img.xz
build/os.img.xz:
	curl $(OS_IMG_URL) -o $@

.PRECIOUS: build/os.img
build/os.img: build/os.img.xz
	unxz -k $<

# In the optimal world raspios would come with a kernel that supports VIRTIO usecases
#build/kernel: build/os.img
	#mkdir -p build/mnt/boot
	#sudo mount -o loop,offset=$$(parted -j build/os.img unit B print | jq -r '.disk.partitions[0].start' | sed 's/.$$//'),sizelimit=$$(parted -j build/os.img unit B print | jq -r '.disk.partitions[0].size' | sed 's/.$$//') $< build/mnt/boot
	#cp mnt/boot/kernel8.img $@
	#sudo umount -d build/mnt/boot
	#rmdir build/mnt/boot
# instead we have to rebuild our kernel ourself...
.PRECIOUS: build/kernel
build/kernel: build/linux/arch/arm64/boot/Image.gz
	cp $< $@

.PRECIOUS: build/kernel-modules.tar.bz2
build/kernel-modules.tar.bz2: build/linux/arch/arm64/boot/Image.gz
	tar -C build/staging/lib/modules -cf $(TOP)/build/kernel-modules.tar.bz2 .

.PRECIOUS: build/initrd
build/initrd: build/os.img
	mkdir -p build/mnt/boot
	sudo mount -o loop,offset=$$(parted -j build/os.img unit B print | jq -r '.disk.partitions[0].start' | sed 's/.$$//'),sizelimit=$$(parted -j build/os.img unit B print | jq -r '.disk.partitions[0].size' | sed 's/.$$//') $< build/mnt/boot
	cp build/mnt/boot/initramfs8 $@
	sudo umount -d build/mnt/boot
	rmdir build/mnt/boot

# node should be stopped before attempting mounting disk in host
.PHONY: node%-mount
node%-mount: IDX=$(strip $*)
node%-mount:
	mkdir -p build/node/$(IDX)/mnt/boot
	mkdir -p build/node/$(IDX)/mnt/rootfs
	sudo mount -o loop,offset=$$(parted -j build/node/$(IDX)/disk unit B print | jq -r '.disk.partitions[0].start' | sed 's/.$$//'),sizelimit=$$(parted -j build/node/$(IDX)/disk unit B print | jq -r '.disk.partitions[0].size' | sed 's/.$$//') build/node/$(IDX)/disk build/node/$(IDX)/mnt/boot
	sudo mount -o loop,offset=$$(parted -j build/node/$(IDX)/disk unit B print | jq -r '.disk.partitions[1].start' | sed 's/.$$//'),sizelimit=$$(parted -j build/node/$(IDX)/disk unit B print | jq -r '.disk.partitions[1].size' | sed 's/.$$//') build/node/$(IDX)/disk build/node/$(IDX)/mnt/rootfs

.PHONY: node%-umount
node%-umount: IDX=$(strip $*)
node%-umount:
	sudo umount -d build/node/$(IDX)/mnt/rootfs
	sudo umount -d build/node/$(IDX)/mnt/boot
	rmdir build/node/$(IDX)/mnt/rootfs
	rmdir build/node/$(IDX)/mnt/boot

.PRECIOUS: build/node/%/disk
build/node/%/disk: IDX=$(strip $*)
build/node/%/disk:
	if [ ! -f $@ ]; then \
		mkdir -p build/node/$(IDX) ; \
		cp build/os.img build/node/$(IDX)/disk ; \
		fallocate -l 10G build/node/$(IDX)/disk ; \
		parted build/node/$(IDX)/disk resizepart 2 10G ; \
		mkdir -p build/node/$(IDX)/mnt/boot ; \
		mkdir -p build/node/$(IDX)/mnt/rootfs ; \
		sudo mount -o loop,offset=$$(parted -j build/node/$(IDX)/disk unit B print | jq -r '.disk.partitions[0].start' | sed 's/.$$//'),sizelimit=$$(parted -j build/node/$(IDX)/disk unit B print | jq -r '.disk.partitions[0].size' | sed 's/.$$//') build/node/$(IDX)/disk build/node/$(IDX)/mnt/boot ; \
		sudo mount -o loop,offset=$$(parted -j build/node/$(IDX)/disk unit B print | jq -r '.disk.partitions[1].start' | sed 's/.$$//'),sizelimit=$$(parted -j build/node/$(IDX)/disk unit B print | jq -r '.disk.partitions[1].size' | sed 's/.$$//') build/node/$(IDX)/disk build/node/$(IDX)/mnt/rootfs ; \
		echo 'pi:$(shell echo tjosan | openssl passwd -6 -stdin)' | sudo tee build/node/$(IDX)/mnt/boot/userconf.txt ; \
		sudo touch build/node/$(IDX)/mnt/boot/ssh ; \
		sudo cp build/network/*.conf build/node/$(IDX)/mnt/rootfs/etc/network/interfaces.d ; \
		sudo sed -i s/IDX/$(IDX)/g build/node/$(IDX)/mnt/rootfs/etc/network/interfaces.d/*.conf ; \
		sudo tar -C build/node/$(IDX)/mnt/rootfs/lib/modules -xf $(TOP)/build/kernel-modules.tar.bz2 ; \
		echo "node$(IDX)" | sudo tee build/node/$(IDX)/mnt/rootfs/etc/hostname ; \
		sudo sed -i s/raspberrypi/node$(IDX)/g build/node/$(IDX)/mnt/rootfs/etc/hosts ; \
		sync ; \
		sudo umount -d build/node/$(IDX)/mnt/rootfs ; \
		sudo umount -d build/node/$(IDX)/mnt/boot ; \
		rmdir build/node/$(IDX)/mnt/rootfs ; \
		rmdir build/node/$(IDX)/mnt/boot ; \
	fi

.PHONY: node%-up
node%-up: IDX=$(strip $*)
node%-up:
node%-up: build/kernel
node%-up: build/kernel-modules.tar.bz2
node%-up: build/initrd
node%-up: build/node/%/disk
	sudo $(QEMU) $(QEMU_OPTS) -append "$(QEMU_APPEND)"

.PHONY: node%-shell
node%-shell: IDX=$(strip $*)
node%-shell:
	sshpass -p tjosan ssh pi@192.168.100.$(IDX)

.PHONY: node%-kill
node%-kill: IDX=$(strip $*)
node%-kill:
	sudo kill $(shell ps -ef | grep "name node$(IDX)" | awk '{print $$2}')

.PHONY: node%-down
node%-down: IDX=$(strip $*)
node%-down:
	sshpass -p tjosan ssh pi@192.168.100.$(IDX) sudo su -c poweroff

.PHONY: node%-delete
node%-delete: IDX=$(strip $*)
node%-delete:
	if (losetup | grep -q build/node/$(IDX)/disk); then \
		make node$(IDX)-umount ; \
	fi
	rm -rf build/node/$(IDX)

