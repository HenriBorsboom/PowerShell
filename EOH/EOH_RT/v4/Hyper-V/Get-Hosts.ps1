Param (
    [Parameter(Mandatory=$False, Position=1)]						# Target System Must contain: SystemName, IPAddress, CommonName, Platform, Username, Password
    [Object[]] $ReportingEnvironment)	

Function Get-Hosts {
    Param (
        [Parameter(Mandatory=$False, Position=1)]						# Target System Must contain: SystemName, IPAddress, CommonName, Platform, Username, Password
        [Object[]] $Environment, `
        [Parameter(Mandatory=$False, Position=1)]						# Target System Must contain: SystemName, IPAddress, CommonName, Platform, Username, Password
        [String[]] $Targets)	

    $ReportHosts = @()
    $UnhealthyHosts = 0
    If ($Environment -ne $null) {
        If (Test-Connection $Environment.'IP Address' -Quiet -ErrorAction Stop) {
            $HealthIcon = '[NonCriticalImage]'
            $State      = 'PoweredOn'
        }
        Else {
            $HealthIcon = '[CriticalImage]'
            $State      = 'PoweredOff'
            $UnhealthyHosts += 1
        }

        $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
            'Name'        = $VMHost
            'State'       = $State
            'Power State' = $State
            'Health'      = $HealthIcon
        })
    }
    ElseIf ($Targets -ne $null) {
        ForEach ($Target in $Targets) {
            If (Test-Connection $Environment.'IP Address' -Quiet -ErrorAction Stop) {
                $HealthIcon = '[NonCriticalImage]'
                $State      = 'PoweredOn'
            }
            Else {
                $HostUnhealthyCounter += 1
                $HealthIcon = '[CriticalImage]'
                $State      = 'PoweredOff'
                $UnhealthyHosts += 1
            }

            $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                'Name'        = $VMHost
                'State'       = $State
                'Power State' = $State
                'Health'      = $HealthIcon
            })
        }
    }

    Return $ReportHosts | Select-Object 'Name', 'State', 'Power State', 'Health'
}