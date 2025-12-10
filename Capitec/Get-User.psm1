Function Get-User {
    Param (
        [Parameter(Mandatory=$True)]
        [String] $User
    )
    Get-ADUser $User -Server CBDC002.capitecbank.fin.sky -Properties Department, Manager, Enabled | Select-Object Name, Enabled, Department, Manager
}