#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# By executing this script, you acknowledge that you are getting this software from the respective providers individually and that theirlegal terms apply to it. 
# Microsoft does not provide rights for third-party software.
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Sample Input
#.\ModifyOfflinedFeeds.ps1 -offlineWebPIFeed "E:\offlinewebpi\feeds\latest\webproductlist.xml" -offlineWebApplicationFeed "E:\offlinewebpi\feeds\latest\supplementalfeeds\webapplicationlist.xml" -server "http://myservername/offlinewebpi/"

Param(
	[string]$offlineWebPIFeed, 
	[string]$offlineWebApplicationFeed, 
	[string]$server
)

#==================================Manipulating Webproductlist.xml========================================================================

[xml] $myWebPiFile =Get-Content($offlineWebPIFeed) | %{$_.Replace("../../", $server)}
$newLink = $server+"feeds/latest/supplementalfeeds/webapplicationlist.xml"

    #Converting reference to webapplicationlist to absolute URL
    $myWebPiFile.feed.link | Where-Object {$_.relativeHref -eq "supplementalfeeds/webapplicationlist.xml"} `
        | %{$_.SetAttribute("href",$newLink); $_.RemoveAttribute("relativeHref")}

    #Moving value from relativeIconUrl to Icon and removing relativeIconUrl
    $myWebPiFile.feed.entry.images | %{ 
        if($_.icon -eq "" -and $_.relativeIconUrl -ne $null) {$_.icon = $_.relativeIconUrl; `
            $_.RemoveChild($_['relativeIconUrl'])}}

    #Moving value from relativeInstallerUrl to installerUrl and removing relativeIconUrl
    $myWebPiFile.feed.entry.installers.installer.installerFile | %{ 
        if($_.installerURL -eq "" -and $_.relativeInstallerURL -ne $null) {$_.installerURL = $_.relativeInstallerURL; `
            $_.RemoveChild($_['relativeInstallerURL'])}}



#==================================Manipulating Webapplicationlist.xml========================================================================

[xml] $myWebApplicationFile =Get-Content($offlineWebApplicationFeed) | %{$_.Replace("../../../", $server)}

    #Moving value from relativeIconUrl to Icon and removing relativeIconUrl
    $myWebApplicationFile.feed.entry.images | %{ 
        if($_.icon -eq "" -and $_.relativeIconUrl -ne $null) {$_.icon = $_.relativeIconUrl; `
            $_.RemoveChild($_['relativeIconUrl'])}}

    #Moving value from relativeInstallerUrl to installerUrl and removing relativeIconUrl
    $myWebApplicationFile.feed.entry.installers.installer.installerFile | %{ 
        if($_.installerURL -eq "" -and $_.relativeInstallerURL -ne $null) {$_.installerURL = $_.relativeInstallerURL; `
            $_.RemoveChild($_['relativeInstallerURL'])}}



#==================================Save files========================================================================================================

$myWebPiFile.Save($offlineWebPIFeed)
$myWebApplicationFile.Save($offlineWebApplicationFeed)


