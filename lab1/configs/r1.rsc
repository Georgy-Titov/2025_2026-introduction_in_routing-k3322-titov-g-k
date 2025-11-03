/system identity set name=R1-Router
/user add name=georgy password=strongpass group=full

/interface vlan
add name=vlan10 vlan-id=10 interface=ether2
add name=vlan20 vlan-id=20 interface=ether2

/ip address
add address=10.10.10.1/24 interface=vlan10
add address=10.10.20.1/24 interface=vlan20

/ip pool
add name=dhcp_pool_vlan10 ranges=10.10.10.128-10.10.10.254
add name=dhcp_pool_vlan20 ranges=10.10.20.128-10.10.20.254

/ip dhcp-server
add name=dhcp_vlan10 interface=vlan10 address-pool=dhcp_pool_vlan10 disabled=no
add name=dhcp_vlan20 interface=vlan20 address-pool=dhcp_pool_vlan20 disabled=no

/ip dhcp-server network
add address=10.10.10.0/24 gateway=10.10.10.1
add address=10.10.20.0/24 gateway=10.10.20.1
