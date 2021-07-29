# Ref: https://docs.microsoft.com/en-us/windows-server/networking/sdn/manage/create-a-tenant-vm

# Get-VMNetworkAdapter -All | Select Name, VMName, MacAddress

# 1 Create the VM and assign a static MAC address to the VM

$vmname = 'vm4'
$vmConfigPath = "c:\ClusterStorage\Volume2\Hyper-V\"
$vhdPath = "c:\ClusterStorage\Volume2\Hyper-V\$vmname\system.vhdx"
$switchName = 's0'
$macAddress = '00-11-22-33-44-57'
$VLANTag = 14

$vhd = New-VHD -Path $vhdPath -SizeBytes 120GB

$vm = New-VM -Generation 2 -Name $vmname -Path $vmConfigPath -MemoryStartupBytes 4GB -VHDPath $vhdPath -SwitchName $switchName 

Set-VM -Name $vmname -ProcessorCount 4

Set-VMNetworkAdapter -VMName $vmname -StaticMacAddress $macAddress


# 2 Set the VLAN ID on the VM network adapter.

Set-VMNetworkAdapterIsolation -VMName $vmname -AllowUntaggedTraffic $true -IsolationMode VLAN -DefaultIsolationId $VLANTag

#3 Get the logical network subnet and create the network interface on Network Controller.

$uri = 'https://sdn.teacloud.local'
$logicalNetworkResourceID = 'L3Forwarding'
$privateIPAddress = '10.3.224.100' # From VLAN 14

get-networkcontrollerLogicalNetwork -connectionuri $uri

$logicalnet = get-networkcontrollerLogicalNetwork -connectionuri $uri -ResourceId $logicalNetworkResourceID

$vmnicproperties = new-object Microsoft.Windows.NetworkController.NetworkInterfaceProperties
$vmnicproperties.PrivateMacAddress = $macAddress
$vmnicproperties.PrivateMacAllocationMethod = "Static"
$vmnicproperties.IsPrimary = $true

$vmnicproperties.DnsSettings = new-object Microsoft.Windows.NetworkController.NetworkInterfaceDnsSettings
$vmnicproperties.DnsSettings.DnsServers = $logicalnet.Properties.Subnets[0].DNSServers

$ipconfiguration = new-object Microsoft.Windows.NetworkController.NetworkInterfaceIpConfiguration
$ipconfiguration.resourceid = ("$vmname" + "_IP0")
$ipconfiguration.properties = new-object Microsoft.Windows.NetworkController.NetworkInterfaceIpConfigurationProperties
$ipconfiguration.properties.PrivateIPAddress = $privateIPAddress
$ipconfiguration.properties.PrivateIPAllocationMethod = "Static"

$ipconfiguration.properties.Subnet = new-object Microsoft.Windows.NetworkController.Subnet
$ipconfiguration.properties.subnet.ResourceRef = $logicalnet.Properties.Subnets[0].ResourceRef

$vmnicproperties.IpConfigurations = @($ipconfiguration)
$vnic = New-NetworkControllerNetworkInterface -ResourceID ("$vmname" + "_Eth0") -Properties $vmnicproperties -ConnectionUri $uri

$InstanceId = $vnic.InstanceId

# Get-NetworkControllerNetworkInterface -ResourceId ("$vmname" + "_Eth0") -ConnectionUri $uri


# 4 Set the InstanceId on the Hyper-V port

#The hardcoded Ids in this section are fixed values and must not change.
$FeatureId = "9940cd46-8b06-43bb-b9d5-93d50381fd56" #Ethernet Switch Port Profile Settings

$vmNic = (Get-VMNetworkAdapter -VMName $vmname)[0]

$CurrentFeature = Get-VMSwitchExtensionPortFeature -FeatureId $FeatureId -VMNetworkAdapter $vmNic

if ($CurrentFeature -eq $null) {
    $Feature = Get-VMSystemSwitchExtensionPortFeature -FeatureId $FeatureId

    $Feature.SettingData.ProfileId = "{$InstanceId}"
    $Feature.SettingData.NetCfgInstanceId = "{56785678-a0e5-4a26-bc9b-c0cba27311a3}"
    $Feature.SettingData.CdnLabelString = "TestCdn"
    $Feature.SettingData.CdnLabelId = 1111
    $Feature.SettingData.ProfileName = "Testprofile"
    $Feature.SettingData.VendorId = "{1FA41B39-B444-4E43-B35A-E1F7985FD548}"
    $Feature.SettingData.VendorName = "NetworkController"
    $Feature.SettingData.ProfileData = 1

    Add-VMSwitchExtensionPortFeature -VMSwitchExtensionFeature $Feature -VMNetworkAdapter $vmNic
}
else {
    $CurrentFeature.SettingData.ProfileId = "{$InstanceId}"
    $CurrentFeature.SettingData.ProfileData = 1

    Set-VMSwitchExtensionPortFeature -VMSwitchExtensionFeature $CurrentFeature  -VMNetworkAdapter $vmNic
}

# Get-VMSwitchExtensionPortFeature -FeatureId $Featureid -VMNetworkAdapter $vmnic 



# 5 Start the VM

Get-VM -Name $vmname | Start-VM


#Clean up (Delete VM and VHD)

$vm | Stop-vm
$vm | Remove-VM -Force
rmdir "$vmConfigPath$vmname" -Recurse

