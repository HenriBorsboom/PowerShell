#function Uninstall-Hotfix {
#[cmdletbinding()]
Param(
    [Parameter(Mandatory=$true, Position=1)]
    [string] $HotfixID, `
    [Parameter(Mandatory=$false, Position=1)]
    [Switch] $Remote, `
    [Parameter(Mandatory=$false, Position=2)]
    [String] $computername)

Write-Host "Checking for Hotfix $HotfixID - " -NoNewline
    Switch ($Remote) {
        $true  {$hotfixes = Get-WmiObject -ComputerName $computername -Class Win32_QuickFixEngineering | select hotfixid}
        $false {$hotfixes = Get-WmiObject -Class Win32_QuickFixEngineering | select hotfixid}
    }
Write-Host "Complete"

If ($hotfixes -match $hotfixID) {
    $hotfixID = $HotfixID.Replace("KB","")
    Write-host "Found the hotfix KB" $HotfixID "- Uninstalling - " -NoNewline
    $UninstallString = "cmd.exe /c wusa.exe /uninstall /KB:$hotfixID /quiet /norestart"
    

    Switch ($Remote) {
        $true  {
            ([WMICLASS]"\\$computername\ROOT\CIMV2:win32_process").Create($UninstallString) | out-null            
            While (@(Get-Process wusa -computername $computername -ErrorAction SilentlyContinue).Count -ne 0) {
                Write-Host "." -NoNewline
                Start-Sleep 3
            }
        }
        $false {
            ([WMICLASS]"ROOT\CIMV2:win32_process").Create($UninstallString) | out-null            
            While (@(Get-Process wusa -ErrorAction SilentlyContinue).Count -ne 0) {
                Write-Host "." -NoNewline
                Start-Sleep 3
            }
        }
    }
Write-Host " - Complete"
#write-host "Completed the uninstallation of $hotfixID"
}
else {            

write-host "Given hotfix($hotfixID) not found"
return
}            

#}