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
        LASTEDIT: 13/04/2016
        KEYWORDS: Windows;Server;2008;2008R2;2012;
    .Link
        
    #Requires - Version 3.0
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $False, Position = 1)]
    [String]   $ProfilesPath = ($env:SystemDrive + "\Users"), `
    [Parameter(Mandatory = $False, Position = 2)]
    [String[]] $Extensions = @("*.log","*.dmp","*.tmp","*.hdmp","*.mdmp","*.regtrans-ms","*.htm","*.dat"))
Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $Color, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Bool]           $EndLine)
    Begin {
    }
    Process {
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $Color[$Index] -NoNewLine
        }
        Switch ($EndLine){
            $True  { Write-Host            }
            $False { Write-Host -NoNewline }
        }
    }
}
Function Delete-LastLine {
    Begin {
        $CursorLeft = [System.Console]::CursorLeft
        $CursorTop  = [System.Console]::CursorTop
    }
    Process {
        [System.Console]::SetCursorPosition($CursorLeft ,$CursorTop  - 1)
        Write-Host "                                                                                                                                            "
        [System.Console]::SetCursorPosition($CursorLeft ,$CursorTop  - 1)
    }
}
Function Clean-UserProfiles {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $False, Position = 1)]
        [String]   $ProfilesPath = ($env:SystemDrive + "\Users"), `
        [Parameter(Mandatory = $False, Position = 2)]
        [String[]] $Extensions = @("*.log","*.dmp","*.tmp","*.hdmp","*.mdmp","*.regtrans-ms","*.htm","*.dat"))

    Begin   {
        If ($ProfilesPath -eq ($env:SystemDrive + "\Users")) { 
            Write-Host "Default Profile Path specified. Setting path to " -ForegroundColor Yellow -NoNewline
            Write-Host ($env:SystemDrive + "\Users") -ForegroundColor Red;
        }
        Else {
            Write-Host "Setting path to " -NoNewline
            Write-Host $ProfilesPath -ForegroundColor Green;
        }
        If ($Extensions   -eq @("*.log","*.dmp","*.tmp","*.hdmp","*.mdmp","*.regtrans-ms","*.htm","*.dat")) {    # Need to compare two arrays correctly
            Write-Host "Extensions not specified. Setting default extensions:" -ForegroundColor Yellow
            ForEach ($Extension in $Extensions) { 
                Write-Host $Extension -ForegroundColor Red 
            }
            Write-Host "Total Extensions: " -NoNewline
            Write-Host $Extensions.Count.ToString() -ForegroundColor Green
        }
        Else {
            Write-Host "Extensions specified:"
            ForEach ($Extension in $Extensions) { 
                Write-Host ("  " + $Extension) -ForegroundColor Green 
            }
            Write-Host "Total Extensions: " -NoNewline
            Write-Host $Extensions.Count.ToString() -ForegroundColor Green
        }
    }
    Process {
        $ErrorActionPreference = "Stop"
        Try {
            Write-Host "Getting list of user profiles - " -NoNewline
                $Profiles = (Get-ChildItem $ProfilesPath -Directory).FullName
            Write-Host ($Profiles.Count.ToString() + " Profiles Found") -ForegroundColor Green
        }
        Catch {
            Write-Color -Text "Unable to find any profiles in ", $ProfilesPath, "The default profiles folder for this computer is", ("  " + $env:SystemDrive + "\Users") -Color Red, Yellow, White, Green -EndLine $true
            Break
        }
        $ProfilesDetails = @()
        $ProfileCounter = 1
        ForEach ($Profile in $Profiles) {
            $ProfileDetails = @()
            Write-Color -Text ($ProfileCounter.ToString() + "/" + $Profiles.Count.ToString()), " - Getting Temp files for ", $Profile, " - " -Color Cyan, White, Yellow, White -EndLine $False
                $ExtensionFiles = (Get-ChildItem -Path $Profile -Include $Extensions -Recurse -Force -ErrorAction SilentlyContinue).FullName
                $AppDataFiles   = (Get-ChildItem -Path ($Profile.ToString() + "\AppData\Local\Temp") -Recurse -Force -ErrorAction SilentlyContinue).FullName
                $TempFilesCount = $ExtensionFiles.Length + $AppDataFiles.Length
                $TempFiles = $ExtensionFiles + $AppDataFiles
            Write-Host ($TempFiles.Count.ToString() + " found") -ForegroundColor Green -NoNewline
            If ($TempFiles.Count -gt 0) {
                Write-Host " - Removing - " -NoNewline
                    Try {
                        $Result = Remove-File -TempFiles $TempFiles
                    }
                    Catch {
                        $Result = New-Object PSObject -Property @{
                            AllTempFilesCount     = 0;
                            AllTempFilesSize      = 0;
                            TempFilesRemovedCount = 0;
                            TempFilesRemovedSize  = 0;
                            TempFilesDeniedCount  = 0;
                            TempFilesDeniedSize   = 0;
                        }
                    }
                    $ProfileDetails = $ProfileDetails + $Result
                Write-Host "Complete" -ForegroundColor Green
                $ProfilesDetails = $ProfilesDetails + $ProfileDetails
            }
            Else {
                Write-Host
            }
            $ProfileCounter ++
            Delete-LastLine
        }
        $ProfilesDetails | Select AllTempFilesCount, AllTempFilesSize, TempFilesRemovedCount, TempFilesRemovedSize, TempFilesDeniedCount, TempFilesDeniedSize #| Format-Table -AutoSize
    }
}
Function Remove-File {
    Param(
        [Parameter(Mandatory = $False,  Position = 1)]
        [String[]] $TempFiles)

    $AllTempFilesCount     = 0 # All Temp Files Count
    $AllTempFilesSize      = 0 # All Temp Files Size
    $TempFilesRemovedCount = 0 # Temp Files Removed Count
    $TempFilesRemovedSize  = 0 # Temp Files Removed Size
    $TempFilesDeniedCount  = 0 # Temp Files Denied Count
    $TempFilesDeniedSize   = 0 # Temp Files Denied Size

    ForEach ($TempFile in $TempFiles) {
        Try {
            [Int64] $TempFileSize = "{0:N2}" -f ((Get-ChildItem $TempFile | Measure-Object -Property Length -Sum).Sum / 1MB)
        }
        Catch  {
            $TempFileSize = 0
        }
        Try {
            $AllTempFilesCount ++
            $AllTempFilesSize = $AllTempFilesSize + $TempFileSize

        
            Remove-Item -Path $TempFile -Recurse -Force -Confirm:$False
            $TempFilesRemovedCount ++
            $TempFilesRemovedSize = $TempFilesRemovedSize + $TempFileSize
        }
        Catch {
            If ($TempFileSize -eq $null) { $TempFileSize = 0 }
            $TempFilesDeniedCount ++
            $TempFilesDeniedSize = $TempFilesDeniedSize + $TempFileSize
        }
    }
    $Details = New-Object PSObject -Property @{
        AllTempFilesCount     = $AllTempFilesCount;
        AllTempFilesSize      = $AllTempFilesSize;
        TempFilesRemovedCount = $TempFilesRemovedCount;
        TempFilesRemovedSize  = $TempFilesRemovedSize;
        TempFilesDeniedCount  = $TempFilesDeniedCount;
        TempFilesDeniedSize   = $TempFilesDeniedSize;
    }
    Return $Details
}

Clean-UserProfiles -ProfilesPath $ProfilesPath -Extensions $Ex