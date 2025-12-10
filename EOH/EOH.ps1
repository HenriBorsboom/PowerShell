Function Get-VMHost {
    Param(
            [Parameter(Mandatory = $True, Position = 1)]
            [String] $Computer)

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
    $VMHost = Get-RemoteRegistryEntry -Computer $Computer -Hive LocalMachine -Key "SOFTWARE\\Microsoft\\Virtual Machine\\Guest\\Parameters" -Value "HostName"
    Return $VMHost
} # Example: Get-VMHost -Computer 'Server'
Function Restart-vCenter {
    Stop-Service vctomcat -Verbose
    Stop-Service ADAM_VMwareVCMSDS -Verbose
    Stop-Service vpxd -Verbose

    Start-Service ADAM_VMwareVCMSDS -Verbose
    Start-Service vpxd -Verbose
    Start-Service vctomcat -Verbose
} # Example: Restart-vCenter # Note: Run on server where vCenter services are hosted
Function Audit-Standalone-Hyper-V {
    $Properties = @("Name", "State", "CPUUsage(%)", "MemoryAssigned(M)", "Uptime", "Status", "ComputerName")
    $Hosts = @()
        $Hosts += ,("")
        $Hosts += ,("")
        $Hosts += ,("")
        $Hosts += ,("")
        $Hosts += ,("")
        $Hosts += ,("")
        $Hosts += ,("")
        $Hosts += ,("")
        $Hosts += ,("")
        $Hosts += ,("")

    $AllVMS = @()
    ForEach ($VMHost in $Hosts) {
        $VMS = Get-VM -ComputerName $VMHost | Select $Properties
        $AllVMS += $VMS
    }
    $Audit = $AllVMS | Select $Properties | Format-Table -AutoSize
    Return $Audit
} # Example: Audit-Standalone-Hyper-V # Note: Set Hosts lists first within Function