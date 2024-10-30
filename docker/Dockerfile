FROM alpine:latest
LABEL org.opencontainers.image.title="simonpi"
LABEL org.opencontainers.image.description="Emulate Raspberry family devices on your laptop"
LABEL org.opencontainers.image.vendor="M0Rf30"
COPY simonpi /usr/bin
COPY docker/bin/setup.sh /usr/bin
RUN \
  apk update; \
  apk add --no-cache \
  bash \
  binutils \
  coreutils \
  cpio \
  curl \
  dnsmasq \
  dosfstools \
  e2fsprogs \
  file \
  grep \
  iproute2 \
  iptables \
  libarchive-tools \
  qemu-img \
  qemu-system-aarch64 \
  qemu-system-arm \
  rpm2cpio \
  sudo \
  unzip \
  util-linux; \
  setup.sh

# Expose raspberry ssh port mapped on 2222 by qemu
EXPOSE 2222
ENTRYPOINT ["simonpi"]
