Function Set-ComputerDescription {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $Description)

    Try {
        If ($Server -eq $env:COMPUTERNAME) {
            $WMIResults = Get-WMIObject Win32_OperatingSystem -ErrorAction Stop
        }
        Else {
            $WMIResults = Get-WMIObject Win32_OperatingSystem -ComputerName $Server -ErrorAction Stop
        }
        $WMIResults.Description = $Description
        $empty = $WMIResults.Put()
        Return $true
    }
    Catch { Return $false }
}

