Param (
    [Parameter(Mandatory=$True, Position=1)][ValidateSet("Start", "Stop")]
    [String] $Action)

Function Stop-VMWare {
    Param ($VMWareServices)

    ForEach ($VMWareService in $VMWareServices.GetEnumerator()) {
        Set-Service $VMWareService.Key -StartupType Disabled
        Stop-Service $VMWareService.Key -Force
    }
}
Function Start-VMWare {
    Param ($VMWareServices)

    ForEach ($VMWareService in $VMWareServices.GetEnumerator()) {
        Set-Service $VMWareService.Key -StartupType $VMWareService.Value
        Start-Service $VMWareService.Key
    }
}
$VMWareServices = @{
    'VMAuthdService'     = 'Automatic'
    'VMnetDHCP'          = 'Automatic'
    'VMUSBArbService'    = 'Automatic'
    'VMware NAT Service' = 'Automatic'
}

Switch ($Action) {
    "Start" { Start-VMWare -VMWareServices $VMWareServices }
    "Stop"  { Stop-VMWare -VMWareServices $VMWareServices }
}