DESCRIPTION = "Sample image for Viridi VCom Condor i.MX 93 & i.MX 91"
LICENSE = "MIT"

require recipes-core/images/core-image-minimal.bb

IMAGE_INSTALL:append = "\
	iw \
	dtc \
	tmux \
	bluez5 \
	ethtool \
	openssh \
	phytool \
	picocom \
	devmem2 \
	libgpiod \
	iproute2 \
	can-utils \
	net-tools \
	memtester \
	modemmanager \
	i2c-tools \
	sdc-tests \
	bluez5-obex \
	libgpiod-tools \
	wpa-supplicant \
	util-linux-lsblk \
	openssh-sftp-server \
	kernel-module-nxp-wlan \
	wireless-regdb-static \
	linux-firmware-nxpiw416-sdio \
"
