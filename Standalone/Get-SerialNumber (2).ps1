Function Get-SerialNumber {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    Try { 
        If ($Server -eq $env:COMPUTERNAME) {
            $WMIResults = Get-WmiObject -Query "Select SerialNumber from Win32_BIOS"
        }
        Else {
            $WMIResults = Get-WmiObject -Query "Select SerialNumber from Win32_BIOS" -ComputerName $Server
        }
        $SerialNumber = $WMIResults.SerialNumber
        Return $SerialNumber
    }
    Catch { Return $false }
}