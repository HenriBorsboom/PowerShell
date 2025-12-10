$ErrorActionPreference = 'Stop'
Write-Host "Getting HTML Files - " -NoNewline
$HTMLFiles = Get-ChildItem 'C:\HealthCheck\Reports\2022-04-07' -Recurse *.html
Write-Host ($HTMLFiles.Count.ToString() + ' found') -ForegroundColor Green

$Errors = @()
For ($i = 1; $i -lt $HTMLFiles.Count; $i ++) {
    Write-host (($i + 1).ToString() + '/' + $HTMLFiles.Count.ToString() + ' Processing ' + $HTMLFiles[$i].BaseName + ' - ') -NoNewline
    Try {
        (Get-Content $HTMLFiles[$i].FullName).Replace("http://sccmprd01:", "http://sccmprd01.mercantile.co.za:") | Out-File $HTMLFiles[$i].FullName
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        $Errors += ,(New-Object -TypeName PSObject -Property @{
            File = $HTMLFiles[$i].FullName
            Error = $_
        })
        Write-Host $_ -ForegroundColor Red
    }
}
If ($null -ne $Errors) {
    $Errors | Out-GridView
}