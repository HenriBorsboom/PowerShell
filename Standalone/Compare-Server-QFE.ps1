$ErrorActionPreference = "Stop"
Function Write-Color {
    Param(
        [Parameter(Mandatory=$true, Position=1)]
        [String[]] $Text, `
        [Parameter(Mandatory=$true, Position=2)]
        [ConsoleColor[]] $Color, `
        [Parameter(Mandatory=$false, Position=3)]
        [switch] $EndLine)
    
    If ($Text.Count -ne $Color.Length) {
        Write-Host "The amount of Text variables and the amount of color variables does not match" -ForegroundColor Red
        Write-Host "Text Variables:  " -NoNewline
        Write-Host $Text.Count -ForegroundColor Yellow -NoNewline
        Write-Host " - Color Variables: " -NoNewline
        Write-Host $Color.Length -ForegroundColor Yellow
        Break
    }
    Else {
        For ($TextArrayIndex = 0; $TextArrayIndex -lt $Text.Length; $TextArrayIndex ++) {
            Write-Host $Text[$TextArrayIndex] -Foreground $Color[$TextArrayIndex] -NoNewLine
        }
        Switch ($EndLine) {
            $true  { Write-Host }
            $false { Write-Host -NoNewline}
        }
    }
}
Function Split-String {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $ReferenceString)
    $Separator = ":"
    $Option = [System.StringSplitOptions]::RemoveEmptyEntries
    $SplitString = $ReferenceString.Split($Separator,3, $Option)
    $ReturnString = $SplitString[2]
    Return $ReturnString
}
Function Get-KBDetails {
    Param (
        [Parameter(Mandatory=$True, Position=2)]
        [String] $Server)

    If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Class Win32_ReliabilityRecords -Filter "Sourcename = 'Microsoft-Windows-WindowsUpdateClient'" | Where Message -like "*KB*" }
    Else { $WMIResults = Get-WmiObject -Class Win32_ReliabilityRecords -Filter "Sourcename = 'Microsoft-Windows-WindowsUpdateClient'" -ComputerName $Server | Where Message -like "*KB*" }
    Return $WMIResults
}
Function Get-KBMessage {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $KB, `
        [Parameter(Mandatory=$True, Position=2)]
        [Object[]] $KBDetails)

    For ($Index = 0; $Index -lt $KBDetails.Message.Count; $Index ++) {
        If ($KBDetails[$Index].Message -like "*$KB*") {
            $CleanerMessage = Split-String -ReferenceString $KBDetails[$Index].Message.ToString()
            Return $CleanerMessage
        }
    }
    Return
}
Function Get-QFE {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)

    If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Class "Win32_QuickFixEngineering" | Select * }
    Else                               { $WMIResults = Get-WmiObject -Class "Win32_QuickFixEngineering" -ComputerName $Server | Select * }
    Return $WMIResults
}
Function Compare-QFE {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String]  $SourceServer, `
        [Parameter(Mandatory=$true, Position=2)]
        [String]  $TargetServer, `
        [Parameter(Mandatory=$true, Position=3)]
        [Object[]] $SourceServerQFE, `
        [Parameter(Mandatory=$true, Position=4)]
        [Object[]] $TargetServerQFE, `
        [Parameter(Mandatory=$true, Position=5)]
        [Object[]] $TargetServerQFEDetails)
    
    $Counter = 1
    For ($Index = 0; $Index -lt $TargetServerQFE.Count; $Index ++) {
        If ($SourceServerQFE.HotFixID -notcontains $TargetServerQFE[$Index].HotFixID) { 
            $Results = Get-KBMessage -KB $TargetServerQFE[$Index].HotFixID -KBDetails $SourceServerQFEDetails
            If ($Results -ne $null) { 
                ForEach ($Result in $Results) { 
                    Write-Color -Text  ("{0:D3}" -f $Counter), " - ", $SourceServer, " - ", $TargetServerQFE[$Index].HotFixID, " - ", $TargetServerQFE[$Index].Caption, " - ", $Result, " - ", "Missing" `
                                -Color Cyan,         White, Yellow,        White, Yellow,                            White, Yellow,                           White, Yellow,  White, Red -EndLine }
            }
            Else { 
                    Write-Color -Text  ("{0:D3}" -f $Counter), " - ", $SourceServer, " - ", $TargetServerQFE[$Index].HotFixID, " - ", $TargetServerQFE[$Index].Caption, " - ", "Missing" `
                                -Color Cyan,         White, Yellow,        White, Yellow,                            White, Yellow,                           White, Red -EndLine
            }
            $Counter ++
        }
    }
}
Function Compare-Servers {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $SourceServer, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $TargetServer)

    Write-Color -Text "Retrieving QFE Installed on    - ", $SourceServer, " - " -Color White, Yellow, White
    $SourceServerQFE = Get-QFE -Server $SourceServer
    Write-Host "Complete" -ForegroundColor Green
    Write-Color -Text "Retrieving QFE Installed on    - ", $TargetServer, " - " -Color White, Yellow, White
    $TargetServerQFE = Get-QFE -Server $TargetServer
    Write-Host "Complete" -ForegroundColor Green
    
    Write-Color -Text "Retrieving QFE Descriptions on - ", $SourceServer, " - " -Color White, Yellow, White
    $SourceServerQFEDetails = Get-KBDetails -Server $SourceServer
    Write-Host "Complete" -ForegroundColor Green
    Write-Color -Text "Retrieving QFE Descriptions on - ", $TargetServer, " - " -Color White, Yellow, White
    $TargetServerQFEDetails = Get-KBDetails -Server $TargetServer
    Write-Host "Complete" -ForegroundColor Green
    
    Write-Color -Text $SourceServer, " - Total installed Hotfixes - ", $SourceServerQFE.HotFixID.Count -Color Yellow, WHite, Yellow -EndLine
    Write-Color -Text $TargetServer, " - Total installed Hotfixes - ", $TargetServerQFE.HotFixID.Count -Color Yellow, WHite, Yellow -EndLine
        If ($SourceServerQFE.HotFixID.Count -eq $TargetServerQFE.HotFixID.Count) { Break }
    ElseIf ($SourceServerQFE.HotFixID.Count -gt $TargetServerQFE.HotFixID.Count) { $MissingPatchCount = $SourceServerQFE.HotFixID.Count - $TargetServerQFE.HotFixID.Count }
    Else                                                                         { $MissingPatchCount = $TargetServerQFE.HotFixID.Count - $SourceServerQFE.HotFixID.Count }
    
    Write-Color -Text "Missing Patch Count - ", $MissingPatchCount -Color Yellow, Red -EndLine

    Write-Color -Text "Comparing ", $SourceServer, " with ", $TargetServer -Color White, Yellow, White, Yellow -EndLine
    Compare-QFE -SourceServer $SourceServer -TargetServer $TargetServer -SourceServerQFE $SourceServerQFE -TargetServerQFE $TargetServerQFE -TargetServerQFEDetails $TargetServerQFEDetails
    
    Write-Color -Text "Comparing ", $TargetServer, " with ", $SourceServer -Color White, Yellow, White, Yellow -EndLine
    Compare-QFE -SourceServer $TargetServer -TargetServer $SourceServer -SourceServerQFE $TargetServerQFE -TargetServerQFE $SourceServerQFE -TargetServerQFEDetails $SourceServerQFEDetails
}

Clear-Host
Compare-Servers -SourceServer "NRAZUREVMH101" -TargetServer "NRAZUREVMH201"