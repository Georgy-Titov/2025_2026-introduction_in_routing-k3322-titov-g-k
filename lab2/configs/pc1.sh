#!/bin/sh
set -e

ip route del default via 172.160.16.1 dev eth0
udhcpc -i eth1
