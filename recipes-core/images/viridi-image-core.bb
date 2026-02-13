DESCRIPTION = "Sample image for Viridi VCom Condor i.MX 93 & i.MX 91"
LICENSE = "MIT"

require recipes-core/images/core-image-minimal.bb

IMAGE_INSTALL:append = "\
	iw \
	dtc \
	tmux \
	bluez5 \
	bluez5-noinst-tools \
	ethtool \
	openssh \
	phytool \
	devmem2 \
	libgpiod \
	iproute2 \
	can-utils \
	net-tools \
	memtester \
	i2c-tools \
	sdc-tests \
	python3-spidev \
	spidev-test \
	bluez5-obex \
	libgpiod-tools \
	net-tools \
	wpa-supplicant \
	util-linux-lsblk \
	openssh-sftp-server \
	kernel-module-nxp-wlan \
	kernel-module-btnxpuart \
	wireless-regdb-static \
	linux-firmware-nxpiw416-sdio \
	pipewire \
	pipewire-pulse \
	wireplumber \
	picocom \
	iperf3 \
	libqmi \
	kernel-modules \
	rs-mode-switch \
	viridi-modprobe-config \
"
