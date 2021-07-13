#Reference
# <https://docs.microsoft.com/en-us/windows-server/networking/sdn/manage/add-a-virtual-gateway-to-a-tenant-virtual-network>
# NOT WORKING!



#Step 1
$uri = "https://sdn.teacloud.local"

# Retrieve the Gateway Pool configuration
$gwPool = Get-NetworkControllerGatewayPool -ConnectionUri $uri

# Display in JSON format
$gwPool | ConvertTo-Json -Depth 2



#Step 2

# Retrieve the Tenant Virtual Network configuration
$Vnet = Get-NetworkControllerVirtualNetwork -ConnectionUri $uri  -ResourceId 'vnet0'

# Display in JSON format
$Vnet | ConvertTo-Json -Depth 4

# Retrieve the Tenant Virtual Subnet configuration
$RoutingSubnet = Get-NetworkControllerVirtualSubnet -ConnectionUri $uri  -ResourceId 'gw' -VirtualNetworkID $vnet.ResourceId

# Display in JSON format
$RoutingSubnet | ConvertTo-Json -Depth 4


#Step 3 Create Tenant Virtual Gateway

# Create a new object for Tenant Virtual Gateway
$VirtualGWProperties = New-Object Microsoft.Windows.NetworkController.VirtualGatewayProperties

# Update Gateway Pool reference
$VirtualGWProperties.GatewayPools = @()
$VirtualGWProperties.GatewayPools += $gwPool

# Specify the Virtual Subnet that is to be used for routing between the gateway and Virtual Network
$VirtualGWProperties.GatewaySubnets = @()
$VirtualGWProperties.GatewaySubnets += $RoutingSubnet

# Update the rest of the Virtual Gateway object properties
$VirtualGWProperties.RoutingType = "Dynamic"
$VirtualGWProperties.NetworkConnections = @()
$VirtualGWProperties.BgpRouters = @()

# Add the new Virtual Gateway for tenant
$virtualGW = New-NetworkControllerVirtualGateway -ConnectionUri $uri  -ResourceId "TeaCloud_VirtualGW" -Properties $VirtualGWProperties -Force

    #View
    #   Get-NetworkControllerVirtualGateway -ConnectionUri $uri -ResourceId $virtualGW.resourceID

    #Remove
    #   Remove-NetworkControllerVirtualGateway -ResourceId $virtualGW.resourceID -ConnectionUri $uri





#Step 4a Logical Network Creation

# Create a new object for the Logical Network to be used for L3 Forwarding
$lnProperties = New-Object Microsoft.Windows.NetworkController.LogicalNetworkProperties

$lnProperties.NetworkVirtualizationEnabled = $false
$lnProperties.Subnets = @()

# Create a new object for the Logical Subnet to be used for L3 Forwarding and update properties
$logicalsubnet = New-Object Microsoft.Windows.NetworkController.LogicalSubnet
$logicalsubnet.ResourceId = "subnet-gwy-jax"
$logicalsubnet.Properties = New-Object Microsoft.Windows.NetworkController.LogicalSubnetProperties
$logicalsubnet.Properties.VlanID = 14
$logicalsubnet.Properties.AddressPrefix = "10.3.224.0/24"
$logicalsubnet.Properties.DefaultGateways = "10.3.224.1"

$lnProperties.Subnets += $logicalsubnet

# Add the new Logical Network to Network Controller
$vlanNetwork = New-NetworkControllerLogicalNetwork -ConnectionUri $uri -ResourceId "L3Forwarding" -Properties $lnProperties -Force

$vlanNetwork | ConvertTo-Json -Depth 4


# View Logical Network

    #   $vlanNetwork = Get-NetworkControllerLogicalNetwork -ConnectionUri $uri -ResourceId "L3Forwarding"

# Remove Logical Network

    #   Remove-NetworkControllerLogicalNetwork -ConnectionUri $uri -ResourceId $vlanNetwork.ResourceId

#Step 4b Create a Network Connection JSON Object and add it to Network Controller.

# Create a new object for the Tenant Network Connection
$nwConnectionProperties = New-Object Microsoft.Windows.NetworkController.NetworkConnectionProperties

