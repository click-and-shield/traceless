FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
       live-build \
       debootstrap \
       dos2unix \
       debian-archive-keyring \
       ca-certificates \
       wget \
       curl \
       gnupg \
       xorriso \
       squashfs-tools \
       isolinux \
       syslinux-utils \
       syslinux-common \
       dosfstools \
       mtools \
       rsync \
       git \
       vim \
       nano \
       less \
       file \
       kmod && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["/bin/bash"]
