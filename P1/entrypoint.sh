#!/bin/sh

ospfd -d && isisd -d && bgpd -d && zebra -d

/usr/sbin/watchquagga ospfd bgpd isisd zebra
