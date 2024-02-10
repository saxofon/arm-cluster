OS_IMG_URL = https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2023-12-11/2023-12-11-raspios-bookworm-arm64-lite.img.xz

QEMU = qemu-system-aarch64

QEMU_OPTS += -M virt -cpu cortex-a53 -smp 4
QEMU_OPTS += -m 1024
QEMU_OPTS += -nographic -monitor none -serial mon:stdio
QEMU_OPTS += -no-reboot
#QEMU_OPTS += -device virtio-serial-device
#QEMU_OPTS += -device virtconsole,chardev=ser0
#QEMU_OPTS += -chardev stdio,id=ser0,signal=off
# network devices get enumerated in opposite order here
QEMU_OPTS += -netdev user,id=cluster-internet,ipv4=on,ipv6=off,hostname="node$(IDX)"
QEMU_OPTS += -device virtio-net-device,netdev=cluster-internet,mac=52:55:00:12:$(shell printf "%2.2x" $(IDX)):03
QEMU_OPTS += -netdev tap,id=cluster-data,script=build/network/cluster-data.ifup,downscript=build/network/cluster-data.ifdown
QEMU_OPTS += -device virtio-net-device,netdev=cluster-data,mac=52:55:00:12:$(shell printf "%2.2x" $(IDX)):02
QEMU_OPTS += -netdev tap,id=cluster-mgmt,script=build/network/cluster-mgmt.ifup,downscript=build/network/cluster-mgmt.ifdown
QEMU_OPTS += -device virtio-net-device,netdev=cluster-mgmt,mac=52:55:00:12:$(shell printf "%2.2x" $(IDX)):01
QEMU_OPTS += -drive id=disk0,file=build/node/$(IDX)/disk,if=none,format=raw
QEMU_OPTS += -device virtio-blk-device,drive=disk0
QEMU_OPTS += -kernel build/kernel8.img
QEMU_OPTS += -initrd build/initramfs8

QEMU_APPEND += console=ttyAMA0
QEMU_APPEND += root=/dev/vda2 rw rootwait
QEMU_APPEND += highres=off

build/os.xz:
	curl  $(OS_IMG_URL) -o $@

build/os.img: build/os.xz
	unxz $<

build/kernel8.img: build/os.img
	mkdir -p mnt
	sudo mount -o loop,offset=$$((512*8192)) $< mnt
	cp mnt/kernel8.img $@
	sudo umount -d mnt
	rmdir mnt

build/initramfs8: build/os.img
	mkdir -p mnt
	sudo mount -o loop,offset=$$((512*8192)) $< mnt
	cp mnt/initramfs8 $@
	sudo umount -d mnt
	rmdir mnt

#node%: build/kernel8.img build/initramfs8
node%: IDX=$(strip $*)
node%:
	mkdir -p build/node/$(IDX)
	if [ ! -f build/node/$(IDX)/disk ]; then \
		cp build/os.img build/node/$(IDX)/disk ; \
		fallocate -l 10G build/node/$(IDX)/disk ; \
		parted build/node/$(IDX)/disk resizepart 2 10G ; \
		mkdir -p build/node/$(IDX)/mnt ; \
		sudo mount -o loop,offset=$$((512*8192)) build/node/$(IDX)/disk build/node/$(IDX)/mnt ; \
		echo 'pi:$(shell echo tjosan | openssl passwd -6 -stdin)' | sudo tee build/node/$(IDX)/mnt/userconf.txt ; \
		sudo touch build/node/$(IDX)/mnt/ssh ; \
		sudo umount -d build/node/$(IDX)/mnt ; \
		rmdir build/node/$(IDX)/mnt ; \
	fi
	sudo $(QEMU) $(QEMU_OPTS) -append "$(QEMU_APPEND)"
