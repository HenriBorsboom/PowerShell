       <#
       .SYNOPSIS
             Windows Azure Pack Tool

       .DESCRIPTION
             The Windows Azure Pack Tool creates a easy and handy menu to perform regular tasks in Windows Azure Pack.
             
       .NOTES
             Author:             Darryl van der Peijl
             Blog  :             http://www.DarrylvanderPeijl.nl/
             Twitter:     @DarrylvdPeijl
        Requires:   Windows Azure Pack MgmtSvc Powershell Module
        Version   : 2.1
             Tested in lab environments, Use on your own risk.
       #>

$host.ui.RawUI.WindowTitle = "Windows Azure Pack Tool"
#region SQLQuery
Function QueryPortalConfigStoreDB {
Invoke-Command -Session $SQLSession -ScriptBlock {
Try{
Try{If (Get-Cluster $SQLServer ) {$instance = $using:SQLServer}} Catch {Write-verbose -Message "$using:SQLServer is not part of a cluster"}
$SQLresults = Invoke-Sqlcmd -Query "SELECT Namespace,Name,Value FROM [Microsoft.MgmtSvc.PortalConfigStore].[Config].[Settings]" -hostname $using:SQLServerInstance -serverinstance $using:Instance
Write-output $SQLresults
}
Catch{
write-output "Could not connect to $ComputerName"
}
}
}

Function QueryStoreDB {
Invoke-Command -Session $SQLSession -ScriptBlock {
Try{
Try{ If (Get-Cluster $SQLServer ) {$instance = $using:SQLServer}} Catch {Write-verbose -Message "$using:SQLServer is not part of a cluster"}
$SQLresults = Invoke-Sqlcmd -Query "SELECT Namespace,Name,Value FROM [Microsoft.MgmtSvc.Store].[Config].[Settings]" -hostname $using:SQLServerInstance -serverinstance $using:Instance
Write-Output $SQLresults
}
Catch{
write-output "Could not connect to $ComputerName"
}
}
}

Function QueryResourceProviders {
Invoke-Command -Session $SQLSession -ScriptBlock {
Try{ 
Try{If (Get-Cluster $SQLServer ) {$instance = $using:SQLServer}} Catch {Write-verbose -Message "$using:SQLServer is not part of a cluster"}
$SQLresults = Invoke-Sqlcmd -Query "SELECT Name,TenantForwardingAddress,AdminForwardingAddress FROM [Microsoft.MgmtSvc.Store].[MP].[Resourceproviders]" -hostname $using:SQLServerInstance -serverinstance $using:Instance
Write-Output $SQLresults
}
Catch{
write-output "Could not connect to $ComputerName"
}
}
}

Function QueryWAPversion {
Invoke-Command -Session $SQLSession -ScriptBlock {
Try{
Try{If (Get-Cluster $SQLServer ) {$instance = $using:SQLServer}} Catch {Write-verbose -Message "$using:SQLServer is not part of a cluster"}
$SQLresults = Invoke-Sqlcmd -Query "SELECT Version FROM [Microsoft.MgmtSvc.Config].[Config].[Version]" -hostname $using:SQLServerInstance -serverinstance $using:Instance
Write-Output $SQLresults
}
Catch{
write-output "Could not connect to $ComputerName"
}
}
}

Function GetInfoPortalConfigStoreDB{
$SQLresults = QueryPortalConfigStoreDB
$Global:TenantSiteURI = (($SQLresults | where {$_.name -eq "Authentication.Fqdn" -and $_.Namespace -eq "TenantSite"}).value)
$Global:AuthSiteURI = (($SQLresults | where {$_.name -eq "Authentication.Fqdn" -and $_.Namespace -eq "Authsite"}).value)
$Global:AdminSiteURI = (($SQLresults | where {$_.name -eq "Authentication.Fqdn" -and $_.Namespace -eq "Adminsite"}).value)
$Global:WindowsAuthSiteURI = (($SQLresults | where {$_.name -eq "Authentication.Fqdn" -and $_.Namespace -eq "WindowsAuthSite"}).value)
}

Function GetInfoStoreDB{
$SQLresults2 = QueryStoreDB
$Global:TenantAPIURI = ($SQLresults2 | where {$_.name -eq "Fqdn" -and $_.Namespace -eq "TenantAPI"}).value
$Global:AdminAPIURI = ($SQLresults2 | where {$_.name -eq "Fqdn" -and $_.Namespace -eq "AdminAPI"}).value
$Global:TenantPublicAPIURI = ($SQLresults2 | where {$_.name -eq "Fqdn" -and $_.Namespace -eq "TenantPublicAPI"}).value
}

Function GetInfoResourceProviderDB{
$SQLresults3 = QueryResourceProviders
$Global:UsageserviceTenantURI = ($SQLresults3 | where {$_.name -eq "usageservice"}).TenantForwardingAddress
$Global:UsageserviceAdminURI = ($SQLresults3 | where {$_.name -eq "usageservice"}).AdminForwardingAddress
$Global:MarketplaceTenantURI = ($SQLresults3 | where {$_.name -eq "marketplace"}).TenantForwardingAddress
$Global:MarketplaceAdminURI = ($SQLresults3 | where {$_.name -eq "marketplace"}).AdminForwardingAddress
$Global:MonitoringTenantURI = ($SQLresults3 | where {$_.name -eq "monitoring"}).TenantForwardingAddress
$Global:MonitoringAdminURI = ($SQLresults3 | where {$_.name -eq "monitoring"}).AdminForwardingAddress
}

Function GetWAPversion{
$SQLresults4 = QueryWAPversion
$Global:WAPversion = (($SQLresults4).version)

}

Function GetInfo {
GetInfoPortalConfigStoreDB
GetInfoStoreDB
GetInfoResourceProviderDB

Write-Output " "
Write-Output " "

}
#endregion

#region Diagnostics

Function GetADFSStatusAdmin {

#Due to a bug in the Get-MgmtSvcRelyingPartySettings cmdlet the target is Tenant instead of admin

If ((Get-MgmtSvcRelyingPartySettings -Target Tenant -Server $SQLServerInstance).realm -match "http://azureservices/") {Write-Output $false}
Else {write-output $true}
}

