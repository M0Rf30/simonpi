#!/usr/bin/env bash

arch_sdcard_img="${STORAGE}/sd-arch-${args[model]}-qemu.img"
docker="$(check_docker)"
istatus="$(img_status)"
pstatus="$(partition_status)"
device1=$(sudo -E losetup -f)
device2=/dev/loop$((${device1##*/loop} + 1))
boot_path="${STORAGE}/${args[model]}/boot"
root_path="${STORAGE}/${args[model]}/root"
cmd_line=""
cmd_line_network=""
custom_image="${args[--path]}"

# Network Variables
bridge_if="rasp-br0"
tap_if="rasp-tap0"
gateway_ip="192.168.66.1"
first_ip="${gateway_ip%.1}.2"
last_ip="${gateway_ip%.1}.254"
broadcast_ip="${gateway_ip%.1}.255"
guest_port_1="22"
external_port_1="2222"
guest_port_2="80"
external_port_2="8080"

check_kernel
if [[ -n ${custom_image} ]]; then
  run_custom_img "${custom_image}"
  arch_sdcard_img="${custom_image}"
fi

if [[ ${istatus} == "0" ]] && [[ ${pstatus} == "0" ]]; then
  check_root
  check_loop_devices "${device2}"
  mount_img "${arch_sdcard_img}" "${device1}" "${device2}"
  check_fs "${device1}" "${device2}"
  check_storage
  mount_partitions "${arch_sdcard_img}" "${device1}" "${device2}" "${boot_path}" "${root_path}"
elif [[ ${istatus} == "1" ]] && [[ ${pstatus} == "0" ]]; then
  check_root
  check_loop_devices "${device2}"
  check_fs "${device1}" "${device2}"
  check_storage
  mount_partitions "${arch_sdcard_img}" "${device1}" "${device2}" "${boot_path}" "${root_path}"
fi

if [[ -n ${args[--path]} ]]; then
  cmd_line=" -initrd ${boot_path}/initramfs-linux.img"
fi

if [[ ${docker} == "0" ]]; then
  check_root
  create_network "${tap_if}" "${bridge_if}" "${gateway_ip}" "${broadcast_ip}"
  check_dnsmasq "${gateway_ip}"
  setup_dnsmasq "${gateway_ip}" "${first_ip}" "${last_ip}" "${bridge_if}"
  setup_nat

  if [[ ${args[model]} == "rpi" ]]; then
    cmd_line_network="${cmd_line} -net nic,macaddr=$(generate_mac) -net tap,ifname=${tap_if},script=no,downscript=no"
  else
    cmd_line_network="${cmd_line} -device virtio-net-device,mac=$(generate_mac),netdev=net0 -netdev tap,id=net0,ifname=${tap_if},script=no,downscript=no"
  fi

else

  if [[ ${args[model]} == "rpi" ]]; then
    cmd_line_network="${cmd_line} -net nic,macaddr=$(generate_mac) -net user,hostfwd=tcp::${external_port_1}-:${guest_port_1},hostfwd=tcp::${external_port_2}-:${guest_port_2}"
  else
    cmd_line_network="${cmd_line} -device virtio-net-device,mac=$(generate_mac),netdev=net0 -netdev user,id=net0,hostfwd=tcp::${external_port_1}-:${guest_port_1},hostfwd=tcp::${external_port_2}-:${guest_port_2}"
  fi

fi

# write_pflash_images
run_"${args[model]}" "${arch_sdcard_img}" "${cmd_line_network}"
umount_partitions "${arch_sdcard_img}" "${boot_path}" "${root_path}"
umount_img
qemu_status="$(check_qemu)"

if [[ ${docker} == "0" ]] && [[ ${qemu_status} == "0" ]]; then
  dnsmasq_pid=$(check_dnsmasq "${gateway_ip}")
  kill_dnsmasq "${dnsmasq_pid}"
  shutdown_network "${bridge_if}" "${tap_if}"
fi