# Update the common object properties
$nwConnectionProperties.ConnectionType = "L3"
$nwConnectionProperties.OutboundKiloBitsPerSecond = 10000
$nwConnectionProperties.InboundKiloBitsPerSecond = 10000

# GRE specific configuration (leave blank for L3)
$nwConnectionProperties.GreConfiguration = New-Object Microsoft.Windows.NetworkController.GreConfiguration

# Update specific properties depending on the Connection Type
$nwConnectionProperties.L3Configuration = New-Object Microsoft.Windows.NetworkController.L3Configuration
$nwConnectionProperties.L3Configuration.VlanSubnet = $vlanNetwork.properties.Subnets[0]


$nwConnectionProperties.IPAddresses = @()
$localIPAddress = New-Object Microsoft.Windows.NetworkController.CidrIPAddress
$localIPAddress.IPAddress = "10.3.224.10"
$localIPAddress.PrefixLength = 24
$nwConnectionProperties.IPAddresses += $localIPAddress

$nwConnectionProperties.PeerIPAddresses = @("10.3.224.6")

# Update the IPv4 Routes that are reachable over the site-to-site VPN Tunnel
$nwConnectionProperties.Routes = @()
$ipv4Route = New-Object Microsoft.Windows.NetworkController.RouteInfo
$ipv4Route.DestinationPrefix = "5.5.5.5/32"
$ipv4Route.metric = 10
$nwConnectionProperties.Routes += $ipv4Route

# Add the new Network Connection for the tenant
New-NetworkControllerVirtualGatewayNetworkConnection -ConnectionUri $uri -VirtualGatewayId $virtualGW.ResourceId -ResourceId "TEA_L3GW" -Properties $nwConnectionProperties -Force




#Step 5 BGP

#Step 5a Add BGP Router

# Create a new object for the Tenant BGP Router
$bgpRouterproperties = New-Object Microsoft.Windows.NetworkController.VGwBgpRouterProperties

# Update the BGP Router properties
$bgpRouterproperties.ExtAsNumber = "0.64515" # Why does 0 have to prefix ASN?
$bgpRouterproperties.RouterId = "172.16.0.4" # Has no impact? Must be on routing subnet!?
$bgpRouterproperties.RouterIP = @("172.16.0.4") # Has no impact? Must be on routing subnet!?

# Add the new BGP Router for the tenant
$bgpRouter = New-NetworkControllerVirtualGatewayBgpRouter -ConnectionUri $uri -VirtualGatewayId $virtualGW.ResourceId -ResourceId "TEA_BgpRouter1" -Properties $bgpRouterProperties -Force

    # Remove BGP Router
    #   Remove-NetworkControllerVirtualGatewayBgpRouter -ConnectionUri $uri -ResourceId "TEA_BgpRouter1" -VirtualGatewayId $virtualGW.ResourceId

    # View BGP Router on Vnet Gateway
    #   $bgpRouter = get-NetworkControllerVirtualGatewayBgpRouter -ConnectionUri $uri -VirtualGatewayId $virtualGW.ResourceId


#Step 5b Add BGP Peer

# Create a new object for Tenant BGP Peer
$bgpPeerProperties = New-Object Microsoft.Windows.NetworkController.VGwBgpPeerProperties

# Update the BGP Peer properties
$bgpPeerProperties.PeerIpAddress = "5.5.5.5"
$bgpPeerProperties.AsNumber = 64521
$bgpPeerProperties.ExtAsNumber = "0.64521"

# Add the new BGP Peer for tenant
$BGPPeer = New-NetworkControllerVirtualGatewayBgpPeer -ConnectionUri $uri -VirtualGatewayId $virtualGW.ResourceId -BgpRouterName $bgpRouter.ResourceId -ResourceId "TEA_BGP_Peer" -Properties $bgpPeerProperties -Force

    # View BGP Peer
    #    $BGPPeer = Get-NetworkControllerVirtualGatewayBgpPeer -ConnectionUri $uri -VirtualGatewayId $virtualGW.ResourceId -BgpRouterName $bgpRouter.ResourceId

    # Remove BGP Peer
    #   Remove-NetworkControllerVirtualGatewayBgpPeer -ConnectionUri $uri -VirtualGatewayId $virtualGW.ResourceId -BgpRouterName $bgpRouter.ResourceId -ResourceId $BGPPeer.ResourceId
