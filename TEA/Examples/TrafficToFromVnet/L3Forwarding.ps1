
# L3 Forwarding ()
$URI = "https://sdn.teacloud.local"

## Create a public IP object to contain the VIP (Static Method).
$VIPIP = "10.3.72.101"

$publicIPProperties = new-object Microsoft.Windows.NetworkController.PublicIpAddressProperties
$publicIPProperties.ipaddress = $VIPIP
$publicIPProperties.PublicIPAllocationMethod = "static"
$publicIPProperties.IdleTimeoutInMinutes = 4
$publicIP = New-NetworkControllerPublicIpAddress -ResourceId "MyPIP" -Properties $publicIPProperties -ConnectionUri $uri -Force -PassInnerException

## Assign the PublicIPAddress to a network interface.

$nic = get-networkcontrollernetworkinterface  -connectionuri $uri -resourceid vm0_Net_Adapter_0 #<ResourceID of VMNet Adapter, use get-networkcontrollernetworkinterface >
$nic.properties.IpConfigurations[0].Properties.PublicIPAddress = $publicIP
$nic = New-NetworkControllerNetworkInterface -ConnectionUri $uri -ResourceId $nic.ResourceId -Properties $nic.properties -PassInnerException -Force

## Troubleshooting
## View all Public IP addresses

Get-NetworkControllerPublicIpAddress -ConnectionUri $uri

## Remove Public IP address
$nic.properties.IpConfigurations[0].Properties.PublicIPAddress = $null
$nic = New-NetworkControllerNetworkInterface -ConnectionUri $uri -ResourceId $nic.ResourceId -Properties $nic.properties -PassInnerException -Force
Remove-NetworkControllerPublicIpAddress -ConnectionUri $uri -ResourceId "MyPIP"

# View Public IP info on VM adapter

$nic.Properties.IpConfigurations[-1].Properties.PublicIPAddress


