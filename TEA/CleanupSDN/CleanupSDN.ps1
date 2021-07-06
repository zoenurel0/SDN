param (
    [Parameter(Mandatory=$true)]
    [String]$ConfigurationDataFile
)


<#Clean up Summary

    Stop and delete SDNVMS

    Delete SDNVM AD Accounts

    Delete DNS record sdn.teainc.org

    Delete SDNVM files from hypervisors

#>

#Get Config Data


$configdata = [hashtable] (iex (gc $ConfigurationDataFile | out-string))

#Get list of VM targets to remove
$deleteVmList = [System.Collections.ArrayList]@()

$SDNVMDeleteTargets = @(
    'NCs'
    'Muxes'
    'Gateways'
)

foreach ($vmGroup in $SDNVMDeleteTargets) {

    $Vms = $configdata.$vmGroup.ComputerName

    foreach ($vm in $Vms) {

        $deleteVmList.Add($vm) | Out-Null
    }
}

## Stop and delete SDNVMS

$hvhosts = $configdata.HyperVHosts

foreach ($hvhost in $hvhosts) {
    $deleteTargets = Get-VM -ComputerName $hvhost -Name $deleteVmList -ErrorAction SilentlyContinue
    Stop-VM -VM $deleteTargets #-WhatIf
    Remove-VM -VM $deleteTargets -Force #-WhatIf
}

## Delete SDNVM AD Accounts

foreach ($SDNVM in $deleteVmList) {

    Try {
        Get-ADComputer -Identity $SDNVM | Remove-ADObject -Recursive -Confirm:$false #-WhatIf
    }
    Catch {
        Write-Output "Failed to remove $SDNVM from AD!"
    }
}

## Delete DNS record sdn.teainc.org
foreach ($SDNVM in $deleteVmList) {
    try {
        $aRecord = Get-DnsServerResourceRecord -ZoneName $configdata.JoinDomain -ComputerName $configdata.JoinDomain -RRType A -Name $SDNVM -ErrorAction Stop
        #$aRecord
        Remove-DnsServerResourceRecord -ZoneName $configdata.JoinDomain -ComputerName $configdata.JoinDomain -InputObject $aRecord -Force  -ErrorAction Stop #-WhatIf
    }
    catch {
        Write-Output "Failed to remove DNS A record for $SDNVM. Record may not exist!"
    }
 }

## Delete SDNVM files from hypervisors
Get-ClusterSharedVolume -Cluster $configdata.HyperVHosts[0] -Name 'Cluster Virtual Disk (Volume1)' | Move-ClusterSharedVolume 
Sleep -Seconds 3

foreach ($SDNVM in $deleteVmList) {

    Try {
        rmdir -Path "\\$($configdata.HyperVHosts[0])\c$\ClusterStorage\Volume1\$SDNVM" -Recurse -ErrorAction Stop
    }

    Catch {
        Write-Output "One or more errors ocurred while removing files for $SDNVM!"
    }
}

