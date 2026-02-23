LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

S = "${WORKDIR}/sources"
UNPACKDIR = "${S}"

SRC_URI = " \
    file://maya-w166.modules-load.conf \
    file://maya-w166.modprobe.conf \
    file://70-eth1.network \
    file://70-eth2.network \
"

do_install() {
    install -d                                               ${D}${nonarch_libdir}/modules-load.d
    install -m 0644 ${UNPACKDIR}/maya-w166.modules-load.conf ${D}${nonarch_libdir}/modules-load.d/20-maya-w166.conf

    install -d                                           ${D}${nonarch_libdir}/modprobe.d
    install -m 0644 ${UNPACKDIR}/maya-w166.modprobe.conf ${D}${nonarch_libdir}/modprobe.d/maya-w166.conf

    install -d                                    ${D}${nonarch_libdir}/systemd/network
    install -m 0644 ${UNPACKDIR}/70-eth1.network ${D}${nonarch_libdir}/systemd/network/
    install -m 0644 ${UNPACKDIR}/70-eth2.network ${D}${nonarch_libdir}/systemd/network/
}

RDEPENDS:${PN} = "kernel-module-btnxpuart kernel-module-nxp-wlan firmware-nxp-wifi"

FILES:${PN} = " \
    ${nonarch_libdir}/modprobe.d \
    ${nonarch_libdir}/modules-load.d \
    ${nonarch_libdir}/systemd/network \
"
