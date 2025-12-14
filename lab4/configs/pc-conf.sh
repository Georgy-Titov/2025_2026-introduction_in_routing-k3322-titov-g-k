#!/bin/sh
ip route del default via 172.160.18.1 dev eth0
udhcpc -i eth1
