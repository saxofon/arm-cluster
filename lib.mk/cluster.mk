define deploy-node
	tmux split-window -t rpi-cluster -h make node$(1)-up
endef

define nic-subnet-up
	mkdir -p build/network
	echo '#!/bin/sh' > build/network/$(1).ifup
	echo 'nic=$$1' >> build/network/$(1).ifup
	echo 'ip link set $$nic up' >> build/network/$(1).ifup
	echo 'sleep 0.5s' >> build/network/$(1).ifup
	echo 'ip link set $$nic master' $(1) >> build/network/$(1).ifup
	chmod 755 build/network/$(1).ifup
endef

define nic-subnet-down
	mkdir -p build/network
	echo '#!/bin/sh' > build/network/$(1).ifdown
	echo 'nic=$$1' >> build/network/$(1).ifdown
	echo 'ip link set $$nic nomaster' >> build/network/$(1).ifdown
	echo 'ip link set $$nic down' >> build/network/$(1).ifdown
	chmod 755 build/network/$(1).ifdown
endef

define cluster-subnet-up
	sudo ip link add $(1) type bridge
	sudo ip addr add 192.168.$(2).254/24 broadcast 192.168.255.255 dev $(1)
	sudo ip link set up dev $(1)
	$(call nic-subnet-up,$(1))
	$(call nic-subnet-down,$(1))
	echo "auto $(3)" > build/network/$(1).conf
	echo "iface $(3) inet static" >> build/network/$(1).conf
	echo "  address 192.168.$(2).IDX/24" >> build/network/$(1).conf
endef

define cluster-subnet-down
	sudo ip link set down dev $(1)
	sudo ip link del $(1)
endef

cluster-up:
	tmux new-session -d -s rpi-cluster
	tmux set-option -t rpi-cluster set-titles on
	tmux set-option -t rpi-cluster set-titles-string rpi-cluster
	$(call cluster-subnet-up,cluster-mgmt,100,eth0)
	$(call cluster-subnet-up,cluster-data,101,eth1)
	echo "auto eth2" > build/network/internet.conf
	echo "iface eth2 inet dhcp" >> build/network/internet.conf
	

cluster-down:
	$(call cluster-subnet-down,cluster-mgmt)
	$(call cluster-subnet-down,cluster-data)
	rm -rf build/network
	tmux kill-session -t rpi-cluster

cluster-info:
	tmux list-sessions

cluster-view:
	tmux attach-session -t rpi-cluster

cluster-node%:
	$(call deploy-node,$*)
