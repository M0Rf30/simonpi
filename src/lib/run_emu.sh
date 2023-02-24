#!/usr/bin/env bash

run_rpi() {
  local arch_sdcard_img="$1"
  local cmd_line_network="$2"

  local qemu_rpi="qemu-system-arm \
    -nographic \
    -cpu arm1176 \
    -m 256 \
    -M versatilepb \
    -drive file=${arch_sdcard_img},if=scsi,format=raw,cache=none \
    -kernel ${STORAGE}/${args[model]}/kernel \
    -no-reboot \
    -append \"root=/dev/sda2 fstab=no rootfstype=ext4 rw console=ttyAMA0 quiet audit=0 panic=1\""

  qemu_rpi+="${cmd_line_network}"
  eval "${qemu_rpi}"
}

run_rpi-2() {
  local arch_sdcard_img="$1"
  local cmd_line_network="$2"

  local qemu_rpi2="qemu-system-arm \
    -nographic \
    -cpu cortex-a15 \
    -m 1024 \
    -M virt \
    -drive file=fat:rw:${STORAGE}/${args[model]}/kernel,if=none,format=raw,cache=none,id=hd0 \
    -device virtio-blk-device,drive=hd0,bootindex=0 \
    -drive file=${arch_sdcard_img},if=none,format=raw,cache=writeback,id=hd1 \
    -device virtio-blk-device,drive=hd1,bootindex=1 \
    -drive file=/usr/share/edk2-armvirt/arm/QEMU_CODE.fd,if=pflash,format=raw,readonly=on \
    -drive file=/usr/share/edk2-armvirt/arm/QEMU_VARS.fd,if=pflash,format=raw \
    -kernel ${STORAGE}/${args[model]}/kernel/image \
    -append \"root=/dev/vda2 rootfstype=ext4 rw audit=0 console=ttyAMA0\""

  qemu_rpi2+=${cmd_line_network}
  eval "${qemu_rpi2}"
}

run_rpi-3() {
  local arch_sdcard_img="$1"
  local cmd_line_network="$2"

  local qemu_rpi3="qemu-system-aarch64 \
    -nographic \
    -machine virt-5.0,accel=tcg,gic-version=3 \
    -cpu cortex-a57 \
    -m 2048 \
    -drive file=fat:rw:${STORAGE}/${args[model]}/kernel,if=none,format=raw,cache=none,id=hd0 \
    -device virtio-blk-device,drive=hd0,bootindex=0 \
    -drive file=${arch_sdcard_img},if=none,format=raw,cache=writeback,id=hd1 \
    -device virtio-blk-device,drive=hd1,bootindex=1 \
    -drive file=/usr/share/edk2-armvirt/aarch64/QEMU_CODE.fd,if=pflash,format=raw,readonly=on \
    -drive file=/usr/share/edk2-armvirt/aarch64/QEMU_VARS.fd,if=pflash,format=raw \
    -kernel ${STORAGE}/${args[model]}/kernel/image \
    -append \"root=/dev/vda2 rootfstype=ext4 rw audit=0 console=ttyAMA0\""

  qemu_rpi3+=${cmd_line_network}
  eval "${qemu_rpi3}"
}

run_rpi-4() {
  local arch_sdcard_img="$1"
  local cmd_line_network="$2"

  local qemu_rpi4="qemu-system-aarch64 \
    -nographic \
    -machine virt-5.0,accel=tcg,gic-version=3 \
    -cpu cortex-a57 \
    -m 2048 \
    -drive file=fat:rw:${STORAGE}/${args[model]}/kernel,if=none,format=raw,cache=none,id=hd0 \
    -device virtio-blk-device,drive=hd0,bootindex=0 \
    -drive file=${arch_sdcard_img},if=none,format=raw,cache=writeback,id=hd1 \
    -device virtio-blk-device,drive=hd1,bootindex=1 \
    -drive file=/usr/share/edk2-armvirt/aarch64/QEMU_CODE.fd,if=pflash,format=raw,readonly=on \
    -drive file=/usr/share/edk2-armvirt/aarch64/QEMU_VARS.fd,if=pflash,format=raw \
    -kernel ${STORAGE}/${args[model]}/kernel/image \
    -append \"root=/dev/vda2 rootfstype=ext4 rw audit=0 console=ttyAMA0\""

  qemu_rpi4+=${cmd_line_network}
  eval "${qemu_rpi4}"
}
