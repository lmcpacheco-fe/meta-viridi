FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add your generated C file to the U-Boot source.
# The 'subdir' parameter specifies where BitBake will place this file
# within the U-Boot source tree during the build.
# VERIFY THIS PATH by inspecting your U-Boot source tree for the i.MX91 QSB.
# A common path for i.MX91 QSB board-specific files is `board/nxp/imx91_qsb/`.

# Adjust 'imx91_qsb' to your board's actual directory
SRC_URI += " \
	file://lpddr4_timing.c;subdir=board/nxp/imx91_qsb \
	file://viridi-imx91.dts \
	file://viridi-imx93.dts \
"

# --- IMPORTANT: Integration Logic within U-Boot ---
# The generated lpddr4_timing.c contains the DDR initialization code.
# You need to ensure this code is compiled and executed by U-Boot.
# There are two common scenarios:

# SCENARIO A: lpddr4_timing.c REPLACES an existing DDR initialization file.
# If the generated lpddr4_timing.c is designed to completely replace a file
# that U-Boot already compiles (e.g., ddr_init.c), you might rename it
# during SRC_URI to match the original filename.
# Example (if it replaces ddr_init.c in that specific subdir):
# SRC_URI += "file://lpddr4_timing.c;name=ddr_init.c;subdir=board/nxp/imx91_qsb"
# In this case, U-Boot's existing Makefiles will automatically compile it.

# SCENARIO B: lpddr4_timing.c is a NEW file that needs to be called.
# If lpddr4_timing.c provides new functions (e.g., `lpddr4_init_optimized()`)
# that need to be called by existing U-Boot code (e.g., in `board_init.c`),
# you will need to create a patch file to modify the relevant U-Boot source.
#
# 1. Create a patch file:
#    - Make the necessary changes to the U-Boot source (e.g., `board/nxp/imx91_qsb/board_init.c`)
#      to include `lpddr4_timing.h` (if generated) and call the main DDR init function.
#    - Generate a patch from these changes (e.g., `git diff > 0001-call-lpddr4-timing.patch`).
#    - Place this patch file in `meta-viridi/recipes-bsp/u-boot/files/`.
# 2. Add the patch to SRC_URI:
#    SRC_URI += "file://0001-call-lpddr4-timing.patch"
#
# You might also need a patch to the U-Boot Makefile in the relevant directory
# to ensure lpddr4_timing.c gets compiled.
# SRC_URI += "file://0002-add-lpddr4-timing-to-makefile.patch"

# Consult NXP's i.MX U-Boot documentation for your BSP version.
# This documentation will guide you on the precise integration point for DDR code.

do_override_files() {
	install -Dm 0644 ${WORKDIR}/sources-unpack/viridi-imx91.dts ${S}/dts/upstream/src/arm64/freescale/viridi-imx91.dts
	install -Dm 0644 ${WORKDIR}/sources-unpack/viridi-imx93.dts ${S}/dts/upstream/src/arm64/freescale/viridi-imx93.dts
}

addtask override_files after do_patch before do_configure
