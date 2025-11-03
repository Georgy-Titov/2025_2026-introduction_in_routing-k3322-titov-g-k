#!/bin/sh
set -e

ip link add link eth1 name vlan10 type vlan id 10
ip link set vlan10 up
udhcpc -i vlan10
ip route add 10.20.0.0/24 via 10.10.0.1 dev vlan10
