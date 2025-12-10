Clear-Host
# All enabled users                    get-aduser -Filter {Enabled -eq $true}
# All groups user belongs to           .memberOf
# Last Logon Date                      .LastLogonDate
# Password last set                    .PasswordLastSet
# Password Expired                     .PasswordExpired

$Properties = @("DisplayName", "MemberOf", "LastLogonDate", "PasswordLastSet", "PasswordExpired")
$ADUsers = Get-ADUser -Filter {Enabled -eq $True} -Properties *

$Details = @()
ForEach ($User in $ADUsers) {
    $ThisUser = New-Object -TypeName PSObject -Property @{
        DisplayName = $User.DisplayName
        MemberOf    = $User.MemberOf -join ("|")
        LastLogonDate = $User.LastLogonDate
        PasswordLastSet = $User.PasswordLastSet
        PasswordExpired = $User.PassswordExpired
    }
    $Details += ,($ThisUser)
}
$Details | Select $Properties | Export-CSV C:\temp\users.csv -Delimiter "," -Encoding ASCII -Force -NoClobber -NoTypeInformation