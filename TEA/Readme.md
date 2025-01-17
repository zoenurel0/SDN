# Notes

* Install SDN
```powershell
CD C:\git\SDN\SDNExpress\scripts

.\SDNExpress.ps1 -ConfigurationDataFile ..\..\TEA\MultiNodeSampleConfig.psd1
```

* Remove SDN
```powershell
CD C:\git\sdn\TEA\CleanupSDN

.\CleanupSDN.ps1 ..\MultiNodeSampleConfig.psd1
```

## **Networking**

### **Notes about Routing Compartments**

Windows has a concept of "Routing Compartments" which behave similar to VRF's
(Virtual Route Forwarders). These "Routing Compartments" provide isolation
of routing information between multiple tenants. Some commands (i.e. Ping and
Ipconfig) need to have extra parameters attached when using these commands.

* Ping a device within a routing domain, where N is the Routing compartment
  ID associated with a tenant.

  ```bash
  Ping -c N x.x.x.x
  ```

* View all interfaces in all routing compartments.

  ```bash
  ipconfig /allcompartments /all
  ```

* View all routes within a Routing Compartment (Like VRF, one for each tenant)

  ```powershell
  Get-NetRoute -IncludeAllCompartments -CompartmentId $compartmentIDNumber
  ```

### **OVSDB Client Dump**

To dump the "Open Virtual Switch Database" associated with the VTEP 
of the HyperV extensible switch, use the following command.

(Execute from Host where tenant VM is running)
```bash
ovsdb-client dump tcp:127.0.0.1:6641 ms_vtep
```

### **Setting port profile to provide traditional VLAN isolation**

* Note: Use the procedure below to enable VLAN isolation and not SDN isolation.

From: Anirban Paul <anpaul@microsoft.com>
Sent: Wednesday, June 9, 2021 2:20 PM
To: Lorenzo Hamilton <lhamilton@teainc.org>
Subject: RE: Azure Stack HCI EAP | The Energy Authority | SDN follow up
 

Hi Lorenzo

Disabling VFP would work but VFP would be re-enabled on the port when the VM is reset, migrate, etc.

The right thing to do would be to set the correct port profile for the VM. I will check why it did not get set for this VM. Did you create this VM through WAC, and attach it to a VLAN?

To set the correct port profile, run the following commands. Let me know if it worked.
 
```powershell
$vmName = <Name of my VM>

$PortProfileFeatureId = "9940cd46-8b06-43bb-b9d5-93d50381fd56"
$NcVendorId = "{1FA41B39-B444-4E43-B35A-E1F7985FD548}"

$portProfileDefaultSetting = Get-VMSystemSwitchExtensionPortFeature -FeatureId $PortProfileFeatureId

$portProfileDefaultSetting.SettingData.NetCfgInstanceId = "{56785678-a0e5-4a26-bc9b-c0cba27311a3}"
$portProfileDefaultSetting.SettingData.CdnLabelString = "TestCdn"
$portProfileDefaultSetting.SettingData.CdnLabelId = 1111
$portProfileDefaultSetting.SettingData.ProfileName = "Testprofile"
$portProfileDefaultSetting.SettingData.VendorId = $NcVendorId
$portProfileDefaultSetting.SettingData.VendorName = "NetworkController"
$portProfileDefaultSetting.SettingData.ProfileData = 2
$portProfileDefaultSetting.SettingData.ProfileId = [Guid]::Empty.ToString("B")

$vmNics = Get-VMNetworkAdapter -VMName $vmName

foreach ($vmNic in $vmNics) {
    $currentProfile = Get-VMSwitchExtensionPortFeature -FeatureId $PortProfileFeatureId -VMNetworkAdapter $vmNic

    if ( $currentProfile -eq $null) {
        Add-VMSwitchExtensionPortFeature -VMSwitchExtensionFeature $portProfileDefaultSetting -VMNetworkAdapter $vmNic
    }
    else {
        $currentProfile.SettingData.ProfileData = $portProfileDefaultSetting.SettingData.ProfileData
        $currentProfile.SettingData.ProfileId = $portProfileDefaultSetting.SettingData.ProfileId
        Set-VMSwitchExtensionPortFeature -VMSwitchExtensionFeature $currentProfile -VMNetworkAdapter $vmNic
    }
}
```
Thanks

Anirban

### **VFP Info**

[6/18 4:59 PM] Jocelyn Berrendonner
    Hello Lorenzo Hamilton,

I asked the SDN experts. Please find their answer below:

Disabling the VFP switch extension will of course allow all VMs to communicate and that’s generally the easiest way to disable SDN completely.

If VMs were previously on a VFP enabled port and had a VLAN ID specified using set-vmnetworkadapterisolation, you will need to reset your VLAN ID using set-vmnetworkadapterVLAN instead.

The VM that is working when VFP is enabled probably has a null guid assigned to the port.  This can be done most easily in the following way:

