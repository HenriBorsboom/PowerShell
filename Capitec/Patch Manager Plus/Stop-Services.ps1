$Services = "PlugPlay","wuauserv","bits","UsoSvc","TrustedInstaller"
foreach ($Service in $Services) {
    Write-Host "Stopping $Service"
    Stop-Service -Name $Service -Force
}