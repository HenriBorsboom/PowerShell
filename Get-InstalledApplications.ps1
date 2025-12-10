Clear-Host
$ErrorActionPreference = "Stop"
#region Common Functions
Function Write-Color {
    Param(
        [String[]] $Text, `
        [ConsoleColor[]] $Color, `
        [switch] $EndLine)
    
    If ($Text.Count -ne $Color.Length) {
        Write-Host "DEBUG!!!!! - Write-Color" -ForegroundColor Red
        Write-Host "The amount of Text variables and the amount of color variables does not match"
        Write-Host "Text Variables:  " $Text.Count
        Write-Host "Color Variables: " $Color.Length
        Break
    }
    Else {
        For ($i = 0; $i -lt $Text.Length; $i++) {
            Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
        }
        Switch ($EndLine){
            $true {Write-Host}
            $false {Write-Host -NoNewline}
        }
    }
}
Function Timer {
    Param(
        [Parameter(Mandatory=$true, Position = 1)]
        [Int64] $StartCount)

    $Duration = New-TimeSpan -Seconds($x)
    $s = $Duration.TotalSeconds
    $ts =  [timespan]::fromseconds($s)
    $ReturnVariable = ("{0:hh\:mm\:ss}" -f $ts)
    Return $ReturnVariable
}
Function JobUpdate {
    Param (
        [Parameter(Mandatory=$true, Position = 1)]
        [Int64] $StartCounter, `
        [Parameter(Mandatory=$false, Position = 2)]
        [String] $Server, `
        [Parameter(Mandatory=$false, Position = 3)]
        [Switch] $MyDebug)
    
    $Counter = Timer -StartCount $StartCounter
    Switch ($MyDebug) {
        $true {Write-Host $Counter -ForegroundColor Red}
        $false {Write-Color -Text "Getting installed applications on ", $Server, " - ", $Counter, " - " -Color White, Yellow, White, Red, White}
    }
    Sleep 1
}
Function MultiThread {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [String] $JobName, `
        [Parameter(Mandatory=$true,Position=2)]
        [String[]] $ScriptBlock, `
        [Parameter(Mandatory=$true,Position=3)]
        [String] $Server, `
        [Parameter(Mandatory=$false,Position=4)]
        [Switch] $MyDebug)
    $x = 1
    $GetChildItemJob = Start-Job -Name $JobName -ScriptBlock {Param($Script); Invoke-Expression $Script} -ArgumentList $ScriptBlock -ErrorAction Stop
    $GetChildItemJobState = Get-Job $GetChildItemJob.Id
    While ($GetChildItemJobState.State -eq "Running") {
        Switch ($MyDebug) {
            $true  {JobUpdate -StartCounter $x -Server $Server -MyDebug}
            $false {Delete-LastLine -SameLine; JobUpdate -StartCounter $x -Server $Server}
        }        
        $x ++
    }
    $GetChildItemJobResults = Receive-Job -Job $GetChildItemJob
    Return $GetChildItemJobResults
}
Function Delete-LastLine {
    Param (
        [Parameter(Mandatory = $false)]
        [Switch] $SameLine)
    $x = [Console]::CursorLeft
    $y = [Console]::CursorTop
    #Write-Host "x - $x; y - $y; SameLine - $SameLine"
    #Break
    Switch ($SameLine) {
        $true {
            [Console]::SetCursorPosition(0,$y)
            Write-Host "                                                                                                                                            "
            [Console]::SetCursorPosition(0,$y)
        }
        $False {
            [Console]::SetCursorPosition($x,$y - 1)
            Write-Host "                                                                                                                                            "
            [Console]::SetCursorPosition($x,$y - 1)
        }
    }
}
#endregion

$AllInstalledApplications = @()
#region Server Configs
Write-Color -Text "Getting Computer Objects from ", "Active Directory", " - " -Color White, Yellow, White
    $Servers = Get-ADComputer -Filter {Name -like 'NRA*'}
    $Servers = $Servers | Select -Unique
    $Servers = $Servers | Sort Name
    $Servers = $Servers.Name
Write-Host "Complete" -ForegroundColor Green

$ExcludeComputers = Get-Content "C:\Temp\Computers\Exclude.TXT"
#endregion

$TimeStamp = $([DateTime]::Now.ToString('HH.mm.ss - dd-MM-yyyy'))
$AllExportFile = "C:\Temp\InstalledApplications\AllInstalledApplications - " + $TimeStamp + ".CSV"  
#Write-Color -Text "Exporting All Installed applications to ", $ExportFile, " - " -Color White, Yellow, White
#    $AllInstalledApplications | Out-File $AllExportFile -Encoding ascii -Append -Force -NoClobber
#Write-Host "Complete" -ForegroundColor Green

$Counter = 1
$Count = $Servers.Count
Write-Color -Text "Total Servers: ", $Count -Color White, Yellow -EndLine
ForEach ($Server in $Servers) {
    If ($Exclude -contains $Server) {} Else {
    $ThreadScript = 'Get-WmiObject -Query "Select * from Win32_Product" -ComputerName ' + $Server
    $TimeStamp = $([DateTime]::Now.ToString('HH.mm.ss - dd-MM-yyyy'))
    $ExportFile = "C:\Temp\InstalledApplications\$Server - " + $TimeStamp + ".CSV"
    
    Write-Color -Text "$Counter/$Count", " - Getting installed applications on ", $Server, " - " -Color Cyan, White, Yellow, White -EndLine
    Write-Color -Text "Getting installed applications on ", $Server, " - " -Color White, Yellow, White
        $Results = MultiThread -JobName "InstalledApplications" -ScriptBlock $ThreadScript -Server $Server # -MyDebug
        $ServerResults = $Results | Select __SERVER,Caption,Version
        #$AllInstalledApplications = $AllInstalledApplications + ($ServerResults | Format-Table -AutoSize @{ Label = "Server" ; Expression = {$_.__SERVER}}, @{ Label = "Name";    Expression = {$_.Caption}} , @{ Label = "Version"; Expression = {$_.Version}}   )
    Write-Host "Complete" -ForegroundColor Green
    Write-Color -Text "Exporting installed applications to ", $ExportFile, " - " -Color White, Yellow, White
        $ServerResults | Export-Csv $ExportFile -Force -NoClobber -Encoding ASCII -Append -Delimiter ";" -NoTypeInformation
        $ServerResults | Export-Csv $AllExportFile -Force -NoClobber -Encoding ASCII -Append -Delimiter ";" -NoTypeInformation
        #($ServerResults `
        #    | Format-Table -AutoSize `
        #        @{ Label = "Server" ; Expression = {$_.__SERVER}}, `
        #        @{ Label = "Name";    Expression = {$_.Caption}} , `
        #        @{ Label = "Version"; Expression = {$_.Version}}   ) | `
        #            Out-File $ExportFile -Encoding ascii -Append -Force -NoClobber
    Write-Host "Complete" -ForegroundColor Green
    }
    $Counter ++
}
#$TimeStamp = $([DateTime]::Now.ToString('HH.mm.ss - dd-MM-yyyy'))
#$AllExportFile = "C:\Temp\InstalledApplications\AllInstalledApplications - " + $TimeStamp + ".CSV"  
#Write-Color -Text "Exporting All Installed applications to ", $ExportFile, " - " -Color White, Yellow, White
#    $AllInstalledApplications | Out-File $AllExportFile -Encoding ascii -Append -Force -NoClobber
#Write-Host "Complete" -ForegroundColor Green
