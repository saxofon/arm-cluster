# ARM cluster

Repo with lab bench setup of a cluster of virtual ARM nodes.
This could in a real live world scenario be a bunch of raspberry pi boards

## Prepare kernel
```
git clone https://github.com/raspberrypi/linux
ARCH=arm64 KERNEL=kernel8 CROSS_COMPILE=aarch64-linux-gnu- make bcm2711_defconfig
```
We need to enable VIRTIO stuff, add in-kernel config.gz as well for ease of use...
Things we want, enable as 'y'
```
ARCH=arm64 KERNEL=kernel8 CROSS_COMPILE=aarch64-linux-gnu- make menuconfig
```
```
ARCH=arm64 KERNEL=kernel8 CROSS_COMPILE=aarch64-linux-gnu- make -j 12 Image.gz dtbs
```

## Prepare initramfs
mount the raspios image partition1, steal initramfs8 from it.

## Bring cluster up
```
make cluster-up
```

## Bring cluster down
```
make cluster-down
```

## Add node to cluster
We can create a node X by using "make cluster-nodeX", like this for a first node :
```
make cluster-node1
```
and we can continue add more nodes as needed :
```
make cluster-node2
make cluster-node3
...
```

## node configuration
node1 example:
```
root@raspberrypi:~# cat /etc/network/interfaces.d/mgmt.conf
auto eth0
iface eth0 inet static
        address 192.168.101.11/24
root@raspberrypi:~# cat /etc/network/interfaces.d/data.conf
auto eth1
iface eth1 inet static
        address 192.168.102.11/24
root@raspberrypi:~# cat /etc/network/interfaces.d/internet.conf
auto eth2
iface eth2 inet dhcp
root@raspberrypi:~#
```
