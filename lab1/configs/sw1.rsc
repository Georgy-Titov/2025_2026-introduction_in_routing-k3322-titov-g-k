/system identity set name=SW1-Switch
/user add name=georgy password=strongpass group=full

/interface bridge
add name=br-trunk vlan-filtering=yes

/interface bridge port
add bridge=br-trunk interface=ether1   
add bridge=br-trunk interface=ether2   
add bridge=br-trunk interface=ether3   

/interface bridge vlan
add bridge=br-trunk vlan-ids=10 tagged=ether1,ether2
add bridge=br-trunk vlan-ids=20 tagged=ether1,ether3
