SUMMARY = "sdc-tests"
DESCRIPTION = "SDC test files"
LICENSE = "CLOSED"

SRC_URI = " \
    file://test-imx91.sh \
    file://test-imx93.sh \
    file://test-imx93-v2.sh \
    file://test-imx93.cukinia.conf \
"

RDEPENDS:${PN} = "cukinia"

do_install() {
    if [ "${MACHINE}" = "viridi-imx91" ]; then
        install -Dm 0755 ${WORKDIR}/sources-unpack/test-imx91.sh ${D}${sysconfdir}/sdc/test-imx91.sh
    fi
    if [ "${MACHINE}" = "viridi-imx93" ]; then
        install -Dm 0755 ${WORKDIR}/sources-unpack/test-imx93.sh ${D}${sysconfdir}/sdc/test-imx93.sh
        install -Dm 0755 ${WORKDIR}/sources-unpack/test-imx93-v2.sh ${D}${sysconfdir}/sdc/test-imx93-v2.sh
        install -Dm 0644 ${WORKDIR}/sources-unpack/test-imx93.cukinia.conf ${D}${sysconfdir}/sdc/test-imx93.cukinia.conf
    fi
}
