$ErrorActionPreference = 'Stop'
#$Creds = (Get-Credential)
$Servers = @()

$File = 'C:\temp\henri\DNS1_Success.txt'
'"Server";"DNS"' | Out-File $File -Encoding ascii

For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Getting details for ' + $Servers[$i] + ' - ') -NoNewline
    Try {
        If (Test-Connection -ComputerName $Servers[$i] -Count 2 -Quiet) {
            $DNSServers = (Get-WmiObject -Class win32_networkadapterconfiguration -ComputerName $Servers[$i] -Property DNSServerSearchOrder -Credential $Creds).DNSServerSearchOrder -join ','
            $Servers[$i] + ";" + $DNSServers | Out-File $File -Encoding ascii -Append
            Write-Host ("Complete") -ForegroundColor Green
        }
        Else {
            $Servers[$i] + ";Offline" | Out-File $File -Encoding ascii -Append
            Write-Host ("Offline") -ForegroundColor Yellow
        }
    }
    Catch {
        $Errors += ,(New-Object -TypeName PSObject -Property @{
                Server = $Servers[$i]
                Error = $_
        })
        $Servers[$i] + ";" + $_ | Out-File $File -Encoding ascii -Append
        Write-Host ("Failed") -ForegroundColor Red
    }
}
Notepad $File