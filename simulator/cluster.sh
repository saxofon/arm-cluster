_TOP=$(dirname $0)
TOP=$(readlink -f $_TOP/..)

MACHINE=qemuarm64

KERNEL=$TOP/yocto/build/build/tmp/deploy/images/${MACHINE}/Image
DISK=$TOP/yocto/build/build/tmp/deploy/images/${MACHINE}/core-image-full-cmdline-qemuarm64.ext4

mkdir -p ${TOP}/build/sim
cp ${KERNEL} ${TOP}/build/sim/kernel

setup_tmux()
{
  tmux new-session -d -s arm-cluster
  tmux set-option -t arm-cluster set-titles on
  tmux set-option -t arm-cluster set-titles-string arm-cluster
}

setup_instance()
{
  IDX=$1

  if [ ! -f ${TOP}/build/sim/disk-${IDX} ]; then
    cp ${DISK} ${TOP}/build/sim/disk-${IDX}
  fi
}

run_instance()
{
  IDX=$1

  QEMU="qemu-system-aarch64"

  QEMU_OPTS=" -machine virt -cpu cortex-a53"
  QEMU_OPTS+=" -m 2048"
  QEMU_OPTS+=" -nographic -monitor none -serial none"
  QEMU_OPTS+=" -device virtio-serial-device"
  QEMU_OPTS+=" -device virtconsole,chardev=ser0"
  QEMU_OPTS+=" -chardev stdio,id=ser0,signal=off"
  QEMU_OPTS+=" -netdev tap,id=clustermgmt,script=${TOP}/build/sim/clustermgmt.ifup,downscript=${TOP}/build/sim/clustermgmt.ifdown"
  QEMU_OPTS+=" -device virtio-net-device,netdev=clustermgmt,mac=52:55:00:12:$(printf "%2.2x" ${IDX}):01"
  QEMU_OPTS+=" -netdev tap,id=payload,script=${TOP}/build/sim/payload.ifup,downscript=${TOP}/build/sim/payload.ifdown"
  QEMU_OPTS+=" -device virtio-net-device,netdev=payload,mac=52:55:00:12:$(printf "%2.2x" ${IDX}):02"
  QEMU_OPTS+=" -drive id=disk0,file=${TOP}/build/sim/disk-${IDX},if=none,format=raw"
  QEMU_OPTS+=" -device virtio-blk-device,drive=disk0"
  QEMU_OPTS+=" -kernel ${TOP}/build/sim/kernel"

  QEMU_OPTS_APPEND=" console=hvc0"
  QEMU_OPTS_APPEND+=" mem=2G"
  QEMU_OPTS_APPEND+=" root=/dev/vda rw"
  QEMU_OPTS_APPEND+=" highres=off"
  QEMU_OPTS_APPEND+=" ip=192.168.100.${IDX}::192.168.100.254:255.255.255.0:host${IDX}:eth1"
  tmux split-window -t arm-cluster -h "sudo ${QEMU} ${QEMU_OPTS} -append \"${QEMU_OPTS_APPEND}\" ; read"
}

setup_tmux

setup_instance 1
setup_instance 2
setup_instance 3

run_instance 1
run_instance 2
run_instance 3
