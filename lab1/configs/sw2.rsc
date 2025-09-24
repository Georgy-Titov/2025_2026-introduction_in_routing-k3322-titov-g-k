/system identity set name=SW2-Switch
/user add name=georgy password=strongpass group=full

/interface bridge
add name=br-edge vlan-filtering=yes

/interface bridge port
add bridge=br-edge interface=ether1
add bridge=br-edge interface=ether2  

/interface bridge vlan
add bridge=br-edge vlan-ids=10 tagged=ether1 untagged=ether2

/interface bridge port
set [find interface=ether2] pvid=10
