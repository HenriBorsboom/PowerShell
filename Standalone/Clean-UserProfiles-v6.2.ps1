Function Clean-Prof {
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
            Write-Host "Unable to find any profiles in " -ForegroundColor Red -NoNewline
            Write-Host $ProfilesPath -ForegroundColor Yellow
            Write-Host "The default profiles folder for this computer is"
            Write-Host ("  " + $env:SystemDrive + "\Users") -ForegroundColor Green
            Break
        }
        $ProfilesDetails = @()
        $ProfileCounter = 1
        ForEach ($Profile in $Profiles) {
            $ProfileDetails = @()
            Write-Host ($ProfileCounter.ToString() + "/" + $Profiles.Count.ToString()) -ForegroundColor Cyan -NoNewline
            Write-Host " - Getting Temp files for " -NoNewline
            Write-Host $Profile -ForegroundColor Yellow -NoNewline
            Write-Host " - " -NoNewline
                #$ProfileDetails = $ProfileDetails + ($TempFiles = (Get-ChildItem -Path $Profile -Include $Extensions -Recurse -Force -ErrorAction SilentlyContinue).FullName)
                $ExtensionFiles = (Get-ChildItem -Path $Profile -Include $Extensions -Recurse -Force -ErrorAction SilentlyContinue).FullName
                $AppDataFiles   = (Get-ChildItem -Path ($Profile.ToString() + "\AppData\Local\Temp") -Recurse -Force -ErrorAction SilentlyContinue).FullName
                $TempFilesCount = $ExtensionFiles.Length + $AppDataFiles.Length
                $TempFiles = $ExtensionFiles + $AppDataFiles
            Write-Host ($TempFiles.Count.ToString() + " found") -ForegroundColor Green -NoNewline
            If ($TempFiles.Count -gt 0) {
                Write-Host " - Removing - " -NoNewline
                    $Result = Remove-File -TempFiles $TempFiles
                    $ProfileDetails = $ProfileDetails + $Result
                Write-Host "Complete" -ForegroundColor Green
                $ProfilesDetails = $ProfilesDetails + $ProfileDetails
            }
            Else {
                Write-Host
            }
            $ProfileCounter ++
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

Clear-Host
Clean-Prof