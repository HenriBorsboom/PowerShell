Function Get-RAM {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    $WMIQuery = "Select TotalPhysicalMemory from Win32_ComputerSystem"
    Try { 
        If ($Server -eq $env:COMPUTERNAME) {
            $WMIResults = Get-WmiObject -Query $WMIQuery
        }
        Else {
            $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server
        }
        $TotalPhysicalMemory = [Math]::Round($WMIResults.TotalPhysicalMemory/1024/1024/1024)
        Return $TotalPhysicalMemory
    }
    Catch { Return $false }
}
