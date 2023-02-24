#!/usr/bin/env bash

# Must be root for some ops
check_root() {
  if [[ $(sudo whoami) != "root" ]]; then
    echo -e "[$(red_bold "FAILED")] Sim-on-Pi will not continue"
    echo -e "[$(red_bold "FAILED")] Please type your user password or run this script as root"
    exit 1
  fi
}

check_kernel() {
  if [[ ! -f "${STORAGE}/${args[model]}/kernel/image" ]]; then
    echo -e "[$(red_bold "FAILED")] Sim-on-Pi will not continue"
    echo -e "[$(cyan_bold " INFO ")] Please download an appropriate kernel with kernel command"
    exit 1
  fi
}

check_loop_devices() {
  local device2="${1}"
  if [[ ${device2##*/loop} -gt 5 ]]; then
    echo -e "[$(yellow_bold " WARN ")] You are using more than 3 instances"
  fi
}

check_docker() {
  local docker
  if [[ -f /.dockerenv ]]; then
    docker=1
    echo -e "[$(yellow_bold " WARN ")] In a Docker container ..."
  else
    docker=0
    echo -e "[$(yellow_bold " WARN ")] Out of a Docker container ..."
  fi
  echo "${docker}"
}
