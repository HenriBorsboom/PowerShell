$GrandTotal = 10
$Total = 50
For ($i = 0; $i -lt $GrandTotal; $i ++) {
    Write-Progress -PercentComplete (($i + 1) / $GrandTotal * 100) -Activity ('Copying Reports - ' + (($i + 1) / $GrandTotal * 100) + '%') -Id 1 #-Status "copying folders"
    For ($x = 0; $x -lt $Total; $x ++) {
        Write-Progress -PercentComplete (($x + 1)/ $Total * 100) -Activity ('Copying Files - ' + (($x + 1)/ $Total * 100) + '%') -ParentId 1 -Status "copying files"
        Start-Sleep -Milliseconds 50
    }
}