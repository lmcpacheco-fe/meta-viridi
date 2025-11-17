#!/bin/sh

# ========= #
# Functions #
# ========= #
function pretty_print {
    printf "\e[1;33m ####################################################################### \e[0m\n"
    for line in "$@"; do
        printf "\e[1;33m ### %-59s ### \e[0m\n" "$line"
    done
    printf "\e[1;33m ####################################################################### \e[0m\n"
}

function check_test {
    printf "\n\n"
    pretty_print "$1 test complete"
    printf "\n\n"
    printf "Did the %s test pass? (y/n) " "$1"
    read -r ANSWER

    if [[ "${ANSWER,,}" == "y" ]]; then
        ((PASSED++))
    fi
    ((TOTAL++))

    pretty_print "$PASSED of $TOTAL tests passed so far"
    printf "\n\n"
}

# ===== #
# Setup #
# ===== #
PASSED=0
TOTAL=0

printf "\n\n"
pretty_print "Starting test for Viridi-imx91"
printf "\n\n"

# ====================== #
# Kernel Log Error Check #
# ====================== #
printf "\n\n"
pretty_print "Checking kernel logs for errors"
printf "\n\n"

ERRORS=$(dmesg | grep -i "error")

if [ -n "$ERRORS" ]; then
    pretty_print "Kernel errors detected:"
    echo "$ERRORS"
    KERNEL_LOG_TEST_RESULT="n"
else
    pretty_print "No kernel errors found in kernel logs"
    KERNEL_LOG_TEST_RESULT="y"
fi

check_test "Kernel Log Errors" KERNEL_LOG_TEST_RESULT

# ====================== #
# DDR Memory Test        #
# ====================== #
printf "\n\n"
pretty_print "Starting DDR memory test"
printf "\n\n"

if ! command -v memtester >/dev/null 2>&1; then
    pretty_print "ERROR: memtester not installed. Skipping DDR test."
    DDR_TEST_RESULT="n"
else
    MEMSIZE=50M
    pretty_print "Testing $MEMSIZE of RAM..."
    memtester $MEMSIZE 1
    DDR_TEST_RESULT="y"
fi

check_test "DDR Memory" DDR_TEST_RESULT

# ====================== #
# eMMC Test              #
# ====================== #
printf "\n\n"
pretty_print "Starting eMMC test"
printf "\n\n"

EMMC_DEV="/dev/mmcblk2"

if [ -b "$EMMC_DEV" ]; then
    pretty_print "eMMC device $EMMC_DEV found"
    lsblk "$EMMC_DEV"

    EMMC_TEST_RESULT="y"
else
    pretty_print "ERROR: eMMC device $EMMC_DEV not found"
    EMMC_TEST_RESULT="n"
fi

check_test "eMMC" EMMC_TEST_RESULT

# # ====================== #
# # FlexSPI NOR Test       #
# # ====================== #
# printf "\n\n"
# pretty_print "Starting FlexSPI NOR flash test"
# printf "\n\n"

# MTD_DEV="/dev/mtd0"
# TEST_SIZE=256
# TMP_WRITE=/tmp/spi_nor_write.bin
# TMP_READ=/tmp/spi_nor_read.bin

# # Check if MTD device exists
# if [ ! -e "$MTD_DEV" ]; then
#     pretty_print "ERROR: $MTD_DEV does not exist. Check /proc/mtd"
#     cat /proc/mtd
#     SPI_TEST_RESULT="n"
#     check_test "FlexSPI NOR" $SPI_TEST_RESULT
#     return
# fi

# # Get flash size from /proc/mtd
# MTD_NAME="${MTD_DEV##*/}"
# FLASH_SIZE_HEX=$(grep "$MTD_NAME" /proc/mtd | awk '{print $2}')
# if [ -z "$FLASH_SIZE_HEX" ]; then
#     pretty_print "ERROR: Could not read size for $MTD_DEV"
#     SPI_TEST_RESULT="n"
#     check_test "FlexSPI NOR" $SPI_TEST_RESULT
#     return
# fi

# FLASH_SIZE=$((16#$FLASH_SIZE_HEX))
# FLASH_SIZE_MB=$((FLASH_SIZE / 1024 / 1024))
# pretty_print "SPI NOR $MTD_DEV found, size: $FLASH_SIZE_MB MB"

