# Añadir la carpeta files para que BitBake encuentre los archivos
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Añadir los archivos al SRC_URI para que se copien a WORKDIR
SRC_URI += " \
    file://viridi-imx91.dts \
    file://viridi-imx91_defconfig \
    file://viridi-imx93.dts \
"

# Copiar los archivos a sus destinos dentro del árbol de fuentes de u-boot
do_override_files() {
#    install -Dm 0644 ${WORKDIR}/viridi-imx91.dts ${S}/dts/upstream/src/arm64/freescale/viridi-imx91.dts
    install -Dm 0644 ${WORKDIR}/sources-unpack/viridi-imx91_defconfig ${S}/configs/viridi-imx91_defconfig
#    install -Dm 0644 ${WORKDIR}/viridi-imx93.dts ${S}/dts/upstream/src/arm64/freescale/viridi-imx93.dts
    install -Dm 0644 ${WORKDIR}/sources-unpack/viridi-imx91.dts ${S}/dts/upstream/src/arm64/freescale/viridi-imx91.dts
    install -Dm 0644 ${WORKDIR}/sources-unpack/viridi-imx93.dts ${S}/dts/upstream/src/arm64/freescale/viridi-imx93.dts
}

addtask override_files after do_patch before do_configure
