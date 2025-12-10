Param (
    [Parameter(Mandatory=$true,Position=1)]
    [String] $NameFilter)

Import-Module ActiveDirectory
$ServiceAccounts = Get-ADUser -Filter {Name -like "$NameFilter"}

ForEach ($ADUser in $ServiceAccounts.Name) {
    Write-Host $ADUser
    Get-ADUser $ADUser -Properties * | select -ExpandProperty MemberOf
    Write-host ""
}
