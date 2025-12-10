Function Get-Hosts {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet('HyperVCluster', 'HyperVStandalone', 'VMWare', 'Dummy')]
        [String] $Platform, `
        [Parameter(Mandatory=$False, Position=2)]
        [String] $VMHost = $env:COMPUTERNAME)

    If ($Platform -like 'Hyper*') { $Platform = 'HyperV' }
    
    $ReportHosts = @()
    $HostUnhealthyCounter = 0

    Switch ($Platform) {
        'HyperV' {
            If (Test-Connection $VMHost -Quiet -ErrorAction Stop) {
                $HealthIcon = '[NonCriticalImage]'
                $State      = 'Connected'
            }
            Else {
                $HostUnhealthyCounter += 1
                $HealthIcon = '[CriticalImage]'
                $State      = 'Not Connected'
            }
    
            $ReportHosts = (New-Object -TypeName PSObject -Property @{
                Name       = $VMHost
                State      = $State
                PowerState = $State
                Health     = $HealthIcon
            })
        }
        'VMWare' {
            $ESXHosts = Get-VMHost | Select-Object Name, ConnectionState, PowerState
            $HostUnhealthyCounter = 0
            ForEach ($ESXHost in $ESXHosts) {
                If ($ESXHost.ConnectionState -eq 'Connected' -and $ESXHost.PowerState -eq 'PoweredOn') {
                    $State = 'OK'
                    $HealthIcon = '[NonCriticalImage]'
                }
                Else {
                    $HostUnhealthyCounter += 1
                    $State = 'Fail'
                    $HealthIcon = '[CriticalImage]'
                }
                $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                    Name       = $ESXHost.Name
                    State      = $ESXHost.ConnectionState
                    PowerState = $ESXHost.PowerState
                    Health     = $HealthIcon
                })
            }
        }
        'Dummy' {
            $HostUnhealthyCounter = 2
            $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                Name       = 'Test Host 1'
                State      = 'Connected'
                PowerState = 'PoweredOn'
                Health     = '[NonCriticalImage]'
            }) # Non Critical
            $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                Name       = 'Test Host 2'
                State      = 'Not Connected'
                PowerState = 'PoweredOff'
                Health     = '[CriticalImage]'
            }) # Critical
            $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                Name       = 'Test Host 3'
                State      = 'Connected'
                PowerState = 'PoweredOff'
                Health     = '[WarningImage]'
            }) # Warning
        }
    }

    If ($HostUnhealthyCounter -eq 0) {
        $Global:HostImage = $NonCriticalImage48
        $Global:HostIcon = '[NonCriticalImage]'
    }
    ElseIf ($HostUnhealthyCounter -lt ($ReportHosts.Count / 2)) {
        $Global:HostImage = $WarningImage48
        $Global:HostIcon = '[WarningImage]'
    }
    Else {
        $Global:HostImage = $CriticalImage48
        $Global:HostIcon = '[CriticalImage]'
    }
    Return $ReportHosts | Select-Object Name, State, PowerState, Health
}
Get-Hosts -Platform Dummy