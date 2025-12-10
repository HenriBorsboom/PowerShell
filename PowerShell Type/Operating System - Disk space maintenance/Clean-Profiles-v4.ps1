<#
    .Synopsis
        Clean the Users Profile folder and sub folders of temporary files
    .Description
        Cleans the Users Profiles folders and sub folders of temporary files that are
        using diskspace
    .Example
        Clean-Profiles -ProfilesPath "C:\Users" -Extensions "*.tmp","*.log","*.dmp"
        Cleans the supplied folder and subfolders of temporary files as well as the
        supplied extension files
    .Example
        Clean-Profiles -ProfilesPath "C:\Users"
        Cleans the supplied folder and subfolders of temporary files
    .Parameter ProfilesPath
        The path of where the users profiles are stored
    .Inputs
        [String]
    .OutPuts
        [String]
    .Notes
        NAME:  Clean-Profiles
        AUTHOR: Henri Borsboom
        LASTEDIT: 09/07/2015
        KEYWORDS: Windows;Server;2008;2008R2;2012;
    .Link
        https://www.linkedin.com/pulse/powershell-applying-wsus-patches-offline-vhdx-image-henri-borsboom
    #Requires - Version 3.0
#>
Param (
    [Parameter(Mandatory=$false,Position=1)]
    [String] $ProfilesPath, `
    [Parameter(Mandatory=$false,Position=2)]
    [String[]] $Extensions)
Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]] $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $Color, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch] $EndLine)
    
    For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
        Write-Host $Text[$Index] -Foreground $Color[$Index] -NoNewLine
    }
    Switch ($EndLine){
        $True  { Write-Host            }
        $False { Write-Host -NoNewline }
    }
}
Function Delete-LastLine {
    $CursorLeft = [System.Console]::CursorLeft
    $CursorTop  = [System.Console]::CursorTop
    [System.Console]::SetCursorPosition($CursorLeft ,$CursorTop  - 1)
    Write-Host "                                                                                                                                            "
    [System.Console]::SetCursorPosition($CursorLeft ,$CursorTop  - 1)
}

#region 0. Check Profile Path
    If ($ProfilesPath -eq $null -or $ProfilesPath -eq "") {
        Write-Color -Text "Profile Path not specified. Setting path to ", "C:\Users" -Color Red, Yellow -EndLine:$true
        $ProfilesPath -eq "C:\Users"
    }
#endregion

#region 1. Set Extensions to search and remove
Write-Host "1. Checking for supplied extentions - " -NoNewline

If ($Extensions -eq $null -or $Extensions -eq "") {
    Write-Host "Not found" -ForegroundColor Yellow
    Write-Host "|- Setting defaults"
    $Extensions = @("*.log","*.dmp","*.tmp","*.hdmp","*.mdmp","*.regtrans-ms","*.htm","*.dat")
    ForEach ($Extension in $Extensions) {
        Write-Color -Text "|-- ", $Extension -Color White, Red -EndLine:$true
    }
}
Else {
    Write-Host "Complete" -ForegroundColor Green
    Write-Host "|- Adding the following extensions: "
    ForEach ($Extension in $Extensions) {
        Write-Color -Text "|-- ", $Extension -Color White, Magenta -EndLine:$true
    }
}
#endregion

#region 2. Get List of User Profiles - Obtains $Profiles as the reference List ($Profiles.Name)
    Try {
        Write-Color -Text "2. Obtaining list of User profiles from ", $ProfilesPath.ToUpper(), " - " -Color White, Cyan, White
            $Profiles = Get-ChildItem $ProfilesPath -Force | Where-Object {$_.Mode -match "d"} -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host "Confirm that the supplied path exists and that you have Read/Write permission"
        Write-Host "The supplied path must be in the format of <Drive Letter>:\<Path>"
        Write-Host "The path must be WITHOUT the ending backslash < \ >"
        Write-Host "For example: C:\Users"
    }
#endregion

#region 3. Delete Extensions from User Profiles Folder
Write-Host "3. Obtaining list of files from Profiles"
Write-Color "|- Total Profiles: ", $Profiles.Count -Color White, Cyan -EndLine:$true
Write-Color "|- Total Extensions: ", $Extensions.Count -Color White, Cyan -EndLine:$true

[Int64] $ExtensionsCount = 1
[Int64] $ProfilesCount = 1

[Int64] $GrandTotalFiles = 0
[Int64] $GrandTotalFilesRemoved = 0
[Int64] $GrandTotalFilesNotRemoved = 0
[Int64] $GrandTotalSpaceSaved = 0
[Int64] $GrandTotalSpaceNotSaved = 0
[Int64] $GrandTotalInaccessibleFiles = 0

    #region Process Profiles
ForEach ($Profile in $Profiles) {
    [Int64] $ProfileTotalTempFiles = 0
    [Int64] $FilesRemoved = 0
    [Int64] $FilesNotRemoved = 0
    [Int64] $SpaceSaved = 0
    [Int64] $SpaceNotSaved = 0
    [Int64] $InaccessibleFiles = 0

    #region Process Profiles - Extensions
    ForEach ($Extension in $Extensions) {
        Write-Color -Text "|- Profiles: ", $ProfilesCount, "/", $Profiles.Count, " - Extensions: ", $ExtensionsCount, "/", $Extensions.Count, " - ", $Profile.Name.ToUpper(), " - " -Color White, Cyan, White, Cyan, White, Cyan, White, Cyan, White, Cyan, White
        Try {
            $TempFiles = Get-ChildItem $Profile.FullName -Recurse -Name $Extension -Force -ErrorAction Stop
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
                        If ($Extension -eq "*.hdmp" -or $Extension -eq "*.mdmp" -or $Extension -eq "*.regtrans-ms" -or $Extension -eq "*.htm") {
                            $empty = Remove-Item $TempFileFullPath -Recurse -Force -ErrorAction Stop 
                        }
                        Else {
                            If ($TempFileFullPath -like "\AppData\*" -and $TempFileFullPath -like "dat") {
                                $empty = Remove-Item $TempFileFullPath -Recurse -ErrorAction Stop
                            }
                            ElseIf ($TempFileFullPath -notlike "\AppData\*" -and $TempFileFullPath -like "dat") { }
                            Else { $empty = Remove-Item $TempFileFullPath -Recurse -ErrorAction Stop }
                        }
                        $FilesRemoved ++
                        $SpaceSaved = $SpaceSaved + $TempFileSize
                    } # Remove File
                    Catch {
                        $FilesNotRemoved ++
                        $SpaceNotSaved = $SpaceNotSaved + $TempFileSize
                    }
                }
            }
            Write-Host "Done" -ForegroundColor Green
            $ProfileTotalTempFiles = $ProfileTotalTempFiles + $TempFiles.Count
            Delete-LastLine
        }
        Catch {
            Write-Host "Failed - $Extension" -ForegroundColor Red
        }
        $ExtensionsCount ++
    }
    $ExtensionsCount = 1
    #endregion

    #region Temp Folder
    $TempFolderFullPath = $Profile.FullName + "\AppData\Local\Temp"
    Write-Color -Text "|- Profiles: ", $ProfilesCount, "/", $Profiles.Count, " - Temporary Folder: ", $TempFolderFullPath.ToUpper(), " - " -Color White, Cyan, White, Cyan, White, Cyan, White
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
        Write-Host "Done" -ForegroundColor Green
        $ProfileTotalTempFiles = $ProfileTotalTempFiles + $TempFiles.Count
    }
    Catch {
        Write-Host "Failed - Temp" -ForegroundColor Red
    }
    #endregion
    
    #region Profile Report
    $GrandTotalFiles = $GrandTotalFiles + $ProfileTotalTempFiles
    $GrandTotalFilesRemoved = $GrandTotalFilesRemoved + $FilesRemoved
    $GrandTotalFilesNotRemoved = $GrandTotalFilesNotRemoved + $FilesNotRemoved
    $GrandTotalInaccessibleFiles = $GrandTotalInaccessibleFiles + $InaccessibleFiles
    $GrandTotalSpaceSaved = $GrandTotalSpaceSaved + $SpaceSaved
    $GrandTotalSpaceNotSaved = $GrandTotalSpaceNotSaved + $SpaceNotSaved
    
    #region Removed Per Profile Reporting
    #Write-Color -Text "|-- Total files found:          ", $ProfileTotalTempFiles -Color White, Yellow -EndLine:$true
    #Write-Color -Text "|-- Total files removed:        ", $FilesRemoved -Color White, Yellow -EndLine:$true
    #Write-Color -Text "|-- Total files not removed:    ", $FilesNotRemoved -Color White, Yellow -EndLine:$true
    #Write-Color -Text "|-- Total inaccessible Files:   ", $InaccessibleFiles -Color White, Yellow -EndLine:$true
    #Write-Color -Text "|-- Total space saved (MB):     ", ([Math]::Round(($SpaceSaved / 1024 / 1024),2)) -Color White, Yellow -EndLine:$true
    #Write-Color -Text "|-- Total space not saved (MB): ", ([Math]::Round(($SpaceNotSaved / 1024 / 1024),2)) -Color White, Yellow -EndLine:$true
    #Write-Host ""
    Delete-LastLine
    $ProfilesCount ++
    #endregion
    #endregion
}
    #endregion
#endregion

#region 4. Extensions Removed Reporting
    Write-Host ""
    Write-Host        "------------------------------------------- Report"
    Write-Color -Text "Total Files found from All Profiles:       ", $GrandTotalFiles -Color White, Green -EndLine:$true
    Write-Color -Text "Total Files removed from All Profiles:     ", $GrandTotalFilesRemoved -Color White, Green -EndLine:$true
    Write-Color -Text "Total Files not removed from All Profiles: ", $GrandTotalFilesNotRemoved -Color White, Green -EndLine:$true
    Write-Color -Text "Total Inaccessible files in All Profiles:  ", $GrandTotalInaccessibleFiles -Color White, Green -EndLine:$true
    Write-Color -Text "Total Space saved from All Profiles (MB):  ", ([Math]::Round(($GrandTotalSpaceSaved / 1024 / 1024),2)) -Color White, Green -EndLine:$true
    Write-Color -Text "Total Space Not from All Profiles (MB):    ", ([Math]::Round(($GrandTotalSpaceNotSaved / 1024 / 1024),2)) -Color White, Green -EndLine:$true
#endregion