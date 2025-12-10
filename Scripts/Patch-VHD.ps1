Clear-Host
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

#endregion

Function Patch-VHD {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [String] $VHDPath, `
        [Parameter(Mandatory=$true,Position=2)]
        [String] $TemporaryDirectory, `
        [Parameter(Mandatory=$true,Position=3)]
        [String] $WSUSServer)
    
#region 1. Mounting VHD
    Write-Color -Text "1. ", "Mounting ", $VHDPath, " at ", $TemporaryDirectory, " - " -Color Magenta, White, Cyan, White, Cyan, White
    Try{
        $empty = Mount-WindowsImage -ImagePath "$VHDPath" -Path $TemporaryDirectory -Index 1 -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch{
        Write-Host "Failed" -ForegroundColor Red
        Exit 1
    }
#endregion

#region 2. Obtaining and implementing CAB Files
    Write-Color "2. ", "Obtaining Update list of ", "CAB", " files - " -Color Magenta, White, Yellow, White 
    Try{
        $UpdatelistCab = Get-ChildItem -Path "\\$WsusServer\WsusContent" -Include *.cab -Recurse -File -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch{
        Write-Color -Text "Failed! ", "Dismounting and discarding ", $VHDPath, " at ", $TemporaryDirectory, " - " -Color Red, White, Cyan, White, Cyan, White
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
        Exit 1
    }

    Write-Color -Text "2.1. ", "Total ", "CAB", " updates: ", $UpdatelistCab.Count -Color Magenta, White, Yellow, White, Yellow -EndLine $true
    $x = 1 
    Foreach ($UpdateCab in $UpdatelistCab) {
        Try {
            Write-color -Text "2.1.", $x, "/", $UpdatelistCab.Count, " - Getting Update Package - " -Color Magenta, Yellow, Yellow, Yellow, White
                $UpdateReady = Get-WindowsPackage -PackagePath $UpdateCab -Path $TemporaryDirectory -WarningAction SilentlyContinue -ErrorAction Stop
            Write-Host "Complete" -ForegroundColor Green
        
            Write-Color -Text "2.2.", $x, "/", $UpdatelistCab.Count, " - Checking if ", $UpdateReady.PackageName, " to be actioned - " -Color Magenta, Yellow, Yellow, Yellow, White, Cyan, White
                If ($UpdateReady.PackageState -eq "installed") {
                    Write-Host "Installed" -ForegroundColor Green
                }
                ElseIf ($UpdateReady.Applicable -eq "true") {
                    Try {
                        Write-Host "Not installed"
                        Write-Color "2.2.1.", $x, "/", $UpdatelistCab.Count, " - Attempting to install in ", $Updatecab.Directory, " - " -Color Magenta, Yellow, Yellow, Yellow, White, Cyan, White
                            $empty = Add-WindowsPackage -PackagePath $Updatecab.Directory -Path $TemporaryDirectory -WarningAction SilentlyContinue -ErrorAction Stop
                        Write-Host "Complete" -ForegroundColor Green
                    }
                    Catch {
                        Write-Host "Failed" -ForegroundColor Red
                    }
                }
                Else {
                    Write-Host "Not Applicable" -ForegroundColor Green
                }
        }
        Catch {
            Write-Host "Failed" -ForegroundColor Red
        }
        $x ++
    }   
#endregion

#region 3. Obtaining and implementing MSU Files...
    Write-Color "3. ", "Obtaining Update list of ", "MSU", " files - " -Color Magenta, White, Yellow, White 
    Try{
        $UpdatelistMsu = Get-ChildItem -Path "\\$WsusServer\WsusContent" -Include *.msu –Recurse -File -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch{
        Write-Host "Failed" -ForegroundColor Red
        Write-Host " Do you want to discard changes and unmount the VHD" -NoNewline; Write-Host " (y)" -ForegroundColor Green
        Write-Host "   OR " -ForegroundColor Yellow
        Write-Host " Do you want to save changes and unmount the VHD" -NoNewline; Write-Host " (n)" -ForegroundColor Red 
        [String] $VHDOption = Read-Host "Discard changes and unmount the VHD? (y)"
        Try {
            If ($VHDOption.ToLower() -eq "y" -or $VHDOption -eq "") {
                Write-Color -Text "Dismounting and discarding changes", $VHDPath, " from ", $TemporaryDirectory, " - "
                $empty = Dismount-WindowsImage -Discard -Path $TemporaryDirectory
                Write-Host "Complete" -ForegroundColor Green
            }
            ElseIf ($VHDOption.ToLower() -eq "n")  {
                Write-Color -Text "Dismounting and saving changes", $VHDPath, " from ", $TemporaryDirectory, " - "
                $empty = Dismount-WindowsImage -Path $TemporaryDirectory -Save
                Write-Host "Complete" -ForegroundColor Green
            }
            Else {
                Write-Host "An invalid selection was made. Please dismount manually."
            }
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
        Exit 1
    }

    Write-Color -Text "3.1.", " Total ", "MSU", " updates: ", $UpdatelistMsu.Count -Color Magenta, White, Yellow, White, Yellow -EndLine $true
    $x = 1
    ForEach ($UpdateMsu in $UpdatelistMsu) {
        Try {
            Write-Color "3.1.", $x, "/", $UpdatelistMsu.Count, " - Attempting to install in ", $UpdateMsu.Directory, " - " -Color Magenta, Yellow, Yellow, Yellow, White, Cyan, White
                $empty = Add-WindowsPackage -PackagePath $UpdateMsu.Directory -Path $TemporaryDirectory -WarningAction SilentlyContinue -ErrorAction Stop
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch {
            Write-Host "Failed" -ForegroundColor red
        }
    }
#endregion
    
#region 4. Dismounting and saving VHD
    Write-Color -Text "4. ", "Dismounting and saving ", $VHDPath, " at ", $TemporaryDirectory, " - " -Color Magenta, White, Cyan, White, Cyan, White
    Try {
        Dismount-WindowsImage -Path $TemporaryDirectory -Save
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
#endregion
}

Function Discard-VHD {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [String] $MountedDirectory)

    Try {
        Write-Color "Dismounting and discarding changes on VHD mounted at ", $MountedDirectory, " - " -Color White, Cyan, White
            $empty = Dismount-WindowsImage -Discard -Path $MountedDirectory -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
    }
}

$VHD = "D:\Removed from VMM Library\Patched\Windows Server 2012 R2\Windows Server 2012 R2 Standard Gen 2.vhdx"
$Temp = "D:\Temp"
$WSUS = "APPSERVER103.domain2.local"

Patch-VHD -VHDPath $VHD -TemporaryDirectory $Temp -WSUSServer $WSUS
#Discard-VHD -MountedDirectory $Temp