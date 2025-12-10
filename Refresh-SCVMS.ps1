Write-Host "Collecting all Virtual Machines loaded in Virtual Machine Manager - " -NoNewline
Try
{
    $SCVMMVirtuals = Get-SCVirtualMachine -all -ErrorAction Stop
    Write-Host "Complete" -ForegroundColor Green
}
Catch
{
    Write-Host "Failed" -ForegroundColor Red
    Exit 1
}
Write-Host "  Total Virtuals: " -NoNewline
Write-Host $SCVMMVirtuals.Count -ForegroundColor Yellow
Write-Host ""
[int] $x = 1
ForEach ($VM in $SCVMMVirtuals)
{
    $DisplayName = $VM.Name
    Write-Host "$x - Refreshing" -NoNewline
    Write-Host " $VM " -ForegroundColor Yellow -NoNewline
    Write-Host "- " -NoNewline
    Try
    {
        $Empty = Read-SCVirtualMachine -VM $VM
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch
    {
        Write-Host "Failed" -ForegroundColor Red
    }
    $x ++
}
