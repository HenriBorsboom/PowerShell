Param (
    [Parameter(Mandatory=$False)]
    [String] $Series = 'Supernatural', `
    [Parameter(Mandatory=$False)]
    [Int] $Season = 6, `
    [Parameter(Mandatory=$False)]
    [String] $TTID = 'tt0460681')

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
Function Get-IMDBMatch {
    <#
    .Synopsis
       Retrieves search results from IMDB
    .DESCRIPTION
       This cmdlet posts a search to IMDB and returns the results.
    .EXAMPLE
       Get-IMDBMatch -Title 'American Dad!'
    .EXAMPLE
       Get-IMDBMatch -Title 'American Dad!' | Where-Object { $_.Type -eq 'TV Series' }
    .PARAMETER Title
       Specify the name of the tv show/movie you want to search for.
    #>

    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory                       = $True, 
            ValueFromPipeline               = $True, 
            ValueFromPipelineByPropertyName = $True)]
        [String[]] $Title)

    Begin { }
    Process {
        $MediaTitles = @()
        ForEach ($MediaTitle in $Title) {
            $IMDBSearch = Invoke-WebRequest -Uri "http://www.imdb.com/find?q=$($MediaTitle -replace " ","+")&s=all" -UseBasicParsing
            $FoundMatches = $IMDBSearch.Content -split "<tr class=`"findresult " | select -Skip 1 | % { (($_ -split "<TD class=`"result_text`">")[1] -split "</TD>")[0] } | Select-String -Pattern "fn_al_tt_"
            ForEach ($Match in $FoundMatches) {
                $ID = (($Match -split "/title/")[1] -split "/")[0]
                $MatchTitle = (($Match -split ">")[1] -split "</a")[0]
                $Released = (($Match -split "</a> \(")[1] -split "\)")[0]
                $Type = (($Match -split "\) \(")[1] -split "\) ")[0]

                If ($Type -eq "") { $Type = "Movie" }
                If ($ID -eq "") { Continue }
                $TitleObject = New-Object PSObject -Property @{
                    ID       = $ID
                    Title    = $MatchTitle
                    Released = $Released
                    Type     = $Type
                }
                $MediaTitles = $MediaTitles + $TitleObject
                #Write-Output $TitleObject
                #Remove-Variable ID, MatchTitle, Released, Type
            }
            Remove-Variable FoundMatches, IMDBSearch
        }
    }
    End { 
        Return $MediaTitles
    }
}
Function Get-EpisodeNames {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $ID, `
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Season)

    $TestURL = ('https://www.imdb.com/title/' + $ID + '/episodes?season=' + $Season)
    $URLResults = Invoke-WebRequest -Uri $TestURL

    #($URLResults.AllElements | Where {$_.itemprop -match 'name'}).innerText
    #($URLResults.AllElements | Where {$_.itemprop -match 'episodeNumber'}).Content

    $Details = $URLResults.AllElements | Where {$_.itemprop -match 'episodeNumber' -or $_.itemprop -match 'name'} | Select content, innertext
    $ReFormat = @()

    For ($i = 1; $i -lt ($Details.Count - 1); $i ++) {
        If ($Details.Content[$i] -ne $null) {
            $ReFormat += ,(New-Object -TypeName PSObject -Property @{
                Number = $Details.Content[$i]
                Name   = $Details.InnerText[$i+1]
            })
        }
    }
    $ReturnResults = @()
    For ($EntryI = 0; $EntryI -lt $ReFormat.Count; $EntryI ++) {
        Try { 
            [Int] $ReFormat[$EntryI].Number | Out-Null
            $ReturnResults += ,(New-Object -TypeName PSObject -Property @{
                Number = $ReFormat[$EntryI].Number
                Name   = $ReFormat[$EntryI].Name
            })
        } 
        Catch { 
            
        }
    }
    Return $ReturnResults
}
function Replace-SpecialChars {
    param($InputString)

    #$SpecialChars = '[#?\{\[\(\)\]\}\*\:]'
    $SpecialChars = '[\\\/\:\*\?\"\<\>\|]'
    $Replacement  = ''

    Return $InputString -replace $SpecialChars,$Replacement
}
Function Rename-Episodes {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $EpisodeList, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $Source, `
        [Parameter(Mandatory=$True, Position=3)]
        [String] $SeasonNumber, `
        [Parameter(Mandatory=$True, Position=4)]
        [String] $SeriesName)

    Set-Location $Source
    $VideoFormats = @()
    $VideoFormats += ,('*.avi')
    $VideoFormats += ,('*.mkv')
    $VideoFormats += ,('*.mp4')
    $VideoFormats += ,('*.m4v')
    #$VideoFormats += ,('')
    #$VideoFormats += ,('')
    #$VideoFormats += ,('')

    $SourceFiles = Get-ChildItem -LiteralPath $Source -Include $VideoFormats -Recurse -Force
    If ($EpisodeList.Count -eq $SourceFiles.Count) {
        For ($FileI = 0; $FileI -lt $SourceFiles.Count; $FileI ++) {
            #$CounterLength = $EpisodeList.Count.ToString().Length
            $EpisodeNumber = "{0:D2}" -f [Int] $EpisodeList[$FileI].Number #($EpisodeList.Count.ToString().Length)
            If ($EpisodeList[$FileI].Name.ToString() -match '\\'`
            -or $EpisodeList[$FileI].Name.ToString() -match '\/'`
            -or $EpisodeList[$FileI].Name.ToString() -match '\:'`
            -or $EpisodeList[$FileI].Name.ToString() -match '\*'`
            -or $EpisodeList[$FileI].Name.ToString() -match '\?'`
            -or $EpisodeList[$FileI].Name.ToString() -match '\<'`
            -or $EpisodeList[$FileI].Name.ToString() -match '\>'`
            -or $EpisodeList[$FileI].Name.ToString() -match '\|') {
                $EpisodeName = Replace-SpecialChars -InputString $EpisodeList[$FileI].Name
            }
            Else {
                $EpisodeName = $EpisodeList[$FileI].Name
            }
            
            $NewName = ($SourceFiles[$FileI].DirectoryName + '\' + $SeriesName + ' - ' + 'S' + $SeasonNumber + 'E' + $EpisodeNumber + ' - ' + $EpisodeName + $SourceFiles[$FileI].Extension)
            Write-Color -Text "Renaming ", $SourceFiles[$FileI].BaseName, ' to ', $NewName -ForegroundColor White, Yellow, Red
            Rename-Item -LiteralPath $SourceFiles[$FileI] -NewName $NewName
        }
    }    
    Else {
        Write-Host "Files Mismatch" -ForegroundColor Red
        Write-Host ("File Count on IMDB:   " + $EpisodeList.Count.ToString())
        Write-Host ("File Count on Source: " + $SourceFiles.Count.ToString())
        $EpisodeList
    }
    
}
Clear-Host

If ($Season -lt 10) {
    $SourceFileLocation = ('\\192.168.1.103\Series\' + $Series + '\Season 0' + $Season)
}
Else {
    $SourceFileLocation = ('\\192.168.1.103\Series\' + $Series + '\Season ' + $Season)
}
If ($TTID -eq '') {
    Write-Host ("Searching for IMDB ID for " + $Series + " - ") -NoNewLine
    $ID = Get-IMDBMatch -Title $Series  | Where-Object { $_.Type -eq 'TV Series' -and $_.Title -eq $Series } 
    Write-Host ($ID.ID + " found") -ForegroundColor Green
}
Else {
    $ID = New-Object -TypeName PSObject -Property @{ID = $TTID}
}

Write-Host "Getting Episode Names"
$EpisodeList = Get-EpisodeNames -ID $ID.ID -Season $Season
Rename-Episodes -EpisodeList $EpisodeList -Source $SourceFileLocation -SeasonNumber ('{0:D2}' -f $Season) -SeriesName $Series