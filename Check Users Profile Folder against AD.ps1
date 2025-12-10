Import-Module ActiveDirectory
$UserList = ls
ForEach ($User in $UserList.Name) {
    Get-ADUser -ErrorAction SilentlyContinue $User -Properties * | Select-Object SamAccountName,AccountExpirationDate,LastLogonDate,Enabled,Name -ErrorAction SilentlyContinue
}
