#!/bin/bash

# ========= #
# Functions #
# ========= #
function pretty_print {
	printf "\e[1;33m ################################################################### \e[0m\n"
	for line in "$@"; do
		printf "\e[1;33m ### %-59s ### \e[0m\n" "$line"
	done
	printf "\e[1;33m ################################################################### \e[0m\n"
}

function check_test {
	printf "\n\n\n\n"
	pretty_print "$1 test complete"
	printf "\n\n\n\n"
	printf "Did the %s test pass? (y/n) " "$1"
	read -r ANSWER

	if [[ "${ANSWER,,}" == "y" ]]; then
		((PASSED++))
	fi
	((TOTAL++))

	pretty_print "$PASSED of $TOTAL tests passed so far"
}

# ===== #
# Setup #
# ===== #
PASSED=0
TOTAL=0

# ======== #
# LED Test #
# ======== #
# TODO: uncomment when you find the led GPIOs
# pretty_print "Testing LED" \
#   "You should see it cycling through colors"
# sleep 1

# timeout .5 gpioset PA9=0
# timeout .5 gpioset PE9=0
# timeout .5 gpioset PA9=1
# timeout .5 gpioset PE13=0
# timeout .5 gpioset PE9=1
# timeout .5 gpioset PA9=0
# timeout .05 gpioset PE13=1
# timeout .05 gpioset PA9=1

# check_test "LED" LED

# ============= #
# Ethernet Test #
# ============= #
pretty_print "Please ensure an ethernet cable is connected" \
	"Press <enter> to continue"
read -r _

timeout 5s ping 8.8.8.8

check_test "Ethernet" ETH

# ========= #
# WiFi Test #
# ========= #
printf "Please enter the WiFi SSID: "
read -r SSID
printf "Please enter the WiFi Password: "
read -r PASSWORD

pretty_print "About to connect to the following WiFi network:" \
	"SSID=$SSID Password=$PASSWORD" \
	"Press <enter> to continue"

read -r _

wpa_passphrase "$SSID" "$PASSWORD" >>/etc/wpa_supplicant.conf
wpa_supplicant -B -i wlu1i2 -c /etc/wpa_supplicant.conf -D nl80211
timeout 20 udhcpc -i wlu1i2
timeout 5 ping 8.8.8.8

check_test "WiFi" WIFI

# ============== #
# Bluetooth Test #
# ============== #
hciconfig hci0 up
timeout 10 hcitool lescan
timeout 10 hcitool scan

check_test "Bluetooth" BLE

# ============= #
# Success Check #
# ============= #
if [ $PASSED -eq $TOTAL ]; then
	printf "\n\n\n\n"
	pretty_print 'All Tests have passed!'
	printf "\n\n\n\n"
else
	printf "\n\n\n\n"
	pretty_print 'ERROR: Not All Tests have passed!'
	printf "\n\n\n\n"
fi
