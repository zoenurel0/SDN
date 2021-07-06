# **Support Info**


## **Support Contact Info:**
Phone:800-936-3100


## **Cases:**

* **SDN Express Installation fails while adding Gateways to Network Controller**

  Case #:
  2105070040002878

  Upload files to:
  <https://protect-us.mimecast.com/s/SVD5Co2nW4SXX9zBi2Vbbn?domain=support.microsoft.com>

  Status: [Closed]

* Notes about deploying the SDN stack using SDN Express
  * The PA addresses of MUX'es, MUST be part of the PA pool range. IF MUX PA
    addresses are not part of the PA pool range, then SDN installation will
    fail!
  * There seems to be a bug where the install logic does not keep track of
    what PA addresses have been assigned to MUX'es while allocating PA
    addresses to the HyperV hosts. While assigning PA addresses to HyperV
    hosts, addresses are allocated from the beginning of the pool and
    increments upward toward the pool end. It is possible that duplicate
    addresses may result if PA IP addresses from MUX'es overlap with
    PA addresses assigned to HyperV host. To avoid this scenario, assign PA IP
    addresses to MUX'es starting from the pool end.  Example, if the PA pool
    starts at 192.168.0.10 (PAPoolStart) and ends at 192.168.0.100 (PAPoolEnd),
    assign MUX PA addresses starting at 192.168.0.100, then .99, 98 etc. When
    the SDN scripts run and the Network controller allocates PA IP addresses
    to the HyperV host, it will begin assigning addresses starting at
    192.168.0.10, then .11, .12 etc. 

* NAT and SLB
  * ICMP does not work for NAT and load balancers. Can you try running:
    Test-NetConnection 8.8.8.8 -port 443. If that does not solve the problem,
    I can try to  troubleshoot with you. If you have the case handy and the
    name of the engineer, please pass that along as well so that I can look at
    the history.
  * For outbound NAT, the traffic goes directly from the host through the PA
    network. When the response comes back, it will come through the SLB MUX.
    This is an optimization we have done and is called Direct Server Return.
    
    <https://docs.microsoft.com/en-us/azure-stack/hci/concepts/software-load-balancer>  

 

## **Open Issues:**

* **How do you create a VM from ISO image?**
  * ISO boot has no automation built in. Requires user input to proceed.
    What is the proper workflow to create VM from ISO?

* **Networking**
  
  * Adding and Deleting Network Adaptors via Windows Admin Center:

    Network adaptors along with their associated isolation properties are
    created on the Network Controller via Windows Admin Center, Powershell
    or API calls. When you create a Network adaptor with SDN isolation and
    assign an IP address, the OS on the guest VM will use DHCP to obtain
    the configured IP address. There is no need to configure a static IP
    address on the guest OS.

  * Can't ping default gateway on jaxazshcit1 (PA Addresses are failing to configure on this host)
    Why is X getting the PA addresses that are assigned to the muxes?
    
    ```bash
    Import-Module NetworkControllerDiagnostics
    Get-ProviderAddress
    
    Address        : 10.4.32.71
    MacAddress     :
    PrefixLength   : 27
    DefaultGateway : {10.4.32.65}
    VlanID         : 50

    Address        : 10.4.32.72
    MacAddress     :
    PrefixLength   : 27
    DefaultGateway : {10.4.32.65}
    VlanID         : 50
    ```
    * ANSWER1: Mgmt and PA addresses of SDN VM's must be allocated from the
      ManagementSubnet and PASubnet pools. See "Notes about deploying the SDN
      stack using SDN Express" above.

* VMs not able to forward traffic after removing SDN stack
  * After removing the SDN components, VMs cannot ping the PA the PA gateway.
  * Are the PA addresses supposed to be reachable via ICMP?
  * Disabling the Azure VFP extension restores reachability
    ```powershell
    Get-VMSwitchExtension -VMSwitchName s0 -Name 'Microsoft Azure VFP Switch Extension' | Disable-VMSwitchExtension
    ```

  * It appears that BGP sessions are established on the PA network and the
    PA interface does not have a default gateway set. BGP peering needs
    direct connectivity on the PA network and is not routed to any other
    interface. Make sure BGP sessions are connected directly via the PA
    interface.

  * Network Adapters
    * Can no longer set isolation properties on network adapter from Windows Admin Center
