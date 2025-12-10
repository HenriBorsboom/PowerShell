$ErrorActionPreference = 'Stop'
$Servers = @()
$Servers += ,('CCPRDWF066')
$Servers += ,('WPAMRISKUDM1')
$Servers += ,('WPISAENGAGPM01')
$Servers += ,('WPPAYHCPWPTX01')
$Servers += ,('WPPAYSVCWPEFT1')
$Servers += ,('WPPENTSTCTR702')
$Servers += ,('WPPLIPLAINSCLA')
$Servers += ,('WPPLRDOCWF1')
$Servers += ,('WPPLRDOCWF3')
$Servers += ,('WPPLSPAYDCDP08')
$Servers += ,('WPPLSPAYDCDP09')
$Servers += ,('WPPLSPAYEFTP1')
$Servers += ,('WPTSCBRBSJ01')
$Servers += ,('WPWSPENGLDCM01')
$Servers += ,('WPWSPENGUOMEGA')


$Details = @()
#D:\Apps\Captools\Scripts\ChangeActiveHours
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i] + ' - ') -NoNewline
    Try {
        $Session = New-CimSession -ComputerName $Servers[$i]
        $Tasks = Get-ScheduledTask -CimSession $Session | Where TaskName -like 'Change Active Hours*'
        If ($Tasks) {
            If ($Tasks.Count -eq 4) {
                Write-Host "Correct" -ForegroundColor Green
            }
            Else {
                Write-Host $Tasks.count.ToString() -ForegroundColor Yellow
                $Details += ,(New-Object -TypeName PSObject -Property @{
                Server = $Servers[$i]
                Status = $Tasks.COunt.ToString()
            })
            }
           
        }
        Else {
            Write-Host "Tasks not found" -ForegroundColor Red
            $Details += ,(New-Object -TypeName PSObject -Property @{
                Server = $Servers[$i]
                Status = 'Task not found'
            })
        }
        
    }
    Catch {
        Write-Host $_ -ForegroundColor Red
        $Details += ,(New-Object -TypeName PSObject -Property @{
                Server = $Servers[$i]
                Status = $_
            })
    }
}
$Details | Out-GridView