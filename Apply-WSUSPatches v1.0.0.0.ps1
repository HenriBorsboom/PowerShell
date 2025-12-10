Param(
    [Parameter(Mandatory=$true,Position=1)]
    [String] $WSUSContentSharePath, `
    [Parameter(Mandatory=$true,Position=2)]
    [String] $VHDFile, `
    [Parameter(Mandatory=$true,Position=3)]
    [String] $TemporaryDirectory, `
    [Parameter(Mandatory=$true,Position=4)]
    [String] $ScratchDirectory)
#region Common Functions
Function Debug{
    Param(
        [Parameter(Mandatory=$false,Position=1)]
        $Variable)
    
    If ($Variable -eq $null){
        $VariableDetails = "Empty Variable"
    }
    Else{
        $VariableDetails = $Variable.getType()
    }
    
    Write-Host "------ DEBUG ------" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Variable Type: " -NoNewline -ForegroundColor Yellow
    Write-Host "$VariableDetails" -ForegroundColor Red
    Write-Host "  Variable Contents" -ForegroundColor Yellow
    Write-Host "  $Variable" -ForegroundColor Red
    Write-Host "  Complete" -ForegroundColor Green
    Write-Host ""
    
    $Return = Read-Host "Press C to continue. Any other key will quit. "
    If ($Return.ToLower() -eq "c"){
        Return
    }
    Else{
        Exit 1
    }
}
Function Strip-Name{
    Param(
        [String] $Name)
        
    $Name = $Name.Remove(0, 7)
    $Name = $Name.Remove($Name.Length - 1, 1)
    Return $Name
}
Function Write-Color {
    Param(
        [String[]] $Text, `
        [ConsoleColor[]] $Color, `
        [bool] $EndLine)
    
    For ($i = 0; $i -lt $Text.Length; $i++) {
        Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
    }
    Switch ($EndLine){
        $true {Write-Host}
        $false {Write-Host -NoNewline}
    }
}
Function Get-TotalTime {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [DateTime] $StartTime, `
        [Parameter(Mandatory=$true,Position=2)]
        [DateTime] $EndTime)

    $Duration = New-TimeSpan -Start $StartTime -End $EndTime

    $s = $Duration.TotalSeconds
    $ts =  [timespan]::fromseconds($s)
    $ReturnVariable = ("{0:hh\:mm\:ss}" -f $ts)
    Return $ReturnVariable
}
Function Delete-LastLine {
    $x = [Console]::CursorLeft
    $y = [Console]::CursorTop
    [Console]::SetCursorPosition($x,$y - 1)
    Write-Host "                                                                                                                                            "
    [Console]::SetCursorPosition($x,$y - 1)
}
#endregion

