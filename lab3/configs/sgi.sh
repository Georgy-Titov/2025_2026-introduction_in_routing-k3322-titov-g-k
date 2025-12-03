#!/bin/sh
ip route del default via 172.20.16.1 dev eth0
udhcpc -i eth1
