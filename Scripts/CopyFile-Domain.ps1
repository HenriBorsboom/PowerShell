Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string] $File, `
    [Parameter(Mandatory=$True,Position=2)]
    [string] $Path, `
    [Parameter(Mandatory=$false,Position=3)]
    [String] $ReferenceFile)

$TargetServers = Get-Content "C:\temp\computers.txt"
Write-Host " Total Targets: " -NoNewline
Write-Host $TargetServers.Count -ForegroundColor Yellow
[int] $x = 1
foreach ($Target in $TargetServers)
{
    [string] $DestComputer = $Target
    $Dest = "\\" + $Target + "\" + $Path
    Try
    {
        Write-Host "$x - Copying " -NoNewline
        Write-Host "$File" -ForegroundColor Yellow -NoNewline
        Write-Host " to " -NoNewline
        Write-host "$Dest" -NoNewline
        Write-Host " - " -NoNewline
        $Empty = copy-item $File -Destination $Dest -Force
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch
    {
        Write-Host "Failed" -ForegroundColor Red
    }
    $x ++
}
