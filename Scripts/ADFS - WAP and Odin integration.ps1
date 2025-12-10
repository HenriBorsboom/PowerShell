Function Change_WAP_Admin_Auth_Website {
    $WAPAuthURL = "https://wapadminauth.domain1.local:30072/FederationMetadata/2007-06/FederationMetadata.xml"
    $SQLConnectionString = "Server=NRAZUREDBSQ107\NRAZUREDBSQ107;User Id=sa;Password=Hv!Sq7SerP@ssw0rd;"

    Set-MgmtSvcRelyingPartySettings –Target Admin –MetadataEndpoint $WAPAuthURL -ConnectionString $SQLConnectionString
}
Function Change_WAP_Tenant_Auth_Website {
$WAPAuthURL = "https://wapauth.domain1.local:30072/FederationMetadata/2007-06/FederationMetadata.xml"
$SQLConnectionString = "Server=NRAZUREDBSQ107\NRAZUREDBSQ107;User Id=sa;Password=Hv!Sq7SerP@ssw0rd;"

Import-Module -Name MgmtSvcConfig 
Set-MgmtSvcRelyingPartySettings –Target Admin –MetadataEndpoint $WAPAuthURL -ConnectionString $SQLConnectionString

}
Function Set_WAP_Admin_Website {
Import-Module MgmtSvcConfig
Set-MgmtSvcFqdn -Namespace "AdminSite" -FullyQualifiedDomainName "wapadmin.domain1.local" -Port 30091 -Server "NRAZUREDBSQ107\NRAZUREDBSQ107"

}
Function Add_AdminUser {
$adminuser = "darrelw@domain2.local"
$dbServer = "NRAZUREDBSQ107\NRAZUREDBSQ107"
$dbUsername = "sa"
$dbPassword = "Hv!Sq7SerP@ssw0rd"
$connectionString = [string]::Format("Server= {0} ;Initial Catalog=Microsoft.MgmtSvc.Store;User Id={1};Password={2};",$dbServer, $dbUsername, $dbPassword)

Add-MgmtSvcAdminUser -Principal $adminuser -ConnectionString $connectionstring 
}
Function Install_ADFS_Farm {
$CertThumbprint = Get-ChildItem -Path Cert:\LocalMachine\My | Select Thumbprint
$domainName = "domain1.local"
$adfsPrefix = "BCXAzure-ADFS"
$username = "domain2\HVI-WAPADFS" 
$password = ConvertTo-SecureString "YourPasswordHere" -AsPlainText -Force
$dnsName = ($adfsPrefix + "." + $domainName)
$SQLConnectionString = "Data Source=NRAZUREDBSQ107\NRAZUREDBSQ107;Initial Catalog=master;User ID=sa;Password=Hv!Sq7SerP@ssw0rd"
$ADFSCreds = New-Object PSCredential ($username,$password)

Install-AdfsFarm –CertificateThumbprint $CertThumbprint.Thumbprint -FederationServiceName $dnsName -ServiceAccountCredential $ADFSCreds -SQLConnectionString $SQLConnectionString
}
Function Add_AdminUser1 {
$adminuser = "username@domain2.local"
$dbServer = "NRAZUREDBSQ107\NRAZUREDBSQ107"
$dbUsername = "sa"
$dbPassword = "Hv!Sq7SerP@ssw0rd"
$connectionString = [string]::Format("Server= {0} ;Initial Catalog=Microsoft.MgmtSvc.Store;User Id={1};Password={2};",$dbServer, $dbUsername, $dbPassword)

Add-MgmtSvcAdminUser -Principal $adminuser -ConnectionString $connectionstring 


}
Function Change_Admin_to_ADFS {
$ADFSURL = "https://bcxazure-adfs.domain1.local/FederationMetadata/2007-06/FederationMetadata.xml"
$SQLConnectionString = "Server=NRAZUREDBSQ107\NRAZUREDBSQ107;User Id=sa;Password=Hv!Sq7SerP@ssw0rd;"

Set-MgmtSvcRelyingPartySettings -Target Admin -MetadataEndpoint $ADFSURL -DisableCertificateValidation -ConnectionString $SQLConnectionString
#Set-MgmtSvcRelyingPartySettings -Target Tenant -MetadataEndpoint $ADFSURL -DisableCertificateValidation -ConnectionString $SQLConnectionString


}
Function Change_Tenant_to_ADFS {
$ADFSURL = "https://bcxazure-adfs.domain1.local/FederationMetadata/2007-06/FederationMetadata.xml"
$SQLConnectionString = "Server=NRAZUREDBSQ107\NRAZUREDBSQ107;User Id=sa;Password=Hv!Sq7SerP@ssw0rd;"

#Set-MgmtSvcRelyingPartySettings -Target Admin -MetadataEndpoint $ADFSURL -DisableCertificateValidation -ConnectionString $SQLConnectionString
Set-MgmtSvcRelyingPartySettings -Target Tenant -MetadataEndpoint $ADFSURL -DisableCertificateValidation -ConnectionString $SQLConnectionString


}
Function Set_ADFS_Membership {
$ADFSURL = "https://bcxazure-adfs.domain1.local/FederationMetadata/2007-06/FederationMetadata.xml"
$SQLConnectionString = "Server=NRAZUREDBSQ107\NRAZUREDBSQ107;User Id=sa;Password=Hv!Sq7SerP@ssw0rd;"

Set-MgmtSvcIdentityProviderSettings -Target Membership -MetadataEndpoint $ADFSURL -DisableCertificateValidation -ConnectionString $SQLConnectionString

}