#region Variables                                                                                                                                                                                                        #region Variables
    #region Usernames and Password
    $AdminUser = "DOMAIN2\svc-admin"
    $AdminUserPassword = "Hv!Qdm1nP@ssw0rd"
    $CloudAdmin = "hvi-cloudadmin"
    $CloudAdminPassword = "Hv!Cl0ud@dm1nP@ssw0rd"
    $FileServerAdminServiceAccount = "DOMAIN2\svc-web-admin"
    $FileServerAdminServiceAccountPassword = "Hv!W@pw3bP@ssw0rd"
    $FileShareOwnerServiceAccount = "DOMAIN2\svc-web-fso"
    $FileShareOwnerServiceAccountPassword = "Hv!W@pw3bFS0P@ssw0rd"
    $FileShareUserServiceAccount = "DOMAIN2\svc-web-fsu"
    $FileShareUserServiceAccountPassword = "Hv!W@pw3bFSuP@ssw0rd"
    $CertificateShareUserServiceAccount = "DOMAIN2\svc-web-csu"
    $CertificateShareUserServiceAccountPassword = "Hv!W@pw3bCs#P@ssw0rd"
    $ManagementServerAdminServiceAccount = "DOMAIN2\svc-web-mn"
    $ManagementServerAdminServiceAccountPassword = "Hv!W@pw3bMn@Password"
    $PublisherAdminServiceAccount = "DOMAIN2\svc-web-pb"
    $PublisherAdminServiceAccountPassword = "Hv!W@pw3bPbP@ssw0rd"
    $FrontEndAdminServiceAccount = "DOMAIN2\svc-web-fe"
    $FrontEndAdminServiceAccountPassword = "Hv!W@pw3bF3"
    $WorkerAdminServiceAccount = "DOMAIN2\svc-web-ww"
    $WorkerAdminServiceAccountPassword = "Hv!W@pw3bWw"
    #endregion

    #region Databse Settings
    $HostingDBString = 'Data Source=WEBSERVER108;Initial Catalog=Hosting;User ID=sa;Password=Hv!Sq7SerP@ssw0rd'
    $ResourceMeteringDBString = 'Data Source=WEBSERVER108;Initial Catalog=ResourceMetering;User ID=sa;Password=Hv!Sq7SerP@ssw0rd'
    #endregion
    
    #region Share Settings
    $contentShareUNCPath = "\\WEBSERVER107.domain2.local\WebSites"
    $contentShareLocalPath = "D:\Websites"
    $certificateShareUNCPath = "\\WEBSERVER107.domain2.local\Certificates"
    $certificateShareLocalPath = "D:\Websites"
    #endregion
    
    #region Other Settings
    $DNSSuffix = "websites.domain2.local"
    $FeedURL = "http://www.microsoft.com/web/wap/webapplicationlist.xml"
    #endregion

    #region Servers
    $ControllerServer = "WEBSERVER101.domain2.local"
    $ManagementServer = "WEBSERVER102.domain2.local"
    $FrontEndServer = "WEBSERVER103.domain2.local"
    $SharedWorkerServer = "WEBSERVER104.domain2.local"
    $ReservedMediumWorkerServer = "WEBSERVER105.domain2.local"
    $PublisherServer = "WEBSERVER106.domain2.local"
    $FileServer = "WEBSERVER107.domain2.local"
    $DatabaseServer = "WEBSERVER108.domain2.local"
    #endregion

#endregion

Function ConfigureWebSitesExtension
{
    Import-Module -Name MgmtSvcConfig
    Import-Module -Name Websites
    $ExtensionSettings = @{}

    $ExtensionSettings.Add("hosting",$HostingDBString);
    $ExtensionSettings.Add("resourceMetering",$ResourceMeteringDBString);
    $ExtensionSettings.Add("managementServerAdminUserName",$ManagementServerAdminServiceAccount);
    $ExtensionSettings.Add("managementServerAdminPassword",$ManagementServerAdminServiceAccountPassword);
    $ExtensionSettings.Add("fileServerAdminUserName",$FileServerAdminServiceAccount);
    $ExtensionSettings.Add("fileServerAdminPassword",$FileServerAdminServiceAccountPassword);
    $ExtensionSettings.Add("frontEndAdminUserName",$FrontEndAdminServiceAccount);
    $ExtensionSettings.Add("frontEndAdminPassword",$FrontEndAdminServiceAccountPassword);
    $ExtensionSettings.Add("publisherAdminUserName",$PublisherAdminServiceAccount);
    $ExtensionSettings.Add("publisherAdminPassword",$PublisherAdminServiceAccountPassword);
    $ExtensionSettings.Add("workerAdminUserName",$WorkerAdminServiceAccount);
    $ExtensionSettings.Add("workerAdminPassword",$WorkerAdminServiceAccountPassword);
    $ExtensionSettings.Add("adminUserName",$AdminUser);
    $ExtensionSettings.Add("adminPassword",$AdminUserPassword);
    $ExtensionSettings.Add("dnsSuffix",$DNSSuffix);
    $ExtensionSettings.Add("managementServerName",$ManagementServer);
    $ExtensionSettings.Add("fileServerName",$FileServer);
    $ExtensionSettings.Add("fileServerType","WindowsSingle");
    $ExtensionSettings.Add("fileShareOwnerUserName",$FileShareOwnerServiceAccount);
    $ExtensionSettings.Add("fileShareOwnerPassword",$FileShareOwnerServiceAccountPassword);
    $ExtensionSettings.Add("fileShareUserUserName",$FileShareUserServiceAccount);
    $ExtensionSettings.Add("fileShareUserPassword",$FileShareUserServiceAccountPassword);
    $ExtensionSettings.Add("cloudAdminUserName",$CloudAdmin);
    $ExtensionSettings.Add("cloudAdminPassword",$CloudAdminPassword);
    $ExtensionSettings.Add("centralCertStoreUserName",$CertificateShareUserServiceAccount);
    $ExtensionSettings.Add("centralCertStorePassword",$CertificateShareUserServiceAccountPassword);
    $ExtensionSettings.Add("contentShareUNCPath",$contentShareUNCPath);
    $ExtensionSettings.Add("contentShareLocalPath",$contentShareLocalPath);
    $ExtensionSettings.Add("certificateShareUNCPath",$certificateShareUNCPath);
    $ExtensionSettings.Add("certificateShareLocalPath",$certificateShareLocalPath);
    $ExtensionSettings.Add("feedUrl",$FeedURL);
    $ExtensionSettings.Add("customFeeds",$FeedURL);
    $ExtensionSettings.Add("SQMEnabled","False");
    $ExtensionSettings.Add("MicrosoftUpdateEnabled","True");

    $settings
    Write-Host ""
    $Return = Read-Host "Are these settings correct (Y/N)? "
    $Return = $Return.ToLower()
    If ($Return -eq "y" -or $Return -eq "yes")
    {
        Initialize-WebSitesExtension -Settings $controllerInitializationSettings -Verbose
    }
    Else
    {
        Write-Host "Exit"
        Return
    
    }
}