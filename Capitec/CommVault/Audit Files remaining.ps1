Function Get-RunDetails {
    Param (
        [Parameter(Mandatory=$True, Position=1)][AllowEmptyString()]
        [String] $Run
    )

    $Reports = (Get-ChildItem ('C:\Temp\CommVault\Reports\' + $Run) -File | Sort-Object BaseName).FullName

    $TotalCount = @()

    For ($i = 0; $i -lt $Reports.Count; $i ++) {
        Write-Host (($i + 1).ToString() + '/' + $Reports.Count.ToString() + ' - Processing ' + $Reports[$i] + ' - ') -NoNewline
        $Contents = Get-Content $Reports[$i]
        Write-Host $Contents.Count.ToString() -ForegroundColor Yellow
        $TotalCount += ,(New-Object -TypeName PSObject -Property @{
            Report = $Reports[$i]
            Files = $Contents.Count
        })
        Remove-Variable Contents
        [GC]::Collect()
    }
    Write-Host ("Total Files: " + ($TotalCount | Measure-Object -Sum Files).Sum.ToString()) -ForegroundColor Magenta
    $TotalCount | Out-GridView
    $TotalCount | Export-CSV ('C:\Temp\CommVault\TotalFilesReport_' + (Get-Date -Format 'yyyy-MM-dd HH-mm-ss') + '_' + $Run + '.csv') -Encoding ASCII -Delimiter ','
}
Get-RunDetails -Run ""