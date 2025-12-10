Clear-Host

[String]   $ProfilesPath = 'C:\Users'
[String[]] $Extensions = @("*.log","*.dmp","*.tmp","*.hdmp","*.mdmp","*.regtrans-ms","*.htm","*.dat")
    $ReportDetails = @()
    $FailedFiles = @()
	Try {
			$Profiles = Get-ChildItem $ProfilesPath -Force | Where-Object {$_.Mode -match "d"} -ErrorAction Stop
	}
	Catch {
	}

    [Int64] $ExtensionsCount = 1
    [Int64] $ProfilesCount = 1

    [Int64] $GrandTotalFiles = 0
    [Int64] $GrandTotalFilesRemoved = 0
    [Int64] $GrandTotalFilesNotRemoved = 0
    [Int64] $GrandTotalSpaceSaved = 0
    [Int64] $GrandTotalSpaceNotSaved = 0
    [Int64] $GrandTotalInaccessibleFiles = 0

    #ForEach ($Profile in $Profiles) {
    For ($i = 0; $i -lt $Profiles.Count; $i ++) {
        Write-Host $Profiles[$i].Fullname
        [Int64] $ProfileTotalTempFiles = 0
        [Int64] $FilesRemoved = 0
        [Int64] $FilesNotRemoved = 0
        [Int64] $SpaceSaved = 0
        [Int64] $SpaceNotSaved = 0
        [Int64] $InaccessibleFiles = 0
        #ForEach ($Extension in $Extensions) {
            Try {
                $TempFiles = Get-ChildItem $Profiles[$i].FullName -Recurse -Include $Extensions -ErrorAction SilentlyContinue
                If ($TempFiles -ne $null) {
                    ForEach ($TempFile in $TempFiles) {
                        Try   {                                                                
                            $FileDetails = Get-ChildItem $TempFile.Fullname -ErrorAction Stop
                            $TempFileSize = $TempFile.Length
                        }
                        Catch {
                            $TempFileSize = 0
                            $InaccessibleFiles ++
                        }
                        Try   {
                            Remove-Item $TempFile.Fullname -Recurse -ErrorAction Stop | Out-Null
                            $FilesRemoved ++
                            $SpaceSaved = $SpaceSaved + $TempFileSize
                            $ReportDetails += ,(New-Object -TypeName PSObject -Property @{
                                Profile      = $Profile
                                FileName     = $TempFile.FullName
                                FileSize     = $TempFile.Length
                            })
                        }
                        Catch {
                            $FilesNotRemoved ++
                            $SpaceNotSaved = $SpaceNotSaved + $TempFileSize
                            $FailedFiles += ,(New-Object -TypeName PSObject -Property @{
                                Profile      = $Profile
                                FileName     = $TempFile.FullName
                                Error        = $_
                            })
                        }
                    }
                }
                $ProfileTotalTempFiles = $ProfileTotalTempFiles + $TempFiles.Count
            }
            Catch {
            }
            $ExtensionsCount ++
        #}
        $ExtensionsCount = 1

        $TempFolderFullPath = $Profiles[$i].FullName + "\AppData\Local\Temp"
        Try {
            $TempFiles = Get-ChildItem $TempFolderFullPath -Recurse -Force -ErrorAction SilentlyContinue
            If ($TempFiles -ne $null) {
                ForEach ($TempFile in $TempFiles) {
                    [Int64] $TempFileSize = 0
                    Try   {                                                                
                        $FileDetails = Get-ChildItem $TempFile.Fullname -ErrorAction Stop
                        $TempFileSize = $FileDetails.Length
                    }
                    Catch {
                        $TempFileSize = 0
                        $InaccessibleFiles ++
                    }
                    Try   {
                        Remove-Item $TempFile.Fullname -Recurse -ErrorAction Stop | Out-Null
                        $FilesRemoved ++
                        $SpaceSaved = $SpaceSaved + $TempFileSize
                    }
                    Catch {
                        $FilesNotRemoved ++
                        $SpaceNotSaved = $SpaceNotSaved + $TempFileSize
                    }
                }
            }
            $ProfileTotalTempFiles = $ProfileTotalTempFiles + $TempFiles.Count
        }
        Catch {
        }

		$GrandTotalFiles = $GrandTotalFiles + $ProfileTotalTempFiles
        $GrandTotalFilesRemoved = $GrandTotalFilesRemoved + $FilesRemoved
        $GrandTotalFilesNotRemoved = $GrandTotalFilesNotRemoved + $FilesNotRemoved
        $GrandTotalInaccessibleFiles = $GrandTotalInaccessibleFiles + $InaccessibleFiles
        $GrandTotalSpaceSaved = $GrandTotalSpaceSaved + $SpaceSaved
        $GrandTotalSpaceNotSaved = $GrandTotalSpaceNotSaved + $SpaceNotSaved
    }

    #$ReportDetails | Select Profile, FileName, FileSize | Format-Table -AutoSize
    $ReportDetails | Select Profile, FileName, FileSize | Export-Csv ($env:temp + "\clean.csv") -Force -NoTypeInformation -Delimiter ","
    #$FailedFiles | Select Profile, Error | Format-Table -AutoSize
    $FailedFiles | Select Profile, Error | Export-Csv ($env:temp + "\Failed.csv") -Force -NoTypeInformation -Delimiter ","
    $ReportDetails
    $FailedFiles