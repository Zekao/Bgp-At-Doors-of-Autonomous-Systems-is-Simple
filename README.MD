# Part 1

#### GNS3 CONFIGURATION WITH DOCKER
-   First of all, we need to install GNS3 on our machine. You can download it from [here](https://docs.gns3.com/docs/getting-started/installation/linux/).
-   After installing GNS3, we need to install Docker. You can download it from [here](https://docs.docker.com/engine/install/ubuntu/).

## First of all, we need to create two images
-   A first image with a system of our choice (in my case, I used alpine:3.14)

-   A second image with a system of our choice with some tools installed 

| |  |
|--|--|
| **Zebra or quagga** | *A network routing software that will provide implementation of differents protocols (BGP), (OSPF), (RIP)...*
| **BGPD** | *A BGP Daemon (bgp is a TCP protocol using the best way algorighm, it have some advantages for big networks because it will automaticaly take the best way to transmit the datas)*
| **OSPFD** | *A OSPF Daemon (ospf is an IP protocol, used most of time for little networks ) .*
| **IS-IS route engine service** | *IS-IS is a link-state IGP that uses the shortest-path-first (SPF) algorithm to determine routes* 
| **BusyBox or an equivalent** | *BusyBox is a multi-call binary that combines many common Unix utilities into a single executable.*

> **Note:** You can find a document explaining difference between BGP and OSPF [here](https://community.fs.com/fr/blog/ospf-vs-bgp-routing-protocol-choice.html)

## Now, we need to create the dockerfiles

-  First dockerfile containing BusyBox

```dockerfile
FROM alpine:3.14

RUN apk add vim 
```

-  Second dockerfile containing Zebra, BGPD, OSPFD, IS-IS route engine service

```dockerfile
FROM alpine:3.14

RUN apk --no-cache add quagga tini && \
    rm -rf /var/cache/apk/* && \
    touch /etc/quagga/zebra.conf && \
    touch /etc/quagga/vtysh.conf && \
    touch /etc/quagga/ospfd.conf && \
    touch /etc/quagga/bgpd.conf && \
    touch /etc/quagga/isisd.conf

COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh && chmod 777 -R /etc/quagga

ENTRYPOINT ["/sbin/tini", "--"]

CMD [ "/entrypoint.sh" ]
```
- The entrypoint.sh will just run all the daemons

```bash
#!/bin/sh

ospfd -d && isisd -d && bgpd -d && zebra -d

/usr/sbin/watchquagga ospfd bgpd isisd zebra
```

--------------------

# Part 2

### DISCOVERING A VXLAN

First of all, we need to create the same network topology on GNS3 as the one in the subject

![image](https://zekao.s-ul.eu/L621xIr3.png)

- We need to configurate the routers with the following commands in order to set up the VXLAN

```bash
# R1
    vtysh # router CLI
    conf t # enter configuration mode
    ip forwarding # enable ip forwarding
    int eth1 # select the interface
    no sh # enable interface
    ip address 32.1.1.253/24 # set the ip address
    int eth0 # select the interface
    no sh # enable interface
    ip address 30.1.1.253/24 # set the ip address
    do write # apply the configuration
    exit # exit the configuration mode
    exit # exit the vtysh mode

    # eth0 will be the interface for the VXLAN

# R1 -> Unicast Routing
ip link add vxlan10 type vxlan id 10 remote 30.1.1.253 dstport 4789 dev eth0 #  distant ip address where the packet will be sent in port 4789
ip link set vxlan10 up
ip addr add 32.1.1.253/24 dev vxlan10

# R2
    vtysh # router CLI
    conf t # enter configuration mode
    ip forwarding # enable ip forwarding
    int eth1 # select the interface
    no sh # enable interface
    ip address 32.1.1.254/24 # set the ip address
    int eth0 # select the interface
    no sh # enable interface
    ip address 30.1.1.254/24 # set the ip address
    do write # apply the configuration
    exit # exit the configuration mode
    exit # exit the vtysh mode

    # eth0 will be the interface for the VXLAN

# R2 -> Unicast Routing
ip link add vxlan10 type vxlan id 10 remote 30.1.1.254 dstport 4789 dev eth0 # distant ip address where the packet will be sent in port 4789
ip link set vxlan10 up
ip addr add 32.1.1.254/24 dev vxlan10
```
- Then, we need to create a bridge in order to connect the link vxlan10 to the eth1 interface to have the same traffic 

```bash
# R1
ip link add name br0 type bridge
ip link set br0 up
ip link set vxlan10 master br0
ip link set eth1 master br0

# R2

ip link add name br0 type bridge
ip link set br0 up
ip link set vxlan10 master br0
ip link set eth1 master br0
```

- Now, we need to configure the hosts

```bash
# H1
ip addr add 32.1.1.1/24 dev eth1
route add default gw 32.1.1.254 

# H2
ip addr add 32.1.1.2/24 dev eth1
route add default gw 32.1.1.253
```

- Now, we can ping the hosts

```bash
# From H1
ping 32.1.1.2
``` 
![image](https://zekao.s-ul.eu/Pok9h4FF.png)

#### We can also analyze the traffic with Wireshark to see if the VXLAN is correctly working

![image](https://zekao.s-ul.eu/TKVjZHsU.png)


## Now, we will need to setup the multicast routing

First of all, we need to understand what is the multicast routing

- The unicast routing is used to send a packet to a specific destination. The packet will be sent to the destination IP address. The unicast routing is used for the majority of the network traffic.

- The multicast routing is used to send a packet to a group of destination. The packet will be sent to the multicast IP address. The multicast routing is used for the network traffic that needs to be sent to a group of destination.

- The broadcast routing is used to send a packet to all the destination. The packet will be sent to the broadcast IP address. The broadcast routing is used for the network traffic that needs to be sent to all the destination.

![image](https://techterms.com/img/xl/multicast_946.png)

#### Now, we need to configure the multicast routing

```bash
# R1
ip link delete vxlan10 # delete the unicast vxlan
ip link add vxlan10 type vxlan id 10 dstport 4789 group 239.1.1.1 dev eth0 ttl auto # 239.1.1.1 will communicate with 30.1.1.254 in the port 4789 with auto ttl for the packets
ip link set up dev vxlan10
ip addr add 32.1.1.254/24 dev vxlan10

# R2
ip link delete vxlan10 # delete the unicast vxlan
ip link add vxlan10 type vxlan id 10 dstport 4789 group 239.1.1.1 dev eth0 ttl auto # 239.1.1.1 will communicate with 30.1.1.253 in the port 4789 with auto ttl for the packets
ip link set up dev vxlan10
ip addr add 32.1.1.253/24 dev vxlan10
```



--------------------

# Part 3