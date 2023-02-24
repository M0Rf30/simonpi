#!/usr/bin/env bash

integrity_check() {
  local arch_iso_md5="$1"

  cd "${STORAGE}/${args[model]}" || exit

  if md5sum --status -c "${arch_iso_md5}"; then
    echo -e "[$(green_bold "  OK  ")] Integrity check successfully completed"
  else
    echo -e "[$(red_bold "FAILED")] Integrity check failed, please retry to download"
    exit 1
  fi
}

download_arch_image() {
  local arch_iso_md5="$1"
  local files=("${arch_iso_md5}" "${arch_iso_md5%%.md5}")

  for i in "${files[@]}"; do
    echo -e "[$(cyan_bold " INFO ")] Downloading latest iso for ${args[model]}..."
    curl -# -L -C - "http://os.archlinuxarm.org/os/${i}" \
      -o "${STORAGE}/${args[model]}/${i}"
  done
}

download_kernel_image() {
  local kernel_image="qemu_kernel_${args[model]//-/_}"
  local files=("${arch_iso_md5}" "${arch_iso_md5%%.md5}")
  local version

  if [[ -f "${STORAGE}/${args[model]}/kernel/image" ]]; then
    rm "${STORAGE}/${args[model]}/kernel/image"
  fi

  if [[ ${args[model]#*-} -gt "3" ]]; then
    kernel_image="qemu_kernel_rpi_3"
  fi

  version="$(curl -L -s -H 'Accept: application/json' \
    https://github.com/M0Rf30/"${kernel_image//_/-}"/releases/latest |
    sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')"

  echo -e "[$(cyan_bold " INFO ")] Downloading latest kernel for ${args[model]}..."
  curl -# -L -C - \
    "https://github.com/M0Rf30/${kernel_image//_/-}/releases/download/${version}/${kernel_image}-${version}" \
    -o "${STORAGE}/${args[model]}/kernel/image"
}

partition_status() {
  local arch_sdcard_img="${STORAGE}/sd-arch-${args[model]}-qemu.img"
  local custom_sdcard_img="${args[--path]}"
  local part_mounted=0

  if [[ -n ${custom_sdcard_img} ]]; then
    arch_sdcard_img="${custom_sdcard_img}"
  fi

  if mount | grep "${STORAGE}/${args[model]}" >/dev/null; then
    part_mounted=1
  elif ! mount | grep "${STORAGE}/${args[model]}" >/dev/null &&
    [[ -n ${LOOPFLAG} ]]; then
    part_mounted=0
  elif [[ ! -f ${arch_sdcard_img} ]]; then
    part_mounted=2
  fi
  echo "${part_mounted}"
}

img_status() {
  local arch_sdcard_img="${STORAGE}/sd-arch-${args[model]}-qemu.img"
  local custom_sdcard_img="${args[--path]}"
  local img_mounted=0

  if [[ -n ${custom_sdcard_img} ]]; then
    arch_sdcard_img="${custom_sdcard_img}"
  fi

  if mount | grep "${STORAGE}/${args[model]}" >/dev/null; then
    img_mounted=1
  elif [[ ! -f ${arch_sdcard_img} ]]; then
    img_mounted=2
  fi
  echo "${img_mounted}"
}

mount_img() {
  local arch_sdcard_img="$1"
  local device1="$2"
  local device2="$3"

  local start1
  start1=$(fdisk -lo Start "${arch_sdcard_img}" | tail -n 2 | head -n -1)
  local start2
  start2=$(fdisk -lo Start "${arch_sdcard_img}" | tail -n 1)
  local length1
  length1=$(fdisk -lo Sectors "${arch_sdcard_img}" | tail -n 2 | head -n -1)
  local length2
  length2=$(fdisk -lo Sectors "${arch_sdcard_img}" | tail -n 1)

  echo -e "[$(green_bold "  OK  ")] Mounting disk image named ${arch_sdcard_img##*/} ..."
  sudo -E losetup -o $((start1 * 512)) --sizelimit $((length1 * 512)) \
    "${device1}" "${arch_sdcard_img}" >/dev/null 2>&1
  sudo -E losetup -o $((start2 * 512)) --sizelimit $((length2 * 512)) \
    "${device2}" "${arch_sdcard_img}" >/dev/null 2>&1
}

umount_img() {
  sudo -E losetup -D
  echo -e "[$(green_bold "  OK  ")] Unmounting disk image named ${arch_sdcard_img##*/} ..."
}

write_pflash_images() {
  if [ ! -f "${STORAGE}/${args[model]}/flash0.img" ]; then
    dd if=/dev/zero bs=1M count=64 of="${STORAGE}/flash0.img"
    dd if=/dev/zero bs=1M count=64 of="${STORAGE}/flash1.img"
    dd if=/usr/share/edk2-armvirt/aarch64/QEMU_CODE.fd \
      of="${STORAGE}/${args[model]}/flash0.img" bs=1M conv=notrunc
    dd if=/usr/share/edk2-armvirt/aarch64/QEMU_VARS.fd \
      of="${STORAGE}/${args[model]}/flash1.img" bs=1M conv=notrunc
  fi
}

run_custom_img() {
  local custom_img="$1"

  if [ ! -f "${custom_img}" ]; then
    echo -e "[$(red_bold "FAILED")] File not found"
    exit 1
  elif [ "$(file "${custom_img}" | cut -d ' ' -f 2)" != "DOS/MBR" ]; then
    echo -e "[$(red_bold "FAILED")] Please specify a valid disk image"
    exit 1
  else
    echo -e "[$(green_bold "  OK  ")] Running with disk image named ${custom_img##*/}"
  fi
}
