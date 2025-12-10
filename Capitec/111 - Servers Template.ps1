$Servers = @()
$Servers += ,('')

$Details = @()
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i] + ' - ') -NoNewline
    Try {
        
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Servers[$i]
            
        })
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Servers[$i]
            
        })
        Write-Host $_ -ForegroundColor Red
    }
}
$Details | Out-GridView