Download sdnexpressmodule.psm1 from here:  <https://github.com/microsoft/SDN/raw/master/SDNExpress/scripts/SDNExpressModule.psm1>

```powershell
Import-module .\sdnexpressmodule.psm1
Enable-SDNExpressVMPort -computername <host name> -vmname <vm name> -vmnetworkadaptername <name> -profiledata 2
```

A few notes:

* NCHostAgent service needs to be running to read the port settings and apply
  them. I assume this is the case otherwise the other VM wouldn’t be unblocked.

* ProfileData 2 will unblock the port and disable VFP from the port.  Since
  the vswitch is enforcing VLAN tags in this case, VLAN id will need to be
  specified using set-vmnetworkadaptervlan

* ProfileData 1 will also unblock the port, but will leave VFP enabled.
  In that case since VFP is processing the VLAN tags, VLAN ID will need to be
  set using set-vmnetworkadapterisolation.

--------

**Dumping VFP Port Rules on VSwitch**

  From the host where VM is located, run:

  ```bash
  Vfpctrl.exe /list-vmswitch-port
  ```
  Search for VM you are interested in from the output of the above command and
  note the 'Port Name' field(s), then run:

  ```bash
  vfpctrl.exe /port <Port Name>  /list-rule
  ```

  Example:

  ```bash
  VM0: vfpctrl /port 6C255B95-2CBF-4945-B9CD-0AEB6FC1D95F /list-rule
  GW02 external port: vfpctrl /port 6AF3867B-C70E-472D-BCA6-CAAA6FE92D52 /list-rule
  GW02 internal port: vfpctrl /port 64902F0A-FBD1-4B77-BFD1-073EC27B800A /list-rule
  ```
--------
### **Troubleshooting**

* **View VLAN Isolation settings of a VM Network Adapter**

```powershell
Get-VMNetworkAdapterIsolation -VMName 'myVM'
```

* **Get SDDC Logs**

  These are the commands to install the "log collector tool" (this need to be run on only 1 node).

  ```powershell
  $hciHost = 'jaxazshcit1'
  $run = {
      Install-PackageProvider NuGet -Force 
      Install-Module PrivateCloud.DiagnosticInfo -Force
      Import-Module PrivateCloud.DiagnosticInfo -Force
      Install-Module -Name MSFT.Network.Diag

      #To collect the logs run this command:
      Get-SDDCDiagnosticInfo

    }

  Invoke-Command -ComputerName $hciHost -ScriptBlock $run
  ```

* It may be necessary, if traffic is not forwarding after uninstalling the
  SDN stack to disable VFP on a particular VmNetwork adapter. To disable VFP
  on an adapter, do the following:

    Execute from the HyperV host where the VM is running.
    ```powershell
    $portdata = Get-VMSwitchExtensionPortData -VMName <vmName> -ComputerName <HyperVHostName>

    $ID=$portdata[0].Data.DeviceId

    vfpctrl /get-port-state /port $ID

    vfpctrl /disable-port /port $ID

    ```

### **FAQ**

* I can no longer add a VM net adapter with SDN isolation post VM creation,
  what happened to this functionality?
  * Apparently something broke in WAC. This should be fixed in a new release
    of WAC.

* We would like to try out Auto VM Activation, where do we find MAK keys for
  Azure Stack HCI host, or do we use Windows server 2019 MAK keys?

* Where do I get the latest information on deploying iDNS services?

  * This is a start:
  
    <https://docs.microsoft.com/en-us/windows-server/networking/sdn/technologies/idns-for-sdn>

* What happened to LoadBalancers tab under networking in WAC?
  * Check SDN LB extension in WAC. This must be installed before you will see
    LB tab show up in Windows Admin Center.

* Where can I find detailed examples on how to configure L3 forwarding for
  VNET gateway using Powershell and WAC?
  * L3 Forwarding example:
    
    <https://docs.microsoft.com/en-us/azure-stack/hci/manage/gateway-connections#create-an-l3-connection>
  
  * What address do you use as the BGP peering IP (IP of GW?)?
    * You will need to set up a Logical Network and subnet. Gateways will
      terminate on an address on one of the subnets configured for the
      logical network.    

* When will I be able to auto assign an IP address for a VM on a subnet (IPAM)?
  * Currently you must assign an IP address manually!

* What addresses do I use for BGP peering to MUX on TOR switches?
  * Use the PA addresses of LB MUX'es

* Public vs Private VIP
  * Is public VIP advertised via BGP?
    * Yes
  * Difference between public and private VIP

* Expanding number of SDN VMs (scale out)
  * Is there tooling available to scale out the SDN infrastructure? It would
    be nice to be able to do this in a declarative manner such as adding SDN
    VM's to the MultiNodeSampleConfig.psd1 file.

* Is the 'Microsoft Azure VFP Switch Extension' built in to the vswitch by
  default or is this installed via some other method?
    * The 'Microsoft Azure VFP Switch Extension' is shipped by default with
      Microsoft HyperV. However, it is disabled by default.

