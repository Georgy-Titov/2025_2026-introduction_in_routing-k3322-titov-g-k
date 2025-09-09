/interface vlan
add name=vlan20_e1 vlan-id=10 interface=ether1
add name=vlan20_e2 vlan-id=10 interface=ether2
/interface bridge
add name=br_v20
/interface bridge port
add interface=vlan20_e1 bridge=br_v20
add interface=vlan20_e2 bridge=br_v20
/ip dhcp-client
add disabled=no interface=br_v20
/user add name=georgy password=adminn group=full
/system identity set name=SW2-Switch
