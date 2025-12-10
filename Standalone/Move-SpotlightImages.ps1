#copy all of the  items from today to C:\temp\Spotlight
Get-ChildItem $env:userprofile\AppData\Local\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets | `
ForEach {
    $image = [System.Drawing.Image]::FromFile($_.FullName)
    if (($image.width -gt "1900") -and ($_.LastWriteTime -gt (get-date).ToShortDateString() )) {Copy-Item $_.FullName C:\temp\Spotlight -ErrorAction SilentlyContinue; $TotalCopied ++}
}

#rename all of the files
Get-ChildItem C:\temp\Spotlight -Exclude "Older" | `
ForEach {
    $newname = $_.FullName + ".jpg"
    Rename-Item $_.FullName -NewName $newname  -ErrorAction SilentlyContinue
}

#move all of the older files
Get-ChildItem  C:\temp\Spotlight -Exclude "Older" | `
ForEach {
    Ff ($_.LastWriteTime -lt (get-date).ToShortDateString() ) {
        Move-Item $_.FullName C:\temp\Spotlight\older  -ErrorAction SilentlyContinue
        $TotalMoved ++
    }
}

Write-Host -ForegroundColor Yellow a Total of $TotalCopied new images were copied
Write-Host -ForegroundColor Yellow a Total of $TotalMoved imaged were moved into the ""older"" folder  