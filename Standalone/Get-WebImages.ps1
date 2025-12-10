# script parameters, feel free to change it 
$downloadFolder = "C:\Downloaded Images\"
$searchFor = "funny pictures"
$nrOfImages = 12

# create a WebClient instance that will handle Network communications 
$webClient = New-Object System.Net.WebClient

# load System.Web so we can use HttpUtility
Add-Type -AssemblyName System.Web

# URL encode our search query
$searchQuery = [System.Web.HttpUtility]::UrlEncode($searchFor)

$url = "http://www.bing.com/images/search?q=$searchQuery&first=0&count=$nrOfImages&qft=+filterui%3alicense-L2_L3_L4"

# get the HTML from resulting search response
$webpage = $webclient.DownloadString($url)

# use a 'fancy' regular expression to finds Urls terminating with '.jpg' or '.png'
$regex = "[(http(s)?):\/\/(www\.)?a-z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-z0-9@:%_\+.~#?&//=]*)((.jpg(\/)?)|(.png(\/)?)){1}(?!([\w\/]+))"

$listImgUrls = $webpage | Select-String -pattern $regex -Allmatches | ForEach-Object {$_.Matches} | Select-Object $_.Value -Unique

# let's figure out if the folder we will use to store the downloaded images already exists
if((Test-Path $downloadFolder) -eq $false) 
{
    Write-Output "Creating '$downloadFolder'..."

    New-Item -ItemType Directory -Path $downloadFolder | Out-Null
}


foreach($imgUrlString in $listImgUrls) 

    [Uri]$imgUri = New-Object System.Uri -ArgumentList $imgUrlString

    # this is a way to extract the image name from the Url
    $imgFile = [System.IO.Path]::GetFileName($imgUri.LocalPath)s

    # build the full path to the target download location
    $imgSaveDestination = Join-Path $downloadFolder $imgFile

    Write-Output "Downloading '$imgUrlString' to '$imgSaveDestination'..."

    $webClient.DownloadFile($imgUri, $imgSaveDestination)    
}