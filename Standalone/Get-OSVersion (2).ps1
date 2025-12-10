Function Get-OSVersion {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    $WMIQuery = "Select Caption from Win32_OperatingSystem"
    Try { 
        If ($Server -eq $env:COMPUTERNAME) {
            $WMIResults = Get-WmiObject -Query $WMIQuery
        }
        Else {
            $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server
        }
        $OSVersion = $WMIResults.Caption
        Return $OSVersion
    }
    Catch { Return $false }
}
