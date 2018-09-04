_TOP=$(dirname $0)
TOP=$(readlink -f $_TOP/..)

mkdir -p ${TOP}/build/sim
SUBNETS="clustermgmt payload"

subnet_create()
{
  net=100
  for subnet in $SUBNETS; do
    echo "Creating subnet $subnet"
    sudo ip link add $subnet type bridge
    sudo ip addr add 192.168.${net}.254/24 broadcast 192.168.255.255 dev $subnet
    sudo ip link set up dev $subnet
    net=$((net+1))
    ln -s ${TOP}/simulator/template.ifup ${TOP}/build/sim/$subnet.ifup
    ln -s ${TOP}/simulator/template.ifdown ${TOP}/build/sim/$subnet.ifdown
  done
}

subnet_stop()
{
  for subnet in $SUBNETS; do
    echo "Removing subnet $subnet"
    sudo ip link set down dev $subnet
    sudo ip link del $subnet
    net=$((net+1))
  done
}

case $1 in
  start)
    subnet_create
    ;;
  stop)
    subnet_stop
    ;;
esac