Function GetADFSAdminEndpoint {

#Due to a bug in the Get-MgmtSvcRelyingPartySettings cmdlet the target is Tenant instead of admin
Try{
Write-output (Get-MgmtSvcRelyingPartySettings -Target Tenant -Server $SQLServerInstance).Endpoint
}
Catch {
$_.exception
}

}


Function GetADFSStatusTenant {

#Due to a bug in the Get-MgmtSvcRelyingPartySettings cmdlet the target is Admin instead of tenant
If ((Get-MgmtSvcRelyingPartySettings -Target Admin -Server $SQLServerInstance).realm -match "http://azureservices/") {Write-Output $false}
Else {write-output $true}
}

Function GetADFStenantEndpoint {

#Due to a bug in the Get-MgmtSvcRelyingPartySettings cmdlet the target is Admin instead of Tenant
Try{
Write-output (Get-MgmtSvcRelyingPartySettings -Target Admin -Server $SQLServerInstance).Endpoint
}
Catch {
$_.exception
}

}

Function GetDiagnostics{
Write-Host " "
GetWAPversion 
Write-Output "Windows Azure Pack Version: $WAPversion"

$ADFSStatusTenant = (GetADFSStatusTenant)
$ADFSStatusAdmin = (GetADFSStatusAdmin)
Write-Host " "
Write-Output "ADFS Enabled for tenant site: $ADFSStatusTenant"  
Write-Output "ADFS Enabled for admin site: $ADFSStatusAdmin" 
If ($ADFSStatusAdmin -eq $true) { 
$ADFSAdminEndpoint = GetADFSAdminEndpoint
Write-output "ADFS Endpoint for admin site: $ADFSAdminEndpoint"
}
If ($ADFSStatusTenant -eq $true) { 
$ADFSTenantEndpoint = GetADFSTenantEndpoint
Write-output "ADFS Endpoint for tenant site: $ADFSTenantEndpoint"
}


GetInfo

$hash=@{}
$hash["Tenant Site URI"]=@("$TenantSiteURI")
$hash["Authentication Site URI"]=@("$AuthSiteURI")
$hash["Admin Site URI"]=@("$AdminSiteURI")
$hash["Windows Authentication Site URI"]=@("$WindowsAuthSiteURI")
$hash["Tenant API URI"]=@("$TenantAPIURI")
$hash["Admin API URI"]=@("$AdminAPIURI")
$hash["Tenant Public API URI"]=@("$TenantPublicAPIURI")

$hash["Usageservice Tenant endpoint URI"]=@("$UsageserviceTenantURI")
$hash["Usageservice Admin endpoint URI"]=@("$UsageserviceAdminURI")
$hash["Marketplace Tenant endpoint URI"]=@("$MarketplaceTenantURI")
$hash["Marketplace Admin endpoint URI"]=@("$MarketplaceAdminURI")
$hash["Monitoing Tenant endpoint URI"]=@("$MonitoringTenantURI")
$hash["Monitoing Admin endpoint URI"]=@("$MonitoringAdminURI")
$hash | FT -AutoSize

Read-Host "Press Enter to return to menu"
}

#endregion

#region ChangeURLs

Function Helptext{
write-output " " 
write-output "Specify http:// or https:// prefix"
Write-Output "Examples: https://sub.domain.com, https://sub.domain.com:444"
write-output " " 
}

Function UpdateTenantURI {
Clear-Host
Helptext

If (GetADFSStatusTenant -eq $true) {
Write-host "WARNING: ADFS is enabled, this function will change the tenant authentication back to WAP authentication.
You can enable ADFS again through the ADFS Menu."
}

if (!($TenantSiteURI2)){ $TenantSiteURI2 = Read-Host "New Tenant Site Hostname <$TenantSiteURI>" }
if (!($TenantSiteURI2)){$TenantSiteURI2 = $TenantSiteURI}

$TenantSiteHost2 = ([URI]$TenantSiteURI2).host
$TenantSitePort2 = ([URI]$TenantSiteURI2).port

If ($TenantSiteHost2 -ne $Null)
{
CheckDNS -URL $TenantSiteHost2

try {
Set-MgmtSvcFqdn -Namespace "TenantSite" -FullyQualifiedDomainName $TenantSiteHost2 -Port $TenantSitePort2 -Server $SQLServerInstance
Set-MgmtSvcRelyingPartySettings –Target "Membership" –MetadataEndpoint ("https://$TenantSiteHost2" + ":" + "$TenantSitePort2/FederationMetadata/2007-06/FederationMetadata.xml") -ConnectionString $connectionstring -DisableCertificateValidation
Write-Output "Settings succesfully set"; sleep 1
}
Catch {
Write-output "ERROR Updating Tenant Portal:
$_.exception
Make sure "https://$TenantSiteHost2"":""$TenantSitePort2/FederationMetadata/2007-06/FederationMetadata.xml" is reachable"
Sleep 5}
}
QueryPortalConfigStoreDB;$TenantSiteURI2=$null;ConfigurationMenu
}

Function UpdateAuthURI {
Clear-Host
Helptext

If (GetADFSStatusTenant -eq $true) {
Write-host "WARNING: ADFS is enabled, this function will change the tenant authentication back to WAP authentication.
You can enable ADFS again through the ADFS Menu."
}


if (!($AuthSiteURI2)){ $AuthSiteURI2 = Read-Host "New Authentication Site Hostname <$AuthSiteURI>" }
if (!($AuthSiteURI2)){$AuthSiteURI2 = $AuthSiteURI}

$AuthSiteHost2 = ([URI]$AuthSiteURI2).host
$AuthSitePort2 = ([URI]$AuthSiteURI2).port

If ($AuthSiteHost2 -ne $Null)
{
CheckDNS -URL $AuthSiteHost2
Try {
Set-MgmtSvcFqdn -Namespace "AuthSite" -FullyQualifiedDomainName $AuthSiteHost2 -Port $AuthSitePort2 -Server $SQLServerInstance
Set-MgmtSvcRelyingPartySettings –Target "Tenant" –MetadataEndpoint ("https://$AuthSiteHost2" + ":" + "$AuthSitePort2/FederationMetadata/2007-06/FederationMetadata.xml") -ConnectionString $connectionstring -DisableCertificateValidation
Write-Output "Settings succesfully set"; sleep 1
}
Catch {
Write-Output "ERROR Updating Authentication Site:
$_.exception
Make sure "https://$AuthSiteHost2"":""$AuthSitePort2/FederationMetadata/2007-06/FederationMetadata.xml" is reachable"
Sleep 5
}
}
Write-Output "End of Function";QueryPortalConfigStoreDB;$AuthSiteURI2=$null;ConfigurationMenu
}

