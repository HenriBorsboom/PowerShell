clear-host
import-module ActiveDirectory
$ServiceAccounts = Get-ADUser -Filter 'Name -like "hvi-*"' | select name

#$AdUser = "HVI-Admin"
ForEach ($ADUser in $ServiceAccounts)
{
    [String] $NewUser = $ADUser
    $NewUser = $NewUser.Remove(0, 7)
    $NewUser = $NewUser.Remove(($NewUser.Length) -1, 1)

    Write-Host $NewUser
    Get-ADUser $NewUser -Properties * | select -ExpandProperty MemberOf
    Write-host ""

}
