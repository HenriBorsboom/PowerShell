Function New-KeyFile {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $FileName)

    $credential = Get-Credential -Message ('Supply Credentials for ' + $FileName)
    $Detail = New-Object -TypeName PSObject -Property @{
        Username = $credential.UserName
        SecurePassword = $credential.Password | ConvertFrom-SecureString
    }
    $Detail | Export-Csv -Path $FileName -Force -Encoding ASCII -Delimiter ";"

    #$credential.Password | ConvertFrom-SecureString | Set-Content $FileName
    Write-Host ('Encrypted Password saved to ' + $FileName)
}

New-KeyFile -FileName 'C:\HealthCheck\Scripts\Keys\Mercantile.key'
New-KeyFile -FileName 'C:\HealthCheck\Scripts\Keys\MBLCard.key'
New-KeyFile -FileName 'C:\HealthCheck\Scripts\Keys\MBLWeb.key'