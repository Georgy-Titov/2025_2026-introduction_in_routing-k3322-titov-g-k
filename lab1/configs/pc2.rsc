#!/bin/sh
ip link add link eth1 name vlan20 type vlan id 20
ip link set vlan20 up
dhclient vlan20
