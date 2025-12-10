Function Get-RemoteRegistryEntry {
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
        $RegistryKey = $Registry.OpenSubKey($Key)
        $Value       = $RegistryKey.GetValue($Value)
    }
    Catch { $Value = "Not found" }
    Return $Value
} # Example: Get-RemoteRegistryEntry -Computer 'SYSJHBVMM' -Hive LocalMachine -Key "SOFTWARE\\Microsoft\\Virtual Machine\\Guest\\Parameters" -Value "HostName"
Function Get-RemoteVMHost {
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [String] $Computer)

    Try {
        $Registry    = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $Computer)
        $RegistryKey = $Registry.OpenSubKey("SOFTWARE\\Microsoft\\Virtual Machine\\Guest\\Parameters")
        $Value       = $RegistryKey.GetValue("HostName")
    }
    Catch { $Value = "Not found" }
    Return $Value
}        # Example: Get-RemoteVMHost -Computer 'SYSJHBVMM'
Function Get-VMHost {
    Try {
        $Registry    = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $env:COMPUTERNAME)
        $RegistryKey = $Registry.OpenSubKey("SOFTWARE\\Microsoft\\Virtual Machine\\Guest\\Parameters")
        $Value       = $RegistryKey.GetValue("HostName")
    }
    Catch { $Value = "Not found" }
    Return $Value
}              # Example: Get-VMHost


Get-RemoteRegistryEntry -Computer 'SYSJHBFS' -Hive LocalMachine -Key "SOFTWARE\\Microsoft\\OLE" -Value "EnableDCOM"
Get-RemoteRegistryEntry -Computer 'SYSCTDC' -Hive LocalMachine -Key "SOFTWARE\\Microsoft\\OLE" -Value "EnableDCOM"
Get-RemoteRegistryEntry -Computer 'SYSCTSTORE' -Hive LocalMachine -Key "SOFTWARE\\Microsoft\\OLE" -Value "EnableDCOM"