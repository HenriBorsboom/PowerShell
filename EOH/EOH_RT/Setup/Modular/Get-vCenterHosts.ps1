Function Get-vCenterHosts {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [Switch] $Dummy)

    # Dummy can be passed to the Function to generate dummy info
    # Get all hosts connected to VMWare
    # Cycle through hosts to determine health state
    # If any host in unhealthy the Global Alarm icon to Critical and the Global Alarm Image to Critical

    $ReportHosts = @()
    Switch ($Dummy) {
        $True {
            $HostUnhealthyCounter = 2
            $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                Name       = 'Test Host 1'
                State      = 'Connected'
                PowerState = 'PoweredOn'
                Health     = '[NonCriticalImage]'
            })
            $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                Name       = 'Test Host 2'
                State      = 'Not Connected'
                PowerState = 'PoweredOff'
                Health     = '[CriticalImage]'
            })
            $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                Name       = 'Test Host 3'
                State      = 'Connected'
                PowerState = 'PoweredOff'
                Health     = '[WarningImage]'
            })
        }
        $False {
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