Function Get-DefaultGateway {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $MACAddress)
        
    $WMIQuery = "Select DefaultIPGateway from Win32_NetworkAdapterConfiguration Where MACAddress = ""$MACAddress"""
    Try { 
        If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery }
        Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server }
        $DefaultIPGateway = $WMIResults.DefaultIPGateway
        Return $DefaultIPGateway
    }
    Catch { Return $false }
}