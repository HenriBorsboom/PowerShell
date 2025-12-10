$SoftwarePackages = @()
$SoftwarePackages += ,('Microsoft Monitoring Agent')
$SoftwarePackages += ,('Configuration Manager Client')

Write-Host "Getting installed software - " -NoNewline
$InstalledSoftware = Get-CimInstance -ClassName Win32_Product
ForEach ($SoftwarePackage in $SoftwarePackages) {
    If ($InstalledSoftware.Name -contains $SoftwarePackage) {
        Write-Host "Installed"
        Invoke-CimMethod -InputObject ($InstalledSoftware | Where-Object Name -eq $SoftwarePackage) -MethodName Uninstall
    }
    Else {
        Write-Host "Not Installed"
    }
}