Function UpdateAdminURI {
Clear-Host
Helptext

If (GetADFSStatusAdmin -eq $true) {
Write-host "WARNING: ADFS is enabled, this function will change the admin authentication back to WAP authentication.
You can enable ADFS again through the ADFS Menu."
}

if (!($AdminSiteURI2)){ $AdminSiteURI2 = Read-Host "New Admin Site Hostname <$AdminSiteURI>" }
if (!($AdminSiteURI2)){$AdminSiteURI2 = $AdminSiteURI}

$AdminSiteHost2 = ([URI]$AdminSiteURI2).host
$AdminSitePort2 = ([URI]$AdminSiteURI2).port

If ($AdminSiteHost2 -ne $Null)
{
CheckDNS -URL $AdminSiteHost2
Try {
Set-MgmtSvcFqdn -Namespace "AdminSite" -FullyQualifiedDomainName $AdminSiteHost2 -Port $AdminSitePort2 -Server $SQLServerInstance
Set-MgmtSvcIdentityProviderSettings –Target Windows –MetadataEndpoint ("https://$AdminSiteHost2" + ":" + "$AdminSitePort2/FederationMetadata/2007-06/FederationMetadata.xml") -ConnectionString $connectionstring -DisableCertificateValidation
Write-Output "Settings succesfully set"; sleep 1
}
Catch {
Write-Output "ERROR Updating Admin Portal:
$_.exception
Make sure "https://$AuthSiteHost2"":""$AuthSitePort2/FederationMetadata/2007-06/FederationMetadata.xml" is reachable"
Sleep 5
}
}
Write-Output "End of Function";QueryPortalConfigStoreDB;$AdminSiteURI2=$null;ConfigurationMenu
}

Function UpdateWindowsAuthURI {
Clear-Host
Helptext

if (!($WindowsAuthSiteURI2)){ $WindowsAuthSiteURI2 = Read-Host "New Windows Auth Site Hostname <$WindowsAuthSiteURI>" }
if (!($WindowsAuthSiteURI2)){$WindowsAuthSiteURI2 = $WindowsAuthSiteURI}

$WindowsAuthSiteHost2 = ([URI]$WindowsAuthSiteURI2).host
$WindowsAuthSitePort2 = ([URI]$WindowsAuthSiteURI2).port

If ($WindowsAuthSiteHost2 -ne $Null)
{
CheckDNS -URL $WindowsAuthSiteHost2
Try{
Set-MgmtSvcFqdn -Namespace "WindowsAuthSite" -FullyQualifiedDomainName $WindowsAuthSiteHost2 -Port $WindowsAuthsitePort2 -Server $SQLServerInstance
Set-MgmtSvcRelyingPartySettings –Target Admin –MetadataEndpoint ("https://$WindowsAuthSiteHost2" + ":" + "$WindowsAuthSitePort2/FederationMetadata/2007-06/FederationMetadata.xml") -ConnectionString $connectionstring -DisableCertificateValidation
Write-Output "Settings succesfully set"; sleep 1
}
Catch {
Write-Output "ERROR Updating Admin Portal:
$_.exception
Make sure "https://$WindowsAuthSiteHost2"":""$WindowsAuthSitePort2/FederationMetadata/2007-06/FederationMetadata.xml" is reachable"
Sleep 5
}
}
Write-Output "End of Function";QueryPortalConfigStoreDB;$WindowsAuthSiteURI2=$null;ConfigurationMenu
}

Function UpdateTenantPublicAPIURI {
Clear-Host
Helptext

if (!($TenantPublicAPIURI2)){ $TenantPublicAPIURI2 = Read-Host "New Public API Hostname <$TenantPublicAPIURI>" }
if (!($TenantPublicAPIURI2)){$TenantPublicAPIURI2 = $TenantPublicAPIURI}

$TenantPublicAPIHost2 = ([URI]$TenantPublicAPIURI2).host
$TenantPublicAPIPort2 = ([URI]$TenantPublicAPIURI2).port

If ($TenantPublicAPIHost2 -ne $Null)
{
CheckDNS -URL $TenantPublicAPIHost2
Try {
Set-MgmtSvcFqdn -Namespace TenantPublicApi -FullyQualifiedDomainName $TenantPublicAPIHost2 -Port $TenantPublicAPIPort2 -Server $SQLServerInstance
Write-Output "Settings succesfully set"; sleep 1
}
Catch {
Write-Output "ERROR Updating Admin Portal:"
$_.exception

Sleep 5
}
}
Write-Output "End of Function";QueryStoreDB;$TenantPublicAPIURI2=$null;ConfigurationMenu
}

Function UpdateAdminAPIURI {
Clear-Host
Helptext

if (!($AdminAPIURI2)){ $AdminAPIURI2 = Read-Host "New Admin API Hostname <$AdminAPIURI>" }
if (!($AdminAPIURI2)){$AdminAPIURI2 = $AdminAPIURI}

$AdminAPIHost2 = ([URI]$AdminAPIURI2).host
$AdminAPIPort2 = ([URI]$AdminAPIURI2).port


If ($AdminAPIHost2 -ne $null)
{
CheckDNS -URL $AdminAPIHost2
Try {
Set-MgmtSvcFqdn -Namespace AdminAPI -FullyQualifiedDomainName $AdminAPIHost2 -Port $AdminAPIPort2 -Server $SQLServerInstance
Write-Output "Settings succesfully set"; sleep 1
}
Catch {
Write-Output "ERROR Updating AdminAPI:"
$_.exception
Sleep 5
}
}
Write-Output "End of Function";QueryStoreDB;$AdminAPIURI2=$null;ConfigurationMenu
}

