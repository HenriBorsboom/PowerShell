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
Function Get-IMDBItem {
    <#
    .Synopsis
       Retrieves information about a movie/tv show etc. from IMDB.
    .DESCRIPTION
       This cmdlet fetches information about the movie/tv show matching the specified ID from IMDB.
       The ID is often seen at the end of the URL at IMDB.
    .EXAMPLE
        Get-IMDBItem -ID tt0848228
    .EXAMPLE
       Get-IMDBMatch -Title 'American Dad!' | Get-IMDBItem
       This will fetch information about the item(s) piped from the Get-IMDBMatch cmdlet.
    .PARAMETER ID
       Specify the ID of the tv show/movie you want get. The ID has the format of tt0123456
    #>
    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory                       = $True, 
            ValueFromPipeline               = $True, 
            ValueFromPipelineByPropertyName = $True)]
          [String[]] $ID)

    Begin { }
    Process {
        ForEach ($ImdbID in $ID) {
            $IMDBItem = Invoke-WebRequest -Uri "http://www.imdb.com/title/$ImdbID" -UseBasicParsing
            $ItemInfo = (($IMDBItem.Content -split "<td id=`"overview-top`">")[1] -split "</td>")[0]
            $ItemTitle = (($ItemInfo -split "<span class=`"itemprop`" itemprop=`"name`">")[1] -split "</span>")[0]
            $Type = (((($ItemInfo -split "<div class=`"infobar`">")[1] -split "<")[0]).Trim() -split "`n")[0]
            
            If ($Type -eq 'TV Episode') { $Released = $null }
            Else { $Released = (($ItemInfo -split "<span class=`"nobr`">")[1] -split "</span>")[0] -replace "^\(" -replace "\)$" }
            
            $Description = (((($ItemInfo -split "<p itemprop=`"description`">")[1] -split "</p>")[0] -split "<a href=`"")[0]).trim()
            $Rating = ((($ItemInfo -split "<div class=`"titlePageSprite star-box-giga-star`">")[1] -split "</div>")[0]).trim()
            
            Try { $RuntimeMinutes = (((($ItemInfo -split "<time itemprop=`"duration`" datetime=")[1] -split ">")[1]).trim() -split " ")[0] }
            Catch { $RuntimeMinutes = $null }
            
            If ($Type -eq "") { $Type = "Movie" }
            If ($Released -like "<a href=`"*") { $Released = (($Released -split "/year/")[1] -split "/")[0] }
            If ($Description -like '*Add a plot*') { $Description = $null }
            $ItemObject = New-Object PSObject -Property @{
                ID             = $ImdbID
                Type           = $Type
                Title          = $ItemTitle
                Description    = $Description
                Released       = $Released
                RuntimeMinutes = $RuntimeMinutes
                Rating         = $Rating
            }
            Write-Output $ItemObject
            Remove-Variable IMDBItem, ItemInfo, ItemTitle, Description, Released, Type, Rating, RuntimeMinutes -ErrorAction SilentlyContinue
        }
    }
End { }
}

Get-IMDBMatch -Title "Avengers"