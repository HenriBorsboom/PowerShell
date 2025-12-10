Clear-Host
$ProfilesPath = 'C:\Users'
$Extensions = @("*.log","*.dmp","*.tmp","*.hdmp","*.mdmp","*.regtrans-ms")
$FullReportDetails = @()
$Profiles = Get-ChildItem $ProfilesPath -Force | Where-Object {$_.Mode -match "d"}
For ($i = 0; $i -lt $Profiles.Count; $i ++) {
    $ProfileReportDetails = @()
    $Files = Get-ChildItem $Profiles[$i].FullName -Recurse -Force -Include $Extensions -ErrorAction SilentlyContinue 
    ForEach ($TempFile in $Files) {
        Try   {
            Remove-Item $TempFile.Fullname -Recurse -ErrorAction Stop | Out-Host
            $ProfileReportDetails += , ( New-Object -TypeName PSObject -Property @{
                FileName   = $TempFile.Name
                FilePath   = $TempFile.FullName
                FileSizeMB = ([Math]::Round((($TempFile.Length) / 1024 / 1024),2))
                Action     = 'Removed'
                Error      = '' 
            })
        }
        Catch {
            $ProfileReportDetails += , ( New-Object -TypeName PSObject -Property @{
                FileName   = $TempFile.Name
                FilePath   = $TempFile.FullName
                FileSizeMB = ([Math]::Round((($TempFile.Length) / 1024 / 1024),2))
                Action     = 'Failed'
                Error      = $_.Exception.Message
            })
        }
    }    

    $FullReportDetails += ,( New-Object -TypeName PSObject -Property @{
        Profile = $Profiles[$i]
        FilesFound = $Files.Count
        TotalClearedMB = (($ProfileReportDetails | Where Action -ne 'Failed' ) | Measure-Object -Property FileSizeMB -Sum).Sum
        TotalRemainingMB = (($ProfileReportDetails | Where Action -eq 'Failed' ) | Measure-Object -Property FileSizeMB -Sum).Sum
        TotalSizeMB = ([Math]::Round(((($Files  | Measure-Object -Property Length -Sum).SUM) / 1024 / 1024),2))
        DetailReport = $ProfileReportDetails
    })
}

<#
$TempFolderFullPath = $Profile.FullName + "\AppData\Local\Temp"
Write-Color -Text "|- Profiles: ", $ProfilesCount, "/", $Profiles.Count, " - Temporary Folder: ", $TempFolderFullPath.ToUpper(), " - " -ForegroundColor White, Cyan, White, Cyan, White, Cyan, White -NoNewLine
Try {
    $TempFiles = Get-ChildItem $TempFolderFullPath -Recurse -Force -ErrorAction SilentlyContinue
    If ($TempFiles -ne $null) {
        ForEach ($TempFile in $TempFiles) {
            $TempFileFullPath = $Profile.FullName + "\" + $TempFile
            [Int64] $TempFileSize = 0
            Try   {                                                                
                $FileDetails = Get-ChildItem $TempFileFullPath -ErrorAction Stop
                $TempFileSize = $FileDetails.Length
            } # Get Temp File's Size
            Catch {
                $TempFileSize = 0
                $InaccessibleFiles ++
            }
            Try   {
                $empty = Remove-Item $TempFileFullPath -Recurse -ErrorAction Stop 
                $FilesRemoved ++
                $SpaceSaved = $SpaceSaved + $TempFileSize
            } # Remove File
            Catch {
                $FilesNotRemoved ++
                $SpaceNotSaved = $SpaceNotSaved + $TempFileSize
            }
        }
    }
    #Write-Color -Complete
    #Write-Host "Done" -ForegroundColor Green
    $ProfileTotalTempFiles = $ProfileTotalTempFiles + $TempFiles.Count
}
Catch {
    #Write-Color -Text "Failed! ", $_ -ForegroundColor Red, Red
    #Write-Host "Failed - Temp" -ForegroundColor Red
}
#>


$FullReportDetails | Ft -Autosize