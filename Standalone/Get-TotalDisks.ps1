Function Get-TotalDisks {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    $WMIQuery = "Select Caption from Win32_LogicalDisk Where DriveType = 3"
    Try { 
        If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery }
        Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server }
        $TotalDisks = ($WMIResults.Caption).Count
        Return $TotalDisks
    }
    Catch { Return $false }
}
