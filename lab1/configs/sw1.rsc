/system identity set name=SW1-Switch
/user add name=georgy password=strongpass group=full

/interface bridge
add name=bridge vlan-filtering=yes

/interface vlan
add name=vlan10 vlan-id=10 interface=bridge
add name=vlan20 vlan-id=20 interface=bridge

/interface bridge port
add bridge=bridge interface=ether2
add bridge=bridge interface=ether3
add bridge=bridge interface=ether4

/interface bridge vlan
add bridge=bridge tagged=bridge,ether2,ether3 vlan-ids=10
add bridge=bridge tagged=bridge,ether2,ether4 vlan-ids=20

/ip address
add address=10.10.0.2/24 interface=vlan10
add address=10.20.0.2/24 interface=vlan20
