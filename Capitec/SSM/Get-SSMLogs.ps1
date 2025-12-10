Write-Host "Getting state of SSM Agent"
If ((Get-Service AmazonSSMAgent).Status -eq 'Running') {
    Write-Host "|- Service running. Stopping Service" -ForegroundColor Yellow
    Get-Service AmazonSSMAgent | Stop-Service
    Write-Host "|- Disabling the Service" -ForegroundColor Yellow
    Set-Service AmazonSSMAgent -StartupType Disabled
    Write-Host "|- Complete" -ForegroundColor Green
}
ElseIf ((Get-Service AmazonSSMAgent).Status -eq 'Stopped') {
    Write-Host "|- Service stopped" -ForegroundColor Yellow
    Write-Host "|- Disabling the Service" -ForegroundColor Yellow
    Set-Service AmazonSSMAgent -StartupType Disabled
    Write-Host "|- Complete" -ForegroundColor Green
}
Write-Host "Renaming log files"
$LogFiles = (Get-ChildItem 'C:\ProgramData\Amazon\SSM\Logs\*.log').FullName
ForEach ($LogFile in $LogFiles) {
    Write-Host ("|- Renaming " + $LogFile + " to " + ($LogFile + '_' + (Get-Date).ToString('HH_mm_ss') + '.old'))
    Rename-Item $LogFile -NewName ($LogFile + '_' + (Get-Date).ToString('HH_mm_ss') + '.old')
}
Write-Host "Setting SSM Agent back to Automatic Start"
Set-Service AmazonSSMAgent -StartupType Automatic
Write-Host "Starting SSM Agent"
Start-Service AmazonSSMAgent
Write-Host "Waiting for SSM Agent Log file to be created"
while (!(Test-Path C:\programdata\Amazon\SSM\Logs\amazon-ssm-agent.log)) {
    write-Host "Waiting for file to be created"
    Start-Sleep -Seconds 1
}
Write-Host "File created" -ForegroundColor Green
$Command = 'get-content C:\programdata\Amazon\SSM\Logs\amazon-ssm-agent.log -Wait'
Start-Process powershell -ArgumentList $Command

Write-Host "Waiting for Agent Worker log to be created"
while (!(Test-Path C:\programdata\Amazon\SSM\Logs\ssm-agent-worker.log)) {
    write-Host "Waiting for file to be created"
    Start-Sleep -Seconds 1
}
Write-Host "File created" -ForegroundColor Green
$Command = 'get-content C:\programdata\Amazon\SSM\Logs\ssm-agent-worker.log -Wait'
Start-Process powershell -ArgumentList $Command