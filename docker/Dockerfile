FROM alpine:latest
LABEL maintainer="Gianluca Boiano <morf3089@gmail.com>"
COPY simonpi /usr/bin
COPY docker/bin/setup /usr/bin
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
    setup
# Expose raspberry ssh port mapped on 2222 by qemu
EXPOSE 2222
ENTRYPOINT ["simonpi"]
