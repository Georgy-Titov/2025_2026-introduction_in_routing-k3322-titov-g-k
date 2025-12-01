/user add name=georgy password=strongpass group=full remove admin
/system identity set name=R01.MSC

/ip address
add address=10.10.2.2/30 interface=ether2
add address=10.10.4.1/30 interface=ether3

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.3/32 interface=loopback network=10.255.255.3

/routing ospf instance
add name=inst router-id=10.255.255.3
/routing ospf area
add name=backbonev2 area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbonev2 network=10.10.2.0/30
add area=backbonev2 network=10.10.4.0/30
add area=backbonev2 network=10.255.255.3/32

/mpls ldp
set lsr-id=10.255.255.3
set enabled=yes transport-address=10.255.255.3
/mpls ldp advertise-filter 
add prefix=10.255.255.0/24 advertise=yes
add advertise=no
/mpls ldp accept-filter 
add prefix=10.255.255.0/24 accept=yes
add accept=no
/mpls ldp interface
add interface=ether2
add interface=ether3
