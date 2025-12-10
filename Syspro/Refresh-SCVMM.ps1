Param (
    [Parameter(Mandatory=$False, Position=1)] 
    [String[]] $ClusterName)
Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $Color, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)

    $ErrorActionPreference = "Stop"
    Try {
        If ($Text.Count -ne $Color.Count) {
            Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $Color.Count.ToString()) -ForegroundColor Red
            Throw
        }
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $Color[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch { 
        Write-Host "Text Count:  " $Text.Count
        Write-Host "Color Count: " $Color.Count
        Write-Host $_
    }
}
Function Refresh-FailOverCluster {
    Param (
        [Parameter(Mandatory=$False, Position=1)] 
        [String[]] $ClusterName)

    Try { Import-Module FailoverClusters }
    Catch { $_; Return $False }
    If ($ClusterName -eq $null -or $ClusterName -eq "") {
        [String[]] $ClusterName = Get-Cluster -Domain $Env:USERDOMAIN
    }
    For ($ClusterIndex = 0; $ClusterIndex -lt $ClusterName.Count; $ClusterIndex ++) {
        Write-Color -Text ($ClusterIndex + 1), "/", $ClusterName.Count, " - Updating ", $ClusterName, " configuration" -Color Cyan, Cyan, Cyan, White, Yellow, White
        Get-ClusterResource -Cluster $ClusterName[$ClusterIndex] | Where-Object {$_.ResourceType.Name -eq 'Virtual Machine Configuration'} | Update-ClusterVirtualMachineConfiguration
    }
}
Function Refresh-SCVMMHostsAndVMs {
    Try { Import-Module VirtualMachineManager }
    Catch { $_; Return $False }

    Try {
        Write-Color "Collecting SCVMM Hosts - " -Color White -NoNewLine
        $SCVMMHosts = Get-SCVMHost
        Write-Color $SCVMMHosts.Count, " found" -Color Yellow, White
    }
    Catch {
        Write-Color "Failed - ", $_ -Color Red, Red
    }
    
    For ($HostIndex = 0; $HostIndex -lt $SCVMMHosts.Count; $HostIndex ++) {
        Try {
            Write-Color -Text ($HostIndex + 1), "/", $SCVMMHosts.Count, " - Refreshing ", $SCVMMHosts[$HostIndex].Name, " - " -Color Cyan, Cyan, Cyan, White, Yellow, White -NoNewLine
            Read-SCVMHost -VMHost $SCVMMHosts[$HostIndex] | Out-Null
            Write-Color -Text "Complete" -Color Green
        
            Write-Color -Text ($HostIndex + 1), "/", $SCVMMHosts.Count, " - Collecting VMs on  ", $SCVMMHosts[$HostIndex].Name, " - " -Color Cyan, Cyan, Cyan, White, Yellow, White -NoNewLine
            $SCVMMHostVMS = Get-SCVirtualMachine -VMHost $SCVMMHosts[$HostIndex]
            Write-Color -Text $SCVMMHostsVMS.Count, " found" -Color Yellow, White
            For ($VMIndex = 0; $VMIndex -lt $SCVMMHostVMS.Count; $VMIndex ++) {
                Try {
                    Write-Color ($HostIndex + 1), "/", $SCVMMHosts.Count, " - ", ($VMIndex + 1), "/", $SCVMMHostVMS.Count, " - Refreshing ", $SCVMMHostVMS[$VMIndex].Name, " - " -Color Cyan, Cyan, Cyan, White, Cyan, Cyan, Cyan, White, Yellow, White -NoNewLine
                    Read-SCVirtualMachine -VM $SCVMMHostVMS[$VMIndex] | Out-Null
                    Write-Color "Complete" -Color Green
                }
                Catch {
                    Write-Color "Failed - ", $_ -Color Red, Red
                }
            }
        }
        Catch {
            Write-Color "Failed - ", $_ -Color Red, Red 
        }
    }
}
$ErrorActionPreference = "Stop"
Clear-Host
Refresh-FailOverCluster -ClusterName $ClusterName
Refresh-SCVMMHostsAndVMs