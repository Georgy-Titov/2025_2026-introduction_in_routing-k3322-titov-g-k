/system identity set name=SW2-Switch
/user add name=georgy password=strongpass group=full

/interface bridge
add name=br-edge

/interface vlan 
add name=vlan10 vlan-id=10 interface=br-edge

/interface bridge port
add bridge=br-edge interface=ether2
add bridge=br-edge interface=ether3 pvid=10

/interface bridge vlan
add bridge=br-edge vlan-ids=10 tagged=br-edge,ether2 untagged=ether3 vlan-ids=10

/interface bridge port
set [find interface=ether2] pvid=10
