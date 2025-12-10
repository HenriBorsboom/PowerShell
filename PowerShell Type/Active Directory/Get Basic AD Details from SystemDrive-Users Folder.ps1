Import-Module ActiveDirectory
ForEach ($User in (Get-ChildItem ($env:SystemDrive + "\Users")).Name) {
    Get-ADUser $User -Properties SamAccountName,AccountExpirationDate,LastLogonDate,Enabled,Name -ErrorAction SilentlyContinue
}