Function UpdateTenantAPIURI {
Clear-Host
Helptext

if (!($TenantAPIURI2)){ $TenantAPIURI2 = Read-Host "New Tenant API Hostname <$TenantAPIURI>" }
if (!($TenantAPIURI2)){$TenantAPIURI2 = $TenantAPIURI}

$TenantAPIHost2 = ([URI]$TenantAPIURI2).host
$TenantAPIPort2 = ([URI]$TenantAPIURI2).port

If ($TenantAPIHost2 -ne $Null)
{
CheckDNS -URL $TenantAPIHost2
Try {
Set-MgmtSvcFqdn -Namespace TenantApi -FullyQualifiedDomainName $TenantAPIHost2 -Port $TenantAPIPort2 -Server $SQLServerInstance
Write-Output "Settings succesfully set"; sleep 1
}
Catch {
Write-Output "ERROR Updating APIs:"
$_.exception
Sleep 5
}
}
Write-Output "End of Function";QueryStoreDB;$TenantAPIURI2=$null;ConfigurationMenu
}

Function UpdateMarketplaceURI{

if (!($adminEndpoint)){ $adminEndpoint = Read-Host "New Marketplace URI <$MarketplaceAdminURI>" }
if (!($adminEndpoint)){$adminEndpoint = $MarketplaceAdminURI}

$resourceProviderName = "marketplace"
Try {
UpdateResourceProviderURI -resourceProviderName $resourceProviderName -adminEndpoint $adminEndpoint -tenantEndpoint $tenantEndpoint
Write-Output "End of Function";QueryResourceProviders;$adminEndpoint=$null;ResourceProviderURIsMenu
Write-Output "Settings succesfully set"; sleep 1
}
Catch {
Write-Output "ERROR Updating Marketplace:"
$_.exception
Sleep 5
}
}

Function UpdateMonitoringURI{

if (!($adminEndpoint)){ $adminEndpoint = Read-Host "New Monitoring URI <$MonitoringAdminURI>" }
if (!($adminEndpoint)){$adminEndpoint = $MonitoringAdminURI}

$resourceProviderName = "Monitoring"
Try {
UpdateResourceProviderURI -resourceProviderName $resourceProviderName -adminEndpoint $adminEndpoint -tenantEndpoint $tenantEndpoint
Write-Output "End of Function";QueryResourceProviders;$adminEndpoint=$null;ResourceProviderURIsMenu 
Write-Output "Settings succesfully set"; sleep 1
}
Catch {
Write-Output "ERROR Updating Monitoring:"
$_.exception
Sleep 5
}
}

Function UpdateUsageServiceURI{

if (!($adminEndpoint)){ $adminEndpoint = Read-Host "New UpdateService URI <$UsageserviceAdminURI>" }
if (!($adminEndpoint)){$adminEndpoint = $UsageserviceAdminURI}

$resourceProviderName = "UsageService"
Try {
UpdateResourceProviderURI -resourceProviderName $resourceProviderName -adminEndpoint $adminEndpoint -tenantEndpoint $tenantEndpoint
Write-Output "End of Function";QueryResourceProviders;$adminEndpoint=$null;ResourceProviderURIsMenu 
Write-Output "Settings succesfully set"; sleep 1
}
Catch{
Write-Output "ERROR Updating Monitoring:"
$_.exception
Sleep 5
}
}

Function UpdateResourceProviderURI {
param ($resourceProviderName,$adminEndpoint,$tenantEndpoint)
GetMgmtSvcToken
$usageEndpoint = $null
$healthCheckEndpoint = $null
$notificationEndpoint = $null
$rp = Get-MgmtSvcResourceProvider -Name $resourceProviderName -IncludeSystemResourceProviders -AdminUri $adminApiUri -Token $token -DisableCertificateValidation
if ($rp.AdminEndpoint -and $adminEndpoint) {
$rp.AdminEndpoint.ForwardingAddress = New-Object System.Uri($adminEndpoint)
}
if ($rp.TenantEndpoint -and $tenantEndpoint) {
$rp.TenantEndpoint.ForwardingAddress = New-Object System.Uri($tenantEndpoint)
}
if ($rp.UsageEndpoint -and $usageEndpoint) {
$rp.TenantEndpoint.ForwardingAddress = New-Object System.Uri($usageEndpoint)
}
if ($rp.HealthCheckEndpoint -and $healthCheckEndpoint) {
$rp.TenantEndpoint.ForwardingAddress = New-Object System.Uri($healthCheckEndpoint)
}
if ($rp.NotificationEndpoint -and $notificationEndpoint) {
$rp.TenantEndpoint.ForwardingAddress = New-Object System.Uri($notificationEndpoint)
}
try{
Set-MgmtSvcResourceProvider -ResourceProvider $rp -AdminUri $adminApiUri -Token $token -DisableCertificateValidation -Force -Confirm:$false
}
Catch{
Write-Output "ERROR Updating Resource Provider:"
$_.exception
Sleep 5
}
}

