#!/usr/bin/env bash

export QEMU_AUDIO_DRV=none

check_qemu() {
  local qemu
  if [[ -n "$(pidof "qemu-system-arm")" ]] ||
    [[ -n "$(pidof "qemu-system-aarch64")" ]]; then
    qemu=1
  else
    qemu=0
  fi
  echo "${qemu}"
}

kill_qemu() {
  local qemu="$1"

  if [[ ${qemu} == "1" ]]; then
    echo -e "[$(green_bold "  OK  ")] Killing QEMU instances ..."
    if [[ -n "$(pidof "qemu-system-arm")" ]]; then
      for i in $(pidof "qemu-system-arm"); do
        sudo -E kill -15 "${i}"
      done
    else
      for i in $(pidof "qemu-system-aarch64"); do
        sudo -E kill -15 "${i}"
      done
    fi
  else
    echo -e "[$(cyan_bold " INFO ")] QEMU is not running ..."
  fi
}