Function Apply-WSUSPatches {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [String] $WSUSContentSharePath, `
        [Parameter(Mandatory=$true,Position=2)]
        [String] $VHDFile, `
        [Parameter(Mandatory=$true,Position=3)]
        [String] $TemporaryDirectory, `
        [Parameter(Mandatory=$true,Position=4)]
        [String] $ScratchDirectory)

#region 1. Mounting VHD
    Try{
        [DateTime] $MountStartTime = Get-Date
        Write-Color -Text "1. ", "Mounting ", $VHDFile, " at ", $TemporaryDirectory, " - ", $MountStartTime.ToLongTimeString(), " - " -Color Magenta, White, Cyan, White, Cyan, White, Magenta, White
        $empty = Mount-WindowsImage -ImagePath "$VHDFile" -Path $TemporaryDirectory -Index 1 -ErrorAction Stop
        [DateTime] $MountEndTime = Get-Date
        Write-Color -Text "Complete", " - ", $MountEndTime.ToLongTimeString() -Color Green, White, Magenta -EndLine $true
    }
    Catch{
        [DateTime] $MountEndTime = Get-Date
        Write-Color -Text "Failed", " - ", $MountEndTime.ToLongTimeString() -Color Red, White, Magenta -EndLine $true
        Exit 1
    }
#endregion
#region 2. Obtaining and implementing CAB and MSU Files
    Try{
        [DateTime] $UpdatesStartTime = Get-Date
        Write-Color "2. ", "Obtaining Update list of ", "CAB and MSU", " files - ", $UpdatesStartTime.ToLongTimeString(), " - " -Color Magenta, White, Yellow, White, Magenta, White
        $updates = get-childitem -Recurse -Path $WSUSContentSharePath | where {($_.extension -eq ".msu") -or ($_.extension -eq ".cab")} # | select fullname
        [DateTime] $UpdatesEndTime = Get-Date
        Write-Color -Text "Complete", " - ", $UpdatesEndTime.ToLongTimeString() -Color Green, White, Magenta -EndLine $true
    }
    Catch{
        [DateTime] $UpdatesEndTime = Get-Date
        Write-Color -Text "Failed", " - Dismounting and discarding ", $VHDFile, " at ", $TemporaryDirectory, " - ", $UpdatesEndTime.ToLongTimeString(), " - " -Color Red, White, Cyan, White, Cyan, White, Magenta, White
        Try {
            $empty = Dismount-WindowsImage -Discard -Path $TemporaryDirectory
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch {
            Write-Host "Failed" -ForegroundColor Red
            Write-Host "Please dismount manually"
            Write-Host " If you wish to discard settings made to the VHD, run:"
            Write-Host "Dismount-WindowsImage -Discard -Path <String>" -ForegroundColor Yellow
            Write-Host ""
            Write-Host " If you wish to save settings made to the VHD, run:"
            Write-Host "Dismount-WindowsImage -Path <String> -Save" -ForegroundColor Yellow
        }
        Break
    }

    [DateTime] $GlobalStartTime = Get-Date    
    Write-Color -Text "2.1. ", "Total ", "CAB", " updates: ", $updates.Count, " - Start Time:",  $GlobalStartTime.ToLongTimeString() -Color Magenta, White, Yellow, White, Yellow, White, Magenta -EndLine $true
    $x = 1 
    ForEach ($update in $updates) {
        Try {
            [DateTime] $UpdateStartTime = Get-Date
            Write-Color "2.1.", $x, "/", $updates.Count, " - Required and Installed ", $update.Name, " - ",$UpdateStartTime.ToLongTimeString(), " - " -Color Magenta, Yellow, Yellow, Yellow, White, Cyan, White, Magenta, White
            $empty = Add-WindowsPackage -PackagePath $update.FullName -Path $TemporaryDirectory -ScratchDirectory $ScratchDirectory -WarningAction SilentlyContinue -ErrorAction Stop
            [DateTime] $UpdateEndTime = Get-Date
            Write-Host "Yes" -ForegroundColor Green
            Delete-LastLine
        }
        Catch {
            [DateTime] $UpdateEndTime = Get-Date
            Write-Host "No" -ForegroundColor Red
            Delete-LastLine
        }
        $x ++
    }
    [DateTime] $GlobalEndTime = Get-Date
    $Duration = Get-TotalTime -StartTime $GlobalStartTime -EndTime $GlobalEndTime
    
    $FinalOutPutInfo = New-Object PSObject
    $FinalOutPutInfo | Add-Member -MemberType NoteProperty -Name "PatchesApplied" -Value $TotalPatchCount
    $FinalOutPutInfo | Add-Member -MemberType NoteProperty -Name "PatchStartTime" -Value $GlobalStartTime.ToLongTimeString()
    $FinalOutPutInfo | Add-Member -MemberType NoteProperty -Name "PatchEndTime" -Value $GlobalEndTime.ToLongTimeString()
    $FinalOutPutInfo | Add-Member -MemberType NoteProperty -Name "PatchDuration" -Value $Duration

    Write-Color -Text "2.2 ", "Total Patches Applied: ", $TotalPatchCount, " - End Time: ", $GlobalEndTime.ToLongTimeString(), " - Duration: ", $Duration -Color Magenta, White, Yellow, White, Yellow, White, Magenta -EndLine $true
#endregion
#region 3. Dismounting and saving VHD
    Try {
        [DateTime] $DismountStartTime = Get-Date
        Write-Color -Text "3. ", "Dismounting and saving ", $VHDFile, " at ", $TemporaryDirectory, " - ", $DismountStartTime.ToLongTimeString(), " - " -Color Magenta, White, Cyan, White, Cyan, White, Magenta, White
        Dismount-WindowsImage -Path $TemporaryDirectory -Save
        [DateTime] $DismountEndTime = Get-Date
        $DismountDuration = Get-TotalTime -StartTime $DismountStartTime -EndTime $DismountEndTime
        Write-Color -Text "Complete", " - ", $DismountEndTime.ToLongTimeString(), " - Duration: ", $DismountDuration, " - " -Color Green, White, Magenta, White, Magenta, White -EndLine $true
    }
    Catch {
        [DateTime] $DismountEndTime = Get-Date
        Write-Color -Text "Failed", " - ", $DismountEndTime.ToLongTimeString() -Color Red, White, Magenta -EndLine $true
        Write-Host "Failed" -ForegroundColor Red
        Write-Host "Please dismount manually"
        Write-Host " If you wish to discard settings made to the VHD, run:"
        Write-Host "Dismount-WindowsImage -Discard -Path <String>" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " If you wish to save settings made to the VHD, run:"
        Write-Host "Dismount-WindowsImage -Path <String> -Save" -ForegroundColor Yellow
    }
#endregion
#region 4. Patching Output Information
    Write-Host ""
    Write-Host "Information on Patches applied:" -ForegroundColor Gray
    Write-Host ""
    $FinalOutPutInfo
#endregion
}

Apply-WSUSPatches -WSUSContentSharePath $WSUSContentSharePath -VHDFile $VHDFile -TemporaryDirectory $TemporaryDirectory -ScratchDirectory $ScratchDirectory