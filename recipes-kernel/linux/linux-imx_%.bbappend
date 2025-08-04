FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://viridi-common.dtsi \
    file://viridi-imx91.dts \
    file://viridi-imx93.dts \
    file://Makefile \
    file://viridi.cfg \
"

do_override_files () {
    install -Dm 0644 ${WORKDIR}/sources-unpack/viridi-common.dtsi ${S}/arch/arm64/boot/dts/freescale/viridi-common.dtsi
    install -Dm 0644 ${WORKDIR}/sources-unpack/viridi-imx91.dts ${S}/arch/arm64/boot/dts/freescale/viridi-imx91.dts
    install -Dm 0644 ${WORKDIR}/sources-unpack/viridi-imx93.dts ${S}/arch/arm64/boot/dts/freescale/viridi-imx93.dts
    install -Dm 0644 ${WORKDIR}/sources-unpack/Makefile ${S}/arch/arm64/boot/dts/freescale/Makefile
}

addtask override_files after do_kernel_configme before do_configure

deltask kernel_localversion
deltask merge_delta_config
