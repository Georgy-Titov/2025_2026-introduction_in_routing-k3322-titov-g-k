#!/bin/sh
set -e
ip link set eth2 up

dhclient -v eth2 || exit 0
