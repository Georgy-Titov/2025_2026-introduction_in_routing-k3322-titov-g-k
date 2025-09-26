#!/bin/sh
set -e
ip link set eth1 up

dhclient -v eth2 || exit 0
