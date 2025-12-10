$ErrorActionPreference = "SilentlyContinue"
$startFolder = "C:\"
Write-Host "Getting folders in " -NoNewline
Write-Host $startFolder -ForegroundColor Yellow -NoNewline
Write-Host " - " -NoNewline
    $colItems = (Get-ChildItem $startFolder -recurse | Where-Object {$_.PSIsContainer -eq $True} | Sort-Object)
    #$EmptyFolders = @()
Write-Host "Complete" -ForegroundColor Green
foreach ($i in $colItems)
    {
        $subFolderItems = (Get-ChildItem $i.FullName | Measure-Object -property length -sum)
        $Result = "{0:N2}" -f ($subFolderItems.sum / 1MB)
        #$Result.GetType()
        #Break
        $Output = $i.FullName + ";" + $Result
        $Output | Export-CSV C:\temp\foldersize.csv -Append -Delimiter ";" -NoTypeInformation
        $Output
        #If ($Result -eq "0,00") {
        #    $EmptyFolders = $EmptyFolders + $i.FullName
        #    }
        #Else {}
    }
#$EmptyFolders | Out-File C:\temp\EmptyFolders.TXT -Encoding ascii -Force
#Notepad C:\temp\EmptyFolders.TXT