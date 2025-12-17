DESCRIPTION = "Sample image for Goldilocks Mamabear app"
LICENSE = "MIT"

require recipes-core/images/core-image-minimal.bb

IMAGE_INSTALL:append = "\
	dtc \
	ethtool \
	i2c-tools \
	libgpiod \
	libgpiod-tools \
	net-tools \
	tmux \
	wpa-supplicant \
"


