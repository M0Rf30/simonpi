#!/usr/bin/env bash

device1=$(sudo -E losetup -f)
device2=/dev/loop$((${device1##*/loop} + 1))

check_fs "${device1}" "${device2}"