Function GetMgmtSvcToken {
if (!($token)){ 
if (!($tokencredential)){ 
Write-Output "For this function we will need a identity token, you will be prompted for credentials"
Sleep -Seconds 1
$tokencredential = Get-Credential
}

If (GetADFSStatusAdmin -eq $true) {

"ADFS Enabled for Admin site, getting ADFS token"

ADFSSettings2

function Get-AdfsToken([string]$adfsAddress, [PSCredential]$credential)
{
    $clientRealm = 'http://azureservices/AdminSite'
    $allowSelfSignCertificates = $true

    Add-Type -AssemblyName 'System.ServiceModel, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'
    Add-Type -AssemblyName 'System.IdentityModel, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'

    $identityProviderEndpoint = New-Object -TypeName System.ServiceModel.EndpointAddress -ArgumentList ($adfsAddress + 'adfs/services/trust/13/usernamemixed')
    $identityProviderBinding = New-Object -TypeName System.ServiceModel.WS2007HttpBinding -ArgumentList ([System.ServiceModel.SecurityMode]::TransportWithMessageCredential)
    $identityProviderBinding.Security.Message.EstablishSecurityContext = $false
    $identityProviderBinding.Security.Message.ClientCredentialType = 'UserName'
    $identityProviderBinding.Security.Transport.ClientCredentialType = 'None'

    $trustChannelFactory = New-Object -TypeName System.ServiceModel.Security.WSTrustChannelFactory -ArgumentList $identityProviderBinding, $identityProviderEndpoint
    $trustChannelFactory.TrustVersion = [System.ServiceModel.Security.TrustVersion]::WSTrust13

    if ($allowSelfSignCertificates)
    {
        $certificateAuthentication = New-Object -TypeName System.ServiceModel.Security.X509ServiceCertificateAuthentication
        $certificateAuthentication.CertificateValidationMode = 'None'
        $trustChannelFactory.Credentials.ServiceCertificate.SslCertificateAuthentication = $certificateAuthentication
    }

    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($credential.Password)
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($ptr)

    $trustChannelFactory.Credentials.SupportInteractive = $false
    $trustChannelFactory.Credentials.UserName.UserName = $credential.UserName
    $trustChannelFactory.Credentials.UserName.Password = $password #$credential.Password

    $rst = New-Object -TypeName System.IdentityModel.Protocols.WSTrust.RequestSecurityToken -ArgumentList ([System.IdentityModel.Protocols.WSTrust.RequestTypes]::Issue)
    $rst.AppliesTo = New-Object -TypeName System.IdentityModel.Protocols.WSTrust.EndpointReference -ArgumentList $clientRealm
    $rst.TokenType = 'urn:ietf:params:oauth:token-type:jwt'
    $rst.KeyType = [System.IdentityModel.Protocols.WSTrust.KeyTypes]::Bearer

    $rstr = New-Object -TypeName System.IdentityModel.Protocols.WSTrust.RequestSecurityTokenResponse

    $channel = $trustChannelFactory.CreateChannel()
    $token = $channel.Issue($rst, [ref] $rstr)

    $tokenString = ([System.IdentityModel.Tokens.GenericXmlSecurityToken]$token).TokenXml.InnerText;
    $result = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($tokenString))
    return $result
}

$global:token = Get-AdfsToken -adfsAddress $ADFSURI -credential $tokencredential 
}
Else {
$global:token = Get-MgmtSvcToken -Type Windows -AuthenticationSite $WindowsAuthSiteURI -ClientRealm "http://azureservices/AdminSite" -User $tokencredential -DisableCertificateValidation

}
}
}

Function CheckDNS{
param($URL)

if (!(Resolve-DnsName $URL -QuickTimeout -ErrorAction SilentlyContinue)){
$caption = "$URL cannot be resolved by DNS and will cause errors"
$message = "Do you still want to continue?"
$yes = new-Object System.Management.Automation.Host.ChoiceDescription "&Yes","help"
$no = new-Object System.Management.Automation.Host.ChoiceDescription "&No","help"
$choices = [System.Management.Automation.Host.ChoiceDescription[]]($no,$yes)
$answer = $host.ui.PromptForChoice($caption,$message,$choices,0)
switch ($answer){
    0 {
       $TenantSiteURI2 = $null;$AuthSiteURI2 = $null;$AdminSiteURI2 = $null;$WindowsAuthSiteURI2 = $null;
       $TenantAPIURI2 = $null;$AdminAPIURI2 = $null;$TenantPublicAPIURI2 = $null;
       ConfigurationMenu }
    1 {write-output " " }
}
}
}

#endregion

#region WAPadminusers

function GetWAPadminusers{
Write-Output "Current administrative users:"
Write-Output " "
# Get WAP Service Admin Users
Get-MgmtSvcAdminUser -Server $SQLServerInstance
Write-Output " "
Read-Host "Press Enter to return to menu"
}

function AddWAPadminusers{

# Add WAP Service Admin User 
Write-Output "This function adds an administrative user or group to the database. This grants principals to access the management portal for administrators and Windows Azure Pack administrator API."
Write-Output " "
$Principal = Read-Host "Principal to add"
try {
Add-MgmtSvcAdminUser -Principal $Principal -Server $SQLServerInstance | Out-Null
}
Catch { Write-output $_.exception
}
Write-Output "$Principal added to admins"
GetWAPadminusers
}

function RemoveWAPadminusers{
Write-Output "Current administrative users:"
Write-Output " "
# Get WAP Service Admin Users
Get-MgmtSvcAdminUser -Server $SQLServerInstance
Write-Output "- - - -"

$Principal = Read-Host "Principal to remove"
# Remove WAP Service Admin User
try {
Remove-MgmtSvcAdminUser -Principal $Principal -Server $SQLServerInstance -Confirm:$false
}
Catch { Write-output $_.exception
}
Write-Output "$Principal removed from admins"
GetWAPadminusers
}
#endregion

#region VMM
Function ChangeSelfServiceOwner {

If(!($VMMServer)) { $Global:VMMServer = Read-Host "VMM Server FQDN" }
If(!($VMMCredentials)) {
Write-Output "Administrative Credentials needed for VMM"
Sleep 1
$Global:VMMCredentials = Get-Credential
}

Function ChangeVMUserRoleCloud {
Param($VMname,$Userrole,$cloudname)

Invoke-Command -Session $Session -ScriptBlock {
$Userrole = get-scuserrole $using:Userrole
$cloudname2 = $using:cloudname
$Cloud = Get-SCCloud -VMMServer $VMMServer | where {$_.Name -eq $cloudname2}
$VM = Get-scvirtualMachine -name $using:VMname -VMMserver $VMMServer

$VM | Set-scvirtualmachine -cloud $Cloud
$VM | Set-scvirtualmachine -userrole $userrole
Write-Output "Changed Self Service owner for $VMname to $userrole"
}
}

$Session = New-PSSession $VMMserver -credential $VMMCredentials

Invoke-Command -Session $Session -ScriptBlock {
Import-Module VirtualMachineManager
$VMMserver = Get-scvmmserver $using:VMMServer -ForOnBehalfOf
}

$Userroles = Invoke-Command -Session $Session -ScriptBlock {
Get-SCUserRole | where {$_.Profile -eq "TenantAdmin"} | Select-Object Name,Cloud
} 
$Userroles | Out-GridView -passthru -Title "Select one Userrole to assign VM(s) to" | foreach { $Userrole = $_.Name;$Cloudname = $_.Cloud.Name}

$VMs = Invoke-Command -Session $Session -ScriptBlock {
Get-scvirtualmachine | Select-Object Name,Owner,Userrole,cloud,selfserviceuserrole
} 
$VMs | Out-GridView -passthru -Title "Select VM(s) to assign to selected userrole" | foreach { ChangeVMUserRoleCloud -VMname $_.Name -UserRole $Userrole -cloudname $Cloudname}
}
#endregion

