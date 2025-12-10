#region Common Tasks
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
#endregion
#region Windows Update Functions
Function Report-WindowsUpdates{
    $Computers = Get-Content "C:\temp\computers.txt"
    Write-Color -Text "Total Hosts: ", $Computers.Count -Color White, Yellow -EndLine $true
    $x = 1
    ForEach ($Server in $Computers){
        Write-Color $x, "/", $Computers.Count, " - Processing ", $Server, " - " -Color Yellow,Yellow,Yellow,White,Cyan,White
        Write-Host "Processing $Server - " -NoNewline
        Try{
            icm -ComputerName $Server -ScriptBlock {wuauclt /reportnow} -ErrorAction Stop
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch{
            Write-Host "Failed" -ForegroundColor Red
        }
        $x ++
    }
}

Function Copy-WindowsUpdateStartupItem{
    Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string] $SourceFile, `
    [Parameter(Mandatory=$True,Position=2)]
    [string] $DestinationPath)
    
    $TargetServers = Get-Content "C:\temp\computers.txt"
    Write-Host " Total Targets: " -NoNewline
    Write-Host $TargetServers.Count -ForegroundColor Yellow
    [int] $x = 1
    foreach ($Target in $TargetServers){
        [string] $DestComputer = $Target
        $Dest = "\\" + $Target + "\" + $DestinationPath
        Try{
            Write-Host "$x - Copying " -NoNewline
            Write-Host "$SourceFile" -ForegroundColor Yellow -NoNewline
            Write-Host " to " -NoNewline
            Write-host "$Dest" -NoNewline
            Write-Host " - " -NoNewline
            $Empty = copy-item $SourceFile -Destination $Dest -Force
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch{
            Write-Host "Failed" -ForegroundColor Red
        }
        $x ++
    }
}

Function Remove-WindowsUpdateStartupItem{
    Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string] $SourceFile, `
    [Parameter(Mandatory=$True,Position=2)]
    [string] $DestinationPath)

    $Computers = Get-Content "c:\temp\computers.txt"
    foreach ($Computer in $Computers){
        [string] $DestComputer = $Computer
        $Dest = "\\" + $DestComputer + "\" + $DestinationPath + "\" + $SourceFile
        Try{
            Remove-Item $Dest
            Write-Host "Removed $SourceFile on \\$DestComputer\$DestinationPath" -ErrorAction Stop
        }
        Catch{
            Write-Host "Could not remove $SourceFile at \\$DestComputer\$Path" -ForegroundColor Red
        }
    }
}
#endregion

#Copy-WindowsUpdateStartupItem -SourceFile "C:\Users\username\Documents\Scripts\WindowsUpdateLink.lnk" -DestinationPath "c$\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
#Report-WindowsUpdates
#Remove-WindowsUpdateStartupItem -SourceFile "WindowsUpdateLink.lnk" -DestinationPath "c$\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"