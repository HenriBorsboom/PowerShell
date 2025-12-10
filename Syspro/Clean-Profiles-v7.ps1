$ErrorActionPreference = 'Stop'

Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)

    $ErrorActionPreference = "Stop"
    Try {
        If ($Text.Count -ne $ForegroundColor.Count) {
            Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $ForegroundColor.Count.ToString()) -ForegroundColor Red
            Throw
        }
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch { 
        Write-Host "Text Count:  " $Text.Count
        Write-Host "Color Count: " $ForegroundColor.Count
        Write-Host $_
    }
}
Function Delete-LastLine {
    If ($Host.Name -notlike '*ISE*') {
        $PShost = Get-Host
        $pswindow = $pshost.ui.rawui

        $x = [Console]::CursorLeft
        $y = [Console]::CursorTop
        [Console]::SetCursorPosition($x,$y - 1)
        $String = ""
        For ($i = 0; $i -lt $pswindow.windowsize.Width; $i ++) {
            $String = ($String + " ")
        }
    
        Write-Host $String 
        [Console]::SetCursorPosition($x,$y -1)
    }
}
Function Clean-UserProfiles {
    Param (
        [Parameter(Mandatory = $False, Position = 1)]
        [String]   $ProfilesPath = ($env:SystemDrive + "\Users"), `
        [Parameter(Mandatory = $False, Position = 2)]
        [String[]] $Extensions = @("*.log","*.dmp","*.tmp","*.hdmp","*.mdmp","*.regtrans-ms","*.htm","*.dat"))

    Begin {
        Write-Color -Text "Setting path to ", $ProfilesPath -ForegroundColor Yellow, DarkCyan
        Write-Color -Text "Setting extensions to:" -ForegroundColor Yellow
        ForEach ($Extension in $Extensions) { 
            Write-Color -Text "   ", $Extensions -ForegroundColor White, DarkCyan
        }
        Write-Color -Text "Total Extensions: ", $Extensions.Count.ToString() -ForegroundColor White, Green
    }
    Process {
        Try {
            $Profiles = (Get-ChildItem $ProfilesPath -Directory).FullName
            Write-Color -Text "Getting list of user profiles - ", $Profiles.Count, " Profiles Found" -ForegroundColor White, DarkCyan, White
        }
        Catch {
            Write-Color -Text "Unable to find any profiles in ", $ProfilesPath, "The default profiles folder for this computer is", ("  " + $env:SystemDrive + "\Users") -ForegroundColor Red, Yellow, White, Green
            Return $False
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
