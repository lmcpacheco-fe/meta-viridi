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
pretty_print "Starting test for Viridi-imx93"
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

EMMC_DEV="/dev/mmcblk0"

if [ -b "$EMMC_DEV" ]; then
    pretty_print "eMMC device $EMMC_DEV found"
    lsblk "$EMMC_DEV"

    EMMC_TEST_RESULT="y"
else
    pretty_print "ERROR: eMMC device $EMMC_DEV not found"
    EMMC_TEST_RESULT="n"
fi

check_test "eMMC" EMMC_TEST_RESULT

# ====================== #
# FlexSPI NOR Test       #
# ====================== #
# printf "\n\n"
# pretty_print "Starting FlexSPI NOR test"
# printf "\n\n"

# MTD_DEV=/dev/mtd0

# # Write pattern: 11 22 33 44 55 66 77 88 at offset 0
# printf "\x11\x22\x33\x44\x55\x66\x77\x88" > /tmp/nor_expected.bin

# # Erase first sector
# flash_erase $MTD_DEV 0 1 >/dev/null 2>&1

# # Write pattern
# dd if=/tmp/nor_expected.bin of=$MTD_DEV bs=1 seek=0 count=8 conv=notrunc 2>/dev/null

# # Read back 8 bytes
# dd if=$MTD_DEV of=/tmp/nor_read.bin bs=1 skip=0 count=8 2>/dev/null

# # Compare
# if cmp -s /tmp/nor_expected.bin /tmp/nor_read.bin; then
#     pretty_print "FlexSPI NOR test PASSED!"
#     SPI_TEST_RESULT="y"
# else
#     pretty_print "FlexSPI NOR test FAILED!"
#     SPI_TEST_RESULT="n"
# fi

# check_test "FlexSPI NOR" $SPI_TEST_RESULT

# # Clean up
# rm -f /tmp/nor_expected.bin /tmp/nor_read.bin

# ====================== #
# EEPROM Test (simple)   #
# ====================== #
printf "\n\n"
pretty_print "Starting EEPROM test"
printf "\n\n"

I2C_BUS=2
EEPROM_ADDR=0x54    # 7-bit address: 0xA8 → 0x54 in decimal

# Write 8 bytes: 11 22 33 44 55 66 77 88 at offsets 0x00..0x07
i2ctransfer -y $I2C_BUS w2@$EEPROM_ADDR 0x00 0x11; usleep 10000
i2ctransfer -y $I2C_BUS w2@$EEPROM_ADDR 0x01 0x22; usleep 10000
i2ctransfer -y $I2C_BUS w2@$EEPROM_ADDR 0x02 0x33; usleep 10000
i2ctransfer -y $I2C_BUS w2@$EEPROM_ADDR 0x03 0x44; usleep 10000
i2ctransfer -y $I2C_BUS w2@$EEPROM_ADDR 0x04 0x55; usleep 10000
i2ctransfer -y $I2C_BUS w2@$EEPROM_ADDR 0x05 0x66; usleep 10000
i2ctransfer -y $I2C_BUS w2@$EEPROM_ADDR 0x06 0x77; usleep 10000
i2ctransfer -y $I2C_BUS w2@$EEPROM_ADDR 0x07 0x88; usleep 10000

# Read back 8 bytes from offset 0x00
readback=$(i2ctransfer -y $I2C_BUS w1@$EEPROM_ADDR 0x00 r8 | tr -d '\n')

# Compare
expected="0x11 0x22 0x33 0x44 0x55 0x66 0x77 0x88"
if [ "$readback" = "$expected" ]; then
    pretty_print "EEPROM test PASSED!"
    echo "Expected: $expected"
    echo "Read:     $readback"
    EEPROM_TEST_RESULT="y"
else
    pretty_print "EEPROM test FAILED!"
    echo "Expected: $expected"
    echo "Read:     $readback"
    EEPROM_TEST_RESULT="n"
fi

check_test "I2C EEPROM" $EEPROM_TEST_RESULT

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
i2cdetect -y -l

pretty_print "Scanning I2C1 (should have IO Expander at 0x44 and RTC at 0x51 )"
i2cdetect -y 0

pretty_print "Probing IO Expander at bus 0, address 0x44"
if i2cget -y -f 0 0x44 0x00>/dev/null >/dev/null; then
    echo "IO Expander at 0x44 responded"
else
    echo "ERROR: IO Expander at 0x44 did NOT respond"
fi

pretty_print "Probing RTC at bus 0, address 0x53"
if i2cget -y -f 0 0x53 0x00>/dev/null >/dev/null; then
    echo "RTC at 0x53 responded"
else
    echo "ERROR: RTC at 0x53 did NOT respond"
fi

pretty_print "Scanning I2C2 (should have PCA9451 at 0x25)"
i2cdetect -y 1

pretty_print "Probing PCA9451 at bus 1, address 0x25"
if i2cget -y -f 1 0x25 0x00 2>/dev/null >/dev/null; then
    echo "PCA9451 at 0x25 responded"
else
    echo "ERROR: PCA9451 at 0x25 did NOT respond"
fi

pretty_print "Scanning I2C3 (should have EEPROM at 0x54)"
i2cdetect -y 2

pretty_print "Probing EEPROM at bus 2, address 0x54"
if i2cget -y -f 2 0x54 0x00 2>/dev/null >/dev/null; then
    echo "EEPROM at 0x54 responded"
else
    echo "ERROR: EEPROM at 0x54 did NOT respond"
fi

pretty_print "Scanning I2C5 (should have two IO Expanders, one at 0x20 an other at 0x21)"
i2cdetect -y 4

pretty_print "Probing IO Expander at bus 4, address 0x20"
if i2cget -y -f 4 0x20 0x00 2>/dev/null >/dev/null; then
    echo "IO Expander at 0x20 responded"
else
    echo "ERROR: IO Expander at 0x20 did NOT respond"
fi
pretty_print "Probing IO Expander at bus 4, address 0x21"
if i2cget -y -f 4 0x21 0x00 2>/dev/null >/dev/null; then
    echo "IO Expander at 0x21 responded"
else
    echo "ERROR: IO Expander at 0x21 did NOT respond"
fi

check_test "I2C" "y"

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
