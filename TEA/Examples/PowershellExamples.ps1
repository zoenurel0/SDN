#Note: The examples here are not guaranteed to work, as they are a work in progress

#Common

$RestName = 'sdn.teacloud.local'
$uri = 'https://sdn.teacloud.local'

$DefaultRestParams = @{
    'ConnectionURI'="https://$RestName";
    'PassInnerException'=$true;
    'Credential'=$credential
}


#Create Logical Network

$subnetPrefix = '10.4.32.0/24'
$subnetGateWays = @('10.4.32.1')
$LogicalNetworkResourceId = 'L3Forwarding'
$LogicalSubnetResourceId = $($LogicalNetworkResourceId + '_sub0')

$LogicalNetworkProperties = new-object Microsoft.Windows.NetworkController.LogicalNetworkProperties
$LogicalNetworkProperties.NetworkVirtualizationEnabled = $false
$LogicalNetworkProperties.Subnets = @()
$LogicalNetworkProperties.Subnets += new-object Microsoft.Windows.NetworkController.LogicalSubnet
$logicalNetworkProperties.Subnets[0].ResourceId = $LogicalSubnetResourceId
$logicalNetworkProperties.Subnets[0].Properties = new-object Microsoft.Windows.NetworkController.LogicalSubnetProperties
$logicalNetworkProperties.Subnets[0].Properties.AddressPrefix = $subnetPrefix
$logicalNetworkProperties.Subnets[0].Properties.DefaultGateways = $subnetGateWays

$LogicalNetwork = New-NetworkControllerLogicalNetwork -ConnectionURI $uri -ResourceID $LogicalNetworkResourceId -properties $LogicalNetworkProperties # @CredentialParam -Force -passinnerexception


#View Logical Networks

Get-NetworkControllerLogicalNetwork -ConnectionUri $uri

Get-NetworkControllerLogicalNetwork -ResourceId $LogicalNetworkResourceId -ConnectionUri $uri

#Remove Logical Network

Remove-NetworkControllerLogicalNetwork -ResourceId $LogicalNetworkResourceId -ConnectionUri $uri -Credential $credential


#View Logical Subnet

Get-NetworkControllerLogicalSubnet -LogicalNetworkId L3ForwardingGateway -ConnectionUri $uri

(Get-NetworkControllerLogicalSubnet -LogicalNetworkId L3ForwardingGateway -ConnectionUri $uri).properties 




Remove-NetworkControllerLogicalSubnet -LogicalNetworkId L3ForwardingGateway -ConnectionUri $uri -ResourceId 'L3Forwarding-JAX0' -Credential $credential


Get-NetworkControllerLogicalSubnet -LogicalNetworkId L3ForwardingGateway -ConnectionUri $uri -ResourceId 'L3Forwarding-JAX0' 


#New-NetworkControllerLogicalSubnet -ResourceId 'L3Forwarding-JAX0' -LogicalNetworkId 'L3ForwardingGateway' -ConnectionUri $uri
