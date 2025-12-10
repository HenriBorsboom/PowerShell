$Servers = @()
$Servers += ,('CBWLPPRAPW127')
$Servers += ,('CBPO')
$Servers += ,('CBWLPPRDBW091')
$Servers += ,('CBWLPPRDBW303')
$Servers += ,('CBPOST02')
$Servers += ,('CBPORT02')
$Servers += ,('CBNXB02')
$Servers += ,('CBWLPPRDBW063')
$Servers += ,('CCPRDAPP081')
$Servers += ,('CCPRDAPP282')
$Servers += ,('CBWLPPRDBW345')
$Servers += ,('CBAWPPRDBW027')
$Servers += ,('CBPOST01')
$Servers += ,('CBTERM01')
$Servers += ,('CBPORT')
$Servers += ,('CBNXB01')
$Servers += ,('CBWLPPRDBW062')

$ScriptBlock = {
    Set-Service WUAUSERV -StartupType Disabled
    Stop-Service WUAUSERV -Force
}

#While ($True) {
    (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    For ($i = 0; $i -lt $Servers.Count; $i ++) {
        Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - ' + $Servers[$i]) -NoNewline
        $Details = Get-Service wuauserv -ComputerName $Servers[$i] | Select-Object Status, StartType
        Write-Host (' - ' + $Details.Status + ' - ' + $Details.StartType)
        If ($Details.Status -ne 'Stopped' -or $Details.StartType -ne 'Disabled') {
            Write-Host ("|- Resetting configuration") -ForegroundColor Yellow
            Invoke-Command -ScriptBlock $ScriptBlock -ComputerName $Servers[$i]
        }
    }
    #Start-Sleep -Seconds 60
#}









