#!/bin/sh
set -e

ip route del defalt via 172.160.16.1 dev eth0
udhcpc -i eth1
