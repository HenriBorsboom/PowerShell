$ErrorActionPreference = 'Stop'

$Servers = @()
$Servers += ,('CBVMPPRAPW004')
$Servers += ,('CBWLPPRAPW387')
$Servers += ,('CBWLPPRAPW502')
$Servers += ,('CBWLPPRWFW088')


$Details = @()
#D:\Apps\Captools\Scripts\ChangeActiveHours
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i] + ' - ') -NoNewline
    Try {
        If (Test-Connection $Servers[$i] -Count 1 -Quiet) {
            $Events = get-winevent -LogName Application -MaxEvents 10 -ComputerName $Servers[$i] | Where-Object {$_.ProviderName -eq 'ChangeActiveHours'}
            If ($Events) {
                
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