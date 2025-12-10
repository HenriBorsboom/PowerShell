#
# Source:      https://technet.microsoft.com/en-us/library/bb963739.aspx
#
#
# Filename:    SummarizeVMMInformation.ps1
# Description: Display information about Virtual Machine Manager 
#              servers (including hosts and library servers), 
#              host groups, virtual machines, and self-service 
#              policies.

# DISCLAIMER:
# Copyright (c) Microsoft Corporation. All rights reserved. This 
# script is made available to you without any express, implied or 
# statutory warranty, not even the implied warranty of 
# merchantability or fitness for a particular purpose, or the 
# warranty of title or non-infringement. The entire risk of the 
# use or the results from the use of this script remains with you.

Function SummaryOfVMMServer {
    ####################################################################
    # Summary of Virtual Machine Manager Server
    ####################################################################
    $SummaryDate = Get-Date
    # Substitute the name of your VMM server and domain in this command:
    $VMMServer = Get-VMMServer -ComputerName "VMMServer1.Contoso.com"
    $VMHosts = @(Get-VMHost)
    $HostedVMs = @(Get-VM | where {$_.Status -ne "Stored"})

    Write-Host "`nVIRTUAL MACHINE MANAGER SERVER" -ForegroundColor Yellow

    Write-Host "Summary Date       :", $SummaryDate
    Write-Host "VMM Server Name    :", $VMMServer.Name
    Write-Host "Evaluation Version :", $VMMServer.IsEvaluationVersion
    Write-Host "Placement Goal     :", $VMMServer.PlacementGoal
    Write-Host "Total Hosts        :", $VMHosts.Count
    Write-Host "Hosted VMs         :", $HostedVMs.Count
    if ($VMHosts.Count -ne 0)
    {
    Write-Host "VMs per Host       :", ($HostedVMs.Count / $VMHosts.Count)
    }
}
Function SummaryOfVMHosts {
    ####################################################################
    # Summary of Virtual Machine Hosts
    ####################################################################
    $VMHosts = @(Get-VMHost)

    Write-Host "`nVIRTUAL MACHINE HOSTS" -ForegroundColor Yellow

    Write-Host "Total Hosts                             :", $VMHosts.Count
    Write-Host "Hosts Not Responding                    :", @($VMHosts | where {$_.Status -eq "NotResponding"}).Count
    Write-Host "Hosts Needing Agent Update              :", @($VMHosts | where {$_.Agent.VersionState -eq "NeedsUpdate"}).Count
    Write-Host "Hosts Needing Virtual Server Update     :", @($VMHosts | where {$_.VirtualServerVersionState -eq "NeedsUpdate"}).Count
    Write-Host "Hosts in Maintenance                    :", @($VMHosts | where {$_.MaintenanceHost -eq $true}).Count
    Write-Host "Hosts on Perimeter Network              :", @($VMHosts | where {$_.PerimeterNetworkHost -eq $true}).Count
}
Function SummaryOfVMs {
    ####################################################################
    # Summary of Virtual Machines
    ####################################################################
    $VMs = @(Get-VM)

    Write-Host "`nVIRTUAL MACHINES" -ForegroundColor Yellow

    Write-Host "Total VMs                :", $VMs.Count
    Write-Host "Hosted VMs               :", @($VMs | where {$_.Status -ne "Stored"}).Count
    Write-Host "Stored VMs               :", @($VMs | where {$_.Status -eq "Stored"}).Count
    Write-Host "Running VMs              :", @($VMs | where {$_.Status -eq "Running"}).Count
    Write-Host "Self-Service VMs         :", @($VMs | where {$_.SelfServicePolicy -ne $null}).Count
    Write-Host "VMs without VMAdditions  :", @($VMs | where {$_.HasVMAdditions -eq $false}).Count
}
Function SummaryOfSelfService {
    ####################################################################
    # Summary of Self-Service
    ####################################################################
    $SelfServicePolicies = @(Get-SelfServicePolicy)
    $VMs = @(Get-VM)

    Write-Host "`nSELF-SERVICE" -ForegroundColor Yellow

    Write-Host "Self Service Policies   :", $SelfServicePolicies.Count
    Write-Host "Total Self-Service VMs  :", @($VMs | where {$_.SelfServicePolicy -ne $null}).Count
    Write-Host "Hosted Self-Service VMs :", @($VMs | where {$_.SelfServicePolicy -ne $null} | where {$_.Status -ne "Stored"}).Count
    Write-Host "Stored Self-Service VMs :", @($VMs | where {$_.SelfServicePolicy -ne $null} | where {$_.Status -eq "Stored"}).Count
}
Function SummaryOfLibraryServers {
    ####################################################################
    # Summary of Library Servers
    ####################################################################
    $LibraryServers = @(Get-LibraryServer)
    $VMs = @(Get-VM)

    Write-Host "`nLIBRARY SERVERS" -ForegroundColor Yellow

    Write-Host "Library Servers :", $LibraryServers.Count
    Write-Host "Stored VMs      :", ($VMs | where {$_.Status -eq "Stored"}).Count
}
Function 
####################################################################
# Summary of Virtual Machine Host Groups
####################################################################
$VMHostGroups = @(Get-VMHostGroup)
$VMs = @(Get-VM)

Write-Host "`nVIRTUAL MACHINE HOST GROUPS" -ForegroundColor Yellow

foreach ($VMHostGroup in $VMHostGroups)
{
    $VMHostCount = $VMHostGroup.Hosts.Count
    $VMCount = @($VMs | where {$VMHostGroup.Hosts -contains $_.VMHost}).Count
    $RunningVMCount = @($VMs | where {$VMHostGroup.Hosts -contains $_.VMHost} | where {$_.Status -eq "Running"}).Count
    $SelfServiceVMCount = @($VMs | where {$VMHostGroup.Hosts -contains $_.VMHost} | where {$_.SelfServicePolicy -ne $null}).Count

    Write-Host "Host Group                :", $VMHostGroup.Name
    Write-Host "Number of Hosts           :", $VMHostCount
    if ($VMHostCount -ne 0)
    {
    Write-Host "Number of VMS             :", $VMCount
    Write-Host "Running VMs               :", $RunningVMCount
    Write-Host "Self-Service VMs          :", $SelfServiceVMCount
    Write-Host "VMs per Host              :", ($VMCount / $VMHostCount)
    Write-Host "Running VMs per Host      :", ($RunningVMCount / $VMHostCount)
    Write-Host "Self-Service VMs per Host :", ($SelfServiceVMCount / $VMHostCount)
    }
    Write-Host
}