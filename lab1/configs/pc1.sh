#!/bin/sh
set -e
ip link add link eth2 name vlan10 type vlan id 10

ip link set vlan10 up

dhclient -v vlan10 || exit 0
