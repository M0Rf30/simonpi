#!/usr/bin/env bash

generate_mac() {
  # Generate Random MAC ADDRESS to avoid collisions
  printf "52:54:%02x:%02x:%02x:%02x" $((RANDOM & 0xff)) $((RANDOM & 0xff)) $((RANDOM & 0xff)) $((RANDOM & 0xff))
}

get_internet_if() {
  iface=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
  echo "${iface}"
}

check_tap() {
  local tap_if="$1"
  if [[ -d "/sys/class/net/${tap_if}" ]]; then
    while [[ -d "/sys/class/net/${tap_if}" ]]; do
      TAPON=1
      tap_if=rasp-tap$((${tap_if##rasp-tap} + 1))
    done
  else
    TAPON=0
  fi
}

check_dnsmasq() {
  local gateway_ip="$1"
  pgrep -f "${gateway_ip}"
}

setup_dnsmasq() {
  local nameservers
  local searchdomains
  local gateway_ip="$1"
  local first_ip="$2"
  local last_ip="$3"
  local bridge_if="$4"

  DNSMASQ_OPTS="--listen-address=${gateway_ip} --interface=${bridge_if} \
    --bind-interfaces --dhcp-range=${first_ip},${last_ip}"

  # Build DNS options from container /etc/resolv.conf
  mapfile -t nameservers < <(grep nameserver /etc/resolv.conf |
    head -n 2 | sed 's/nameserver //')
  mapfile -t searchdomains < <(grep search /etc/resolv.conf |
    sed 's/search //' | sed 's/ /,/g')

  domainname=$(echo "${searchdomains[@]}" | awk -F"," '{print $1}')

  if [[ -n ${domainname} ]]; then
    DNSMASQ_OPTS+=" --dhcp-option=option:domain-name,${domainname}"
  fi

  for nameserver in "${nameservers[@]}"; do
    [[ -z ${DNS_SERVERS} ]] &&
      DNS_SERVERS=${nameserver} ||
      DNS_SERVERS="${DNS_SERVERS},${nameserver}"
  done

  if [[ -z ${DNSMASQPID} ]] &&
    ! ss -ntl | grep -q :53; then
    echo -e "[$(green_bold "  OK  ")] Turning up dnsmasq for guest IP assignment ..."
    DNSMASQ_OPTS+=" --dhcp-option=option:dns-server,${DNS_SERVERS} --dhcp-option=option:router,${GATEWAY}"
    eval "sudo -E ${DNSMASQ} ${DNSMASQ_OPTS}"
    echo -e "[$(green_bold "  OK  ")] Gateway address: ${gateway_ip}"

  elif [[ -z ${DNSMASQPID} ]] && ss -ntl | grep -q :53; then
    echo -e "[$(yellow_bold " WARN ")] Port 53 is busy"
    echo -e "[$(yellow_bold " WARN ")] Trying to use local dns service ( maybe offline )"
    DNSMASQ_OPTS="${DNSMASQ_OPTS} --dhcp-option=option:dns-server,127.0.0.1 --port=0"
    eval "sudo -E ${DNSMASQ} ${DNSMASQ_OPTS}"
  else
    echo -e "[$(yellow_bold " WARN ")] Another instance of ${DNSMASQ} is running ..."
  fi
}

kill_dnsmasq() {
  local dnsmasq_pid="$1"
  if [[ -n ${dnsmasq_pid} ]]; then
    sudo -E kill -9 "${dnsmasq_pid}"
  fi
}

shutdown_network() {
  local bridge_if="$1"
  local tap_if="$2"

  echo -e "[$(green_bold "  OK  ")] Shutting down present network for QEMU ..."
  while [[ -d "/sys/class/net/${bridge_if}" ]] ||
    [[ -d "/sys/class/net/${tap_if}" ]]; do
    sudo -E ip link set "${tap_if}" nomaster >/dev/null 2>&1          # Enslave tap
    sudo -E ip tuntap del dev "${tap_if}" mode tap >/dev/null 2>&1    # Remove tap
    sudo -E ip link delete "${bridge_if}" type bridge >/dev/null 2>&1 # Remove bridge
    sudo -E su -c "echo 0 > /proc/sys/net/ipv4/ip_forward"
  done
}

force_shutdown_network() {
  local bridge_if="$1"
  echo -e "[$(green_bold "  OK  ")] Forced network shutdown for QEMU ..."

  while [[ -d "/sys/class/net/${bridge_if}" ]] ||
    [[ -n "$(find /sys/class/net/ -name "rasp*")" ]]; do
    for i in /sys/class/net/rasp-tap*; do
      # Enslave tap
      sudo -E ip link set "${i##*/}" nomaster >/dev/null 2>&1
      # Remove tap
      sudo -E ip tuntap del dev "${i##*/}" mode tap >/dev/null 2>&1
    done
    # Remove bridge
    sudo -E ip link delete "${bridge_if}" type bridge >/dev/null 2>&1
  done
}

bridge_up() {
  # Add bridge
  sudo -E ip link add "${bridge_if}" type bridge
  # Set ip to bridge interface
  sudo -E ip addr add "${gateway_ip}"/24 broadcast "${broadcast_ip}" dev "${bridge_if}"
  sudo -E ip link set "${bridge_if}" up

  sleep 0.5s
}

setup_nat() {
  iface=$(getInternetIf)
  sudo -E iptables -t nat -A POSTROUTING -o "${iface}" -j MASQUERADE
  sudo -E iptables -A FORWARD -m conntrack \
    --ctstate RELATED,ESTABLISHED -j ACCEPT
  sudo -E iptables -A FORWARD -i "${tap_if}" -o "${iface}" -j ACCEPT
}

setup_tap() {
  local tap_if="$1"

  # Add tap interface
  sudo -E ip tuntap add dev "${tap_if}" mode tap user "$(checkUser)"
  sudo -E ip link set "${tap_if}" up promisc on

  sleep 0.5s
  # Bind tap to bridge
  sudo -E ip link set "${tap_if}" master "${bridge_if}"
}

create_network() {
  local tap_if="$1"
  local bridge_if="$2"
  local gateway_ip="$3"
  local broadcast_ip="$4"

  check_tap "${tap_if}"

  echo -e "[$(green_bold "  OK  ")] Turning up a network for QEMU ..."
  if [[ ${IPFORWARD} != "1" ]]; then
    sudo -E su -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
  fi

  if [[ ${TAPON} -eq 0 ]]; then
    bridge_up "${bridge_if}" "${gateway_ip}" "${broadcast_ip}"
  fi

  setup_tap "${tap_if}" "${bridge_if}"
}
