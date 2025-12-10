Function Get-CPUSpeed {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    $WMIQuery = "Select MaxClockSpeed from Win32_Processor"
    Try { 
        If ($Server -eq $env:COMPUTERNAME) {
            $WMIResults = Get-WmiObject -Query $WMIQuery
        }
        Else {
            $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server
        }
        $MaxClockSpeed = $WMIResults.MaxClockSpeed
        Return $MaxClockSpeed
    }
    Catch { Return $false }
}