#region ADFS

Function ADFSSettings {

If(!($ADFSserver)) { $Global:ADFSServer = Read-Host "ADFS Server FQDN [DC1.contoso.com]"}
If(!($ADFSserver)) { "ADFS Server needed"; Sleep 2; ADFSMenu}

If($ADFSserver) {$Global:ADFSsession = New-PSSession -ComputerName $ADFSServer}

If (!($connectionstring)) {
$Global:Connectionstring = "Data Source=$SQLserver;Initial Catalog=Microsoft.MgmtSvc.Store;Integrated Security = SSPI"
}
}

Function ADFSSettings2 {
ADFSSettings

If(!($ADFSFSN)) { $Global:ADFSFSN = (Invoke-Command -Session $ADFSsession -ScriptBlock { Write-output (Get-AdfsProperties).hostname}) }
If(!($ADFSFSN)) { "Cannot find ADFS Federation Service Name Serveron ADFS Server"; Sleep 2; ADFSMenu}
[uri]$global:ADFSURI = "https://$ADFSFSN"; $Global:ADFSFEDURI = "$ADFSURI" + "FederationMetadata/2007-06/FederationMetadata.xml"
}

Function ADFSSettings3 {

$Global:AuthSiteFEDURI = "$AuthSiteURI/federationmetadata/2007-06/federationmetadata.xml" 
$Global:TenantSiteFEDURI = "$TenantSiteURI/federationmetadata/2007-06/federationmetadata.xml" 
$Global:AdminSiteFEDURI = "$AdminSiteURI/federationmetadata/2007-06/federationmetadata.xml" 
$Global:WindowsAuthSiteFEDURI = "$WindowsAuthSiteURI/federationmetadata/2007-06/federationmetadata.xml" 

}

