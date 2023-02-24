#!/usr/bin/env bash
gateway_ip="192.168.66.1"
bridge_if="rasp-br0"

qemu_status="$(check_qemu)"
check_root
kill_qemu "${qemu_status}"
dnsmasq_pid=$(check_dnsmasq "${gateway_ip}")
kill_dnsmasq "${dnsmasq_pid}"
force_shutdown_network "${bridge_if}"
