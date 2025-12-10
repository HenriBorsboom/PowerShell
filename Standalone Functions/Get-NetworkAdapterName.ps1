Function Get-NetworkAdapterName {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $MACAddress)
        
    $WMIQuery = "Select NetConnectionID from Win32_NetworkAdapter Where MACAddress = ""$MACAddress"""
    Try { 
        If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery }
        Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server }
        $NetConnectionID = $WMIResults.NetConnectionID
        Return $NetConnectionID
    }
    Catch { Return $false }
}