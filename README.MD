# Part 1

#### GNS3 CONFIGURATION WITH DOCKER
-   First of all, we need to install GNS3 on our machine. You can download it from [here](https://www.gns3.com/software/download).
-   After installing GNS3, we need to install Docker. You can download it from [here](https://www.docker.com/products/docker-desktop).

## First of all, we need to create two images
-   A first image with a system of our choice (in my case, I used alpine:3.14)

-   A second image with a system of our choice with some tools installed 

| |  |
|--|--|
| **Zebra or quagga** | *A network routing software that will provide implementation of differents protocols (BGP), (OSPF), (RIP)...*
| **BGPD** | *A BDP Daemon (bgp is a TCP protocol using the best way algorighm, it have some advantages for big networks because it will automaticaly take the best way to transmit the datas)*
| **OSPFD** | *A OSPF Daemon (ospf is an IP protocol, used most of time for little networks ) .*
| **IS-IS route engine service** | *IS-IS is a link-state IGP that uses the shortest-path-first (SPF) algorithm to determine routes* 
| **BusyBox or an equivalent** | *BusyBox is a multi-call binary that combines many common Unix utilities into a single executable.*

> **Note:** You can find a document explaining difference between BGP and OSPF [here](https://community.fs.com/fr/blog/ospf-vs-bgp-routing-protocol-choice.html)

## Now, we need to create a topology
-   We need to create a topology with 2 routers and 2 switches. We will connect the routers to the switches and the switches to the routers. We will also connect the routers to each other.

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

