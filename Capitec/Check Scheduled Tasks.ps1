Function Get-Servers {
    $OUs = @()
    $OUs += ,('OU=Infrastructure-PRD,OU=Custom,OU=Servers,DC=capitecbank,DC=fin,DC=sky')
    $OUs += ,('OU=PROD,OU=Custom,OU=Servers,DC=capitecbank,DC=fin,DC=sky')
    $OUs += ,('OU=PROD,OU=Servers,DC=capitecbank,DC=fin,DC=sky')
    $OUs += ,('OU=PROD,OU=Standard,OU=Servers,DC=capitecbank,DC=fin,DC=sky')

    $Servers = @()
    For ($OUi = 0; $OUi -lt $OUs.Count; $OUi ++) {
        $LogonDateAllowed = (Get-Date).AddMonths(-1)
        Write-Host (($OUi + 1).ToString() + '/' + $OUs.Count.ToString() + ' Processing ' + $OUs[$OUi] + ' - ') -NoNewline
        $OUServers = (Get-ADComputer -SearchBase $OUs[$OUi] -Filter {Name -like '*' -and OperatingSystem -like '*server*' -and Enabled -eq $True -and LastLogonDate -gt $LogonDateAllowed } -Properties Description, OperatingSystem).Name
        ForEach ($Server in $OUServers) {
            $Servers += ,($Server)
        }
        Write-Host " Complete" -ForegroundColor Green
    }
    Return $Servers
}
$Servers = Get-Servers

$Details = @()
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i])
    Try {
        If (Test-Connection -ComputerName $Servers[$i] -Count 1 -Quiet) {
            $OS = (Get-WmiObject -Class Win32_OperatingSystem -Property Caption -ComputerName $Servers[$i]).Caption
            $Tasks = Invoke-Command -ComputerName $Servers[$i] -ScriptBlock {
                Get-ScheduledTask | where taskname -like 'Change Active Hours*'
            }
            If ($Tasks -eq $null) {
                Write-Host "|- Not setup" -ForegroundColor Yellow
                Write-Host ("|- " + $OS) -ForegroundColor Yellow
            }
            Else {
                Write-Host "|- Setup" -ForegroundColor Green
                Write-Host ("|- " + $OS) -ForegroundColor Green
                $Tasks = $Tasks.Count
            }
        }
        Else {
            $OS = 'Offline'
            $Tasks = 'Offline'
        }
    }
    Catch {
        Write-Host ("|- " + $_) -ForegroundColor Yellow
    }
    Finally {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Servers[$i]
            OS = $OS
            Tasks = $Tasks
        })
    }
}
$Details | Out-GridView
#(Get-ScheduledTask | where taskname -like 'Change Active Hours*')