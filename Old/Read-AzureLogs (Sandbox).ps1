Clear-Host

#$Get_WinEventsScript = {Get-WinEvent -Computername $Server -FilterHashtable @{logname=$Log; StartTime=$LogDate} -Force -ErrorAction Stop | Format-Table -AutoSize -Wrap}
#$Get_WinEventLogsScript = {Get-WinEvent -ListLog * -ComputerName $Server -Force -ErrorAction Stop | where LogName -like 'Microsoft-WindowsAzurePack-*'}

$Servers = @(
    "NRAZUREAPP105", `
    "NRAZUREAPP106", `
    "NRAZUREAPP107", `
    "NRAZUREAPP108", `
    "NRAZUREAPP109", `
    "NRAZUREAPP110", `
    "NRAZUREAPP111")

Write-Host "Establishing PowerShell Sessions - " -NoNewline
    $Sessions = New-PSSession -ComputerName $Servers
Write-Host "Complete" -ForegroundColor Green

Write-Host "Starting collection of log names - " -NoNewline
    $Jobs = Invoke-Command -Session $Sessions -ScriptBlock {Start-Job -ScriptBlock {Get-WinEvent -ListLog * -Force -ErrorAction Stop | where LogName -like 'Microsoft-WindowsAzurePack-*'} | Wait-Job}
Write-Host "Complete" -ForegroundColor Green

Write-Host "Collecting results of collection - " -NoNewline 
    $Results = Invoke-Command -Session $Sessions -ScriptBlock {Get-Job | Receive-Job}
Write-Host "Complete" -ForegroundColor Green
$Results.logname


#start-job -ScriptBlock {Get-eventlog -LogName system} | Wait-Job