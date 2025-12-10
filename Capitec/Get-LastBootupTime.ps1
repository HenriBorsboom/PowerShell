Function Get-LastBootupTime {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $ComputerName
    )

    $WMI = Get-WmiObject -Class Win32_OperatingSystem -Property LastBootUpTime -ComputerName $ComputerName
    Return ($WMI.ConvertToDateTime($WMI.LastBootUpTime))
    #Return ($Result -f '{0:yyyy/MM/dd HH:mm:ss}')
}

$Servers = @()
$Servers +=, ('CBDLSINT02')

$Details = @()
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i] + ' - ') -NoNewline
    Try {
        $Uptime = Get-LastBootupTime -ComputerName $Servers[$i]
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Servers[$i]
            LastBootUpTime = $Uptime
        })
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Servers[$i]
            LastBootUpTime = $_
        })
        Write-Host $_ -ForegroundColor Red
    }
}
$Details | Out-GridView