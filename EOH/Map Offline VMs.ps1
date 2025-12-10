Clear-Host
$Clusters = @()
$Clusters += ,('SLBCLSPRD001')
$Clusters += ,('SLBCLSPRD200')
$Clusters += ,('SLBCLSQA203')
$Clusters += ,('SLBCLSTST200')
$Clusters += ,('SLBCLSTST201')

$AllVMs = @()
$AllOfflineVMs = @()
For ($ClusterI = 0; $ClusterI -lt $Clusters.Count; $ClusterI ++) {
    Write-Host ("Checking if " + $Clusters[$ClusterI] + " is online - ") -NoNewline
    If (Test-Connection -ComputerName $Clusters[$ClusterI] -Count 2 -Quiet) {
        Write-Host "Online" -ForegroundColor Green
        #<#
        #Getting Nodes
        Write-Host ("   Getting cluster nodes for " + $Clusters[$ClusterI] + " - ") -NoNewline
        $ClusterNodes = Get-ClusterNode -Cluster $Clusters[$ClusterI]
        Write-Host ($ClusterNodes.Count.ToString() = ' found') -ForegroundColor Green
        #
        #getting VMs on Node
        For ($NodeI = 0; $NodeI -lt $ClusterNodes.Count; $NodeI ++) {
            Write-Host ("     Getting VMs on " + $ClusterNodes[$NodeI].Name + " - ") -NoNewline
            $NodeVMs = Get-VM -ComputerName $ClusterNodes[$NodeI].Name
            Write-Host ($nodeVMs.Count.ToString() + ' found') -ForegroundColor Green
            #$AllVMs += $NodeVMs | Select Name, State, @{Name='Host'; expression={$Clusters[$Clusteri]}}, @{Name='Test'; expression={$VMSwitch}}
            For ($VMi = 0; $VMi -lt $NodeVMs.Count; $VMi ++) {
                Write-Host ("         Processing VM " + $NodeVMs[$VMi].Name + " - ") -NoNewline
                $VMSwitch = ($NodeVMs[$VMi] | Select -ExpandProperty NetworkAdapters).SwitchName
                $AllVMs += $NodeVMs[$VMi] | Select Name, State, @{Name='Host'; expression={$Clusters[$Clusteri]}}, @{Name='SwitchName'; expression={$VMSwitch}}
                If ($NodeVMs[$VMi].State -ne 'Running') { # -or $VMSwitch -notlike 'Client*') {
                    $AllOfflineVMs += $NodeVMs[$VMi] | Select Name, State, @{Name='Host'; expression={$Clusters[$Clusteri]}}, @{Name='SwitchName'; expression={$VMSwitch}}
                    Write-Host "Added to 'Offline'" -ForegroundColor Red
                }
                Else {
                    Write-Host "Skipped" -ForegroundColor Green
                }
                $VMSwitch = $null
            }
        }
        #
        #>
    }
    Else {
        Write-Host "Offline" -ForegroundColor Red
    }        
}

$AllVMs
$AllOfflineVMs