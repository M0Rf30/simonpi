#!/usr/bin/env bash

check_docker() {
  if [[ -f /.dockerenv ]]; then
    echo -e "[$(yellow_bold " WARN ")] In a Docker container ..."
  else
    echo -e "[$(yellow_bold " WARN ")] Out of a Docker container ..."
  fi
}
