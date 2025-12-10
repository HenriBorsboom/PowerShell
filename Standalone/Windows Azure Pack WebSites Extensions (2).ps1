#region Variables
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

$Settings,@{}

$Settings.Add("hosting",$HostingDBString);
$Settings.Add("resourceMetering",$ResourceMeteringDBString);
$Settings.Add("managementServerAdminUserName",$ManagementServerAdminServiceAccount);
$Settings.Add("managementServerAdminPassword",$ManagementServerAdminServiceAccountPassword);
$Settings.Add("fileServerAdminUserName",$FileServerAdminServiceAccount);
$Settings.Add("fileServerAdminPassword",$FileServerAdminServiceAccountPassword);
$Settings.Add("frontEndAdminUserName",$FrontEndAdminServiceAccount);
$Settings.Add("frontEndAdminPassword",$FrontEndAdminServiceAccountPassword);
$Settings.Add("publisherAdminUserName",$PublisherAdminServiceAccount);
$Settings.Add("publisherAdminPassword",$PublisherAdminServiceAccountPassword);
$Settings.Add("workerAdminUserName",$WorkerAdminServiceAccount);
$Settings.Add("workerAdminPassword",$WorkerAdminServiceAccountPassword);
$Settings.Add("adminUserName",$AdminUser);
$Settings.Add("adminPassword",$AdminUserPassword);
$Settings.Add("dnsSuffix",$DNSSuffix);
$Settings.Add("managementServerName",$ManagementServer);
$Settings.Add("fileServerName",$FileServer);
$Settings.Add("fileServerType","WindowsSingle");
$Settings.Add("fileShareOwnerUserName",$FileShareOwnerServiceAccount);
$Settings.Add("fileShareOwnerPassword",$FileShareOwnerServiceAccountPassword);
$Settings.Add("fileShareUserUserName",$FileShareUserServiceAccount);
$Settings.Add("fileShareUserPassword",$FileShareUserServiceAccountPassword);
$Settings.Add("cloudAdminUserName",$CloudAdmin);
$Settings.Add("cloudAdminPassword",$CloudAdminPassword);
$Settings.Add("centralCertStoreUserName",$CertificateShareUserServiceAccount);
$Settings.Add("centralCertStorePassword",$CertificateShareUserServiceAccountPassword);
$Settings.Add("contentShareUNCPath",$contentShareUNCPath);
$Settings.Add("contentShareLocalPath",$contentShareLocalPath);
$Settings.Add("certificateShareUNCPath",$certificateShareUNCPath);
$Settings.Add("certificateShareLocalPath",$certificateShareLocalPath);
$Settings.Add("feedUrl",$FeedURL);
$Settings.Add("customFeeds",$FeedURL);
$Settings.Add("SQMEnabled","False");
$Settings.Add("MicrosoftUpdateEnabled","True");

Initialize-WebSitesExtension -Settings $controllerInitializationSettings -Verbose