# # Generate random test data
# dd if=/dev/urandom of=$TMP_WRITE bs=1 count=$TEST_SIZE status=none 2>/dev/null

# # Erase first sector (required before write)
# pretty_print "Erasing first $TEST_SIZE bytes (sector 0)..."
# if ! flash_erase "$MTD_DEV" 0 1 >/dev/null 2>&1; then
#     pretty_print "ERROR: flash_erase failed. Install mtd-utils."
#     SPI_TEST_RESULT="n"
#     rm -f $TMP_WRITE
#     check_test "FlexSPI NOR" $SPI_TEST_RESULT
#     return
# fi

# # Write random data
# pretty_print "Writing $TEST_SIZE random bytes to offset 0..."
# if ! dd if=$TMP_WRITE of=$MTD_DEV bs=1 seek=0 count=$TEST_SIZE conv=notrunc status=none 2>/dev/null; then
#     pretty_print "ERROR: Failed to write to $MTD_DEV"
#     SPI_TEST_RESULT="n"
#     rm -f $TMP_WRITE
#     check_test "FlexSPI NOR" $SPI_TEST_RESULT
#     return
# fi

# # Read back
# pretty_print "Reading back $TEST_SIZE bytes..."
# if ! dd if=$MTD_DEV of=$TMP_READ bs=1 skip=0 count=$TEST_SIZE status=none 2>/dev/null; then
#     pretty_print "ERROR: Failed to read from $MTD_DEV"
#     SPI_TEST_RESULT="n"
#     rm -f $TMP_WRITE $TMP_READ
#     check_test "FlexSPI NOR" $SPI_TEST_RESULT
#     return
# fi

# # Compare
# if cmp -s $TMP_WRITE $TMP_READ; then
#     pretty_print "FlexSPI NOR test PASSED!"
#     SPI_TEST_RESULT="y"
# else
#     pretty_print "FlexSPI NOR test FAILED! Data mismatch."
#     SPI_TEST_RESULT="n"
# fi

# # Clean up flash (erase test area again)
# pretty_print "Cleaning up test area..."
# flash_erase "$MTD_DEV" 0 1 >/dev/null 2>&1

# # Final result
# check_test "FlexSPI NOR" $SPI_TEST_RESULT

# # Remove temp files
# rm -f $TMP_WRITE $TMP_READ

# ====================== #
# EEPROM  Test           #
# ====================== #
printf "\n\n"
pretty_print "Starting EEPROM test"
printf "\n\n"

I2C_BUS=4
EEPROM_ADDR=0x54    # 7-bit address: 0xA8 → 0x54 in decimal
WP_ADDR=0x30        # 7-bit address: 0x60 → 0x30 in decimal
TEST_SIZE=32
TMP_WRITE=/tmp/eeprom_write.bin
TMP_READ=/tmp/eeprom_read.bin

# Generate random test data
dd if=/dev/urandom of=$TMP_WRITE bs=1 count=$TEST_SIZE status=none 2>/dev/null

# Check if i2c-tools are installed
if ! command -v i2cdetect &> /dev/null; then
    pretty_print "ERROR: i2cdetect not found. Install i2c-tools."
    EEPROM_TEST_RESULT="n"
    check_test "I2C EEPROM" $EEPROM_TEST_RESULT
    rm -f $TMP_WRITE $TMP_READ
    return
fi

# Convert addresses to lowercase hex for grep matching
EEPROM_HEX=$(printf '%02x' $EEPROM_ADDR)
WP_HEX=$(printf '%02x' $WP_ADDR)

# Scan I2C bus for both EEPROM and Write Protection addresses
pretty_print "Scanning I2C bus $I2C_BUS..."
i2cdetect -y $I2C_BUS | grep -q "$EEPROM_HEX"
if [ $? -ne 0 ]; then
    pretty_print "ERROR: EEPROM not found at 0x$(printf '%X' $EEPROM_ADDR)"
    EEPROM_TEST_RESULT="n"
    check_test "I2C EEPROM" $EEPROM_TEST_RESULT
    rm -f $TMP_WRITE $TMP_READ
    return
fi

