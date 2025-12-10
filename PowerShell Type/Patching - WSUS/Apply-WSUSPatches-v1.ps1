Param(
    [Parameter(Mandatory = $True  , Position = 1)]
    [String] $WSUSContentSharePath, `
    [Parameter(Mandatory = $True ,  Position = 2)]
    [String] $VHDFile, `
    [Parameter(Mandatory = $True ,  Position = 3)]
    [String] $TemporaryDirectory, `
    [Parameter(Mandatory = $True ,  Position = 4)]
    [String] $ScratchDirectory)

#region Common Functions
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
Function Get-TotalTime {
    Param(
        [Parameter(Mandatory = $True,  Position = 1)]
        [DateTime] $StartTime, `
        [Parameter(Mandatory = $True,  Position = 2)]
        [DateTime] $EndTime)

    $Duration = New-TimeSpan -Start $StartTime -End $EndTime

    $TotalSeconds = $Duration.TotalSeconds
    $TimeSpan =  [TimeSpan]::FromSeconds($TotalSeconds)
    $ReturnVariable = ("{0:hh\:mm\:ss}" -f $TimeSpan)
    Return $ReturnVariable
}
Function Delete-LastLine {
    $CursorLeft = [System.Console]::CursorLeft
    $CursorTop  = [System.Console]::CursorTop
    [System.Console]::SetCursorPosition($CursorLeft ,$CursorTop  - 1)
    Write-Host "                                                                                                                                            "
    [System.Console]::SetCursorPosition($CursorLeft ,$CursorTop  - 1)
}
#endregion
Function Dismount-Image {
    Param(
        [Parameter(Mandatory = $True,  Position = 1)]
        [String] $TemporaryDirectory, `
        [Parameter(Mandatory = $True,  Position = 2)]
        [Bool]   $Successfull)

    Try {
        Switch ($Successfull) {
            $True  { $Empty = Dismount-WindowsImage -Path $TemporaryDirectory -Save -ErrorAction Stop }
            $False { $Empty = Dismount-WindowsImage -Discard -Path $TemporaryDirectory -ErrorAction Stop }
        }
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host "Please dismount manually"
        Write-Host "  If you wish to discard settings made to the VHD, run:"
        Write-Host "Dismount-WindowsImage -Discard -Path <String>" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  If you wish to save settings made to the VHD, run:"
        Write-Host "Dismount-WindowsImage -Path <String> -Save"    -ForegroundColor Yellow
    }
}
Function Apply-WSUSPatches {
    Param(
        [Parameter(Mandatory = $True,  Position=1)]
        [String] $WSUSContentSharePath, `
        [Parameter(Mandatory = $True,  Position=2)]
        [String] $VHDFile, `
        [Parameter(Mandatory = $True,  Position=3)]
        [String] $TemporaryDirectory, `
        [Parameter(Mandatory = $True,  Position=4)]
        [String] $ScratchDirectory)
#region 0. Create Temporary Folders
    Try {
        Write-Color -Text "0. ", "Test and Create Temporary Folders - " -Color Cyan, White
        If (Test-Path -Path $TemporaryDirectory -PathType Container) {                                   # True - Exist
            $Empty = Remove-Item -Path $TemporaryDirectory -Recurse -ErrorAction Stop
            $Empty = Remove-Item -Path $ScratchDirectory   -Recurse -ErrorAction Stop
            $Empty = New-Item    -Path $TemporaryDirectory -ItemType Directory -Force -ErrorAction Stop
            $Empty = New-Item    -Path $ScratchDirectory   -ItemType Directory -Force -ErrorAction Stop
        }
        Else {                                                                                           # False - Does not exist
            $Empty = New-Item    -Path $TemporaryDirectory -ItemType Directory -Force -ErrorAction Stop
            $Empty = New-Item    -Path $ScratchDirectory   -ItemType Directory -Force -ErrorAction Stop
        }
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Return
    }
#endregion
#region 0. Check and Read Logs
    Try {
        [String] $LogFile = $VHDFile.ToString() + ".Log"
        If (Get-ChildItem $LogFile -ErrorAction SilentlyContinue) {
            $PreviouslyPatched = Get-Content $LogFile -ErrorAction Stop
            If ($PreviouslyPatched -eq $null) { $PreviouslyPatched = @() }
        }
        Else { $PreviouslyPatched = @() }
    }
    Catch {
        Write-Color -Text "Unable to access ", $LogFile -Color Red, Cyan
        Write-Output $_
        Return
    }
#endregion
#region 1. Mounting VHD
    Try{
        [System.DateTime] $MountStartTime = Get-Date
        Write-Color -Text "1. ", "Mounting ", $VHDFile, " at ", $TemporaryDirectory, " - ", $MountStartTime.ToLongTimeString(), " - " -Color Cyan, White, Cyan, White, Cyan, White, Yellow, White
            $empty = Mount-WindowsImage -ImagePath "$VHDFile" -Path $TemporaryDirectory -Index 1 -ErrorAction Stop
            [System.DateTime] $MountEndTime = Get-Date
        Write-Color -Text "Complete", " - ", $MountEndTime.ToLongTimeString() -Color Green, White, Cyan -EndLine
    }
    Catch{
        [System.DateTime] $MountEndTime = Get-Date
        Write-Color -Text "Failed", " - ", $MountEndTime.ToLongTimeString() -Color Red, White, Cyan -EndLine
        Write-Host        "Dismounting Image - " -ForegroundColor Red
        Dismount-Image -TemporaryDirectory $TemporaryDirectory -Successfull $false
        Return
    }
#endregion
#region 2.1. Obtaining CAB and MSU Files
    Try{
        [System.DateTime] $UpdatesStartTime = Get-Date
        Write-Color "2. ", "Obtaining Update list of ", "CAB and MSU", " files - ", $UpdatesStartTime.ToLongTimeString(), " - " -Color Cyan, White, Yellow, White, Cyan, White
            $Updates = Get-ChildItem -Recurse -Path $WSUSContentSharePath | Where-Object { ($_.extension -eq ".msu") -or ($_.extension -eq ".cab") }
            [System.DateTime] $UpdatesEndTime = Get-Date
        Write-Color -Text "Complete", " - ", $UpdatesEndTime.ToLongTimeString() -Color Green, White, Yellow -EndLine
    }
    Catch{
        [System.DateTime] $UpdatesEndTime = Get-Date
        Write-Color -Text "Failed", " - Dismounting and discarding ", $VHDFile, " at ", $TemporaryDirectory, " - ", $UpdatesEndTime.ToLongTimeString(), " - " -Color Red, White, Cyan, White, Cyan, White, Yellow, White
        Dismount-Image -TemporaryDirectory $TemporaryDirectory -Successfull $false
        Return
    }
#endregion
#region 2.2. Implementing CAB and MSU Files
    [System.DateTime] $GlobalStartTime = Get-Date    
    Write-Color -Text "2.1. ", "Total ", "CAB", " updates: ", $updates.Count, " - Start Time: ",  $GlobalStartTime.ToLongTimeString() -Color Cyan, White, Yellow, White, Yellow, White, Yellow -EndLine
    $Counter               = 1 
    $TotalPatchCount       = 0
    $TotalUnappliedPatches = 0
    ForEach ($Update in $Updates) {
        Try {
            If ($Counter -ne 1) {Delete-LastLine; Delete-LastLine} 
            Write-Color -Text "2.1.0 ", "Applied Patches: ", $TotalPatchCount, " - Not Applicable Patches: ", $TotalUnappliedPatches, " - Previously Applied Patches: ", $PreviouslyPatched.Count -Color Cyan, White, Green, White, Red, White, Yellow -EndLine
            [DateTime] $UpdateStartTime = Get-Date
            Write-Color "2.1.", $Counter, "/", $Updates.Count, " - Required and Installed ", $Update.Name, " - ",$UpdateStartTime.ToLongTimeString(), " - " -Color Cyan, Yellow, Yellow, Yellow, White, Cyan, White, Cyan, White
            If (-not $PreviouslyPatched.Contains($Update.Name)) {
                $Empty = Add-WindowsPackage -PackagePath $Update.FullName -Path $TemporaryDirectory -ScratchDirectory $ScratchDirectory -WarningAction SilentlyContinue -ErrorAction Stop
                [System.DateTime] $UpdateEndTime = Get-Date
                Write-Host "Yes" -ForegroundColor Green
                $PreviouslyPatched = $PreviouslyPatched + $Update.Name
            }
            Else {
                Write-Host ""
            }
            $TotalPatchCount ++
        }
        Catch {
            [System.DateTime] $UpdateEndTime = Get-Date
            Write-Host "No" -ForegroundColor Red
            $PreviouslyPatched = $PreviouslyPatched + $Update.Name
            $TotalUnappliedPatches ++
        }
        $Counter ++
    }
    Try {
        Write-Color -Text "2.1 ", "Exporting Patch history to log ", $LogFile, " - " -Color Cyan, White, Cyan, White
            If (Get-ChildItem $LogFile -ErrorAction SilentlyContinue) { $Empty = Remove-Item $LogFile -Force -ErrorAction Stop }
            $PreviouslyPatched | Out-File $LogFile -Encoding ascii -Force -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Output $_
        Sleep 10
    }
    [System.DateTime] $GlobalEndTime = Get-Date
    $Duration        = Get-TotalTime -StartTime $GlobalStartTime -EndTime $GlobalEndTime
    $FinalOutPutInfo = New-Object PSObject -Property @{
        PatchesApplied       = $TotalPatchCount;
        PatchesNotApplicable = $TotalUnappliedPatches;
        PatchStartTime       = $GlobalStartTime.ToLongTimeString();
        PatchEndTime         = $GlobalEndTime.ToLongTimeString();
        PatchDuration        = $Duration;
    }
    Write-Color -Text "2.3 ", "Total Patches Applied: ", $TotalPatchCount, " - End Time: ", $GlobalEndTime.ToLongTimeString(), " - Duration: ", $Duration -Color Cyan, White, Yellow, White, Yellow, White, Yellow -EndLine
#endregion
#region 3. Dismounting and saving VHD
    Try {
        [System.DateTime] $DismountStartTime = Get-Date
        Write-Color -Text "3. ", "Dismounting and saving ", $VHDFile, " at ", $TemporaryDirectory, " - ", $DismountStartTime.ToLongTimeString(), " - " -Color Cyan, White, Cyan, White, Cyan, White, Yellow, White
            Dismount-Image -TemporaryDirectory $TemporaryDirectory -Successfull $True
            [System.DateTime] $DismountEndTime = Get-Date
            $DismountDuration = Get-TotalTime -StartTime $DismountStartTime -EndTime $DismountEndTime
        Write-Color -Text "Complete", " - ", $DismountEndTime.ToLongTimeString(), " - Duration: ", $DismountDuration, " - " -Color Green, White, Cyan, White, Yellow, White -EndLine
    }
    Catch {
        [System.DateTime] $DismountEndTime = Get-Date
        Write-Color -Text "Failed", " - ", $DismountEndTime.ToLongTimeString() -Color Red, White, Yellow -EndLine
        Dismount-Image -TemporaryDirectory $TemporaryDirectory -Successfull $True
    }
#endregion
#region 4. Remove Temporary Folders
    Try {
        Write-Color -Text "4. Remove Temporary Folders - " -Color White
            $Empty = Remove-Item -Path $TemporaryDirectory -Recurse -ErrorAction Stop
            $Empty = Remove-Item -Path $ScratchDirectory   -Recurse -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Break
    }
#endregion
#region 5. Patching Output Information
    Write-Host ""
    Write-Host "Information on Patches applied:" -ForegroundColor Gray
    Write-Host ""
    $FinalOutPutInfo
    Write-Host "Logfile: $LogFile"
    Remove-Variable "FinalOutPutInfo"
#endregion
}

Apply-WSUSPatches -WSUSContentSharePath $WSUSContentSharePath -VHDFile $VHDFile -TemporaryDirectory $TemporaryDirectory -ScratchDirectory $ScratchDirectory