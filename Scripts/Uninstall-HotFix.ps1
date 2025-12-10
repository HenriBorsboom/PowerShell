#function Uninstall-Hotfix {
#[cmdletbinding()]
param(
    [Parameter(Mandatory=$true, Position=1)]
    [String] $computername, `
    [Parameter(Mandatory=$true, Position=2)]
    [string] $HotfixID
)            
Write-Host "Checking for Hotfix $HotfixID - " -NoNewline
$hotfixes = Get-WmiObject -ComputerName $computername -Class Win32_QuickFixEngineering | select hotfixid            
Write-Host "Complete"
if($hotfixes -match $hotfixID) {
    $hotfixID = $HotfixID.Replace("KB","")
    Write-host "Found the hotfix KB" + $HotfixID
    Write-Host "Uninstalling the hotfix"
    $UninstallString = "cmd.exe /c wusa.exe /uninstall /KB:$hotfixID /quiet /norestart"
    ([WMICLASS]"\\$computername\ROOT\CIMV2:win32_process").Create($UninstallString) | out-null            

    while (@(Get-Process wusa -computername $computername -ErrorAction SilentlyContinue).Count -ne 0) {
        Start-Sleep 3
        Write-Host "Waiting for update removal to finish ..."
    }
write-host "Completed the uninstallation of $hotfixID"
}
else {            

write-host "Given hotfix($hotfixID) not found"
return
}            

#}