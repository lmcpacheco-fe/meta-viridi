# Add the files directory so that BitBake can find the files
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add the files to the SRC_URI so that they are copied to the WORKDIR
SRC_URI += " \
    file://lpddr4_timing-91.c \
    file://lpddr4_timing-93.c \
    file://spl.c \
    file://viridi-imx91.dts \
    file://viridi-imx93.dts \
    file://viridi-imx91_defconfig \
    file://viridi-imx93_defconfig \
"

# Copy the files to their destinations within the U-Boot source tree
do_override_files() {
    if [ "${MACHINE}" = "viridi-imx91" ]; then
        install -Dm 0644 ${WORKDIR}/sources-unpack/lpddr4_timing-91.c ${S}/board/freescale/imx91_evk/lpddr4_timing.c
        install -Dm 0644 ${WORKDIR}/sources-unpack/spl.c ${S}/board/freescale/imx91_evk/spl.c
        install -Dm 0644 ${WORKDIR}/sources-unpack/viridi-imx91_defconfig ${S}/configs/viridi-imx91_defconfig
        install -Dm 0644 ${WORKDIR}/sources-unpack/viridi-imx91.dts ${S}/dts/upstream/src/arm64/viridi-imx91.dts
    fi

    if [ "${MACHINE}" = "viridi-imx93" ]; then
        install -Dm 0644 ${WORKDIR}/sources-unpack/lpddr4_timing-93.c ${S}/board/freescale/imx93_evk/lpddr4_timing.c
        install -Dm 0644 ${WORKDIR}/sources-unpack/spl.c ${S}/board/freescale/imx93_evk/spl.c
        install -Dm 0644 ${WORKDIR}/sources-unpack/viridi-imx93_defconfig ${S}/configs/viridi-imx93_defconfig
        install -Dm 0644 ${WORKDIR}/sources-unpack/viridi-imx93.dts ${S}/dts/upstream/src/arm64/viridi-imx93.dts
    fi
}

addtask override_files after do_patch before do_configure