Function ConfigureADFS{

ADFSSettings
ADFSSettings2


Invoke-Command -ComputerName $ADFSserver -ArgumentList $AuthSiteURI,$TenantSiteURI,$AdminSiteURI -ScriptBlock {

$AuthSiteURI = $args[0];$TenantSiteURI = $args[1];$AdminSiteURI = $args[2];

Function ConfigureADFSserver{
Param(
    [Parameter(Mandatory=$true)][string]$identityProviderMetadataEndpoint, 
    [Parameter(Mandatory=$true)][string]$tenantRelyingPartyMetadataEndpoint, 
    [Parameter(Mandatory=$true)][string]$adminRelyingPartyMetadataEndpoint, 
    [string]$identityProviderName, 
    [string]$tenantRelyingPartyName,
    [string]$adminRelyingPartyName,
    [switch]$allowSelfSignCertificates)

Import-Module -Name 'ADFS'

if (!$identityProviderName)
{
    $identityProviderName = "WAP-AuthSite"
}

if (!$tenantRelyingPartyName)
{
    $tenantRelyingPartyName = "WAP-TenantSite"
}

if (!$adminRelyingPartyName)
{
    $adminRelyingPartyName = "WAP-AdminSite"
}

Write-Verbose -Message "identityProviderMetadataEndpoint: $identityProviderMetadataEndpoint"
Write-Verbose -Message "tenantRelyingPartyMetadataEndpoint: $tenantRelyingPartyMetadataEndpoint"
Write-Verbose -Message "adminRelyingPartyMetadataEndpoint: $adminRelyingPartyMetadataEndpoint"
Write-Verbose -Message "identityProviderName: $identityProviderName"
Write-Verbose -Message "tenantRelyingPartyName: $tenantRelyingPartyName"
Write-Verbose -Message "adminRelyingPartyName: $adminRelyingPartyName"
Write-Verbose -Message "allowSelfSignCertificates: $allowSelfSignCertificates"

$OriginalServerCertificateValidationCallback = [Net.ServicePointManager]::ServerCertificateValidationCallback

if ($allowSelfSignCertificates)
{
    [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
}

try
{
    $identityProvider = Get-AdfsClaimsProviderTrust -Name $identityProviderName
    if ($identityProvider)
    {
        Write-Verbose -Message "Removing existing identity provider $identityProviderName"
        Remove-AdfsClaimsProviderTrust -TargetName $identityProviderName
    }
    
    Write-Verbose -Message "Creating identity provider $identityProviderName"
    $providerTransformationRules = (
        "@RuleTemplate = ""PassThroughClaims"" @RuleName = ""UPN"" c:[Type == ""http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn""] => issue(claim = c);")

    Add-AdfsClaimsProviderTrust `
        -Name $identityProviderName `
        -MetadataUrl $identityProviderMetadataEndpoint `
        -MonitoringEnabled $true `
        -Notes "Created with Windows Azure Pack Tool" `
        -AcceptanceTransformRules ([System.String]::Concat($providerTransformationRules))

    $relyingParty = Get-AdfsRelyingPartyTrust -Name $tenantRelyingPartyName
    if ($relyingParty)
    {
        Write-Verbose -Message "Removing existing relying party $tenantRelyingPartyName"
        Remove-AdfsRelyingPartyTrust -TargetName $tenantRelyingPartyName
    }
        
    Write-Verbose -Message "Creating relying party $tenantRelyingPartyName"
    $transformationRules = (
        "@RuleTemplate = ""LdapClaims"" @RuleName = ""UPN - LDAP"" c:[Type == ""http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname"", Issuer == ""AD AUTHORITY""] => issue(store = ""Active Directory"", types = (""http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn""), query = "";userPrincipalName;{0}"", param = c.Value);",
        "@RuleTemplate = ""LdapClaims"" @RuleName = ""Groups - LDAP"" c:[Type == ""http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname"", Issuer == ""AD AUTHORITY""] => issue(store = ""Active Directory"", types = (""http://schemas.xmlsoap.org/claims/Group""), query = "";tokenGroups(domainQualifiedName);{0}"", param = c.Value);",
        "@RuleTemplate = ""PassThroughClaims"" @RuleName = ""UPN - Passthrough"" c:[Type == ""http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn""] => issue(claim = c);",
        "@RuleTemplate = ""PassThroughClaims"" @RuleName = ""Groups - Passthrough"" c:[Type == ""http://schemas.xmlsoap.org/claims/Group""] => issue(claim = c);")

    $issuanceRules = (
        "=> issue(Type = ""http://schemas.microsoft.com/authorization/claims/permit"", Value = ""true"");")

    $impersonationRules = (
        "c:[Type == ""http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid"", Issuer =~""^(AD AUTHORITY|SELF AUTHORITY|LOCAL AUTHORITY)$"" ] => issue(store=""_ProxyCredentialStore"", types=(""http://schemas.microsoft.com/authorization/claims/permit""),query=""isProxySid({0})"", param=c.Value );c:[Type == ""http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid"", Issuer =~ ""^(AD AUTHORITY|SELF AUTHORITY|LOCAL AUTHORITY)$"" ] => issue(store=""_ProxyCredentialStore"",types=(""http://schemas.microsoft.com/authorization/claims/permit""),query=""isProxySid({0})"", param=c.Value );c:[Type == ""http://schemas.microsoft.com/ws/2008/06/identity/claims/proxytrustid"", Issuer =~ ""^SELF AUTHORITY$"" ] => issue(store=""_ProxyCredentialStore"",types=(""http://schemas.microsoft.com/authorization/claims/permit""),query=""isProxyTrustProvisioned({0})"", param=c.Value );")


    Add-AdfsRelyingPartyTrust `
        -Enabled $true `
        -Name $tenantRelyingPartyName `
        -MetadataUrl $tenantRelyingPartyMetadataEndpoint `
        -EnableJWT $true `
        -Notes "Created with Windows Azure Pack Tool" `
        -AllowedClientTypes None `
        -IssuanceTransformRules ([System.String]::Concat($transformationRules)) `
        -IssuanceAuthorizationRules ([System.String]::Concat($issuanceRules)) `
        -ImpersonationAuthorizationRules ([System.String]::Concat($impersonationRules))


    Add-AdfsRelyingPartyTrust `
        -Enabled $true `
        -Name $adminRelyingPartyName `
        -MetadataUrl $adminRelyingPartyMetadataEndpoint `
        -EnableJWT $true `
        -Notes "Created with Windows Azure Pack Tool" `
        -AllowedClientTypes None `
        -ClaimsProviderName "Active Directory" `
        -IssuanceTransformRules ([System.String]::Concat($transformationRules)) `
        -IssuanceAuthorizationRules ([System.String]::Concat($issuanceRules)) `
        -ImpersonationAuthorizationRules ([System.String]::Concat($impersonationRules))

}
finally
{
    [Net.ServicePointManager]::ServerCertificateValidationCallback = $OriginalServerCertificateValidationCallback
}
}

ConfigureADFSserver –identityProviderMetadataEndpoint "$AuthSiteURI/federationmetadata/2007-06/federationmetadata.xml" -tenantRelyingPartyMetadataEndpoint "$TenantSiteURI/federationmetadata/2007-06/federationmetadata.xml" -adminRelyingPartyMetadataEndpoint "$AdminSiteURI/federationmetadata/2007-06/federationmetadata.xml" 
} #end Invoke-command
}

Function EnableADFSWAPAdmin {

ADFSSettings
ADFSSettings2

## Re-establish trust for the Admin Site
Set-MgmtSvcRelyingPartySettings -Target Admin -MetadataEndpoint $ADFSFEDURI -ConnectionString $connectionstring

## Re-establish trust for the Admin Auth Site
Set-MgmtSvcIdentityProviderSettings -Target Windows -MetadataEndpoint $ADFSFEDURI -ConnectionString $connectionstring
#Empty token
$global:token = $null
}

Function EnableADFSWAPTenant {

ADFSSettings
ADFSSettings2

## Re-establish trust for the Tenant Site 
Set-MgmtSvcRelyingPartySettings -Target Tenant -MetadataEndpoint $ADFSFEDURI -ConnectionString $connectionstring

## Re-establish trust for the Tenant Auth Site
Set-MgmtSvcIdentityProviderSettings -Target Membership -MetadataEndpoint $ADFSFEDURI -ConnectionString $connectionstring

}

Function DisableADFSWAPAdmin {

ADFSSettings3

## Re-establish trust for the Admin Site
Set-MgmtSvcRelyingPartySettings -Target Admin -MetadataEndpoint $WindowsAuthSiteFEDURI -ConnectionString $connectionstring

## Re-establish trust for the Admin Auth Site
Set-MgmtSvcIdentityProviderSettings -Target Windows -MetadataEndpoint $AdminSiteFEDURI  -ConnectionString $connectionstring
}

Function DisableADFSWAPTenant {

ADFSSettings3

## Re-establish trust for the Tenant Site 
Set-MgmtSvcRelyingPartySettings -Target Tenant -MetadataEndpoint $AuthSiteFEDURI -ConnectionString $connectionstring

## Re-establish trust for the Tenant Auth Site
Set-MgmtSvcIdentityProviderSettings -Target Membership -MetadataEndpoint $TenantSiteFEDURI  -ConnectionString $connectionstring

}

#endregion

#region Menu
Function Show-Menu {

Param(
[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter your menu text")]
[ValidateNotNullOrEmpty()]
[string]$Menu,
[Parameter(Position=1)]
[ValidateNotNullOrEmpty()]
[string]$Title="Menu",
[switch]$ClearScreen
)

if ($ClearScreen) {Clear-Host}
#build the menu prompt
$menuPrompt=$title
#add a return
$menuprompt+="`n"
#add an underline
$menuprompt+="-"*$title.Length
$menuprompt+="`n"
#add the menu
$menuPrompt+=$menu

Read-Host -Prompt $menuprompt
}

Function MainMenu {
$menu=@"

1: Configuration Tasks

2: Management Tasks

3: Diagnostics

4: About

Q: Quit

-----

Select a task by number or Q to quit
"@

Do {
    Switch (Show-Menu $menu "Windows Azure Pack - Tool v2.1" -clear) {
     "1" {ConfigurationMenu} 
     "2" {ManagementMenu}
     "3" {GetDiagnostics}
       "4" {About}
     "Q" {Write-output "Thanks for using the Windows Azure Pack Tool"
         exit
         }
     Default {Write-Warning "Invalid Choice. Try again."
              sleep -milliseconds 750}
    } 
} While ($True)
}

Function ConfigurationMenu {
$menu=@"

1: Change Portal URIs

2: Change API URIs

3: Change Resource Provider URIs

4: Configure ADFS

B: Back

-----

Select a task by number or B to go back
"@

Do {
    Switch (Show-Menu $menu "Configuration Menu" -clear) {
     "1" {PortalURIsMenu} 
     "2" {APIURIsMenu}
     "3"  {ResourceProviderURIsMenu}
     "4"  {ADFSMenu}
       "B" {MainMenu}
     Default {Write-Warning "Invalid Choice. Try again."; sleep -milliseconds 750}
    } 
} While ($True)
}

Function PortalURIsMenu {
$menu=@"

1: Change Tenant Portal URI

2: Change Tenant Authentication URI

3: Change Admin Portal URI

4: Change Windows Authentication URI  

B: Back

-----

Select a task by number or B to go back
"@


Do {
    Switch (Show-Menu $menu "Configuration Menu" -clear) {
     "1" {UpdateTenantURI} 
     "2" {UpdateAuthURI}
     "3"  {UpdateAdminURI}
       "4"  {UpdateWindowsAuthURI}
       "B" {ConfigurationMenu}
     Default {Write-Warning "Invalid Choice. Try again."; sleep -milliseconds 750}
    } 
} While ($True)
}

Function APIURIsMenu {
$menu=@"

1: Change Tenant API URI

2: Change Admin API URI

3: Change Tenant Public API URI

B: Back

-----

Select a task by number or B to go back
"@

Do {
    Switch (Show-Menu $menu "Configuration Menu" -clear) {
       "1"  {UpdateTenantAPIURI}
       "2"  {UpdateAdminAPIURI}
       "3"  {UpdateTenantPublicAPIURI}
       "B" {ConfigurationMenu}
     Default {Write-Warning "Invalid Choice. Try again."; sleep -milliseconds 750}
    } 
} While ($True)
}

Function ResourceProviderURIsMenu {
$menu=@"

1: Change Market Place URI

2: Change Monitoring URI

3: Change Usage Service URI

B: Back

-----

Select a task by number or B to go back
"@

Do {
    Switch (Show-Menu $menu "Configuration Menu" -clear) {
       "1"  {UpdateMarketPlaceURI}
       "2"  {UpdateMonitoringURI}
       "3"  {UpdateUsageServiceURI}
       "B" {ConfigurationMenu}
     Default {Write-Warning "Invalid Choice. Try again."; sleep -milliseconds 750}
    } 
} While ($True)
}

Function ADFSMenu {
$menu=@"

1: Configure ADFS Server

2: Enable ADFS for Tenant Portal

3: Enable ADFS for Admin Portal

4: Disable ADFS for Tenant Portal

5: Disable ADFS for Admin Portal

B: Back

-----

Select a task by number or B to go back
"@

Do {
    Switch (Show-Menu $menu "ADFS Menu" -clear) {
       "1"  {ConfigureADFS}
       "2"  {EnableADFSWAPTenant}
       "3"  {EnableADFSWAPAdmin}
       "4"  {DisableADFSWAPTenant}
       "5"  {DisableADFSWAPAdmin}
       "B" {ConfigurationMenu}
     Default {Write-Warning "Invalid Choice. Try again."; sleep -milliseconds 750}
    } 
} While ($True)
}

Function ManagementMenu {
$menu=@"

1: Get current WAP Admin users

2: Add WAP Admin user / group

3: Remove WAP Admin user / group

4: Assign VM(s) to Userrole / subscription

B: Back

-----

Select a task by number or B to go back
"@
Do {
    Switch (Show-Menu $menu "Management Menu" -clear) {
     "1" {GetWAPadminusers} 
     "2" {AddWAPadminusers}
    "3"  {RemoveWAPadminusers}
       "4"  {ChangeSelfServiceOwner}
     "B" {MainMenu}
     Default {Write-Warning "Invalid Choice. Try again."; sleep -milliseconds 750}
    }
} While ($True)
}
#endregion

Function About {

Write-Output "
Author:             Darryl van der Peijl
Blog  :             http://www.DarrylvanderPeijl.nl/
Twitter:     @DarrylvdPeijl
Requires:    Windows Azure Pack MgmtSvc Powershell Module
Version   : 2.1
Tested in lab environments, Use on your own risk.
"
Read-Host "Press Enter to return to menu"
}



Clear-Host
write-output "Initializing Windows Azure Pack Tookit" 
Write-Output "Loading MgmtSvcConfig Module"
Try {
Import-Module -Name MgmtSvcConfig
}
Catch{
"Cannot load MgmtSvcConfig module, Run from WAP Admin server";sleep 2;exit;
}
Clear-Host
Write-Host "Please define the Windows Azure Pack SQL Server"
Write-Host "in the format Servername\Instance (when default instance, only specify servername)" 
Write-Host " "

$Global:SQLserver = Read-Host "Windows Azure Pack SQL Server"

if ($sqlserver.split("\").count -gt 1)
{
    $Global:SQLServerInstance = $SQLserver
    $Global:Instance = $sqlserver
    $Global:sqlserver = $sqlserver.split("\") | select -First 1
    $Global:Connectionstring = "Data Source=$SQLServerInstance;Initial Catalog=Microsoft.MgmtSvc.Store;Integrated Security = SSPI"

}
else
{
    $Global:SQLServerInstance = $SQLserver
    $Global:instance = "."
    $Global:Connectionstring = "Data Source=$SQLServerInstance;Initial Catalog=Microsoft.MgmtSvc.Store;Integrated Security = SSPI"
   
}

if (!($SQLserver)){Write-Output "SQL Server is needed, exiting";exit}
$SQLsession = New-PSSession -ComputerName $SQLserver

Write-Host "Querying database server $SQLserver"

GetInfo


MainMenu
