Param([Parameter(Mandatory=$true,Position=1)]
    [String] $UserProfilePath)

Function Get-ADUsers {
    Param([Parameter(Mandatory=$true,Position=1)]
        [String] $UserProfilePath)

    Import-Module ActiveDirectory
    $UserList = Get-ChildItem -Path $UserProfilePath | Where-Object {$_.Mode -match "d"}

    ForEach ($User in $UserList.Name){
        Try{
            Get-ADUser $User -Properties * | Select SamAccountName,Name,Enabled,AccountExpirationDate,LastLogonDate
        }
        Catch{
            Write-Host "Could not get details for $User" -ForegroundColor Red
        }
    }
}

Get-ADUsers -UserProfilePath $UserProfilePath