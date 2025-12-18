#@TYPE: Kernel Recipe Append
#@NAME: viridi-imx93 linux-imx extension
#@SOC: i.MX93
#@DESCRIPTION: Adds Viridi i.MX93 board support via DTS files and kernel config fragments.
#@MAINTAINER: Aitor Carrizosa <aitor.carrizosa@futureelectronics.com>

# Add the files directory so that BitBake can find the files
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add the files to the SRC_URI so that they are copied to the WORKDIR
SRC_URI:append = " \
    file://viridi-common.dtsi \
    file://viridi-imx91.dts \
    file://viridi-imx93.dts \
    file://Makefile \
    file://imx_v8_defconfig \
"

# Copy the files to their destinations within the Kernel source tree
do_override_files() {
    install -Dm 0644 ${WORKDIR}/sources-unpack/viridi-common.dtsi  ${S}/arch/arm64/boot/dts/freescale/viridi-common.dtsi
    install -Dm 0644 ${WORKDIR}/sources-unpack/viridi-imx91.dts  ${S}/arch/arm64/boot/dts/freescale/viridi-imx91.dts
    install -Dm 0644 ${WORKDIR}/sources-unpack/viridi-imx93.dts  ${S}/arch/arm64/boot/dts/freescale/viridi-imx93.dts
    install -Dm 0644 ${WORKDIR}/sources-unpack/Makefile ${S}/arch/arm64/boot/dts/freescale/Makefile
    install -Dm 0644 ${WORKDIR}/sources-unpack/${KBUILD_DEFCONFIG} ${S}/arch/arm64/configs/${KBUILD_DEFCONFIG}
}

# Define task execution order 
addtask override_files after do_patch before do_compile

# Keep a stable kernel release string (avoids -dirty / git hash)
KERNEL_LOCALVERSION = "-lts-next"
KERNEL_LOCALVERSION_AUTO = "0"
SCMVERSION = "n"
