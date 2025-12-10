Clear-Host
Try {
    Import-Module FailoverClusters -ErrorAction Stop
    Import-Module Hyper-V -ErrorAction Stop
}
Catch {
    Write-Host "Module import failed" -ForegroundColor Red
}

Write-Host "Getting clusters from domain - " -NoNewline
[Object[]] $Clusters = Get-Cluster -Domain $env:UserDomain
Write-Host ($Clusters.Count.ToString() + ' found') -ForegroundColor Green

$Details = @()
$Failures = @()
For ($ClusterI = 0; $ClusterI -le $Clusters.Count; $ClusterI ++) {
    Write-Host ("Testing Connectivity to " + $Clusters[$ClusterI].Name + ' - ') -NoNewline
    If (Test-Connection -ComputerName $Clusters[$ClusterI].Name -Count 2 -Quiet) {
        Write-Host "Cluster online" -ForegroundColor Green
        Write-Host ("|- Getting hosts for cluster - ") -NoNewline
        $ClusterNodes = Get-ClusterNode -Cluster $Clusters[$ClusterI].Name
        Write-Host ($ClusterNodes.Count.ToString() + ' found') -ForegroundColor Green
        For ($ClusterNodeI = 0; $ClusterNodeI -lt $ClusterNodes.Count; $ClusterNodeI ++) {
            Write-Host ("|-- Checking for Hyper-V on " + $ClusterNodes[$ClusterNodeI].Name + " - ") -NoNewline
            Try {
                $ServerRoles = Get-WmiObject -Class Win32_Serverfeature -ComputerName $ClusterNodes[$ClusterNodeI].Name -ErrorAction Stop
                $HyperVEnabled = $False
                ForEach ($Role in $Roles) {
                    If ($Role.Name.ToLower() -like "*hyper*") { $HyperVEnabled = $True } 
                }
                If ($HyperVEnabled -eq $True) {
                    Write-Host "Installed" -ForegroundColor Yellow
                    Write-Host ("|--- Getting VMs on ",$ClusterNodes[$ClusterNodeI].Name + " - ") -NoNewline
                    $ClusterName = $Clusters[$ClusterI].Name
                    $ClusterHostName = $ClusterNodes[$ClusterNodeI].Name
                    Try {
                        $OSCaption = (Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption' -ComputerName $ClusterHostName).Caption
                        If ($OSCaption -like '*201*') {
                            $HostedVMs = Get-VM | Select Name, State, IntegrationServices, @{Name='Cluster'; Expression={$ClusterName}}, @{Name='Host'; Expression={$ClusterHostName}} -ErrorAction Stop
                            ForEach ($HostedVM in $HostedVMs) {
                                $Details += ,($HostedVM)
                            }
                        }
                        Else {
                            $HostedVMs = Get-WmiObject -Query "Select * from MSVM_ComputerSystem Where Caption = 'Virtual Machine'" -Namespace 'root\virtualization' -ComputerName $ClusterHostName
                            ForEach ($HostedVM in $HostedVMs) {
                                Switch ($HostedVM.HealthState) {
                                    "5" {
                                        $State = "OK"
                                    }
                                    "20" {
                                        $State = "Major Failure"
                                    }
                                    "25" {
                                        $State = "Critical Failure"
                                    }
                                    Default {
                                        $State = "Unknown"
                                    }
                                }
                                $Details += ,(New-Object -TypeName PSObject -Property @{
                                    Name = $HostedVM.ElementName
                                    State = $State
                                    IntegrationServices = ''
                                    Cluster = $ClusterName
                                    Host = $ClusterHostName
                                    }
                                )
                            }
                        }
                        
                        Write-Host ($HostedVMs.Count.ToString() + ' found') -ForegroundColor Green
                    }
                    Catch {
                        Write-Host "Failed" -ForegroundColor Red
                        $Failures += ,($Clusters[$ClusterI])
                    }
                }
                Else {
                    Write-Host "Not found" -ForegroundColor Green
                }
            }
            Catch {
                Write-Host "Failed" -ForegroundColor Red
                $Failures += ,($Clusters[$ClusterI])
            }
        }
    }
    Else {
        Write-Host "Cluster Offline" -ForegroundColor Red
        $Failures += ,($Clusters[$ClusterI])   
    }
}

$Details | Select Name, State, IntegrationServices, Cluster, Host