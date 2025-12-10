# Notes:
# Removed sentive information in strings and replaced with '<common descriptive info>'
# Replace the '' and the information inside with environment information

Function Change_WAP_Admin_Auth_Website {
    $WAPAuthURL = "https://'<Tenant Admin Auth.domain.com>':30072/FederationMetadata/2007-06/FederationMetadata.xml"
    $SQLConnectionString = "Server='<WAP SQL Instance\WAP SQL Instance>';User Id='<sa>';Password='<Password>';"

    Set-MgmtSvcRelyingPartySettings –Target Admin –MetadataEndpoint $WAPAuthURL -ConnectionString $SQLConnectionString
}
Function Change_WAP_Tenant_Auth_Website {
$WAPAuthURL = "https://'<Tenant Admin Auth.domain.com>':30072/FederationMetadata/2007-06/FederationMetadata.xml"
$SQLConnectionString = "Server='<WAP SQL Instance\WAP SQL Instance>';User Id='<sa>';Password='<Password>';"

Import-Module -Name MgmtSvcConfig 
Set-MgmtSvcRelyingPartySettings –Target Admin –MetadataEndpoint $WAPAuthURL -ConnectionString $SQLConnectionString

}
Function Set_WAP_Admin_Website {
Import-Module MgmtSvcConfig
Set-MgmtSvcFqdn -Namespace "AdminSite" -FullyQualifiedDomainName "'<WAP Admin.domain.com>'" -Port 30091 -Server "'<WAP SQL Instance\WAP SQL Instance>'"

}
Function Add_AdminUser {
$adminuser = "'<Admin User@domain.com>'"
$dbServer = "'<WAP SQL Instance\WAP SQL Instance>'"
$dbUsername = "'<sa>'"
$dbPassword = "'<Password>'"
$connectionString = [string]::Format("Server= {0} ;Initial Catalog=Microsoft.MgmtSvc.Store;User Id={1};Password={2};",$dbServer, $dbUsername, $dbPassword)

Add-MgmtSvcAdminUser -Principal $adminuser -ConnectionString $connectionstring 
}
Function Install_ADFS_Farm {
$CertThumbprint = Get-ChildItem -Path Cert:\LocalMachine\My | Select Thumbprint
$domainName = "'<Domain Name>'"
$adfsPrefix = "'<ADFS Prefix>'"
$username = "'<domain\Service Account>'" 
$password = ConvertTo-SecureString "'<Password>'" -AsPlainText -Force
$dnsName = ($adfsPrefix + "." + $domainName)
$SQLConnectionString = "Data Source='<WAP SQL Instance\WAP SQL Instance>';Initial Catalog=master;User ID='<sa>';Password='<Password>'"
$ADFSCreds = New-Object PSCredential ($username,$password)

Install-AdfsFarm –CertificateThumbprint $CertThumbprint.Thumbprint -FederationServiceName $dnsName -ServiceAccountCredential $ADFSCreds -SQLConnectionString $SQLConnectionString
}

Function Change_Admin_to_ADFS {
$ADFSURL = "https://'<ADFS Prefix.domain.com>'/FederationMetadata/2007-06/FederationMetadata.xml"
$SQLConnectionString = "Server='<WAP SQL Instance\WAP SQL Instance>';User Id='<sa>';Password='<Password>';"

Set-MgmtSvcRelyingPartySettings -Target Admin -MetadataEndpoint $ADFSURL -DisableCertificateValidation -ConnectionString $SQLConnectionString
#Set-MgmtSvcRelyingPartySettings -Target Tenant -MetadataEndpoint $ADFSURL -DisableCertificateValidation -ConnectionString $SQLConnectionString


}
Function Change_Tenant_to_ADFS {
$ADFSURL = "https://'<ADFS Prefix.domain.com>'/FederationMetadata/2007-06/FederationMetadata.xml"
$SQLConnectionString = "Server='<WAP SQL Instance\WAP SQL Instance>';User Id='<sa>';Password='<Password>';"

#Set-MgmtSvcRelyingPartySettings -Target Admin -MetadataEndpoint $ADFSURL -DisableCertificateValidation -ConnectionString $SQLConnectionString
Set-MgmtSvcRelyingPartySettings -Target Tenant -MetadataEndpoint $ADFSURL -DisableCertificateValidation -ConnectionString $SQLConnectionString


}
Function Set_ADFS_Membership {
$ADFSURL = "https://'<ADFS Prefix.domain.com>'/FederationMetadata/2007-06/FederationMetadata.xml"
$SQLConnectionString = "Server='<WAP SQL Instance\WAP SQL Instance>';User Id='<sa>';Password='<Password>';"

Set-MgmtSvcIdentityProviderSettings -Target Membership -MetadataEndpoint $ADFSURL -DisableCertificateValidation -ConnectionString $SQLConnectionString

}