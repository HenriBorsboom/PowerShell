Param (
    [Parameter(Mandatory=$True, Position=1)]
    [String] $Computer, `
    [Parameter(Mandatory=$false, Position=1)]
    [Switch] $Raw)
Function Test-Online {
    Param (
        [Parameter(Mandatory=$True,  Position=1)]
        [String] $Computer)

    If (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
        Return $True
    }
    Else {
        Return $False
    }
}
Function Get-DiskSize {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Computer, `
        [Parameter(Mandatory=$false, Position=1)]
        [Switch] $Raw)

    If (Test-Online -Computer $Computer) {
        $WMIProperties = @(
            'Name'
            'Size'
            'FreeSpace')
        $FormattedProperties = @(
            'Computer'
            'Name'
            'Size'
            'Free Space'
            'Free Space %')
        $WMIQuery = "SELECT Name, Size, FreeSpace FROM Win32_LogicalDisk WHERE DriveType = 3"
        $Results = Get-WmiObject -Query $WMIQuery -ComputerName $Computer
        
        Switch ($Raw) {
            $False  {
                $FormattedResults = @()
                ForEach ($Volume in $Results) {
                    $FormattedResult = New-Object -TypeName PSObject -Property @{
                        'Computer'     = $Computer
                        'Name'         = $Volume.Name
                        'Size'         = ([string]::Format( "{0:N2}", ($Volume.Size / 1024 / 1024)) + " GB")
                        'Free Space'   = ([string]::Format( "{0:N2}", ($Volume.FreeSpace / 1024 / 1024)) + " GB")
                        'Free Space %' = ([string]::Format( "{0:N1}", ($Volume.FreeSpace / $Volume.Size * 100)) + "%")
                    }
                    $FormattedResults += ,($FormattedResult)
                }
                $FormattedResults | Select $FormattedProperties
            }
            $True  {
                $Results | Select $WMIProperties
            }
        }
    }
    Else {
        Write-Host ($Computer + " is offline") -ForegroundColor Red
    }
}

Switch ($Raw) {
    $True  { Get-DiskSize -Computer $Computer -Raw | Ft -AutoSize}
    $False { Get-DiskSize -Computer $Computer | Ft -AutoSize }
}
