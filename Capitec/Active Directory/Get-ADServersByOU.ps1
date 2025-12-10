$ErrorActionPreference = 'Stop'
Function Get-Servers {
    $OUs = @()
    $OUs += ,('OU=DEV,OU=Custom,OU=Servers,DC=capitecbank,DC=fin,DC=sky')
    $OUs += ,('OU=DEV,OU=Standard,OU=Servers,DC=capitecbank,DC=fin,DC=sky')

    $Servers = @()
    For ($OUi = 0; $OUi -lt $OUs.Count; $OUi ++) {
        $LogonDateAllowed = (Get-Date).AddMonths(-1)
        Write-Host (($OUi + 1).ToString() + '/' + $OUs.Count.ToString() + ' Processing ' + $OUs[$OUi] + ' - ') -NoNewline
        $OUServers = Get-ADComputer -SearchBase $OUs[$OUi] -Filter {Name -like '*' -and OperatingSystem -like '*server 2012*' -and Enabled -eq $True -and LastLogonDate -gt $LogonDateAllowed } -Properties Description, OperatingSystem
        ForEach ($Server in $OUServers) {
            $Servers += ,(New-Object -TypeName PSObject -Property @{
                Server = $Server.Name
                OperatingSystem = $Server.OperatingSystem
                OU = $OUs[$OUi]
            })
            
        }
        Write-Host " Complete" -ForegroundColor Green
    }
    Return $Servers
}
Get-Servers | Out-GridView