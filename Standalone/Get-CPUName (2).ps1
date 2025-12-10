Function Get-CPUName {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    $WMIQuery = "Select Name from Win32_Processor"
    Try { 
        If ($Server -eq $env:COMPUTERNAME) {
            $WMIResults = Get-WmiObject -Query $WMIQuery
        }
        Else {
            $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server
        }
        $Name = $WMIResults.Name
        Return $Name
    }
    Catch { Return $false }
}
