Clear-Host
$ScriptBlock = {
    $SXSFolder = 'C:\Windows\WinSXS'
    Write-Host "Calculating Size of $SXSFolder before removal: " -NoNewline
        $BeforeSize = [Math]::Round((Get-ChildItem $SXSFolder -Recurse | Measure-Object -Property Length -sum).Sum / 1024/1024, 2)
    Write-Host ($BeforeSize.ToString() + " MB")
    Write-Host "Removing Available Windows Features - " -NoNewline
        Get-WindowsFeature | Where-Object -FilterScript { $_.Installed -Eq $FALSE } | Uninstall-WindowsFeature -Remove | Out-Null
    Write-Host "Complete"
    Write-Host "Calculating Size of $SXSFolder After Removal: " -NoNewline
        $AfterSize = [Math]::Round((Get-ChildItem $SXSFolder -Recurse | Measure-Object -Property Length -sum).Sum / 1024/1024, 2)
    Write-Host ($AfterSize.ToString() + " MB")
    Write-Host ("Size Before: " + $BeforeSize)
    Write-Host ("Size After:  " + $AfterSize)
    Write-Host ("Space Saved: " + ($BeforeSize - $AfterSize) + " MB")
}
Write-Host "Getting Computer Object in AD - " -NoNewline
    $Servers = (Get-ADComputer -Filter {Name -Like "*"} | Sort Name).Name
Write-Host $Servers.Count -ForegroundColor Yellow
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Try {
        Write-Host ("Checking if " + $Servers[$i] + " is online - ") -NoNewline
        If (Test-Connection $Servers[$i] -Count 1 -Quiet) {
            Write-Host "Online" -ForegroundColor Green
            Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' ' + $Servers[$i])
            Invoke-Command -ComputerName $Servers[$i] -ScriptBlock $ScriptBlock
        }
        Else { Write-Host "Offline" -ForegroundColor Red }
    }
    Catch { Write-Host $_ -ForegroundColor Red }
}