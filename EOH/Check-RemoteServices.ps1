$Servers = @()
$Servers += ,('MYHRWEBPRD01')
$Servers += ,('MYHRWEBPRD02')
$Servers += ,('MYHRWEBPRD03')
$Servers += ,('MYHRAPPPRD01')
$Servers += ,('MYHRREPPRD01')
$Servers += ,('MYHRAPIPRD01')
$Servers += ,('MYHRCACHE01')
$Servers += ,('MYHRSQLPRD01')
$Servers += ,('MYHRSQLPRD02')

#$AdminCredentials = Get-Credential
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host ("Getting services on " + $Servers[$i]) -ForegroundColor Yellow
    If (Test-Connection -ComputerName $Servers[$i] -Count 1 -Quiet) {
        $Services = Get-WmiObject -Class Win32_Service -ComputerName $Servers[$i] -Credential $AdminCredentials | Where-Object {$_.StartMode -eq 'Auto' -and $_.Started -eq $false}
        ForEach ($Service in $Services) {
            Write-Host ("Starting " + $Service.Name + " on " + $Servers[$i])
            Invoke-Command -ComputerName $Servers[$i] -ArgumentList $Service.Name -Credential $AdminCredentials { Param ($ServiceName); Start-Service $ServiceName }
        }
    }
    Else { Write-Host ($Servers[$i] + " offline") -ForegroundColor Red }
}
#(Get-WmiObject -Class Win32_OperatingSystem -Property LastBootUpTime -ComputerName $Servers -Credential $AdminCredentials).LastBootUpTime
