Function Get-MACAddress {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
        
    $WMIQuery = "Select MACAddress from Win32_NetworkAdapter Where NetConnectionStatus = ""2"""
    Try { 
        If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery }
        Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server }
        $MACAddress = $WMIResults.MACAddress
        Return $MACAddress
    }
    Catch { Return $false }
}