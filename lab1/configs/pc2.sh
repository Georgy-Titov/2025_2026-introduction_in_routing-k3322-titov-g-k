#!/bin/sh
set -e

ip link add link eth1 name vlan20 type vlan id 20
ip link set vlan20 up
udhcpc -i vlan20
