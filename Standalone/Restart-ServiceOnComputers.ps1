Param(
    [Parameter(Mandatory=$True,Position=1)]
    [bool] $DomainWide, `
    [Parameter(Mandatory=$False,Position=2)]
    [array] $TargetServers, `
    [Parameter(Mandatory=$True,Position=3)]
    [String] $ServiceName)

If ($DomainWide -eq $True)
{
    $TargetServers = Get-Content "C:\temp\computers.txt"
}
Else
{
    If ($TargetServers -eq "" -or $TargetServers -eq $null)
    {
        Write-Host "Domain Wide is set to False and no Target Servers are defined"
        exit 1
    }
}    

Write-Host " Total Targets: " -NoNewline
Write-Host  $TargetServers.Count -ForegroundColor Yellow

[int] $x = 1
        
ForEach ($Server in $TargetServers)
{
    Write-Host "$x - Restarting " -NoNewline
    Write-Host "$ServiceName" -ForegroundColor Yellow -NoNewline
    Write-Host " on " -NoNewline
    Write-Host "$Server" -ForegroundColor Yellow -NoNewline 
    Write-Host " - " -NoNewline
    Try
    {
        $Empty = Icm -ComputerName $Server -ScriptBlock {Restart-Service -Name $ServiceName}
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch
    {
        Write-Host "Failed" -ForegroundColor Red
    }
    $x ++
}
