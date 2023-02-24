#!/usr/bin/env bash

write_sdcard_img() {
  local arch_sdcard_img="${1}"

  if [[ -e ${arch_sdcard_img} ]]; then
    echo -e "[$(yellow_bold " WARN ")] An ${arch_sdcard_img##*/} file already exists. Please delete it"
    exit 1
  else
    echo -e "[$(green_bold "  OK  ")] Creating a ${args[--size]} GB disk image named ${arch_sdcard_img##*/} ..."
    qemu-img create -f raw "${arch_sdcard_img}" "${args[--size]}"G >/dev/null
    echo -e "[$(green_bold "  OK  ")] Creating partition table on ${arch_sdcard_img##*/} ..."
    (
      echo o
      echo n
      echo p
      echo 1
      echo 8192
      echo +100M
      echo t
      echo c
      echo n
      echo p
      echo 2
      echo 8192
      echo
      echo
      echo w
    ) |
      fdisk "${arch_sdcard_img}" >/dev/null 2>&1
  fi
}

extract_arch() {
  local arch_iso="${1}"
  local arch_sdcard_img="${2}"
  local boot_path="${3}"
  local root_path="${4}"

  echo -e "[$(green_bold "  OK  ")] Extracting ${arch_iso} to ${arch_sdcard_img##*/} ..."
  sudo bsdtar --exclude=^boot -xpf "${STORAGE}/${args[model]}/${arch_iso}" -C "${root_path}"
  sudo bsdtar -xpf "${STORAGE}/${args[model]}/${arch_iso}" boot/* -C "${boot_path}" >/dev/null 2>&1
}

isaNumber='^[0-9]+$'

if ! [[ ${args[--size]} =~ ${isaNumber} ]] || [[ -z ${args[--size]} ]]; then
  echo -e "[$(red_bold "FAILED")] Please specify a size in GB"
  exit 1
elif [[ ${args[--size]} -lt 2 ]]; then
  echo -e "[$(red_bold "FAILED")] Please specify a size >= 2 GB"
  exit 1
fi

case "${args[model]}" in
rpi)
  echo -e "[$(red_bold "FAILED")] ARMv5 and ARMv6 architectures are not supported anymore"
  echo -e "[$(cyan_bold " INFO ")] You can still run whatever sdcard image with --path flag"
  exit 1
  ;;
rpi-2)
  iso_type="rpi-armv7"
  ;;
*)
  iso_type="rpi-aarch64"
  ;;
esac

arch_iso_md5="ArchLinuxARM-${iso_type}-latest.tar.gz.md5"
arch_sdcard_img="${STORAGE}/sd-arch-${args[model]}-qemu.img"

boot_path="${STORAGE}/${args[model]}/boot"
root_path="${STORAGE}/${args[model]}/root"

device1=$(sudo -E losetup -f)
device2=/dev/loop$((${device1##*/loop} + 1))

check_storage
download_arch_image "${arch_iso_md5}"
integrity_check "${arch_iso_md5}"
partition_status
img_status
write_sdcard_img "${arch_sdcard_img}"
sync
check_root
mount_img "${arch_sdcard_img}" "${device1}" "${device2}"
check_loop_devices "${device2}"
format_lo_devices "${arch_sdcard_img}" "${device1}" "${device2}"
sync
mount_partitions "${arch_sdcard_img}" "${device1}" "${device2}" "${boot_path}" "${root_path}"
extract_arch "${arch_iso_md5%%.md5}" "${arch_sdcard_img}" "${boot_path}" "${root_path}"
# customContent
sync
umount_partitions "${arch_sdcard_img}" "${boot_path}" "${root_path}"
umount_img
sudo chown "${USER}:${USER}" "${arch_sdcard_img}"
echo -e "[$(green_bold "  OK  ")] DONE"
