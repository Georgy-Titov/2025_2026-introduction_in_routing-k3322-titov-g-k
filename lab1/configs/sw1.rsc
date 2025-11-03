/system identity set name=SW1-Switch
/user add name=georgy password=strongpass group=full

/interface bridge
add name=br-trunk vlan-filtering=yes

/interface vlan 
add name=vlan10 vlan-id=10 interface=br-trunk
add name=vlan20 vlan-id=20 interface=br-trunk

/interface bridge port
add bridge=br-trunk interface=ether2
add bridge=br-trunk interface=ether3   
add bridge=br-trunk interface=ether4   

/interface bridge vlan
add bridge=br-trunk tagged=br-trunk,ether2,ether3 vlan-ids=10
add bridge=br-trunk tagged=br-trunk,ether2,ether4 vlan-ids=20

/ip address
add address=10.10.10.2/24 interface=vlan10
add address=10.10.20.2/24 interface=vlan20
