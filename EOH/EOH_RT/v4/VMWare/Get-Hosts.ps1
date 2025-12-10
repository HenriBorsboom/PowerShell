Param (
    [Parameter(Mandatory=$False, Position=1)]						# Target System Must contain: SystemName, IPAddress, CommonName, Platform, Username, Password
    [Object[]] $ReportingEnvironment)	
    
Function Get-Hosts {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Platform, `
        [Parameter(Mandatory=$False, Position=2)]
        [String] $VMHost = $env:COMPUTERNAME)
    
    $ReportHosts = @()

    $ESXHosts = Get-VMHost | Select-Object Name, ConnectionState, PowerState
    $UnhealthyHosts = 0
    ForEach ($ESXHost in $ESXHosts) {
        If ($ESXHost.ConnectionState -eq 'Connected' -and $ESXHost.PowerState -eq 'PoweredOn') {
            $State      = 'OK'
            $HealthIcon = '[NonCriticalImage]'
        }
        Else {
            $UnhealthyHosts += 1
            $State      = 'Fail'
            $HealthIcon = '[CriticalImage]'
        }
        $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
            'Name'        = $ESXHost.Name
            'State'       = $ESXHost.ConnectionState
            'Power State' = $ESXHost.PowerState
            'Health'      = $HealthIcon
        })
    }
        
    Return $ReportHosts | Select-Object 'Name', 'State', 'Power State', 'Health'
}