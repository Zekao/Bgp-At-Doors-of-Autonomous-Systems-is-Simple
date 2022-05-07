# routeur_nabentay-1
vtysh
enable
conf t
ip forwarding
int eth1
no sh
ip address 32.1.1.254/24
int eth0 
no sh
ip address 30.1.1.254/24
do write

# Add vxlan UNICAST
ip link add vxlan10 type vxlan id 10 remote 30.1.1.2 dstport 4789 dev eth0
ip link set vxlan10 up
ip addr add 32.1.1.254/24 dev vxlan10

# Add vxlan MULTICAST
ip link add vxlan10 type vxlan id 10 dstport 4789 group 239.1.1.1 dev eth0 ttl auto
ip link set up dev vxlan10
ip addr add 32.1.1.254/24 dev vxlan10

# Add bridge interface
ip link add name br0 type bridge
ip link set br0 up
ip link set vxlan10 master br0
ip link set eth1 master br0

# routeur_nabentay-2
vtysh
enable
conf t
ip forwarding
int eth1
no sh
ip address 32.1.1.253/24
int eth0 
no sh
ip address 30.1.1.253/24
do write

# Add vxlan UNICAST
ip link add vxlan10 type vxlan id 10 remote 30.1.1.1 dstport 4789 dev eth0
ip link set vxlan10 up
ip addr add 32.1.1.253/24 dev vxlan10

# Add vxlan MULTICAST
ip link add vxlan10 type vxlan id 10 dstport 4789 group 239.1.1.1 dev eth0 ttl auto
ip link set up dev vxlan10
ip addr add 32.1.1.253/24 dev vxlan10

# Add bridge interface
ip link add name br0 type bridge
ip link set br0 up
ip link set vxlan10 master br0
ip link set eth1 master br0

# host_nabentay-1
auto eth1
iface eth1 inet static
	address 32.1.1.1
	netmask 255.255.255.0
	gateway 32.1.1.254

# host_nabentay-2
auto eth1
iface eth1 inet static
	address 32.1.1.2
	netmask 255.255.255.0
	gateway 32.1.1.253