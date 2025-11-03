#!/bin/sh
set -e

ip link add link eth1 name vlan20 type vlan id 20
ip link set vlan20 up
udhcpc -i vlan20
ip route add 10.10.0.0/24 via 10.20.0.1 dev vlan20
