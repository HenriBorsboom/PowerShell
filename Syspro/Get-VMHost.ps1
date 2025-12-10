Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [String] $Computer)

Function Get-RemoteRegistryDetails {
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [String] $Computer, `
        [Parameter(Mandatory = $True, Position = 2)][ValidateSet("ClassesRoot", "CurrentConfig", "CurrentUser", "DynData", "LocalMachine", "PerformanceData", "Users")]
        [String] $Hive, `
        [Parameter(Mandatory = $True, Position = 3)]
        [String] $Key, `
        [Parameter(Mandatory = $True, Position = 1)]
        [String] $Value)

    Try {
        $Registry    = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $Computer)
        $RegistryKey = $Registry.OpenSubKey($Key) # $Registry.OpenSubKey("SOFTWARE\\Microsoft\\Virtual Machine\\Guest\\Parameters")
        $Value       = $RegistryKey.GetValue($Value)
    }
    Catch { $Value = "Not found" }
    Return $Value
}

$VMHost = Get-RemoteRegistryDetails -Computer $Computer -Hive LocalMachine -Key 'SOFTWARE\\Microsoft\\Virtual Machine\\Guest\\Parameters' -Value 'HostName'
New-Object -TypeName PSObject -Property @{
    VirtualMachine = $Computer.ToUpper()
    Host           = $VMHost
} | Select VirtualMachine, Host