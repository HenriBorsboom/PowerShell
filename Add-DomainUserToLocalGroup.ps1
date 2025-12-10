Function Add-DomainUserToLocalGroup { 
    [cmdletBinding()] 
    Param( 
        [Parameter(Mandatory=$True)] 
        [string]$computer, 
        [Parameter(Mandatory=$True)] 
        [string]$group, 
        [Parameter(Mandatory=$True)] 
        [string]$domain, 
        [Parameter(Mandatory=$True)] 
        [string]$user) 
    
    $de = [ADSI]"WinNT://$computer/$Group,group" 
    $de.psbase.Invoke("Add",([ADSI]"WinNT://$domain/$user").path) 
} #end function Add-DomainUserToLocalGroup 


Clear-Host
$Servers = @(
    "WEBSERVER101", `
    "WEBSERVER102", `
    "WEBSERVER103", `
    "WEBSERVER104", `
    "WEBSERVER105", `
    "WEBSERVER106", `
    "WEBSERVER107", `
    "WEBSERVER108")
$ServiceAccounts = @(
    "HVI-WAPWEB-SVC", `
    "HVI-WAPWEB-FSO-SVC", `
    "HVI-WAPWEB-FSU-SVC", `
    "HVI-WAPWEB-CSU-SVC", `
    "HVI-WAPWEB-MN-SVC", `
    "HVI-WAPWEB-PB-SVC", `
    "HVI-WAPWEB-FE-SVC", `
    "HVI-WAPWEB-WW-SVC", `
    "WAPWeb-LocalAdmins")

Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
ForEach ($Server in $Servers) {
    ForEach ($User in $ServiceAccounts) {
        Write-Host "$Server  - " -ForegroundColor Cyan -NoNewline
        Write-Host "$User - " -ForegroundColor Yellow -NoNewline
        Try {Add-DomainUserToLocalGroup -computer $Server -group Administrators -domain domain2.local -user $user -ErrorAction Stop}
        Catch {Write-Host "Failed" -ForegroundColor Red}
        Write-Host "Complete" -ForegroundColor Green
    }
}