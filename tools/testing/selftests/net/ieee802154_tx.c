// SPDX-License-Identifier: GPL-2.0

/* Copyright (C) 2018 Stefan Schmidt <stefan@datenfreihafen.org> */

#include <sys/types.h>
#include <sys/socket.h>
#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <string.h>

#define IEEE802154_ADDR_LEN 8
#define MAX_PACKET_LEN 127

enum {
	IEEE802154_ADDR_NONE = 0x0,
	IEEE802154_ADDR_SHORT = 0x2,
	IEEE802154_ADDR_LONG = 0x3,
};

struct ieee802154_addr_sa {
	int addr_type;
	uint16_t pan_id;
	union {
		uint8_t hwaddr[IEEE802154_ADDR_LEN];
		uint16_t short_addr;
	};
};

struct sockaddr_ieee802154 {
	sa_family_t family;
	struct ieee802154_addr_sa addr;
};

int main(int argc, char *argv[]) {
	int sd;
	ssize_t len;
	struct sockaddr_ieee802154 dst;
	char buf[MAX_PACKET_LEN + 1];
	uint8_t long_addr[IEEE802154_ADDR_LEN] = {0xd6, 0x55, 0x2c, 0xd6, 0xe4, 0x1c, 0xeb, 0x57};

	sd = socket(PF_IEEE802154, SOCK_DGRAM, 0);
	if (sd < 0) {
		perror("socket");
		return 1;
	}

	memset(&dst, 0, sizeof(dst));
	dst.family = AF_IEEE802154;
	dst.addr.pan_id = 0x4224;

	sprintf(buf, "Hello world from IEEE 802.15.4 socket example!");

	dst.addr.addr_type = IEEE802154_ADDR_LONG;
	memcpy(&dst.addr.hwaddr, long_addr, IEEE802154_ADDR_LEN);
	len = sendto(sd, buf, strlen(buf), 0, (struct sockaddr *)&dst, sizeof(dst));
	if (len < 0) {
		perror("sendto");
	}

	dst.addr.addr_type = IEEE802154_ADDR_SHORT;
	dst.addr.short_addr = 0x0002;
	len = sendto(sd, buf, strlen(buf), 0, (struct sockaddr *)&dst, sizeof(dst));
	if (len < 0) {
		perror("sendto");
	}

	shutdown(sd, SHUT_RDWR);
	close(sd);
	return 0;
}
