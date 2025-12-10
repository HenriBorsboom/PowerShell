Function Write-Color {
    <#
    .SYNOPSIS
	    Write Host with Simpler Color Management
    .DESCRIPTION
	    Write-Color gives you the same functionality as Write-Host but with simpler and quicker color management
    .EXAMPLE
	    Write-Color -Text 'Test 1 '
    .EXAMPLE
	    Write-Color -Text 'Test 1 ' -ForegroundColor Black
    .EXAMPLE
	    Write-Color -Text 'Test 1 ' -BackgroundColor Yellow
    .EXAMPLE
	    Write-Color -Text 'Test 1 ' -ForegroundColor Black -BackgroundColor Yellow
    .EXAMPLE
	    Write-Color -Text 'Test 1 ', 'Test 2 ' -ForegroundColor Yellow -BackgroundColor Black
    .EXAMPLE
	    Write-Color -Text 'Test 1 ', 'Test 2 ' -ForegroundColor Yellow, Green -BackgroundColor Black, Yellow
    .EXAMPLE
	    Write-Color -Complete
    .EXAMPLE
	    Write-Color -Text 'Test 1 ', 'Test 2 ' -ForegroundColor Yellow, Green -BackgroundColor Black, Yellow -NoNewline
    .EXAMPLE
	    Write-Color -Complete -NoNewline
    .INPUTS
	    [String[]]
    .PARAMETER Text
	    This is the collection of text that needs to be written to the host
    .INPUTS
	    [ConsoleColor[]]
    .PARAMETER ForegroundColor
	    This is the collection of Foreground colors that needs to be applied to the text
	    If there is more text in the collection and only 1 Foreground color is specified
	    then the first foreground color will be applied to all text
    .INPUTS
	    [ConsoleColor[]]
    .PARAMETER BackgroundColor
	    This is the collection of Background colors that needs to be applied to the text
	    If there is more text in the collection and only 1 Background color is specified
	    then the first Background color will be applied to all text
    .INPUTS
	    [Switch]
    .PARAMETER NoNewLine
	    This is to specify if you want to terminate the line or not
    .INPUTS
	    [Switch]
    .PARAMETER Complete
	    This is will write to the host "Complete" with the Foreground color set to Green
    .INPUTS
	    [Int64]
    .PARAMETER IndexCounter
	    This is the counter for the current item
    .INPUTS
	    [Int64]
    .PARAMETER TotalCounter
	    This is the total number of items that needs to be processed. This is needed
        to format the counter properly
    .Notes
        NAME:  Write-Color
        AUTHOR: Henri Borsboom
        LASTEDIT: 30/08/2017
        KEYWORDS: Write-Host, Console Output, Color
    .Link
        https://www.linkedin.com/pulse/powershell-<>-henri-borsboom
        #Requires -Version 2.0
    #>
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
Clear-Host

$WorkingDirectory = 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots'
Write-Color -Text 'Getting screenshots - ' -NoNewLine -ForegroundColor White 
    $ScreenShots = Get-ChildItem -Path $WorkingDirectory -File
    Write-Color -Text $ScreenShots.Count, ' Found' -ForegroundColor Yellow, White

Write-Color -Text 'Collecting the dates - ' -ForegroundColor White -NoNewLine
    [String[]] $UniqueFolders = @()
    ForEach ($CreationDate in $Screenshots.CreationTime) {
        $UniqueFolders += ($CreationDate.Date.ToString("yyyy-MM-dd"))
    }
    $UniqueFolders = $UniqueFolders | Select-Object -Unique
    #(($ScreenShots.CreationTime).Date.ToString("yyyy/MM/dd")).Replace('/', '-') | Select-Object -Unique
    Write-Color -Text $UniqueFolders.Count, ' - Found' -ForegroundColor Yellow, White

For ($UF = 0; $UF -lt $UniqueFolders.Count; $UF ++) {
    #Delete-LastLine
    Write-Color -IndexCounter $UF -TotalCounter $UniqueFolders.Count -Text 'Creating folder for ', $UniqueFolders[$UF], ' - ' -ForegroundColor White, Yellow, White -NoNewLine
    Try { New-Item -Path ($WorkingDirectory + '\' + $UniqueFolders[$UF]) -ItemType directory -ErrorAction Stop | Out-Null; Write-Color -Complete }
    Catch { Write-Color -Text 'Skipped' -ForegroundColor Red }
}

For ($SC = 0; $SC -lt $ScreenShots.Count; $SC ++) {
    #Delete-LastLine
    Write-Color -IndexCounter $SC -TotalCounter $ScreenShots.Count -Text 'Moving screenshot to ', (($ScreenShots[$SC].CreationTime).Date.ToShortDateString()).Replace('/', '-'), ' - ' -ForegroundColor White, Yellow, White -NoNewLine
    If (Test-Path ($WorkingDirectory + '\' + (($ScreenShots[$SC].CreationTime).Date.ToString("yyyy-MM-dd")))) {
        Move-Item $ScreenShots[$SC].FullName -Destination ($WorkingDirectory + '\' + (($ScreenShots[$SC].CreationTime).Date.ToString("yyyy-MM-dd")))
        Write-Color -Complete
    }
    Else {
        Write-Color -Text 'Failed to find destination' -ForegroundColor Red
    }
}
Write-Host ""
Write-Color -Text "Total Screenshots: ", $ScreenShots.Count, " and Total Unique Dates: ", $UniqueFolders.Count -ForegroundColor White, Magenta, White, Magenta