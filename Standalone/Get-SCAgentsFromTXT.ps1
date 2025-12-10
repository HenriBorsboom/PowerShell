Clear-Host
$ErrorActionPreference = "SilentlyContinue"

$SCCM        = "Configuration Manager Client"
$SCOM        = "Microsoft Monitoring Agent"
$SCEP        = "Microsoft Forefront Endpoint Protection 2010 Server Management"
$SDPM        = "Microsoft System Center 2012 R2 DPM Protection Agent"

$SCCMServers = @()
$SCOMServers = @()
$SCEPServers = @()
$SDPMServers = @()

$Files   = Get-ChildItem -Path C:\Temp\Temp -Filter *.txt

ForEach ($File in $Files) {
    $Products = Get-Content -Path $File.FullName
    If ($Products.Contains($SCCM)) {
        $SCCMServers = $SCCMServers + $File.Name
    }
    If ($Products.Contains($SCOM)) {
        $SCOMServers = $SCOMServers + $File.Name
    }
    If ($Products.Contains($SCEP)) {
        $SCEPServers = $SCEPServers + $File.Name
    }
    If ($Products.Contains($SDPM)) {
        $SDPMServers = $SDPMServers + $File.Name
    }
}
$SCCMServers | Out-File C:\Temp\$SCCM.txt -Encoding ascii -Force -NoClobber
$SCOMServers | Out-File C:\Temp\$SCOM.txt -Encoding ascii -Force -NoClobber
$SCEPServers | Out-File C:\Temp\$SCEP.txt -Encoding ascii -Force -NoClobber
$SDPMServers | Out-File C:\Temp\$SDPM.txt -Encoding ascii -Force -NoClobber
