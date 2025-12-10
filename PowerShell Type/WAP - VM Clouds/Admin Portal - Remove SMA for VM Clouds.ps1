$Credential = Get-Credential
$Token = Get-MgmtSvcToken `
    -Type Windows `
    –AuthenticationSite https://yourauthenticationsite:30072 `
    -ClientRealm http://azureservices/AdminSite `
    -User $Credential `
    -DisableCertificateValidation

Get-MgmtSvcResourceProvider `
    -AdminUri “https://localhost:30004" `
    -Token $Token `
    -DisableCertificateValidation `
    -name "Automation"

Remove-MgmtSvcResourceProvider `
    -AdminUri “https://localhost:30004" `
    -Token $Token `
    -DisableCertificateValidation `
    -Name “Automation” `
    -InstanceId “the instance ID you got from Get-MgmtSvcResourceProvider“
