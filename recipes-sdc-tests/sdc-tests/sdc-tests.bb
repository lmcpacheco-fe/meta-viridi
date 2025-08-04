SUMMARY = "sdc-tests"
DESCRIPTION = "SDC test files"
LICENSE = "CLOSED"

SRC_URI = "file://test.sh"

do_install() {
	install -Dm 0755 ${WORKDIR}/sources-unpack/test.sh ${D}${sysconfdir}/sdc/test.sh
}
