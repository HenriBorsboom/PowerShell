Function Query-Registry {
Param (
    [Parameter(Mandatory=$True, Position=1)]
    [String] $VM)

    $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $VM)
    Try {
        $Value = (($Reg.OpenSubKey("SOFTWARE\\Microsoft\\.NETFramework\\v4.0.30319\\SKUs\\.NETFramework,version=v4.8")).GetValue("(Default)"))
        If ($Value -eq $null) {
            $Value = ".NETFramework,version=v4.8"
        }
    }
    Catch {
        $Value = "Key not found"
    }
    Return $Value
}

$Servers = @()
$Servers += ,('')

Clear-host

$Return = @()
ForEach ($Server in $Servers) {
    $Object = Query-Registry -VM $Server
    $Return += (New-Object -TypeName PSObject -Property @{
        Name = $Server
        Value = $Object
    })
}

$Return | select Name, Value

If (Test-Path $env:temp\Servers.csv) {
    Remove-Item $env:temp\Servers.csv
}
$Return | select Name, Value | Export-Csv -Path $env:temp\Servers.csv