i2cdetect -y $I2C_BUS | grep -q "$WP_HEX"
if [ $? -ne 0 ]; then
    pretty_print "ERROR: Write Protection not found at 0x$(printf '%X' $WP_ADDR)"
    EEPROM_TEST_RESULT="n"
    check_test "I2C EEPROM" $EEPROM_TEST_RESULT
    rm -f $TMP_WRITE $TMP_READ
    return
fi

pretty_print "EEPROM found at 0x$(printf '%X' $EEPROM_ADDR)"
pretty_print "WP found at 0x$(printf '%X' $WP_ADDR)"

# Disable write protection
pretty_print "Disabling write protection..."
i2cset -y $I2C_BUS $WP_ADDR 0x00
if [ $? -ne 0 ]; then
    pretty_print "ERROR: Failed to disable write protection"
    EEPROM_TEST_RESULT="n"
    check_test "I2C EEPROM" $EEPROM_TEST_RESULT
    rm -f $TMP_WRITE $TMP_READ
    return
fi

# Write random data byte by byte
pretty_print "Writing $TEST_SIZE random bytes to EEPROM..."
for ((addr=0; addr<$TEST_SIZE; addr++)); do
    # Extract one byte from random file
    byte_hex=$(dd if=$TMP_WRITE bs=1 skip=$addr count=1 2>/dev/null | xxd -p)
    i2cset -y $I2C_BUS $EEPROM_ADDR $addr 0x$byte_hex
    usleep 5000  # Wait ~5ms per write (safe for EEPROM)
done

# Read back the data
pretty_print "Reading back data..."
> $TMP_READ
for ((addr=0; addr<$TEST_SIZE; addr++)); do
    val=$(i2cget -y $I2C_BUS $EEPROM_ADDR $addr)
    printf "%02x" $val | xxd -r -p >> $TMP_READ
done

# Compare written and read data
if cmp -s $TMP_WRITE $TMP_READ; then
    pretty_print "EEPROM test PASSED!"
    EEPROM_TEST_RESULT="y"
else
    pretty_print "EEPROM test FAILED!"
    EEPROM_TEST_RESULT="n"
fi

check_test "I2C EEPROM" $EEPROM_TEST_RESULT

# Clean up temporary files
rm -f $TMP_WRITE $TMP_READ

# ====================== #
# SDIO/MMC Test          #
# ====================== #
printf "\n\n"
pretty_print "Starting MMC/SDIO test"
printf "\n\n"
SDIO_FOUND=0
declare -A dt_alias
dt_alias=( ["mmc0"]="usdhc1" ["mmc1"]="usdhc2" ["mmc2"]="usdhc3" )

for host in /sys/class/mmc_host/mmc[0-9]*; do
    host_name=$(basename "$host")
    usdhc=${dt_alias[$host_name]:-"unknown"} 

    devices=$(ls "$host" 2>/dev/null | grep -E 'mmc[0-9]+:[0-9]+')
    if [ -n "$devices" ]; then
        SDIO_FOUND=1
        for dev in $devices; do
            devpath="$host/$dev"

            [ -f "$devpath/name" ]   && name=$(tr -d '\0' < "$devpath/name")
            [ -f "$devpath/manfid" ] && manfid=$(tr -d '\0' < "$devpath/manfid")
            [ -f "$devpath/serial" ] && serial=$(tr -d '\0' < "$devpath/serial")
            [ -f "$devpath/type" ]   && type=$(tr -d '\0' < "$devpath/type")

            pretty_print "Device on $host_name ($usdhc)"
            echo "Name         : ${name:-N/A}"
            echo "Manufacturer : ${manfid:-N/A}"
            echo "Serial       : ${serial:-N/A}"
            echo "Type(sysfs)  : ${type:-N/A}"

            case "$type" in
                MMC)
                    echo "Classified   : eMMC (on-board storage)"
                    ;;
                SD)
                    echo "Classified   : SD card (removable)"
                    ;;
                SDIO)
                    echo "Classified   : SDIO device (Wi-Fi/BT/Other)"
                    ;;
                *)
                    echo "Classified   : Unknown"
                    ;;
            esac
        done
    fi
done

if [ $SDIO_FOUND -eq 1 ]; then
    SDIO_TEST_RESULT="y"
else
    pretty_print "ERROR: No MMC/SDIO devices found"
    SDIO_TEST_RESULT="n"
