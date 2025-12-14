#!/bin/sh
ip route del default via 172.161.16.1 dev eth0
udhcpc -i eth1
