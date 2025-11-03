/system identity set name=SW2-Switch
/user add name=georgy password=strongpass group=full

/interface bridge
add name=br-edge

/interface vlan 
add name=vlan20 vlan-id=20 interface=br-edge

/interface bridge port
add bridge=br-edge interface=ether2
add bridge=br-edge interface=ether3 pvid=20

/interface bridge vlan
add bridge=br-edge tagged=br-edge,ether2 untagged=ether3 vlan-ids=20

/ip address
add address=10.10.20.3/24 interface=vlan20
