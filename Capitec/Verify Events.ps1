$ErrorActionPreference = 'Stop'

$Servers = @()
$Servers +=, ('CBFP02')
$Servers +=, ('CBPOST02')
$Servers +=, ('CBPOST01')
$Servers +=, ('CBTERM01')
$Servers +=, ('CBVMPPRAPW012')
$Servers +=, ('CCPRDWF066')
$Servers +=, ('CCPRDWF067')


$Details = @()
#D:\Apps\Captools\Scripts\ChangeActiveHours
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i] + ' - ') -NoNewline
    Try {
        If (Test-Connection $Servers[$i] -Count 1 -Quiet) {
            $ScriptBlock = {
                Start-ScheduledTask -TaskName 'Change Active Hours - 15-03'
                Start-Sleep -Seconds 2
                Get-WinEvent -LogName Application -MaxEvents 10 | Where-Object {$_.ProviderName -eq 'ChangeActiveHours'} | Select-Object Message
            }
            Invoke-Command $Servers[$i] -ScriptBlock $ScriptBlock
            $Events = get-winevent -LogName Application -MaxEvents 10 -ComputerName $Servers[$i] | Where-Object {$_.ProviderName -eq 'ChangeActiveHours'}
            If ($Events) {3

                
                $Details += ,(New-Object -TypeName psobject -Property @{
                    Server = $Servers[$i]
                    Status = 'Done'
                })
                Write-Host "Complete" -ForegroundColor Green
            }
            Else {
                $Details += ,(New-Object -TypeName psobject -Property @{
                    Server = $Servers[$i]
                    Status = 'No event'
                })
                Write-Host "No events" -ForegroundColor Yellow
            }
            Remove-Variable Events
            
        }
        Else {
            Write-Host "Offline" -ForegroundColor Red
            $Details += ,(New-Object -TypeName psobject -Property @{
                Server = $Servers[$i]
                Status = 'Offline'
            })
        }
    }
    Catch {
        Write-Host $_ -ForegroundColor Red
        $Details += ,(New-Object -TypeName psobject -Property @{
                Server = $Servers[$i]
                Status = 'Error'
            })
    }
}
$Details | Out-GridView