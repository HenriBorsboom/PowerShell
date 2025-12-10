$ErrorActionPreference = "SilentlyContinue"
Function Get-OldestYears {
    Param (
        $dateStrings
    )
    # Example array of date strings
    #$dateStrings = $ReportContents.LastWriteTime

    # Convert the date strings to DateTime objects
    $dateTimes = $dateStrings | ForEach-Object { [datetime]::ParseExact($_, "MM/dd/yyyy HH:mm:ss", $null) }

    # Extract the years from the DateTime objects
    $years = $dateTimes | ForEach-Object { $_.Year }

    # Get unique years and sort them
    $uniqueYears = $years | Sort-Object -Unique

    # Retrieve the two oldest years
    $twoOldestYears = $uniqueYears | Select-Object -First 2

    # Output the results
    Return $twoOldestYears
}
$ReportFiles = Get-ChildItem 'C:\Temp\CommVault\CalculateReports\Reports\*.csv'
$Details = @()
For ($i = 0; $i -lt $ReportFiles.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $ReportFiles.Count.ToString() + ' - Loading ' + $ReportFiles[$i] + ' - ') -NoNewline
    [Object[]] $ReportContents = Import-CSV $ReportFiles[$i].FullName -Delimiter '|'
    Write-Host "Complete" -ForegroundColor Green
    Write-Host "|- Getting Oldest Years - " -NoNewline
    $OldestYears = Get-OldestYears $ReportContents.LastWriteTime
    Write-Host "Complete" -ForegroundColor Green
    Write-Host "|- Calculating size - " -NoNewline
    $Size = [Math]::Round(($ReportContents | Measure-Object -Sum Length).Sum / 1MB, 2)
    Write-Host "Complete" -ForegroundColor Green
    $Details +=, (New-Object -TypeName PSObject -Property @{
        Report = $ReportFiles[$i].FullName
        TotalFiles = $ReportContents.Count
        SizeGB = $Size
        OldestYear1 = $OldestYears[0]
        OldestYear2 = $OldestYears[1]
    })


    Remove-Variable ReportContents
    Remove-Variable OldestYears
    Remove-Variable Size
    [GC]::Collect()
    #
}
$Details | Select-Object Report, TotalFiles, SizeGB, OldestYear1, OldestYear2 | Out-GridView