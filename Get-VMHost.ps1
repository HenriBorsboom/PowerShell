Param (
    [Parameter(Mandatory=$True, Position=1)]
    [String] $VM)

$Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $VM)
Write-Host ("VM Host: " + ($Reg.OpenSubKey("SOFTWARE\\Microsoft\\Virtual Machine\\Guest\\Parameters")).GetValue("PhysicalHostName"))
