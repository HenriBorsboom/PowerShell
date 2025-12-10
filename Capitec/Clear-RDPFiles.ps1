Write-Host ((Get-ChildItem $env:userprofile\downloads\*.rdp).Count.ToString() + ' found')
Remove-Item $env:userprofile\downloads\*.rdp