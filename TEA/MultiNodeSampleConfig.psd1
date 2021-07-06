@{
    ScriptVersion        = '2.0'

    #Location from where the VHD will be copied.  VHDPath can be a local directory where SDN Express is run or an SMB share.
    VHDPath              = '\\teacloud-lib1\Fabric\VHDs'
    #Name of the VHDX as the golden image to use for VM creation.  Use the convert-windowsimage utility to create this from an iso or install.wim.
    VHDFile              = 'AZSHCI_OS.vhdx'

    #This is the location on the Hyper-V host where the VM files will be stored, including the VHD.  A subdirectory will be created for each VM using the VM name.  This location can be a local path on the host, a cluster volume, or an SMB share with appropriate permissions.
    VMLocation           = 'c:\ClusterStorage\Volume1'

    #Specify the name of the active directory domain where you want the SDN infrastructure VMs to be joined.  Domain join takes place offline prior to VM creation.
    JoinDomain           = 'teacloud.local'

    #IMPORTANT: if you deploy multiple network controllers onto the same network segments, you must change the SDNMacPool range to prevent overlap.
    SDNMacPoolStart      = '00-11-22-00-01-00'
    SDNMacPoolEnd        = '00-11-22-00-01-FF'

    #ManagmentSubnet, ManagementGateway, and ManagementDNS are not required if DHCP is configured for the management adapters below.
    ManagementSubnet     = '10.7.0.0/24'
    ManagementGateway    = '10.7.0.1'
    ManagementDNS        = @('10.7.72.113', '10.7.72.114')#@('10.7.144.136')
    #Use 0, or comment out ManagementVLANID to configure the management adapter for untagged traffic 
    ManagementVLANID     = 0

    #Usernames must be in the format Domain\User, Example: Contoso\Greg
    #IMPORTANT: DomainJoinUsername is used for admin operations on the Hyper-V host when creating VMs, it is no longer used for domain joining, instead the current user that is running the script requires domain join permission.
    DomainJoinUsername   = 'teacloud\RA-PrivateCloud-PQA'
    LocalAdminDomainUser = 'teacloud\RA-PrivateCloud-PQA'
    NCUsername           = 'teacloud\RA-PrivateCloud-PQA'

    #RestName must contain the FQDN that will be assigned to the SDN REST floating IP.
    RestName             = 'sdn.teacloud.local'

   NCs = @(
        #Optional parameters for each NC: 
        #  MacAddress - if not specified Mac Address is taken from start of SDNMacPool. SDN Mac Pool start is incremented to not include this mac.
        #  HostName - if not specified, taken round robin from list of hypervhosts
        #  ManagementIP - if not specified, Management adapter will be configured for DHCP on the ManagementVLANID VLAN.  If DHCP is used it is strongly recommended that you configure a reservation for the assigned IP address on the DHCP server.
        @{ComputerName = 'JAXNC01'; HostName = 'JAXAZSHCIT1'; ManagementIP = '10.7.0.211'; MACAddress = '001DD8220000' },
        @{ComputerName = 'JAXNC02'; HostName = 'JAXAZSHCIT2'; ManagementIP = '10.7.0.212'; MACAddress = '001DD8220001' }
        @{ComputerName = 'JAXNC03'; HostName = 'JAXAZSHCIT1'; ManagementIP = '10.7.0.213'; MACAddress = '001DD8220002' }
    )
    Muxes = @(
        #Optional parameters for each Mux: 
        #  HostName - if not specified, taken round robin from list of hypervhosts
        #  MacAddress - if not specified Management adapter Mac Address is taken from start of SDNMacPool. SDN Mac Pool start is incremented to not include this mac.
        #  PAMacAddress - if not specified PA Adapter Mac Address is taken from start of SDNMacPool. SDN Mac Pool start is incremented to not include this mac.
        #  PAIPAddress - if not specified the PA IP Address is taken from the beginning of the HNV PA Pool.  The start of the pool is incremented to not include this address.
        #  ManagementIP - if not specified, Management adapter will be configured for DHCP on the ManagementVLANID VLAN.  If DHCP is used it is strongly recommended that you configure a reservation for the assigned IP address on the DHCP server.
        #IMPORTANT NOTE: if specified, PAMacAddress must be outside of the SDN Mac Pool range.   PAIPAddress must be outside of the HNV PA IP Pool Start and End range.
        @{ComputerName = 'JAXMux01'; HostName = 'JAXAZSHCIT2'; ManagementIP = '10.7.0.214'; MACAddress = '001DD8220003'; PAIPAddress = '10.4.32.94'; PAMACAddress = '001DD8220004' },
        @{ComputerName = 'JAXMux02'; HostName = 'JAXAZSHCIT1'; ManagementIP = '10.7.0.215'; MACAddress = '001DD8220005'; PAIPAddress = '10.4.32.93'; PAMACAddress = '001DD8220006' }
    )
    Gateways = @(
        #Optional parameters for each Gateway: 
        #  HostName - if not specified, taken round robin from list of hypervhosts
        #  MacAddress - if not specified Management adapter Mac Address is taken from start of SDNMacPool.  SDN Mac Pool start is incremented to not include this mac.
        #  BackEndMac - if not specified Back End Adapter Mac Address is taken from start of SDNMacPool.  This Mac remains within the SDN Mac Pool.
        #  FrontEndMac - if not specified Front End Adapter Mac Address is taken from start of SDNMacPool.  This Mac remains within the SDN Mac Pool.
        #  FrontEndIP - if not specified the FrontEnd IP Address is taken from the beginning of the HNV PA Pool.  
        #  ManagementIP - if not specified, Management adapter will be configured for DHCP on the ManagementVLANID VLAN.  If DHCP is used it is strongly recommended that you configure a reservation for the assigned IP address on the DHCP server.
        #IMPORTANT NOTE: if specified, frontendmac, backendmac must be within the SDN Mac Pool range.   FrontEndIP must be within the HNV PA IP Pool Start and End range.
        @{ComputerName = 'JAXGW01'; HostName = 'JAXAZSHCIT2'; ManagementIP = '10.7.0.216'; MACAddress = '001DD8220007'; FrontEndIp = '10.4.32.92'; FrontEndMac = '001DD8220008'; BackEndMac = '001DD8220009' },
        @{ComputerName = 'JAXGW02'; HostName = 'JAXAZSHCIT1'; ManagementIP = '10.7.0.217'; MACAddress = '001DD822000A'; FrontEndIp = '10.4.32.91'; FrontEndMac = '001DD822000B'; BackEndMac = '001DD822000C' }
    )

    # Names of the initial Hyper-V hosts to add to the SDN deployment.  If you will be using additional Hyper-V hosts on different HNV PA subnets, you must add those after the initial deployment using the Add-SDNExpressHost function in the SDNExpressModule. 
    HyperVHosts = @(
        'JAXAZSHCIT1', 
        'JAXAZSHCIT2'
    )

    # Intiail HNV PA subnet to add for the network virtualization overlay to use.  You can add additional HNV PA subnets after deployment using the Add-SDNExpressVirtualNetworkPASubnet function in the sdnexpressmodule.
    PASubnet             = '10.4.32.64/27'
    PAVLANID             = '50'
    PAGateway            = '10.4.32.65'
    PAPoolStart          = '10.4.32.71'
    PAPoolEnd            = '10.4.32.94' 

    # Load Balancer and Gateway BGP information
    # SDN ASN to be used for load balancing VIPs, public IPs and GRE gateway advertisements.  Peering will take place from the HNV PA IP addresses assigned above.  It is recommended that your network administrator configure a peer group for the HNV PA subnet. 
    SDNASN               = '64513'
    
    # Router BGP peering endpoint ASN and IP address that is configured for peering by your network administrator.  On some routers it is recommended to peer with the loopback address.
    Routers = @(
        @{ RouterASN = '64512'; RouterIPAddress = '10.4.32.68' },
        @{ RouterASN = '64512'; RouterIPAddress = '10.4.32.69' }
        @{ RouterASN = '64512'; RouterIPAddress = '10.4.32.67' } #VYOS Router
    )

    # Initial set of VIP subnets to use for load balancing and public IPs 
    PrivateVIPSubnet     = '10.3.200.0/24'
    PublicVIPSubnet      = '10.3.72.0/24'

    # Subnet to use for GRE gateway connection endpoints.  This subnet is only used if you configure GRE gateway connections.
    GRESubnet            = '192.168.0.0/24'
    
    # Gateway VM network capacity, used by SDN controller for capacity management of gateway connections.    
    Capacity             = 10000


    # Optional fields.  Uncomment items if you need to override the defaults.

    # Initial gateway pool name, if not specified will use DefaultAll.  Additional pools can be added after the initial deployment using the SDNExpressModule.
    # PoolName             = 'DefaultAll'

    # Specify ProductKey if you have a product key to use for newly created VMs.  If this is not specified you may need 
    # to connect to the VM console to proceed with eval mode.
    # ProductKey       = '#####-#####-#####-#####-#####'

    # Switch name is only required if more than one virtual switch exists on the Hyper-V hosts.
    SwitchName='S0'

    # Amount of Memory and number of Processors to assign to VMs that are created.
    # If not specified a default of 8 procs and 8GB RAM are used.
    # VMMemory = 4GB
    # VMProcessorCount = 4

    # If Locale and Timezone are not specified the local time zone of the deployment machine is used.
    # Locale           = ''
    # TimeZone         = ''

    # Passwords can be optionally included if stored encrypted as text encoded secure strings.  Passwords will only be used
    # if SDN Express is run on the same machine where they were encrypted, otherwise it will prompt for passwords.
    # DomainJoinSecurePassword  = ''
    # LocalAdminSecurePassword   = ''
    # NCSecurePassword   = ''

}
