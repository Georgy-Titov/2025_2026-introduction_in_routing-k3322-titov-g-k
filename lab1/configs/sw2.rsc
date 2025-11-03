/system identity set name=SW2-Switch
/user add name=georgy password=strongpass group=full

/interface bridge
add name=bridge

/interface vlan
add name=vlan10 vlan-id=10 interface=bridge

/interface bridge port
add bridge=bridge interface=ether2
add bridge=bridge interface=ether3 pvid=10

/interface bridge vlan
add bridge=bridge tagged=bridge,ether2 untagged=ether3 vlan-ids=10

/ip address
add address=10.10.0.3/24 interface=vlan10
