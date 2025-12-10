<#
    .Synopsis
        Clean the Users Profile folder and sub folders of temporary files
    .Description
        Cleans the Users Profiles folders and sub folders of temporary files that are
        using diskspace
    .Example
        Clean-Profiles -ProfilesPath "C:\Users"
        Cleans the supplied folder from temporary files
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
$ProfilesPath = "c:\users"
#Param (
#    [Parameter(Mandatory=$true,Position=1)]
#    [String] $ProfilesPath, `
#    [Parameter(Mandatory=$false,Position=1)]
#    [Array] $Extensions)
Function Write-Color {
    Param(
        [String[]] $Text, `
        [ConsoleColor[]] $Color, `
        [bool] $EndLine)
    
    If ($Text.Count -ne $Color.Length) {
        Write-Host "DEBUG"
        Write-Host "DEBUG"
        Write-Host "DEBUG"
        Write-Host "DEBUG"
        Break
    }
    Else {
        Write-Host "SUCCESS"
        Break
    }


    For ($i = 0; $i -lt $Text.Length; $i++) {
        Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
    }
    Switch ($EndLine){
        $true {Write-Host}
        $false {Write-Host -NoNewline}
    }
}

#region 1. Set Extensions to search and remove
Write-Host "1. Checking for supplied extentions - " -NoNewline

If ($Extensions -eq $null -or $Extensions -eq "") {
    Write-Host "Not found" -ForegroundColor Yellow
    Write-Host "|- Setting defaults"
    $Extensions = @("*.log","*.DB","*.dmp")
    ForEach ($Extension in $Extensions) {
        Write-Color -Text "|-- ", $Extension -Color White, Magenta, White -EndLine $true
    }
}
Else {
    Write-Host "Complete" -ForegroundColor Green
    Write-Host "|- Adding the following extensions: "
    ForEach ($Extension in $Extensions) {
        Write-Color -Text "|-- ", $Extension -Color White, Magenta -EndLine $true
    }
}
#endregion

#region 2. Get List of User Profiles - Obtains $Profiles as the reference List ($Profiles.Name)
    Try {
        Write-Color -Text "2. Obtaining lit of User profiles from ", $ProfilesPath.ToUpper(), " - " -Color White, Magenta, White
            $Profiles = Get-ChildItem $ProfilesPath | Where-Object {$_.Mode -match "d"} -ErrorAction Stop
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
Write-Host "|- Total Profiles:" $Profiles.Count
Write-Host "|- Total Extensions:" $Extensions.Count
[Int64] $ExtensionsCount = 1
[Int64] $ProfilesCount = 1

[Int64] $GrandTotalFilesRemoved = 0
[Int64] $GrandTotalFilesNotRemoved = 0
[Int64] $GrandTotalSpaceSaved = 0
[Int64] $GrandTotalSpaceNotSaved = 0

ForEach ($Profile in $Profiles) {
    [Int64] $FilesRemoved = 0
    [Int64] $FilesNotRemoved = 0
    [Int64] $SpaceSaved = 0
    [Int64] $SpaceNotSaved = 0
    ForEach ($Extension in $Extensions) {
        Write-Color -Text "|- Profiles: ", $ProfilesCount, "/", $Profiles.Count, " - Extensions: ", $ExtensionsCount, "/", $Extensions.Count, " - ", $Profile.Name, " - " -Color White, Magenta, White, Magenta, White, Magenta, White, Magenta, White, Magenta, White
        $TempFiles = Get-ChildItem $Profile.FullName -Recurse -Name $Extension -Force -ErrorAction SilentlyContinue
    
        If ($TempFiles -ne $null) {
            ForEach ($TempFile in $TempFiles) {
                $TempFileFullPath = $Profile.FullName + "\" + $TempFile
                [Int64] $TempFileSize = 0
                Try {
                    $FileDetails = Get-ChildItem $TempFileFullPath -ErrorAction Stop
                    $TempFileSize = $FileDetails.Length
                }
                Catch {
                    $TempFileSize = 0
                }
                Try {
                    $empty = Remove-Item $File -ErrorAction Stop 
                    $FilesRemoved ++
                    $SpaceSaved = $SpaceSaved + $TempFileSize
                }
                Catch {
                    $FilesNotRemoved ++
                    $SpaceNotSaved = $SpaceNotSaved + $TempFileSize
                }
            }
        }
    }
    Write-Color -Text "|-- Total files found:       ", $TempFiles.Count -Color White, Magenta -EndLine $True
    Write-Color -Text "|-- Total files removed:     ", $FilesRemoved.Count -Color White, Magenta -EndLine $True
    Write-Color -Text "|-- Total files not removed: ", $FilesNotRemoved.Count -Color White, Magenta -EndLine $True
    Write-Color -Text "|-- Total space saved:       ", $SpaceSaved.Count -Color White, Magenta -EndLine $True
    Write-Color -Text "|-- Total space not saved:   ", $SpaceNotSaved.Count -Color White, Magenta -EndLine $True

    
}

#endregion
Function DeleteTempFilesAndFolders {
    $Profiles = Get-Content "c:\users\users.csv"

    foreach ($Profile in $Profiles)
    {
        $OutputObj2  = New-Object -Type PSObject
        if ($Profile -ne '"Name"' -and $Profile -ne '"@To be deleted"')
        {
            $CorrectProfile = $Profile.Remove(0,1)
            $CorrectProfile = $CorrectProfile.remove($CorrectProfile.Length -1 , 1)
        
            $buildpath = ".\" + $CorrectProfile + "\AppData\Local\Temp"
            Try
            {
                Remove-Item -Path $buildpath -Recurse -ErrorAction SilentlyContinue            
                $OutputObj2 | Add-Member -MemberType NoteProperty -Name Profile -Value $CorrectProfile
                $OutputObj2 | Add-Member -MemberType NoteProperty -Name Path -Value $buildpath
                $OutputObj2 | Add-Member -MemberType NoteProperty -Name Deleted -Value "Yes"
            }
            Catch
            {
                $OutputObj2 | Add-Member -MemberType NoteProperty -Name Profile -Value $CorrectProfile
                $OutputObj2 | Add-Member -MemberType NoteProperty -Name Path -Value $buildpath
                $OutputObj2 | Add-Member -MemberType NoteProperty -Name Deleted -Value "No"
            }
        }
        $OutputObj2
    } 
}


#DeleteExtensions -Extension $Extenstion -Profiles $Profiles.Name
#DeleteTempFilesAndFolders
