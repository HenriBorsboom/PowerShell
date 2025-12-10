#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# By executing this script, you acknowledge that you are getting this software from the respective providers individually and that theirlegal terms apply to it. 
# Microsoft does not provide rights for third-party software.
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Sample Input
#.\offlinewebappgalleryv2.ps1 -webPiFeedUri "http://www.microsoft.com/web/webpi/4.6/webproductlist.xml" -webAppGalleryFeedUri "http://www.microsoft.com/web/wap/webapplicationlist.xml" -offlineLocation "E:\offlinewebpi"


Param(
	[System.Uri]$webPiFeedUri, 
	[System.Uri]$webAppGalleryFeedUri,
    [string] $offlineLocation
)

#======================================== Read Feeds ===========================================================================

[xml]$webPiFeedUriXml = (New-Object System.Net.WebClient).DownloadString($webPiFeedUri)
[xml]$webAppGalleryFeedUriXml = (New-Object System.Net.WebClient).DownloadString($webAppGalleryFeedUri)

#======================================== Remove reference to WebPI Web Application Gallery ====================================
$links = $webPiFeedUriXml.feed.link | Where-Object {$_.href -eq "https://www.microsoft.com/web/webpi/4.6/webapplicationlist.xml"} `
    | %{$_.href = [string]$webAppGalleryFeedUri}

#======================================== Saving temporary Feeds================================================================
$tempDir = "$env:temp\webPIoffline-"+(Get-Date).ToString("yyyy-MM-dd-HH-mm-ss-ffff")
New-Item $tempDir -type directory -Force |Out-Null
$tempWebPiFile = "$tempdir\webproductlist.xml"
$webPiFeedUriXml.Save($tempWebPiFile)

#======================================== Getting Product Ids from Feed ========================================================
$productids = $webAppGalleryFeedUriXml.feed.entry.productid
$list = [string]::Join(',',$productids)

#======================================== Offlining Web Application Gallery items ==============================================
& "C:\Program Files\Microsoft\Web Platform Installer\WebpiCmd.exe" /Offline /XML:$tempWebPiFile /Path:$offlineLocation /Products:$list #/UpdateAll

#======================================== Clean Up =============================================================================
Write-Host "Cleaning up temp files....."
Remove-Item $tempDir -Force -Recurse

#======================================== Display Feed Location =================================================================
Write-Host "Your feeds have been offlined to  "-nonewline; Write-Host "$offlineLocation" -foregroundcolor Cyan `
    -nonewline; 

Invoke-Item $offlineLocation\feeds\latest
