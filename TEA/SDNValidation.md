# SDN Validation Use Cases

## **Deploy Full SDN Stack**

**Description:**

Deploy full SDN stack on HCI cluster.

Deployment must include:

* Network Controller  (3 nodes)

* MUX (2 nodes)

* Gateways (2 nodes)


**Expected Result:**

SDN stack deploys with zero errors. All components are fully operational.

**Actual Result:**

SDN stack deploys with zero errors. All components are fully operational.

**Notes:**

Installing SDN stack enables Microsoft's VFP extension and therefore modifies
the default forwarding behavior of the VSwitch. It is possible that after
you uninstall the SDN stack, VM's may lose connectivity to the network.
This issue can be corrected by setting the correct port profile on a 
VM Network adapter. See Support cases and [Readme.md](./Readme.md)
for more info.   

---

## **Layer 3 Forwarding using Public IP address on VM**

**Description:**

Create and assign a Public IP address to a VM. Ensure forwarding of traffic to 
the Internet. Note, DNS is not validated in this test.

**Expected Result:**

IP traffic can reach public and private IP destinations without NAT translation.

**Actual Result:**

IP traffic can reach public and private IP destinations without NAT translation.

**Notes:**

Test consisted of creating the Public IP address and pinging 4.2.2.2.

---

## **Outbound NAT using SDN Load Balancer**

**Description:**

Use SLB MUX to NAT traffic from a VNET to the Internet

**Expected Result:**

VM is able to communicate with IP resources outside of the VNET using SLB MUX
with Outbound NAT.

**Actual Result:**

VM is able to communicate with IP resources outside of the VNET using SLB MUX
with Outbound NAT. However, pings were unsuccessful.

**Notes:**

Using NAT with SLB MUX does NOT support ICMP traffic. Only TCP/UDP traffic is
supported.

---

## **Layer 3 Forwarding with VNET Gateway - Static routes / BGP**

**Description:**

This use case is particularly important because on there will naturally be a
transition from traditional VLAN isolation to SDN isolation. This will require
that there is a way to communicate between VNETs and the physical network
without the requirement for NAT translation. This will be the use case TEA
will most likely target. Other options would include: assigning Public IP
addresses and SLB MUX with NAT. Both of these options are undesirable due to
either being to restrictive of IP traffic types or the explosion of Public IP
address requirements (an IP for communicating within the VNET and another
for communicating to the outside world).

**Expected Result:**

IP traffic is able to flow from VNET to Physical network via VNET gateway.



**Actual Result:**

**Notes:**



## **Deploy Datacenter Firewall ACL to control Inbound/Outbound Traffic Flows**

## **Establish Intra subnet communication within a Single VNET**

## **VNET to VNET Peering**

## **SDN Isolation using VLAN and Logical Network**

## **Manage SDN with Windows Admin Center (WAC)**

* Load Balancer

* Logical Networks

* Gateway Connections

* Virtual Networks / Subnets

* Virtaul Switches

* Public IP addresses

* Access Control Lists

* Route Tables

## **Deploy and Test iDNS services**


Template

**Description:**

**Expected Result:**

**Actual Result:**

**Notes:**

   