fi

check_test "MMC/SDIO" SDIO_TEST_RESULT

# ====================== #
# I2C Test               #
# ====================== #
printf "\n\n"
pretty_print "Starting I2C bus test"
printf "\n\n"

pretty_print "Available I2C buses"
i2cdetect -l

pretty_print "Scanning I2C1 (should have IO Expander at 0x44 and RTC at 0x51 )"
i2cdetect -y 0

pretty_print "Probing IO Expander at bus 0, address 0x44"
if i2cget -y -f 0 0x44 0x00>/dev/null >/dev/null; then
    echo "IO Expander at 0x44 responded"
else
    echo "ERROR: IO Expander at 0x44 did NOT respond"
fi

pretty_print "Probing RTC at bus 0, address 0x51"
if i2cget -y -f 0 0x51 0x00>/dev/null >/dev/null; then
    echo "RTC at 0x51 responded"
else
    echo "ERROR: RTC at 0x51 did NOT respond"
fi

pretty_print "Scanning I2C2 (should have PCA9451 at 0x25)"
i2cdetect -y 1

pretty_print "Probing PCA9451 at bus 1, address 0x25"
if i2cget -y 1 0x25 0x00 2>/dev/null >/dev/null; then
    echo "PCA9451 at 0x25 responded"
else
    echo "ERROR: PCA9451 at 0x25 did NOT respond"
fi

pretty_print "Scanning I2C3 (should have EEPROM at 0x54)"
i2cdetect -y 2

pretty_print "Probing EEPROM at bus 2, address 0x54"
if i2cget -y 2 0x54 0x00 2>/dev/null >/dev/null; then
    echo "EEPROM at 0x54 responded"
else
    echo "ERROR: EEPROM at 0x50 did NOT respond"
fi

pretty_print "Scanning I2C5 (should have two IO Expanders, one at 0x20 an other at 0x21)"
i2cdetect -y 4

pretty_print "Probing IO Expander at bus 4, address 0x20"
if i2cget -y 4 0x20 0x00 2>/dev/null >/dev/null; then
    echo "IO Expander at 0x20 responded"
else
    echo "ERROR: IO Expander at 0x20 did NOT respond"
fi
pretty_print "Probing IO Expander at bus 4, address 0x21"
if i2cget -y 4 0x21 0x00 2>/dev/null >/dev/null; then
    echo "IO Expander at 0x21 responded"
else
    echo "ERROR: IO Expander at 0x21 did NOT respond"
fi

check_test "I2C" "y"

# ====================== #
# Ethernet Test          #
# ====================== #
# printf "\n\n"
# pretty_print "Starting Ethernet test"
# printf "\n\n"

# IFACE="eth0"
# IP_ADDR="10.219.8.14/20"

# IF_STATUS=$(cat /sys/class/net/$IFACE/operstate 2>/dev/null)

# if [[ "$IF_STATUS" == "up" ]]; then
#     pretty_print "$IFACE is already active. Skipping configuration."
# else
#     pretty_print "$IFACE is down. Bringing up interface and configuring IP."
#     ip link set $IFACE up
#     ip addr add $IP_ADDR dev $IFACE
#     ip route add default via $GATEWAY dev $IFACE
# fi

# pretty_print "Interface status:"
# ip addr show $IFACE

# if command -v ethtool >/dev/null 2>&1; then
#     pretty_print "Checking link status with ethtool..."
#     ethtool $IFACE
# else
#     echo "ethtool not installed, skipping link check."
# fi

# pretty_print "Pinging 8.8.8.8..."
# ping -c 4 8.8.8.8

# check_test "Ethernet" "y"

# ====================== #
# Audio/SAI Test         #
# ====================== #
# printf "\n\n"
# pretty_print "Starting Audio (SAI) test"
# printf "\n\n"
# # aplay -l, arecord -l, play/record
# pretty_print "Listing playback devices:"
# aplay -l

# pretty_print "Listing capture devices:"
# arecord -l

# # aplay <archivo_wav> -D <device>
# # arecord -d 5 -f cd <archivo_wav> -D <device>

# check_test "Audio/SAI" "y"

# ====================== #
# LED Test  #
# ====================== #
printf "\n\n"
pretty_print "LED Sequential Test"
printf "\n\n"

