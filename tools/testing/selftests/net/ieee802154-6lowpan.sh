#!/bin/bash
# SPDX-License-Identifier: GPL-2.0

# Kselftest framework requirement - SKIP code is 4.
ksft_skip=4

COUNT=5

test_setup_env () {
	if [ $UID != 0 ]; then
		echo "Please run ieee802154_6lowpan test as root [SKIP]"
		exit $ksft_skip
	fi

	# Check if mac802154_hwsim is either compiled in or loaded, if not try
	# to load the module
	if [ ! -d /sys/module/mac802154_hwsim ]; then
		if /sbin/modprobe -q mac802154_hwsim; then
			echo "Module mac802154_hwsim not found [SKIP]"
			exit $ksft_skip
		fi
	fi
}

test_simple_setup_hwsim () {
	ip link add link wpan0 name lowpan0 type lowpan
	ip link set wpan0 up
	ip link set lowpan0 up

	ip link add link wpan1 name lowpan1 type lowpan
	ip link set wpan1 up
	ip link set lowpan1 up
}

test_cleanup_env () {
	ip link delete lowpan0 type lowpan
	ip link delete lowpan1 type lowpan

	if /sbin/modprobe -q -r mac802154_hwsim; then
		echo "Removed mac802154_hwsim module";
	fi
}

test_result_check () {
	if [ "$?" = "0" ]; then
		echo "$1 [PASS]";
	else
		echo "$1 [FAILED]";
	fi
}

# Run ping6 with different size options and counts
test_6lowpan_ping6 () {
	# Allow 2 seconds for the link to go from tentaive to normal and packets get through
	sleep 2
	LOWPAN1_IPV6=$(ip a | grep lowpan1 -A 2 | tail -1 | awk '{print $2}' | rev | cut -c4- | rev)

	echo "---- 6LoWPAN ping6 packet size testing ----"
	ping -6 -q -A -c $COUNT $LOWPAN1_IPV6%lowpan0 >/dev/null 2>&1
	test_result_check "6LoWPAN ping6: default ping packet size (56 + 8), one frame:"

	ping -6 -q -A -c $COUNT -s 8 $LOWPAN1_IPV6%lowpan0 >/dev/null 2>&1
	test_result_check "6LoWPAN ping6: minimum ping packet size (8 + 8), one frame:"

	ping -6 -q -A -c $COUNT -s 90 $LOWPAN1_IPV6%lowpan0 >/dev/null 2>&1
	test_result_check "6LoWPAN ping6: maximum packet size for one frame (90 + 8), one frame:"

	ping -6 -q -A -c $COUNT -s 91 $LOWPAN1_IPV6%lowpan0 >/dev/null 2>&1
	test_result_check "6LoWPAN ping6: minimum packet size for two frames (91 + 8), two frames:"

	ping -6 -q -A -c $COUNT -s 1272 $LOWPAN1_IPV6%lowpan0 >/dev/null 2>&1
	test_result_check "6LoWPAN ping6: 1280 MTU to check IPv6 compliance (1272 + 8), XXX frames:"
}

source ieee802154.local

test_setup_env
test_simple_setup_hwsim
test_6lowpan_ping6
test_cleanup_env
