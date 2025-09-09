/interface vlan
add name=vlan10_e1 vlan-id=10 interface=ether1
add name=vlan20_e1 vlan-id=20 interface=ether1
add name=vlan10_e2 vlan-id=10 interface=ether2
add name=vlan20_e3 vlan-id=20 interface=ether3
/interface bridge
add name=br_v10
add name=br_v20
/interface bridge port
add interface=vlan10_e1 bridge=br_v10
add interface=vlan10_e2 bridge=br_v10
add interface=vlan20_e1 bridge=br_v20
add interface=vlan20_e3 bridge=br_v20
/ip dhcp-client
add disabled=no interface=br_v20
add disabled=no interface=br_v10
/user add name=georgy password=admin group=full
/system identity set name=SW1-Switch
