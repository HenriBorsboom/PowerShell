$ErrorActionPreference = 'Stop'
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
#$Servers = Get-Servers
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
$Details = @()
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i])
    Try {
        If (Test-Connection $Servers[$i] -Count 1 -Quiet) {
            Try {
                $AUOption = (Invoke-Command -ComputerName $Servers[$i] -ScriptBlock {
                    param ($path)
                    Get-ItemProperty -Path $path
                } -ArgumentList $registryPath | Select-Object AUOptions).AUOptions
                If ($AUOption.ToString() -ne '2' -and $AUOption.ToString() -ne '7') {
                    Write-Host ("|- AU Option " + $AUOption.ToString()) -ForegroundColor Cyan
                }
                Else {
                    Write-Host ("|- AU Option " + $AUOption.ToString()) -ForegroundColor Green
                }
            }
            Catch {
                $AUOption = 'Not configured'
                Write-Host ("|- AU Option " + $AUOption.ToString()) -ForegroundColor Red
            }
            Finally {
                $Details += ,(New-Object -TypeName PSObject -Property @{
                    Server = $Servers[$i]
                    AUOption = $AUOption
                })
            }
        }
        Else {
            Write-Host "|- Offline" -ForegroundColor Cyan
            $Details += ,(New-Object -TypeName PSObject -Property @{
                Server = $Servers[$i]
                AUOption = 'Offline'
            })
        }
        
        #Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Servers[$i]
            AUOption = $_
        })
        Write-Host $_ -ForegroundColor Red
    }
}
$Details | Select-Object Server, AUOption | Out-GridView


#REG QUERY "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate"