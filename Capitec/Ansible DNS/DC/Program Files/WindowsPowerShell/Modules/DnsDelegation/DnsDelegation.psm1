function Set-DnsTtlA {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, Position=1)]
    [string] $Zone,
    [Parameter(Mandatory = $true, Position=2)]
    [string ]$Name,
    [Parameter(Mandatory = $true, Position=3)]
    [int] $TtlSeconds
  )
    $AllowedRecords = Import-Csv 'C:\Temp\Records.csv'

    If ($AllowedRecords.RecordName.Contains(($name + '.' + $zone))) {
        $OldObjs = Get-DnsServerResourceRecord -Name $Name -ZoneName $Zone -RRType 'A'
        ForEach ($OldObj in $OldObjs) {
            $NewObj = [ciminstance]::new($OldObj) 
            $NewObj.TimeToLive = [System.TimeSpan]::FromSeconds($TTLSeconds) 
            Set-DnsServerResourceRecord -NewInputObject $NewObj -OldInputObject $OldObj -ZoneName $Zone -PassThru
        }
    }
    Else {
        Write-Error ("Record not in allowed list: `nZone: " + $Zone + "`nName: " + $Name + "`nTTL Seconds: " + $TtlSeconds.ToString())
    }
    Remove-Variable AllowedRecords
    [GC]::Collect()
    
}
function Set-DnsTtlCNAME {
    [CmdletBinding()]
    param(
    [Parameter(Mandatory = $true, Position=1)]
    [string] $Zone,
    [Parameter(Mandatory = $true, Position=2)]
    [string] $Name,
    [Parameter(Mandatory = $true, Position=3)]
    [int]    $TtlSeconds,
    [Parameter(Mandatory = $False, Position=4)]
    [string]  $Value = $null
    )

    $AllowedRecords = Import-Csv 'C:\Temp\Records.csv'

    If ($AllowedRecords.RecordName.Contains(($name + '.' + $zone))) {
        $OldObj = Get-DnsServerResourceRecord -Name $Name -ZoneName $Zone -RRType 'CNAME'
        $NewObj = [ciminstance]::new($OldObj) 
        If ($null -eq $value) {
            $NewObj.RecordData.HostNameAlias = $Value
        }
        Else {
            $NewObj.RecordData.HostNameAlias = $Value
        }
        $NewObj.TimeToLive = [System.TimeSpan]::FromSeconds($TTLSeconds) 
        Set-DnsServerResourceRecord -NewInputObject $NewObj -OldInputObject $OldObj -ZoneName $Zone -PassThru
    }
    Else {
        Write-Error ("Record not in allowed list: `nZone: " + $Zone + "`nName: " + $Name + "`nTTL Seconds: " + $TtlSeconds.ToString() + "`nValue: " + $Value)
    }
    Remove-Variable AllowedRecords
    [GC]::Collect()
}
Export-ModuleMember -Function Set-DnsTtlA
Export-ModuleMember -Function Set-DnsTtlCNAME