SUMMARY = "Firmware for MAYA-W166 (IW416) - Kernel 6.12+"
LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# 1. Point to your local file
SRC_URI:append = "file://sduartiw416_combo.bin"

S = "${WORKDIR}/sources"
UNPACKDIR = "${S}"

do_install() {
    install -d ${D}${nonarch_base_libdir}/firmware/mrvl
    install -d ${D}${nonarch_base_libdir}/firmware/nxp

    # NOTE: We use ${S} here because UNPACKDIR put the file there
    install -m 0644 ${S}/sduartiw416_combo.bin ${D}${nonarch_base_libdir}/firmware/mrvl/sd8987_uapsta.bin
    install -m 0644 ${S}/sduartiw416_combo.bin ${D}${nonarch_base_libdir}/firmware/nxp/sduartiw416_combo.bin
    
    ln -sf sduartiw416_combo.bin ${D}${nonarch_base_libdir}/firmware/nxp/sd8987_uapsta.bin
}

FILES:${PN} += " \
    ${nonarch_base_libdir}/firmware/mrvl/* \
    ${nonarch_base_libdir}/firmware/nxp/* \
"