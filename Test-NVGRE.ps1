Clear-Host

Try {
    Write-Host "Getting Network Services - " -NoNewline
        $NetworkServices = Get-SCNetworkService -ErrorAction Stop
    Write-Host "Found:" $NetworksServices.Count -ForegroundColor Green
    Write-Host "Getting 'Run As' Account - " -NoNewline
        $RunAsAccount = Get-SCRunAsAccount -Name "Domain2 - VMM Host Access Account"
    Write-Host "Complete" -ForegroundColor Green
}
Catch { Write-Host "Failed" -ForegroundColor Red; $_ }

ForEach ($NetworkService in $NetworkServices) {
    Write-Host "Processing " -NoNewline
    Write-Host $NetworkService.Name -ForegroundColor Yellow
    Try {
        $empty = Read-SCNetworkService -NetworkService $NetworkService -ErrorAction Stop
        Test-SCNetworkService -ConnectionString $NetworkService.ConnectionString -RunAsAccount $RunAsAccount -ConfigurationProvider $NetworkService.ConfigurationProvider -ErrorAction Stop
    }
    Catch { Write-Host "Failed" -ForegroundColor Red; $_ }
}