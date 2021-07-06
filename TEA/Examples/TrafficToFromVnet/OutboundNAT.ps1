# Reference:
# https://docs.microsoft.com/en-us/windows-server/networking/sdn/manage/configure-slb-and-nat

# Create FrontEnd and BackEnd IP configs for load balancer
import-module NetworkController
 $URI = "https://sdn.teacloud.local"

 $LBResourceId = "OutboundNATMMembers"
 $VIPIP = "10.3.72.100"

 $VIPLogicalNetwork = get-networkcontrollerlogicalnetwork -ConnectionUri $uri -resourceid "PublicVIP" -PassInnerException

 $LoadBalancerProperties = new-object Microsoft.Windows.NetworkController.LoadBalancerProperties

 $FrontEndIPConfig = new-object Microsoft.Windows.NetworkController.LoadBalancerFrontendIpConfiguration
 $FrontEndIPConfig.ResourceId = "FE1"
 $FrontEndIPConfig.ResourceRef = "/loadBalancers/$LBResourceId/frontendIPConfigurations/$($FrontEndIPConfig.ResourceId)"

 $FrontEndIPConfig.Properties = new-object Microsoft.Windows.NetworkController.LoadBalancerFrontendIpConfigurationProperties
 $FrontEndIPConfig.Properties.Subnet = new-object Microsoft.Windows.NetworkController.Subnet
 $FrontEndIPConfig.Properties.Subnet.ResourceRef = $VIPLogicalNetwork.Properties.Subnets[0].ResourceRef
 $FrontEndIPConfig.Properties.PrivateIPAddress = $VIPIP
 $FrontEndIPConfig.Properties.PrivateIPAllocationMethod = "Static"

 $LoadBalancerProperties.FrontEndIPConfigurations += $FrontEndIPConfig

 $BackEndAddressPool = new-object Microsoft.Windows.NetworkController.LoadBalancerBackendAddressPool
 $BackEndAddressPool.ResourceId = "BE1"
 $BackEndAddressPool.ResourceRef = "/loadBalancers/$LBResourceId/backendAddressPools/$($BackEndAddressPool.ResourceId)"
 $BackEndAddressPool.Properties = new-object Microsoft.Windows.NetworkController.LoadBalancerBackendAddressPoolProperties

 $LoadBalancerProperties.backendAddressPools += $BackEndAddressPool


 # Create Outbound NAT Rule

 $OutboundNAT = new-object Microsoft.Windows.NetworkController.LoadBalancerOutboundNatRule
 $OutboundNAT.ResourceId = "onat1"

 $OutboundNAT.properties = new-object Microsoft.Windows.NetworkController.LoadBalancerOutboundNatRuleProperties
 $OutboundNAT.properties.frontendipconfigurations += $FrontEndIPConfig
 $OutboundNAT.properties.backendaddresspool = $BackEndAddressPool
 $OutboundNAT.properties.protocol = "ALL"

 $LoadBalancerProperties.OutboundNatRules += $OutboundNAT

 # Add LB Object in Network Controller

 $LoadBalancerResource = New-NetworkControllerLoadBalancer -ConnectionUri $URI -ResourceId $LBResourceId -Properties $LoadBalancerProperties -Force -PassInnerException



 # Add Interfaces to backend pools

 ## Get the resourceid of vmnic you want to provide NAT for

 get-networkcontrollernetworkinterface  -connectionuri $uri
  
 $nicResourceId = 'vm0_Net_Adapter_0' #Replace with ResourceID of your NIC

 ## Get LB Object
 #$LBResourceId = "OutboundNATMMembers"
 $lb = get-networkcontrollerloadbalancer -connectionuri $uri -resourceID $LBResourceId -PassInnerException

 ## Get the network interface and add it to the loadbalancerbackendaddresspools array
 $nic = get-networkcontrollernetworkinterface  -connectionuri $uri -resourceid  $nicResourceId -PassInnerException
 $nic.properties.IpConfigurations[0].properties.LoadBalancerBackendAddressPools += $lb.properties.backendaddresspools[0]

 ## Put the network interface to apply the change
 new-networkcontrollernetworkinterface  -connectionuri $uri -resourceid  $nicResourceId -properties $nic.properties -force -PassInnerException


 ## Test Outbound NAT
 # Note, the LB NAT solution does NOT support ICMP. Only TCP/UDP connections
 # are possible.

 Test-NetConnection 8.8.8.8 -Port 443


 #Remove Load Balancer
 Remove-NetworkControllerLoadBalancer -ResourceId OutboundNATMMembers -ConnectionUri $uri

