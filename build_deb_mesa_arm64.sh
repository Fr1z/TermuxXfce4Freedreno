#!/bin/bash

# Preparing
. /etc/os-release; echo "${UBUNTU_CODENAME}"

echo "
deb http://ports.ubuntu.com/ubuntu-ports ${UBUNTU_CODENAME} main restricted universe multiverse
deb-src http://ports.ubuntu.com/ubuntu-ports ${UBUNTU_CODENAME} main restricted universe multiverse

deb http://ports.ubuntu.com/ubuntu-ports ${UBUNTU_CODENAME}-updates main restricted universe multiverse
deb-src http://ports.ubuntu.com/ubuntu-ports ${UBUNTU_CODENAME}-updates main restricted universe multiverse

deb http://ports.ubuntu.com/ubuntu-ports ${UBUNTU_CODENAME}-backports main restricted universe multiverse
deb-src http://ports.ubuntu.com/ubuntu-ports ${UBUNTU_CODENAME}-backports main restricted universe multiverse

deb http://ports.ubuntu.com/ubuntu-ports ${UBUNTU_CODENAME}-security main restricted universe multiverse
deb-src http://ports.ubuntu.com/ubuntu-ports ${UBUNTU_CODENAME}-security main restricted universe multiverse
" > /etc/apt/sources.list

dpkg --add-architecture arm64
apt update
apt upgrade
apt build-dep mesa 
apt install make cmake git wget vulkan-tools mesa-utils g++-arm-linux-gnueabihf g++-aarch64-linux-gnu
apt install zlib1g-dev:arm64 libexpat1-dev:arm64 libdrm-dev:arm64 libx11-dev:arm64 libx11-xcb-dev:arm64 libxext-dev:arm64 libxdamage-dev:arm64 libxcb-glx0-dev:arm64 libxcb-dri2-0-dev:arm64 libxcb-dri3-dev:arm64 libxcb-shm0-dev:arm64 libxcb-present-dev:arm64 libxshmfence-dev:arm64 libxxf86vm-dev:arm64 libxrandr-dev:arm64 libwayland-dev:arm64 wayland-protocols:arm64 libwayland-egl-backend-dev:arm64  
cp /usr/include/libdrm/drm.h /usr/include/libdrm/drm_mode.h /usr/include/

# Download mesa
BUILD_PREFIX=~/Desktop
MESA_PREFIX=${BUILD_PREFIX}/mesa-main

wget --continue --directory-prefix ${BUILD_PREFIX} https://gitlab.freedesktop.org/mesa/mesa/-/archive/main/mesa-main.tar.gz
tar -xf ${BUILD_PREFIX}/*.tar.gz --directory ${BUILD_PREFIX}

# Set env var

MESA_VER=$(cat ${MESA_PREFIX}/VERSION)
DATE=$(date +"%F" | sed 's/-//g')

MESA_64=${BUILD_PREFIX}/mesa-vulkan-kgsl_${MESA_VER}-${DATE}-${UBUNTU_CODENAME}_arm64

# Cross compile

echo "\
[binaries]
c = 'arm-linux-gnueabihf-gcc'
cpp = 'arm-linux-gnueabihf-g++'
ar = 'arm-linux-gnueabihf-ar'
strip = 'arm-linux-gnueabihf-strip'
pkgconfig = 'arm-linux-gnueabihf-pkg-config'

[host_machine]
system = 'linux'
cpu_family = 'arm'
cpu = 'armv7l'
endian = 'little'
" > ${MESA_PREFIX}/arm.txt

# Build mesa 
cd ${MESA_PREFIX}

meson build64/ --prefix /usr --libdir lib/aarch64-linux-gnu/ -D platforms=x11 -D gallium-drivers= -D vulkan-drivers=freedreno -D freedreno-kmds=kgsl -D buildtype=release -D glx=disabled -D egl=disabled -D gles1=disabled -D gles2=disabled -D gallium-xa=disabled -D opengl=false -D shared-glapi=false -D b_lto=true -D b_ndebug=true
meson compile -C build64/
meson install -C build64/ --destdir ${MESA_64}


# Build deb64
cd ${BUILD_PREFIX}

apt remove -y mesa-vulkan-drivers:arm64
apt download mesa-vulkan-drivers:arm64
dpkg-deb -e mesa-vulkan-drivers_*_arm64.deb ${MESA_64}/DEBIAN/
sed -ie "3s/.*/Version: ${MESA_VER}-${DATE}/g" ${MESA_64}/DEBIAN/control
rm mesa-vulkan-drivers_*_arm64.deb
rm ${MESA_64}/DEBIAN/md5sums ${MESA_64}/DEBIAN/triggers
rm -rf ${MESA_64}/usr/share/drirc.d
dpkg-deb --build --root-owner-group ${MESA_64}






