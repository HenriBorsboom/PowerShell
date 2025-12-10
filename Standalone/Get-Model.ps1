Function Get-Model {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    Try { 
        If ($Server -eq $env:COMPUTERNAME) {
            $WMIResults = Get-WmiObject -Query "Select Model from Win32_ComputerSystem"
        }
        Else {
            $WMIResults = Get-WmiObject -Query "Select Model from Win32_ComputerSystem" -ComputerName $Server
        }
        $Model = $WMIResults.Model
        Return $Model
    }
    Catch { Return $false }
}