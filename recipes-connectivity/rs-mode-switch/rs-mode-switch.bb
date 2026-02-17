SUMMARY = "rs-mode-switch"
DESCRIPTION = "RS232/RS485 mode switching utilities"
LICENSE = "CLOSED"

SRC_URI = " \
    file://rs485-enable.c \
    file://rs232-enable.c \
    file://check-rs485-support.c \
    file://check-uart-config.c \
"

S = "${WORKDIR}/sources-unpack"

# Skip QA check for debug buildpaths
INSANE_SKIP:${PN}-dbg += "buildpaths"

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} -o rs485-enable ${S}/rs485-enable.c
    ${CC} ${CFLAGS} ${LDFLAGS} -o rs232-enable ${S}/rs232-enable.c
    ${CC} ${CFLAGS} ${LDFLAGS} -o check-rs485-support ${S}/check-rs485-support.c
    ${CC} ${CFLAGS} ${LDFLAGS} -o check-uart-config ${S}/check-uart-config.c
}

do_install() {
    install -Dm 0755 ${B}/rs485-enable ${D}${bindir}/rs485-enable
    install -Dm 0755 ${B}/rs232-enable ${D}${bindir}/rs232-enable
    install -Dm 0755 ${B}/check-rs485-support ${D}${bindir}/check-rs485-support
    install -Dm 0755 ${B}/check-uart-config ${D}${bindir}/check-uart-config
}
