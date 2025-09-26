/system identity set name=SW2-Switch
/user add name=georgy password=strongpass group=full

/interface bridge
add name=br-edge

/interface vlan 
add name=vlan10 vlan-id=10 interface=br-edge
add name=vlan20 vlan-id=20 interface=br-edge

/interface bridge port
add bridge=br-edge interface=ether1
add bridge=br-edge interface=ether2

/interface bridge vlan
add bridge=br-edge vlan-ids=20 tagged=br-edge,ether1 untagged=ether2

/interface bridge port
set [find interface=ether2] pvid=20
