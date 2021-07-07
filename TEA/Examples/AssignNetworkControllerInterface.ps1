# Create a VM and connect to a tenant virtual network or VLAN
# <https://docs.microsoft.com/en-us/windows-server/networking/sdn/manage/create-a-tenant-vm>

# Be sure to restart VMs for this to take affect.

$vmHost = 'jaxazshcit2'
$vmName = 'vm1'
$staticMAC = '00-11-22-33-44-56' # '00-11-22-33-44-55' $staticMAC.Replace('-',"")
$URI = "https://sdn.teacloud.local"
$privateIPAddress = '172.16.2.100'
$VNETResourceID = 'vnet0'
$subnetName = 'sub2'
$vmIPResourceId = $($vmName+'_IP0')

Get-VMNetworkAdapter -CimSession $vmHost -VMName $vmName

Add-VMNetworkAdapter -CimSession $vmHost -VMName $vmName -StaticMacAddress $staticMAC -SwitchName 'S0'

Set-VMNetworkAdapter -CimSession $vmHost  -VMName $vmName -StaticMacAddress $staticMAC

Remove-VMNetworkAdapter -CimSession $vmHost -VMName $vmName


#Create Interface on Network Controller and assign to VNET/Subnet

$vnet = get-networkcontrollervirtualnetwork -connectionuri $uri -ResourceId $VNETResourceID

$vmnicproperties = new-object Microsoft.Windows.NetworkController.NetworkInterfaceProperties
$vmnicproperties.PrivateMacAddress = $($staticMAC.Replace('-',""))
$vmnicproperties.PrivateMacAllocationMethod = "Static"
$vmnicproperties.IsPrimary = $true

$vmnicproperties.DnsSettings = new-object Microsoft.Windows.NetworkController.NetworkInterfaceDnsSettings
$vmnicproperties.DnsSettings.DnsServers = @("4.2.2.2", "8.8.8.8")

$ipconfiguration = new-object Microsoft.Windows.NetworkController.NetworkInterfaceIpConfiguration
$ipconfiguration.resourceid = $vmIPResourceId
$ipconfiguration.properties = new-object Microsoft.Windows.NetworkController.NetworkInterfaceIpConfigurationProperties
$ipconfiguration.properties.PrivateIPAddress = $privateIPAddress
$ipconfiguration.properties.PrivateIPAllocationMethod = "Static"

$ipconfiguration.properties.Subnet = new-object Microsoft.Windows.NetworkController.Subnet
# $ipconfiguration.properties.subnet.ResourceRef = $vnet.Properties.Subnets[0].ResourceRef
$ipconfiguration.properties.subnet.ResourceRef = ($vnet.Properties.Subnets | ? { $_.ResourceId -match $subnetName }).ResourceRef

$vmnicproperties.IpConfigurations = @($ipconfiguration)
New-NetworkControllerNetworkInterface –ResourceID $($vmName+'_Ethernet1') –Properties $vmnicproperties –ConnectionUri $uri

$nic = Get-NetworkControllerNetworkInterface -ConnectionUri $uri -ResourceId $($vmName+'_Ethernet1')
$nicInstanceId = $nic.InstanceId
$nicInstanceId



# Set the Interface ID on the Hyper-V VM network adapter port. (Binds Network
# Controller Interface to VMNetworkAdapter Port Profile)

$sBlock = {
    param (
        $vmHost,
        $vmName,
        $nicInstanceId
    )

    #Do not change the hardcoded IDs in this section, because they are fixed values and must not change.

    $FeatureId = "9940cd46-8b06-43bb-b9d5-93d50381fd56"

    $vmNics = Get-VMNetworkAdapter -VMName $vmName

    $CurrentFeature = Get-VMSwitchExtensionPortFeature -FeatureId $FeatureId -VMNetworkAdapter $vmNics[0]

    $CurrentFeature
    $nicInstanceId

    if ($CurrentFeature -eq $null) {
        $Feature = Get-VMSystemSwitchExtensionPortFeature -FeatureId $FeatureId

        $Feature.SettingData.ProfileId = "{$nicInstanceId}"
        $Feature.SettingData.NetCfgInstanceId = "{56785678-a0e5-4a26-bc9b-c0cba27311a3}"
        $Feature.SettingData.CdnLabelString = "TestCdn"
        $Feature.SettingData.CdnLabelId = 1111
        $Feature.SettingData.ProfileName = "Testprofile"
        $Feature.SettingData.VendorId = "{1FA41B39-B444-4E43-B35A-E1F7985FD548}"
        $Feature.SettingData.VendorName = "NetworkController"
        $Feature.SettingData.ProfileData = 1

        Add-VMSwitchExtensionPortFeature -VMSwitchExtensionFeature  $Feature -VMNetworkAdapter $vmNics[0]
    }
    else {
        $CurrentFeature.SettingData.ProfileId = "{$nicInstanceId}"
        $CurrentFeature.SettingData.ProfileData = 1

        Set-VMSwitchExtensionPortFeature -VMSwitchExtensionFeature $CurrentFeature  -VMNetworkAdapter $vmNic[0]
    }

} 

Invoke-Command -ComputerName $vmHost -ArgumentList $vmHost, $vmName, $nicInstanceId -ScriptBlock $sBlock


#Remove VM Network adapters from VM and Network Controller

Remove-VMNetworkAdapter -CimSession $vmHost -VMName $vmName

Remove-NetworkControllerNetworkInterface –ResourceID $($vmName+'_Ethernet1') –ConnectionUri $uri

Get-NetworkControllerNetworkInterface -ConnectionUri $URI



#Diagnose

$FeatureId = "9940cd46-8b06-43bb-b9d5-93d50381fd56"

$vmNics = Get-VMNetworkAdapter -VMName $vmName -CimSession $vmHost

$CurrentFeature = Get-VMSwitchExtensionPortFeature -FeatureId $FeatureId -VMNetworkAdapter $vmNics[0]

$CurrentFeature.SettingData
