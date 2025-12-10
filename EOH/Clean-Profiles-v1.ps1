Param (
    [Parameter(Mandatory=$False, Position=1)]
    [String] $ProfilesPath = 'C:\Users', `
    [Parameter(Mandatory=$False, Position=2)]
    [String[]] $Extensions = @("*.log","*.dmp","*.tmp","*.hdmp","*.mdmp","*.regtrans-ms","*.htm","*.dat"))

Function Write-Color {
    [CmdletBinding(DefaultParameterSetName='Normal')]
    Param( 
        [Parameter(Mandatory=$True, Position=1,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$True, Position=1,ParameterSetName='Tab')]
        [String[]] $Text, `
        [Parameter(Mandatory=$False, Position=2,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=2,ParameterSetName='Tab')]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory=$False, Position=3,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=3,ParameterSetName='Tab')]
        [ConsoleColor[]] $BackgroundColor, `
        [Parameter(Mandatory=$False, Position=1,ParameterSetName='Complete')]
        [Switch] $Complete, `
	    [Parameter(Mandatory=$False, Position=4,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=4,ParameterSetName='Tab')]
	    [Parameter(Mandatory=$False, Position=2,ParameterSetName='Complete')]
        [Switch] $NoNewLine, `
        [Parameter(Mandatory=$False, Position=5,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=8,ParameterSetName='Tab')]
	    [Parameter(Mandatory=$False, Position=3,ParameterSetName='Complete')]
        [String] $LogFile = "", `
	    [Parameter(Mandatory=$False, Position=5,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=4,ParameterSetName='Complete')]
        [Int16] $StartTab = 0, `
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=5,ParameterSetName='Complete')]
        [Int16] $LinesBefore = 0, `
        [Parameter(Mandatory=$False, Position=7,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Complete')]
        [Int16] $LinesAfter = 0, `
        [Parameter(Mandatory=$False, Position=9,ParameterSetName='Tab')]
        [String] $TimeFormat = "yyyy-MM-dd HH:mm:ss", `
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Normal')]
        [Parameter(Mandatory=$False, Position=10,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=1,ParameterSetName='Counter')]
        [Int64] $IndexCounter, `
        [Parameter(Mandatory=$False, Position=7,ParameterSetName='Normal')]
        [Parameter(Mandatory=$False, Position=11,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=2,ParameterSetName='Counter')]
        [Int64] $TotalCounter)

    Begin {
        $CurrentActionPreference = $ErrorActionPreference; 
        $ErrorActionPreference = 'Stop'

        If ($Text.Count -gt 0) {
            If ($BackgroundColor.Count -eq 0 -and $ForegroundColor.Count -eq 0) { $OperationMode = 'WriteHost' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -eq 0) { $OperationMode = 'SingleBackground' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -eq 0) { $OperationMode = 'SingleForeground' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count) { $OperationMode = 'SingleForegroundBackground' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count) { $OperationMode = 'SingleBackgroundForeground' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -ge $Text.Count -or $ForegroundColor.Count -eq 0) { $OperationMode = 'Background' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -ge $Text.Count -or $BackgroundColor.Count -eq 0) { $OperationMode = 'Foreground' }
            ElseIf ($BackgroundColor.Count -eq $Text.Count -and $ForegroundColor.Count -eq $Text.Count) { $OperationMode = 'Normal' }
            Else { Throw }
        }
        If ($Complete -eq $True) { $OperationMode = 'Complete' }
    }
    Process {
        If ($LinesBefore -ne 0) { For ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline } }
        If ($StartTab -ne 0) { For ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewLine } }
        If ($TotalCounter -gt 0 -and $IndexCounter -ge 0) {
            $CounterLength = $TotalCounter.ToString().Length
            Write-Host ("[" + ("{0:D$CounterLength}" -f ($IndexCounter + 1) + "/" + $TotalCounter) + "] ") -ForegroundColor DarkCyan -NoNewline
        }
        If ($OperationMode -eq 'WriteHost') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Foreground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Background') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'SingleBackground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -BackgroundColor $BackgroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'SingleForeground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'SingleForegroundBackground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[0] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'SingleBackgroundForeground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -BackgroundColor $BackgroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'Normal') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Complete') { Write-Host 'Complete' -ForegroundColor Green -NoNewLine }
        If ($LinesAfter -ne 0) { For ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host "`n" } }
    }
    End {
        If ($NoNewLine -eq $False) { Write-Host } Else { }
        If ($LogFile -ne "") {
            $TextToFile = ""
            For ($i = 0; $i -lt $Text.Length; $i++) {
                $TextToFile += $Text[$i]
            }
            Write-Output "[$([datetime]::Now.ToString($TimeFormat))] $TextToFile" | Out-File $LogFile -Encoding unicode -Append
        }
        $ErrorActionPreference = $CurrentActionPreference
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

Write-Color "1. ", "Checking for supplied extensions - " -ForegroundColor DarkCyan, White -NoNewLine
ForEach ($Extension in $Extensions) {
    Write-Color -Text "|-- ", $Extension -ForegroundColor DarkCyan, Magenta
}
Try {
    Write-Color -Text "2. ", "Obtaining a list of User Profiles from ", $ProfilesPath.toUpper(), " - " -ForegroundColor DarkCyan, White, Yellow, White -NoNewLine
        $Profiles = Get-ChildItem $ProfilesPath -Force | Where-Object {$_.Mode -match "d"} -ErrorAction Stop
    Write-Color -Complete
}
Catch {
    Write-Color -Text "Failed! ", $_ -ForegroundColor Red, Red
}
Write-Color "3. ", "Obtaining list of files from Profiles" -ForegroundColor DarkCyan, White
    
[Int64] $ExtensionsCount = 1
[Int64] $ProfilesCount = 1
[Int64] $GrandTotalFiles = 0
[Int64] $GrandTotalFilesRemoved = 0
[Int64] $GrandTotalFilesNotRemoved = 0
[Int64] $GrandTotalSpaceSaved = 0
[Int64] $GrandTotalSpaceNotSaved = 0
[Int64] $GrandTotalInaccessibleFiles = 0
$Details = @()
ForEach ($Profile in $Profiles) {
    [Int64] $ProfileTotalTempFiles = 0
    [Int64] $FilesRemoved = 0
    [Int64] $FilesNotRemoved = 0
    [Int64] $SpaceSaved = 0
    [Int64] $SpaceNotSaved = 0
    [Int64] $InaccessibleFiles = 0
    ForEach ($Extension in $Extensions) {
        Try {
            Write-Color -Text "|- Profiles: ", $ProfilesCount, "/", $Profiles.Count, " - Processing Extension: ", $Extension.ToUpper(), " - " -ForegroundColor White, Cyan, White, Cyan, White, Cyan, White -NoNewLine
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
            $ProfileTotalTempFiles = $ProfileTotalTempFiles + $TempFiles.Count
            Write-Color -Text "Saved (MB): ", $SpaceSaved -ForegroundColor White, Magenta
            Delete-LastLine
        }
        Catch {
        }
        $ExtensionsCount ++
    }
    $ExtensionsCount = 1

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
    Write-Color -Text "Saved (MB): ", ([Math]::Round(($SpaceSaved / 1024 / 1024),2)) -ForegroundColor White, Magenta 
    $ProfilesCount ++
}
Write-Host ""
Write-Host        "------------------------------------------- Report"
Write-Color -Text "Total Files found from All Profiles:       ", $GrandTotalFiles -ForegroundColor White, Green
Write-Color -Text "Total Files removed from All Profiles:     ", $GrandTotalFilesRemoved -ForegroundColor White, Green
Write-Color -Text "Total Files not removed from All Profiles: ", $GrandTotalFilesNotRemoved -ForegroundColor White, Green 
Write-Color -Text "Total Inaccessible files in All Profiles:  ", $GrandTotalInaccessibleFiles -ForegroundColor White, Green
Write-Color -Text "Total Space saved from All Profiles (MB):  ", ([Math]::Round(($GrandTotalSpaceSaved / 1024 / 1024),2)) -ForegroundColor White, Green
Write-Color -Text "Total Space Not from All Profiles (MB):    ", ([Math]::Round(($GrandTotalSpaceNotSaved / 1024 / 1024),2)) -ForegroundColor White, Green
#}
