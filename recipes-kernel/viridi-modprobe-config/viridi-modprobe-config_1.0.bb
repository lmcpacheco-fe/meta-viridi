SUMMARY = "Viridi kernel module blacklist configuration"
DESCRIPTION = "Blacklist btnxpuart to allow proper IW416 combo mode initialization"
LICENSE = "CLOSED"

SRC_URI = "file://blacklist.conf"

S = "${WORKDIR}/sources-unpack"

do_install() {
    install -Dm 0644 ${S}/blacklist.conf ${D}${sysconfdir}/modprobe.d/blacklist.conf
}
