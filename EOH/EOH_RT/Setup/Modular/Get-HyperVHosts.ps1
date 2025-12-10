Function Get-HyperVHosts {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $VMHost = $env:COMPUTERNAME)

    # VMHost can be passed to the function but defaults to the localhost
    # Test connection to the host and set health and state
    # Validate the accessibility of the host
    # If any host in unhealthy the Global Alarm icon to Critical and the Global Alarm Image to Critical

    $ReportHosts = @()
    $HostUnhealthyCounter = 0

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

    If ($HostUnhealthyCounter -eq 0) {
        $Global:HostImage = $NonCriticalImage48
        $Global:HostIcon = "[NonCriticalImage]"
    }
    ElseIf ($HostUnhealthyCounter -lt ($ReportHosts.Count / 2)) {
        $Global:HostImage = $WarningImage48
        $Global:HostIcon = "[WarningImage]"
    }
    Else {
        $Global:HostImage = $CriticalImage48
        $Global:HostIcon = "[CriticalImage]"
    }
    Return $ReportHosts | Select-Object Name, State, PowerState, Health
}