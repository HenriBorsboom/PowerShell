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

Function  WebSiteCloudInit{
    # PowerShell script to configure Web Site Clouds
    Import-Module -Name MgmtSvcConfig
    Import-Module -Name Websites

    $WebSiteSettings = @{}
    # Hosting and ResourceMetering database connection strings.
    $WebSiteSettings.Add('hosting',$HostingDBString);
    $WebSiteSettings.Add('resourceMetering',$ResourceMeteringDBString);

    $WebSiteSettings.Add('dnsSuffix',$DNSSuffix);

    # Optional WebPI feed
    $WebSiteSettings.Add('feedUrl',$FeedURL);

    # Admin credentials 
    $WebSiteSettings.Add('adminUserName',$AdminUser);
    $WebSiteSettings.Add('adminPassword',$AdminUserPassword);

    # ManagementServer role settings (REST API)
    $WebSiteSettings.Add('managementServerName',$ManagementServer);
    $WebSiteSettings.Add('cloudAdminUserName',$CloudAdmin);
    $WebSiteSettings.Add('cloudAdminPassword',$CloudAdminPassword);

    # Optional credentials; admin credentials used if any are not specified.
    $WebSiteSettings.Add('managementServerAdminUserName',$ManagementServerAdminServiceAccount);
    $WebSiteSettings.Add('managementServerAdminPassword',$ManagementServerAdminServiceAccountPassword);
    $WebSiteSettings.Add('fileServerAdminUserName',$FileServerAdminServiceAccount);
    $WebSiteSettings.Add('fileServerAdminPassword',$FileServerAdminServiceAccountPassword);
    $WebSiteSettings.Add('frontEndAdminUserName',$FrontEndAdminServiceAccount);
    $WebSiteSettings.Add('frontEndAdminPassword',$FrontEndAdminServiceAccountPassword);
    $WebSiteSettings.Add('publisherAdminUserName',$PublisherAdminServiceAccount);
    $WebSiteSettings.Add('publisherAdminPassword',$PublisherAdminServiceAccountPassword);
    $WebSiteSettings.Add('workerAdminUserName',$WorkerAdminServiceAccount);
    $WebSiteSettings.Add('workerAdminPassword',$WorkerAdminServiceAccountPassword);

    # FileServer role settings (WebSites and Certificates shares)
    $WebSiteSettings.Add('fileServerName','WEBSERVER107');
    $WebSiteSettings.Add('fileServerType','WindowsSingle');
    $WebSiteSettings.Add('fileShareOwnerUserName',$FileShareOwnerServiceAccount);
    $WebSiteSettings.Add('fileShareOwnerPassword',$FileShareOwnerServiceAccountPassword);
    $WebSiteSettings.Add('fileShareUserUserName',$FileShareUserServiceAccount);
    $WebSiteSettings.Add('fileShareUserPassword',$FileShareUserServiceAccountPassword);     

    $WebSiteSettings.Add('centralCertStoreUserName',$CertificateShareUserServiceAccount);
    $WebSiteSettings.Add('centralCertStorePassword',$CertificateShareUserServiceAccountPassword);
    $WebSiteSettings.Add('contentShareUNCPath',$contentShareUNCPath);
    $WebSiteSettings.Add('contentShareLocalPath',$contentShareLocalPath);
    $WebSiteSettings.Add('certificateShareUNCPath',$certificateShareUNCPath);
    $WebSiteSettings.Add('certificateShareLocalPath',$certificateShareLocalPath);
    #$WebSiteSettings.Add('skipManagementServerProvisioning', 'False');
    #$WebSiteSettings.Add('isVMMBased','False');

    $WebSiteSettings
    Write-Host ""
    $Return = Read-Host "Are these settings correct (Y/N)? "
    $Return = $Return.ToLower()
    If ($Return -eq "y" -or $Return -eq "yes")
    {
        Initialize-WebSitesInstance -Settings $WebSiteSettings -Verbose
    }
    Else
    {
        Write-Host "Exit"
        Return
    
    }
    #Initialize-MgmtSvcFeature -Name HostingController -Settings $WebSiteSettings -Verbose
}

Clear-Host
WebSiteCloudInit