* Is there a prescribed procedure for removing SDN?

### **Other Info:**

Stand Alone DC
Domain = teacloud.local
Hostname = teacloud-dc1
  IP=10.7.144.136/24

* **Install AD Domain Services via Powershell**

  ```powershell
  Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -Restart 

  $params = @{
  CreateDnsDelegation = $false
  DatabasePath = "C:\Windows\NTDS"
  DomainMode   = "WinThreshold"
  DomainName   = "teacloud.local"
  DomainNetbiosName = "TEACLOUD"
  ForestMode = "WinThreshold"
  InstallDns = $true
  LogPath = "C:\Windows\NTDS"
  NoRebootOnCompletion = $false
  SysvolPath = "C:\Windows\SYSVOL"
  Force = $true
  }

  Import-Module ADDSDeployment

  Install-ADDSForest @params
  ```


### **Documentation:**

* **Configure the Software Load Balancer for Load Balancing and Network Address Translation (NAT)**

    <https://docs.microsoft.com/en-us/windows-server/networking/sdn/manage/configure-slb-and-nat>

* **Deploy an SDN infrastructure using SDN Express - Azure Stack HCI | Microsoft Docs**

    <https://docs.microsoft.com/en-us/azure-stack/hci/manage/sdn-express>

* **Use Datacenter Firewall to configure ACLs with PowerShell - Azure Stack HCI | Microsoft Docs required**

    <https://docs.microsoft.com/en-us/azure-stack/hci/manage/use-datacenter-firewall-powershell>

* **Create, delete, or update tenant virtual network | Microsoft Docs  required**

    <https://docs.microsoft.com/en-us/windows-server/networking/sdn/manage/create,-delete,-or-update-tenant-virtual-networks>

* **Add a Virtual Gateway to a Tenant Virtual Network | Microsoft Docs   required**

    <https://docs.microsoft.com/en-us/windows-server/networking/sdn/manage/add-a-virtual-gateway-to-a-tenant-virtual-network>

* **Connect container endpoints to a tenant virtual network | Microsoft Docs Not required**

    <https://docs.microsoft.com/en-us/windows-server/networking/sdn/manage/connect-container-endpoints-to-a-tenant-virtual-network>

* **Configure Encryption for a Virtual Network | Microsoft Docs Not required**

    <https://docs.microsoft.com/en-us/windows-server/networking/sdn/vnet-encryption/sdn-config-vnet-encryption>

* **Egress metering in virtual network | Microsoft Docs Not required**

    <https://docs.microsoft.com/en-us/windows-server/networking/sdn/manage/sdn-egress>

* **Create a VM and connect to a tenant virtual network or VLAN | Microsoft Docs required**

    <https://docs.microsoft.com/en-us/windows-server/networking/sdn/manage/create-a-tenant-vm>

* **Configure Quality of Service (QoS) for a tenant VM network adapter | Microsoft Docs  not required**

    <https://docs.microsoft.com/en-us/windows-server/networking/sdn/manage/configure-qos-for-tenant-vm-network-adapter>

* **Configure the Software Load Balancer for Load Balancing and Network Address Translation (NAT) | Microsoft Docs required** 

    <https://docs.microsoft.com/en-us/windows-server/networking/sdn/manage/configure-slb-and-nat>

* **Use network virtual appliances on a virtual network | Microsoft Docs Not required**

    <https://docs.microsoft.com/en-us/windows-server/networking/sdn/manage/use-network-virtual-appliances-on-a-vn>

* **Guest clustering in a virtual network | Microsoft Docs not required**

    <https://docs.microsoft.com/en-us/windows-server/networking/sdn/manage/guest-clustering>

* **Upgrade, backup, and restore SDN infrastructure | Microsoft Docs required**

    <https://docs.microsoft.com/en-us/windows-server/networking/sdn/manage/update-backup-restore>

* **Deploy an SDN infrastructure using SDN Express - Azure Stack HCILearn to deploy an SDN infrastructure using SDN Expressdocs.microsoft.com**

    <https://docs.microsoft.com/en-us/azure-stack/hci/manage/sdn-express>

* **Bill Curtis Git HUB** ****
  <https://github.com/mgodfre3/AzSHCI-AZNested>

  <https://docs.microsoft.com/en-us/windows-server/networking/sdn/manage/configure-slb-and-nat#example-use-slb-for-outbound-nat>

  <https://github.com/billcurtis/AzSHCISandbox>

  <https://docs.microsoft.com/en-us/azure-stack/hci/concepts/network-controller>

### **EAP Info:**

* **EAP Town hall, new features**

  <https://microsoft.sharepoint.com/:v:/t/AzureStackHCIPreviewCommunity/EYtjYziHK19Pof2t3vNAJvkBaTix-4Evjk3N4jb6oSvYng?e=v4y8ID>


* **Join Azure Stack HCI Preview Channel**

  <https://docs.microsoft.com/en-us/azure-stack/hci/manage/preview-channel>

