#!/bin/sh
set -e

ip link add link eth1 name vlan10 type vlan id 10
ip link set vlan10 up
udhcpc -i vlan10
