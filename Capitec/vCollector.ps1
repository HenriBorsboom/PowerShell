# VMware vCollector
# Copyright VMware Inc. 2020
#
# Author: Josh Miller
# 
# Technical Contact: Josh Miller
# Email: joshmiller@vmware.com
#
# Description: The script uses VMware's PowerCLI to connect to a vSphere 
#     vCenter or standalone ESXi host and collects data required for assessing
#     license compliance. Data collected includes license keys, licenses 
#     assignments, physical host details, and a list of virtual machines.
#
# DISCLAIMER: VMware offers this script as-is and makes no representations or 
#     warranties of any kind whether express, implied, statutory, or other. 
#     This includes, without limitation, warranties of fitness for a particular
#     purpose, title, non-infringement, course of dealing or performance, usage 
#     of trade, absence of latent or other defects, accuracy, or the presence 
#     or absence of errors, whether known or discoverable. In no event will 
#     VMware be liable to You for any direct, special, indirect, incidental, 
#     consequential, punitive, exemplary, or other losses, costs, expenses, or 
#     damages arising out of Your use of this script.

# Import the PowerCLI module or snapin if it is available
# exit the script if it is not
if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core)) {  
    Write-Output "Loading the VMware Core Module..."  
    Import-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue
    if (!(Get-Module -Name VMware.VimAutomation.Core)) {
        # Error out if loading fails  
        Write-Error "`nERROR: Cannot load the VMware Module. Please check that PowerCLI is installed."
            Write-Host "Press Enter to exit"
            $Host.UI.ReadLine()
        Exit
    }
    Write-Host "Module loaded."
} elseif (!(Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -and !(Get-Module -Name VMware.VimAutomation.Core)) {  
    Write-Output "Loading the VMware Core Snapin..."  
    Add-PSSnapin -PassThru VMware.VimAutomation.Core -ErrorAction SilentlyContinue
    if (!(Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
        # Error out if loading fails  
        Write-Error "`nERROR: Cannot load the VMware Snapin or Module. Please check that PowerCLI is installed."
        Write-Host "Press Enter to exit"
        $Host.UI.ReadLine()
        Exit
    }
    Write-Host "Snapin loaded."
}

# Disconnect any current connections
$ErrorActionPreference = "SilentlyContinue"
Disconnect-VIServer -Server $global:DefaultVIServers -Force -Confirm:$false
$ErrorActionPreference = "Continue"

# Get the location of the current script
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

# Set the output path
$outputPath = $scriptPath + "\VMware Data\vCollector\"

if(!(Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

# Get the current date
$Date = Get-Date -Format "yyyy-MM-dd"

# Get PowerCLI version
$Version = Get-Module -Name VMware.VimAutomation.Core | Select Name,Version

# Start the connection log
Add-Content -Path "$outputPath\ConnectionLog $Date.txt" -Value "##### vCollector Run Start #####"
Add-Content -Path "$outputPath\ConnectionLog $Date.txt" -Value "vCollector Version: 1.9"
Add-Content -Path "$outputPath\ConnectionLog $Date.txt" -Value "PowerCLI Version: $($Version.Version)"

# Check and update the PowerCLI configurations
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false | Out-Null
$Config = Get-PowerCLIConfiguration -Scope Session

Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope Session -Confirm:$false | Out-Null
$Config = Get-PowerCLIConfiguration -Scope Session

# Add config values to the connection log
Add-Content -Path "$outputPath\ConnectionLog $Date.txt" -Value "InvalidCertificateAction: $($Config.InvalidCertificateAction)"
Add-Content -Path "$outputPath\ConnectionLog $Date.txt" -Value "DefaultVIServerMode: $($Config.DefaultVIServerMode)"

# Get server name or IP address from user
Write-Host "`nPlease provide the name or IP address of the vCenter server or ESXi host"
Write-Host " * ESXi hosts managed by a vCenter do not need to be scanned individually"
Write-Host " * For vCenters in Enhanced Linked Mode, only one vCenter needs to be scanned"
$ServerName = $Host.UI.ReadLine()

# Connect to the provided host or vCenter server
Write-Host "`nAttempting to connect to server: $ServerName"
Add-Content -Path "$outputPath\ConnectionLog $Date.txt" -Value "`r`nAttempting to connect to server: $ServerName"
$Output = Connect-VIServer -Server $ServerName -Verbose *>&1 
Add-Content -Path "$outputPath\ConnectionLog $Date.txt" -Value $Output

# Check for errors
if($Output -like "*incorrect user name or password*") {
    Write-Error "`nError: Cannot complete login due to an incorrect user name or password."

    if($global:DefaultVIServers.Count -eq 0) {
        $Cred = Get-Credential
        Write-Host "`nAttempting to connect to server: $ServerName"
        Add-Content -Path "$outputPath\ConnectionLog $Date.txt" -Value "`r`nAttempting to connect to server: $ServerName"
        $Output = Connect-VIServer -Server $ServerName -Credential $Cred -Verbose *>&1 
        Add-Content -Path "$outputPath\ConnectionLog $Date.txt" -Value $Output
    }
}

if($global:DefaultVIServers.Count -eq 0) {
    Add-Content -Path "$outputPath\ConnectionLog $Date.txt" -Value "`r`n`r`n"
    Write-Error "`nERROR: Unable to connect to provided vCenter or host. Review connection log for details."
    Write-Host "Press Enter to exit"
    $Host.UI.ReadLine()
    Exit
}

# Get license data
Write-Host "Collecting license data"
$ServiceInstance = Get-View ServiceInstance
$LicenseManager = Get-View $ServiceInstance.Content.LicenseManager

$Licenses = @()
$LicenseManager.Licenses | % {
    $Licenses += New-Object PSObject -Property @{
        Product = $_.Name
        LicenseKey = $_.LicenseKey
        Total = $_.Total 
        Used = $_.Used
        Metric = $_.CostUnit 
        ExpirationDate = ($_.Properties | Where {$_.Key -eq "ExpirationDate"} | Select -ExpandProperty Value)
        Info = ($_.Labels | Select -ExpandProperty Value)
    }
}

# Connect to the provided host or vCenter server in linked mode
Write-Host "Attempting to connect to any linked vCenters"
Add-Content -Path "$outputPath\ConnectionLog $Date.txt" -Value "`r`nAttempting to connect to any linked vCenters"
$Output = Connect-VIServer -Server $ServerName -AllLinked -Verbose *>&1 
Add-Content -Path "$outputPath\ConnectionLog $Date.txt" -Value $Output

# Get host data
Write-Host "Collecting host data"
$Hosts = Get-VMHost | Select Name,Version,LicenseKey,APIVersion,ConnectionState,PowerState,@{N="Cluster";E={$_.Parent.Name}},
    @{N="vCenterIP";E={$_.ExtensionData.Summary.ManagementServerIp}},@{N="NumCPU";E={$_.ExtensionData.Summary.Hardware.NumCpuPkgs}},
    @{N="NumCores";E={$_.ExtensionData.Hardware.CpuInfo.NumCpuCores}},@{N="NumThreads";E={$_.ExtensionData.Hardware.CpuInfo.NumCpuThreads}},
    @{N="VMCount";E={($_ | Get-VM).Count}}

# Add license product name to hosts
$Hosts | % {
    $Key = $_.PSObject.Properties["LicenseKey"].Value
    $Entry = $Licenses | Where LicenseKey -eq $Key | Select -First 1
    
    $vCenter = ""
    $FQDN = ""
    if(($_.vCenterIP -ne $null) -and ($_.vCenterIP -ne "")) {
        try {
            $FQDN = [System.Net.Dns]::GetHostEntry($_.vCenterIP).HostName
            $vCenter = $FQDN.Split(".")[0]
        } catch {
            $vCenter = $_.vCenterIP
        }
    }

    if($_.Cluster -eq "host") {
        $_.Cluster = ""
    }

    $_ | Add-Member -Name "Product" -Value $Entry.PSObject.Properties["Product"].Value -MemberType NoteProperty
    $_ | Add-Member -Name "Metric" -Value $Entry.PSObject.Properties["Metric"].Value -MemberType NoteProperty
    $_ | Add-Member -Name "vCenter" -Value $vCenter -MemberType NoteProperty
}

# Get VM data
Write-Host "Collecting VM data"
$VMs = Get-VM | Select Name,@{N="DNS Name";E={$_.ExtensionData.Guest.Hostname}},PowerState,@{N="Status";E={$_.ExtensionData.OverallStatus}},VMHost,
    @{N="Guest OS";E={$_.ExtensionData.Guest.GuestFullName}},NumCpu

# Export VM data to CSV
Write-Host "Writing data to $outputPath"
$VMs | Export-Csv -Path "$outputPath\$ServerName VMs $Date.csv" -NoTypeInformation

# Export host data to CSV
$Hosts | Select Name,Product,Version,LicenseKey,ApiVersion,ConnectionState,PowerState,Cluster,vCenter,Metric,NumCpu,NumCores,NumThreads,VMCount | 
    Export-Csv -Path "$outputPath\$ServerName Hosts $Date.csv" -NoTypeInformation

# Export license data
$Licenses | Select Product,LicenseKey,Total,Used,Metric,ExpirationDate,Info | 
    Export-Csv -Path "$outputPath\$ServerName Licenses $Date.csv" -NoTypeInformation

Write-Host "`nScan successful for:"
foreach($vc in $global:DefaultVIServers) {
    Write-Host $vc.Name
}

# Disconnect server
Disconnect-VIServer -Server $ServerName -Confirm:$false
Add-Content -Path "$outputPath\ConnectionLog $Date.txt" -Value "`r`n`r`n"

# Prompt to exit
Write-Host "`nPress Enter to exit"
$Host.UI.ReadLine()






# SIG # Begin signature block
# MIIFlwYJKoZIhvcNAQcCoIIFiDCCBYQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU4vwq/4vZ8oHMLo1jR2E1gtFH
# /vagggMkMIIDIDCCAgigAwIBAgIQL7KlRTLJ57xHE4/4e2Ex8TANBgkqhkiG9w0B
# AQsFADAoMSYwJAYDVQQDDB1WTXdhcmUgQ29tcGxpYW5jZSBDZXJ0aWZpY2F0ZTAe
# Fw0yMTA0MDcxNzQwNDVaFw0yMjA0MDcxODAwNDVaMCgxJjAkBgNVBAMMHVZNd2Fy
# ZSBDb21wbGlhbmNlIENlcnRpZmljYXRlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
# MIIBCgKCAQEA0080ZZGbVh3yk5f7M6gTJvyTAK1B1t3IFNXwWP8WahyvtEnW05k0
# IxcAGAk9gtoB9XVjxai79YilGCttF0E1mXGMOErhDdGkuNpJvzKo9KH9GL7BkWJU
# QGkRF93EICyCI/J8gTQReHDmUVn9AXJ72lcRLCPMueoEs/jtG1snlNSNqcOGLhzp
# NyHjv6ZX2GuOPoiaBbmbDhRFxnyWAOTEMda2DvQmnq3XPwxVrL1+9S+oHrpHkISq
# /3MHc3+29r6Ey8hdaPikvhrjEUZOZQSb+gdtCF7uNiCwUuOgysaQQEmyEen6mfxi
# r3AGSsnHI6FwHHulZBvmx4qElh14tg6BoQIDAQABo0YwRDAOBgNVHQ8BAf8EBAMC
# B4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHhjJQasCNM1+SeOQIJI
# R5wD9xDWMA0GCSqGSIb3DQEBCwUAA4IBAQC/6sQv82ar2x3pb0yPLGNYxJUBOmBS
# Xoxr7gzMEPDjxolH65gp/P+aAXdX91AfKSwg+Z09qjeqZTKZapRzGJyRQecV4EgS
# XJXIPFkXL+ew2kKx7lEcFxYjyILL486G4pVsavkCDBYLI0HiVKQ00FcLtkgbZLsU
# yBQoKtaFHdbR1etm1jxaspP8PJ1XvapQZMt1HKPtpOP2DiikAcIVA9wD+44Frtw9
# hsZiG6h6x+sJ/96KttIdrAglAetH7rjqlYwKOIlq+8B6XKzYv8v1nyCzdopeeMv8
# Y7RWRlsU2CWu+ls8x/wvugW3r1Qd3oNBX6xIHSObU0q4cJPoh5ailofuMYIB3TCC
# AdkCAQEwPDAoMSYwJAYDVQQDDB1WTXdhcmUgQ29tcGxpYW5jZSBDZXJ0aWZpY2F0
# ZQIQL7KlRTLJ57xHE4/4e2Ex8TAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEK
# MAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3
# AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUUsC8xfo4wGpJbYkt
# Lbeit3fanKMwDQYJKoZIhvcNAQEBBQAEggEAGHHGMOTop2QhWPkduUV3o39kDye4
# Om6OvQtvcPKy8LZ3tC6uPIhptzhNZ6Dan6LYw5t8YkmxCm2cLUD/eYpxOotziDb/
# stL82j/goxj/jy1RThAEtokfjUpUlziIF9VrxJUfEyswKU+Ht1tjnOXoEsShhe1K
# gzRDx5w5OgZUhYIDixw98rmtYEYO7ayfulPC97SX7zP/XPzWOZS2q+7mdwT7K950
# kd6MtB2Bj2dYvsaVsj4SpiEQh7C16m+NofL15EEv6zD2kUA0yYHOjNfGAqyS3fgi
# 9UtFxCdeqpsSGRVYMPxxr/lv4N8AfJvaaChNq7SPnQDBL6vzewARWfKbRg==
# SIG # End signature block
