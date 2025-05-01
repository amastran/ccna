# 2025-05-01 15:22:22 by RouterOS 7.16
# software id =
#
/interface ethernet
set [ find default-name=ether1 ] disable-running-check=no name=ether1-WAN
set [ find default-name=ether2 ] disable-running-check=no name=ether2-MGMT
set [ find default-name=ether3 ] disable-running-check=no name=ether3-LAN
set [ find default-name=ether4 ] disable-running-check=no name=ether4-TO-R2
set [ find default-name=ether5 ] disable-running-check=no
set [ find default-name=ether6 ] disable-running-check=no
set [ find default-name=ether7 ] disable-running-check=no
set [ find default-name=ether8 ] disable-running-check=no
/interface list
add name=WAN
add name=LAN
add name=MGMT
/ip pool
add name=DHCP-POOL ranges=192.168.219.15-192.168.219.50
/ip dhcp-server
add address-pool=DHCP-POOL interface=ether3-LAN name=DHCP-LAN server-address=\
    192.168.219.1
/port
set 0 name=serial0
/ip settings
set max-neighbor-entries=12288
/ipv6 settings
set max-neighbor-entries=6144
/interface list member
add interface=ether1-WAN list=WAN
add interface=ether3-LAN list=LAN
add interface=ether2-MGMT list=MGMT
add interface=ether4-TO-R2 list=LAN
/ip address
add address=192.168.219.1/24 interface=ether3-LAN network=192.168.219.0
add address=192.168.88.1/24 interface=ether2-MGMT network=192.168.88.0
add address=10.10.10.2/30 interface=ether4-TO-R2 network=10.10.10.0
/ip dhcp-client
add comment="Dhcp sulla wan" interface=ether1-WAN
/ip dhcp-server network
add address=192.168.219.0/24 dns-server=192.168.122.1 domain=r3.testlan \
    gateway=192.168.219.1 netmask=24
/ip firewall filter
add action=accept chain=input comment="MANAGEMENT SU WAN" in-interface=\
    ether2-MGMT
add action=accept chain=forward comment="accett  in stato new  per forwarding \
    sulla lanlist, sblocca tutto il traffico per la LAN" connection-state=new \
    in-interface-list=LAN src-address=10.10.10.0/30
add action=accept chain=forward comment="accett  in stato new  per forwarding \
    sulla lanlist, sblocca tutto il traffico per la LAN" connection-state=new \
    in-interface-list=LAN src-address=192.168.219.0/24
add action=accept chain=forward comment="Allow Related" connection-state=\
    related
add action=accept chain=forward comment="Allow Established" connection-state=\
    established
add action=accept chain=input comment="Accetto Established Input" \
    connection-state=established
add action=accept chain=input comment="Accetto Related Input" \
    connection-state=related
add action=reject chain=forward comment=\
    "reject in stato new per forwardin: regola molto drastica" \
    connection-state=new reject-with=icmp-network-unreachable
add action=accept chain=input comment="Pemetto di arrivare sulla PTP Logica da\
    gli ip con il sorgente 192.168.219.0/24 della LAN " connection-state=new \
    in-interface=ether3-LAN src-address=192.168.219.0/24
add action=drop chain=input comment="Droppo all input" log=yes log-prefix=\
    DROP-INPUT
/ip firewall nat
add action=src-nat chain=srcnat comment="SOURCE NAT PER SOLO LAN " \
    out-interface-list=WAN src-address=192.168.219.0/24 to-addresses=\
    192.168.122.208
add action=masquerade chain=srcnat comment="MASQUERADE SU WAN LIST" disabled=\
    yes out-interface-list=WAN
/system identity
set name=R3
/system note
set show-at-login=no
