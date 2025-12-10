Function Get-DiskSize {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $Drive)
    $WMIQuery = "Select Size from Win32_LogicalDisk Where Caption = ""$Drive"""
    Try { 
        If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery }
        Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server }
        $Size = [Math]::Round($WMIResults.Size / 1024 / 1024 / 1024)
        Return $Size
    }
    Catch { Return $false }
}
