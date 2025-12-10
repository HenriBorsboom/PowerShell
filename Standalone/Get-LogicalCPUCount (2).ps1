Function Get-LogicalCPUCount {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    $WMIQuery = "Select NumberOfLogicalProcessors from Win32_ComputerSystem"
    Try { 
        If ($Server -eq $env:COMPUTERNAME) {
            $WMIResults = Get-WmiObject -Query $WMIQuery
        }
        Else {
            $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server
        }
        $NumberOfLogicalProcessors = $WMIResults.NumberOfLogicalProcessors
        Return $NumberOfLogicalProcessors
    }
    Catch { Return $false }
}