I2C_BUS=1                    # LPI2C1 → /dev/i2c-1
I2C_ADDR=0x44                # 7-bit I2C address
REG_OUTPUT=0x01              # Output Port Register
REG_DIRECTION=0x03           # Direction Register (0 = output)
LED_PINS=(0 1 2 3)           # GPIO0 → LED1_nEN, GPIO1 → LED2_nEN, ...
LED_NAMES=("LED1" "LED2" "LED3" "LED4")
ON_DURATION=3                # Seconds each LED stays ON

if ! command -v i2cset >/dev/null 2>&1; then
    pretty_print "ERROR: i2c-tools not installed (i2cset missing). Skipping test."
    IO_EXPANDER_TEST_RESULT="n"
    check_test "LED Sequential" LED_TEST_RESULT
    return 1
fi

if ! i2cdetect -y $I2C_BUS | grep -q "$I2C_ADDR"; then
    pretty_print "ERROR: FXL6408 not detected at 0x$I2C_ADDR on bus $I2C_BUS"
    IO_EXPANDER_TEST_RESULT="n"
else
    pretty_print "FXL6408 detected at 0x$I2C_ADDR. Running LED sequence..."

    # Configure GPIO0-3 as outputs (bits 0-3 = 0)
    i2cset -y $I2C_BUS $I2C_ADDR $REG_DIRECTION 0xF0 2>/dev/null

    IO_EXPANDER_TEST_RESULT="y"
    local idx pin bit_mask current

    pretty_print "Starting LED sequence..."

    for idx in {0..3}; do
        pin=${LED_PINS[$idx]}
        bit_mask=$((1 << pin))

        # Turn ON current LED (active-low)
        pretty_print "  ${LED_NAMES[$idx]} (GPIO$pin) ON for ${ON_DURATION}s"
        current=$(i2cget -y $I2C_BUS $I2C_ADDR $REG_OUTPUT 2>/dev/null || echo 0xFF)
        current=$((current & ~bit_mask))           # Clear bit → 0 = ON
        i2cset -y $I2C_BUS $I2C_ADDR $REG_OUTPUT $current
        sleep $ON_DURATION

        # Turn OFF current LED
        current=$(i2cget -y $I2C_BUS $I2C_ADDR $REG_OUTPUT 2>/dev/null || echo 0xFF)
        current=$((current | bit_mask))            # Set bit → 1 = OFF
        i2cset -y $I2C_BUS $I2C_ADDR $REG_OUTPUT $current
    done

    i2cset -y $I2C_BUS $I2C_ADDR $REG_OUTPUT 0x0F
    pretty_print "LED sequence completed. All LEDs OFF."
fi


check_test "LED Sequential" LED_TEST_RESULT

# ====================== #
# Temperature Test       #
# ====================== #
printf "\n\n"
pretty_print "Temperature Test"
printf "\n\n"
if [ -d /sys/class/thermal ]; then
    for zone in /sys/class/thermal/thermal_zone*; do
        [ -f "$zone/temp" ] || continue

        NAME=$(cat "$zone/type" 2>/dev/null)
        TEMP=$(cat "$zone/temp" 2>/dev/null)

        case "$TEMP" in
            ''|*[!0-9]*)
                echo "$NAME: N/A"
                continue
                ;;
        esac

        if [ "$TEMP" -ge 1000 ]; then
            INT=$(( TEMP / 1000 ))
            DEC=$(( (TEMP % 1000) / 100 ))
            printf "%s: %d.%01d °C\n" "$NAME" "$INT" "$DEC"
        else
            printf "%s: %d °C\n" "$NAME" "$TEMP"
        fi
    done
    TEMP_TEST_RESULT="y"
else
    echo "No thermal sensors found"
    TEMP_TEST_RESULT="n"
fi

check_test "Temperature" TEMP_TEST_RESULT

# ============= #
# Success Check #
# ============= #
if [ $PASSED -eq $TOTAL ]; then
    printf "\n\n\n"
    pretty_print 'All Tests have passed!'
    printf "\n\n\n"
else
    printf "\n\n\n"
    pretty_print 'ERROR: Not All Tests have passed!'
    printf "\n\n\n"
fi
