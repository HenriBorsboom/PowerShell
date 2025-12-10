Param (
    [Parameter(Mandatory=$True)] 
    [string[]] $Servers, 
    [Parameter(Mandatory=$True)] 
    [string[]] $UserAccounts)

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

ForEach ($Server in $Servers) {
    ForEach ($User in $ServiceAccounts) {
        Write-Host "$Server  - " -ForegroundColor Cyan -NoNewline
        Write-Host "$User - " -ForegroundColor Yellow -NoNewline
        Try {Add-DomainUserToLocalGroup -computer $Server -group Administrators -domain domain2.local -user $user -ErrorAction Stop}
        Catch {Write-Host "Failed" -ForegroundColor Red}
        Write-Host "Complete" -ForegroundColor Green
    }
}