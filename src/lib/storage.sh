#!/usr/bin/env bash

check_storage() {
  local required_folders=("boot" "kernel" "root")

  for i in "${required_folders[@]}"; do
    if [[ -d "${STORAGE}/${args[model]}/${i}" ]]; then
      echo -e "[$(yellow_bold " WARN ")] ${args[model]}/${i} folder is present"
    else
      echo -e "[$(green_bold "  OK  ")] Creating ${args[model]}/${i} folder ..."
      mkdir -p "${STORAGE}/${args[model]}/${i}"
      chown -R "${USER}:${USER}" "${STORAGE}/${args[model]}/${i}"
    fi
  done
}

list_storage() {
  echo -e "[$(cyan_bold " INFO ")] Content of ${STORAGE}/${args[model]}"
  cyan_bold "$(ls -la "${STORAGE}/${args[model]}")"
}

check_fs() {
  local device1="$1"
  local device2="$2"
  echo -e "[$(green_bold "  OK  ")] Checking partitions to prevent failures ..."
  sudo -E fsck.vfat -f "${device1}"
  sudo -E fsck.ext4 -f "${device2}"
}

purge_storage() {
  local arch_sdcard_img="$1"
  local istatus="$2"

  if [[ ${istatus} != "2" ]]; then
    echo -e "[$(green_bold "  OK  ")] Soft cleaning ..."
    rm -rf "${arch_sdcard_img}"
    rm -rf "${STORAGE:?}/${args[model]}/kernel/image"
  fi
}

purge_storage_e() {
  echo -e "[$(green_bold "  OK  ")] Hard cleaning ..."
  rm -rf "${STORAGE:?}/${args[model]}/"
}

format_lo_devices() {
  local arch_sdcard_img="$1"
  local device1="$2"
  local device2="$3"

  echo -e "[$(green_bold "  OK  ")] Creating partitions on disk image named ${arch_sdcard_img##*/} ..."
  sudo -E mkfs.vfat -n boot -F 32 "${device1}" >/dev/null 2>&1
  sudo -E mkfs.ext4 -L rootfs "${device2}" >/dev/null 2>&1
}

mount_partitions() {
  local arch_sdcard_img="$1"
  local device1="$2"
  local device2="$3"
  local boot_path="$4"
  local root_path="$5"

  echo -e "[$(green_bold "  OK  ")] Mounting partitions of ${arch_sdcard_img##*/} ..."
  sudo -E mount "${device1}" "${boot_path}"
  sudo -E mount "${device2}" "${root_path}"
}

umount_partitions() {
  local arch_sdcard_img="$1"
  local boot_path="$2"
  local root_path="$3"
  echo -e "[$(green_bold "  OK  ")] Umounting partitions of ${arch_sdcard_img##*/} ..."
  sudo -E umount "${boot_path}"
  sudo -E umount "${root_path}"
}
