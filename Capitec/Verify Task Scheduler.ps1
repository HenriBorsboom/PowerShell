$ErrorActionPreference = 'Stop'
$Servers = @()
$Servers +=, ('CBFP02')
$Servers +=, ('CBPOST02')
$Servers +=, ('CBPOST01')
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
        $Session = New-CimSession -ComputerName $Servers[$i]
        $Tasks = Get-ScheduledTask -CimSession $Session | Where-Object TaskName -like 'Change Active Hours*'
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