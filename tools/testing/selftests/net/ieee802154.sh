#!/bin/bash
# SPDX-License-Identifier: GPL-2.0

# Kselftest framework requirement - SKIP code is 4.
ksft_skip=4

CHANNEL=13
PANID=0x4224
COUNT=5

DEST_SHORT=0x0002
DEST_LONG=DE:AD:BE:EF:BA:BE:00:02

test_setup_env () {
	if [ $UID != 0 ]; then
		echo "Please run ieee802154 test as root [SKIP]"
		exit $ksft_skip
	fi

	# Check if mac802154_hwsim is either compiled in or loaded, if not try
	# to load the module
	if [ ! -d /sys/module/mac802154_hwsim ]; then
		if /sbin/modprobe -q mac802154_hwsim ; then
			echo "Module mac802154_hwsim not found [SKIP]"
			exit $ksft_skip
		fi
	fi


	if [ ! hash iwpan 2>/dev/null ]; then
		echo "Command iwpan not found [SKIP]"
		echo "Please install the wpan-tools package for this test."
		exit $ksft_skip
	else
		iwpan --version
	fi

	if [ ! hash wpan-ping 2>/dev/null ]; then
		echo "Command wpan-ping not found [SKIP]"
		echo "Please install the wpan-tools package >= 0.9 for this test."
		exit $ksft_skip
	else
		wpan-ping --version
	fi
}

test_cleanup_env () {
	if /sbin/modprobe -q -r mac802154_hwsim; then
		echo "Removed mac802154_hwsim module";
	fi
}

# Setup a virtaul test bed with two ieee802154 radios (wpanX)
test_setup_hwsim () {
	ip link set wpan0 down
	iwpan dev wpan0 del
	iwpan phy phy0 interface add wpan0 type node DE:AD:BE:EF:BA:BE:00:01
	iwpan phy phy0 set channel 0 $CHANNEL
	iwpan dev wpan0 set ackreq_default 1
	iwpan dev wpan0 set pan_id $PANID
	iwpan dev wpan0 set short_addr 0x0001
	ip link set wpan0 up

	ip link set wpan1 down
	iwpan dev wpan1 del
	iwpan phy phy1 interface add wpan1 type node DE:AD:BE:EF:BA:BE:00:02
	iwpan phy phy1 set channel 0 $CHANNEL
	iwpan dev wpan1 set ackreq_default 1
	iwpan dev wpan1 set pan_id $PANID
	iwpan dev wpan1 set short_addr 0x0002
	ip link set wpan1 up
}

test_result_check () {
	if [ "$?" = "0" ]; then
		echo "$1 [PASS]";
	else
		echo "$1 [FAILED]";
	fi
}

test_wpan_ping () {
	# Start daemon on interface wpan1
	wpan-ping -i wpan1 -d &

	echo "---- IEEE 802.15.4 packet size testing ----"
	wpan-ping -a $DEST_SHORT -c $COUNT -s 5 -i wpan0
	test_result_check "ieee802154: wpan-ping: minimum wpan-ping size, short address:"

	wpan-ping -a $DEST_SHORT -c $COUNT -s 104 -i wpan0
	test_result_check "ieee802154: wpan-ping: maximum wpan-ping size, short address:"

	wpan-ping -e -a $DEST_LONG -c $COUNT  -s 5 -i wpan0
	test_result_check "ieee802154: wpan-ping: minimum wpan-ping size, extended address:"

	wpan-ping -e -a $DEST_LONG -c $COUNT -s 104 -i wpan0
	test_result_check "ieee802154: wpan-ping: maximum wpan-ping size, extended address:"
	killall wpan-ping
}

#source ieee802154.local

test_setup_env
test_setup_hwsim
#test_wpan_ping
test_cleanup_env
