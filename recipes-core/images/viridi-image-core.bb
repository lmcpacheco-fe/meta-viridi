DESCRIPTION = "Sample image for Viridi VCom Condor i.MX 93 & i.MX 91"
LICENSE = "MIT"

require recipes-core/images/core-image-minimal.bb

IMAGE_INSTALL:append = "\
	dtc \
	tmux \
	ethtool \
	openssh \
	phytool \
	libgpiod \
	net-tools \
	memtester \
	i2c-tools \
	sdc-tests \
	libgpiod-tools \
	wpa-supplicant \
	util-linux-lsblk \
	openssh-sftp-server \
	kernel-module-nxp-wlan \
	linux-firmware-nxpiw416-sdio \
	devmem2 \
"
