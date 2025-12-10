$ErrorActionPreference = 'Stop'
# List of IP configurations
$Configs = @(
    @{ 
        IP = (Get-ItemProperty 'HKLM:\Software\WNIP\BLIS' -Name 'IP').IP
        SubnetMask = (Get-ItemProperty 'HKLM:\Software\WNIP\BLIS' -Name 'SubnetMask').SubnetMask
        Gateway = (Get-ItemProperty 'HKLM:\Software\WNIP\BLIS' -Name 'Gateway').Gateway
        DNS = (Get-ItemProperty 'HKLM:\Software\WNIP\BLIS' -Name 'DNS').DNS -split ','
    }
    @{ 
        IP = (Get-ItemProperty 'HKLM:\Software\WNIP\BFTC' -Name 'IP').IP
        SubnetMask = (Get-ItemProperty 'HKLM:\Software\WNIP\BFTC' -Name 'SubnetMask').SubnetMask
        Gateway = (Get-ItemProperty 'HKLM:\Software\WNIP\BFTC' -Name 'Gateway').Gateway
        DNS = (Get-ItemProperty 'HKLM:\Software\WNIP\BFTC' -Name 'DNS').DNS -split ','
    }
)

# Try to create a new event log source for logging
Try {
    New-EventLog -LogName "System" -Source "Windows Network IP Profile" -ErrorAction Stop
}
Catch {
    # Ignore errors if the event log source already exists
}
# Function to detect active network interface
Function Get-ActiveNetworkInterface {
    $ReturnInterface = @()
    $Interfaces = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    ForEach ($Interface in $Interfaces) {
        # Get IP configuration for the interface
        Try {
            $IPConfig = Get-NetIPAddress -InterfaceAlias $Interface.Name
            # Get gateway configuration for the interface
            $GatewayConfig = Get-NetRoute -InterfaceAlias $Interface.Name | Where-Object {$_.DestinationPrefix -eq "0.0.0.0/0"}

            # Check if both an IP configuration and a gateway exist
            if ($IPConfig -and $GatewayConfig) {
                $ReturnInterface += ,($interface)
            }
        }
        Catch { # IPv4 is not enabled on the adapter
        }
    }
    # Return results based on the number of active interfaces found
    # [0] Interface to use, $False if multiple interfaces with gateways configured, $null if no interface found
    # [1] IP configuration.
    # [2] Gateway configuration
    If ($ReturnInterface.Count -gt 1) {
        return $False, $IPConfig, $null # Return false if multiple interfaces are found. First value to specify that there are multiple interfaces with gateways configured. The second value 
    }
    ElseIf ($ReturnInterface.Count -eq 1) {
        return $ReturnInterface[0], $IPConfig, $GatewayConfig # Return the single active interface
    }
    Else {
        return $null, $null, $null # Return null if no active interfaces are found
    }
}
# Function to calculate the prefix length from a subnet mask
Function Get-PrefixLength {
    Param (
        [string] $SubnetMask # Subnet mask as a string
    )
    # Split the subnet mask into octets and calculate the binary representation
    $BinaryMask = ($SubnetMask -split '\.') | ForEach-Object { [Convert]::ToString([int]$_, 2).PadLeft(8, '0') }

    # Count the number of 1s in the binary representation (this equals the prefix length)
    Return ($BinaryMask -join '').ToCharArray() | Where-Object { $_ -eq '1' } | Measure-Object | Select-Object -ExpandProperty Count
}
# Function to configure network settings
Function ConfigureNetwork {
    Param (
        [string] $InterfaceAlias, # Network interface alias
        [string] $IP, # IP address
        [string] $SubnetMask, # Subnet mask
        [string] $Gateway, # Gateway address
        [string[]] $DNS # DNS server addresses
    )
    # Calculate the prefix length
    $PrefixLength = Get-PrefixLength -SubnetMask $SubnetMask 
    
    # Remove existing IP configuration
    Remove-NetIPAddress -InterfaceAlias $InterfaceAlias -Confirm:$false -ErrorAction SilentlyContinue

    # Remove gateway
    Get-NetRoute -InterfaceAlias $InterfaceAlias | Where-Object {$_.DestinationPrefix -eq "0.0.0.0/0"} | Remove-NetRoute -Confirm:$false

    # Assign new IP configuration
    New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IP -PrefixLength $PrefixLength -DefaultGateway $Gateway

    # Set DNS servers
    Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $DNS
    
    # Set DNS suffix search order
    $DNSSuffixSearchOrder = @()
    $DNSSuffixSearchOrder += ,("capitecbank.fin.sky")
    $DNSSuffixSearchOrder += ,("linux.capinet")
    Set-DnsClientGlobalSetting -SuffixSearchList $DNSSuffixSearchOrder
}
# Function to test gateway connectivity
Function TestPing {
    Param (
        [string] $Gateway # Gateway address to test
    ) 
    # Ping the gateway
    $PingResult = Test-Connection -ComputerName $Gateway -Count 2 -Quiet
    Return $PingResult # Return the result of the ping test
}
# Function to disable NetBIOS on all network adapters
Function Disable-NetBIOS {
    # Get all network adapters with IP enabled
    $NetworkAdapters = Get-CimInstance -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }

    ForEach ($Adapter in $NetworkAdapters) {
        # Disable NetBIOS (set to 2)
        If ($Adapter.TCPIPNetBiosOptions -ne '2') {
            $Adapter | Invoke-CimMethod -MethodName SetTcpipNetbios -Arguments @{TcpipNetbiosOptions = 2} # Set NetBIOS option to disabled
            Write-Host "Disabled NetBIOS on interface: $($Adapter.Description)"
            Write-EventLog -LogName "System" -Source "Windows Network IP Profile" -EventId 1001 -EntryType Information -Message "Disabled NetBIOS on interface: $($Adapter.Description)"
        }
    }
}
# Function to disable LMHOSTS lookup
Function Disable-LMHOSTS {
    # Get the current LMHOSTS setting
    $LMHostValue = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters").EnableLMHosts
    If ($LMHostValue -eq 1) {
        # Disable LMHOSTS lookup
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -Name "EnableLMHosts" -Value 0
        Write-Host "Disabled LMHOSTS Lookup"
        Write-EventLog -LogName "System" -Source "Windows Network IP Profile" -EventId 1001 -EntryType Information -Message "Disabled LMHOSTS Lookup"
    }
}
# Function to get entries in HOSTS file
Function Get-ConfiguredHosts {
    # Define the path to the hosts file
    $Hosts = @()
    # Read and filter the hosts file
    Get-Content -Path "C:\Windows\System32\Drivers\etc\hosts" | ForEach-Object {
        # Skip lines starting with '#' (comments) or empty lines
        if ($_ -notmatch "^\s*#|^\s*$") {
            # Use regex to match and split IP and hostname
            if ($_ -match "^\s*(\d{1,3}(\.\d{1,3}){3}|::1)\s+(\S+)") {
                # Output the matched IP and hostname
                $Hosts += ,($matches[1] + " " + $matches[3])
            }
        }
    }
    Return $Hosts -join ';' # Return the hosts as a semicolon-separated string
}
# Function to disable IPv6
Function Disable-IPv6 {
    # Get all network adapters
    $Interfaces = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}

    ForEach ($Interface in $Interfaces) {
        # Check if IPv6 is enabled on the interface
        If ((Get-NetAdapterBinding -Name $Interface.Name | Where-Object ComponentID -eq ms_tcpip6).Enabled -eq $True) {
            Write-Host "Disabling IPv6 on adapter: $($Interface.Name)"
            # Use Disable-NetAdapterBinding to disable IPv6
            Disable-NetAdapterBinding -Name $Interface.Name -ComponentID ms_tcpip6 -Confirm:$false
            Write-EventLog -LogName "System" -Source "Windows Network IP Profile" -EventId 1001 -EntryType Information -Message ("Disabled IPv6 on " + $Interface.Name)
        }
    }
}

# Define the default content for an empty HOSTS file
$EmptyHosts = @"
# Copyright (c) 1993-2009 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
#
# This file contains the mappings of IP addresses to host names. Each
# entry should be kept on an individual line. The IP address should
# be placed in the first column followed by the corresponding host name.
# The IP address and the host name should be separated by at least one
# space.
#
# Additionally, comments (such as these) may be inserted on individual
# lines or following the machine name denoted by a '#' symbol.
#
# For example:
#
#      102.54.94.97     rhino.acme.com          # source server
#       38.25.63.10     x.acme.com              # x client host

# localhost name resolution is handled within DNS itself.
#	127.0.0.1       localhost
#	::1             localhost
"@
# Main script logic
Try {
    Disable-NetBIOS | Out-Null # Disable NetBIOS
    Disable-LMHOSTS | Out-Null # Disable LMHOSTS
    Disable-IPv6 | Out-Null # Disable IPv6

    # Check if the HOSTS file contains entries
    If ((Get-ConfiguredHosts) -ne "") {
        Write-Host "HOSTS file entries are not allowed. File backed up and replaced" -ForegroundColor Red
        Write-EventLog -LogName "System" -Source "Windows Network IP Profile" -EventId 1002 -EntryType Warning -Message "HOSTS file entries are not allowed. File backed up and replaced"
        # Backup and replace the HOSTS file
        Rename-Item -Path "C:\Windows\System32\Drivers\etc\hosts" -NewName ("C:\Windows\System32\Drivers\etc\hosts_" + ((Get-Date).ToString("yyyy-MM-dd HH_mm_ss")) + ".old")
        $EmptyHosts | Out-File "C:\Windows\System32\Drivers\etc\hosts" -Encoding ascii
    }

    # Detect the active network interface
    $ActiveInterface = Get-ActiveNetworkInterface
    if ($null -eq $ActiveInterface[0].Name) {
        Write-Host "No active network interface detected." -ForegroundColor Red
        Throw "No active network interface detected."
        Exit
    }
    ElseIf ($ActiveInterface[0] -eq $false) {
        Write-Host "Too many interfaces with gateways configured" -ForegroundColor Red
        Throw "Too many interfaces with gateways configured"
        Exit
    }

    Write-Host ("Active network interface: " + $ActiveInterface[0].Name)
    $ConfigWorking = $False # Initialize configuration status
    $Gateway = (Get-NetRoute -InterfaceAlias (Get-Netadapter | Where-Object Status -eq 'Up').Name -ErrorAction SilentlyContinue | Where-Object {$_.DestinationPrefix -eq "0.0.0.0/0"}).NextHop
    If (TestPing -Gateway $Gateway) {
        Write-Host "Gateway reachable: $Gateway" -ForegroundColor Green
        $ConfigWorking = $True
        Write-EventLog -LogName "System" -Source "Windows Network IP Profile" -EventId 1001 -EntryType Information -Message ("Gateway reachable. No changes made")
        Break
    }
    Else {
        Write-Host "Gateway unreachable: $Gateway. Moving to next configuration..." -ForegroundColor Red
    }

    # Iterate through the list of configurations
    ForEach ($Config in $Configs) {
        $OldIP = (Get-NetIPAddress -InterfaceAlias $ActiveInterface[0].Name | Select-Object -ExpandProperty IPAddress)
        
        Write-Host "Trying IP: $($Config.IP)"
        ConfigureNetwork -InterfaceAlias $ActiveInterface[0].Name -IP $Config.IP -SubnetMask $Config.SubnetMask -Gateway $Config.Gateway -DNS $Config.DNS | Out-Null
       
        Write-Host "Waiting 5 seconds for configuration to apply..."
        Start-Sleep -Seconds 5
        if (TestPing -Gateway $Config.Gateway) {
            Write-EventLog -LogName "System" -Source "Windows Network IP Profile" -EventId 1001 -EntryType Information -Message ("Success `nOld IP: " + $OldIP.ToString() + "New IP: " +$Config.IP + "`nSubnet Mask: " + $Config.SubnetMask + "`nGateway: " + $Config.Gateway + "`nDNS Servers: " + ($Config.DNS -join ','))
            Write-Host "Gateway reachable: $($Config.Gateway)" -ForegroundColor Green
            $ConfigWorking = $True
            break
        } 
        else {
            Write-Host "Gateway unreachable: $($Config.Gateway). Moving to next configuration..." -ForegroundColor Red
                
            
        }
    }

    # If no configuration worked, reset to the original configuration
    If ($ConfigWorking -eq $False) {
        Write-Host "Resetting configuration" -ForegroundColor Red
        $DNSServers = (Get-ItemProperty ("HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP\Parameters\Interfaces\" + $ActiveInterface[0].InterfaceGuid)).NameServer -split ","
        Remove-NetIPAddress -InterfaceAlias $ActiveInterface[0].Name -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

        # Remove gateway
        Get-NetRoute -InterfaceAlias $ActiveInterface[0].Name | Where-Object {$_.DestinationPrefix -eq "0.0.0.0/0"} | Remove-NetRoute -Confirm:$false | Out-Null

        # Assign new IP configuration
        New-NetIPAddress -InterfaceAlias $ActiveInterface[0].Name -IPAddress $ActiveInterface[1].IPAddress -PrefixLength $ActiveInterface[1].prefixLength -DefaultGateway $ActiveInterface[2].NextHop | Out-Null

        # Set DNS servers
        Set-DnsClientServerAddress -InterfaceAlias $ActiveInterface[0].Name -ServerAddresses $DNSServers | Out-Null
        Write-EventLog -LogName "System" -Source "Windows Network IP Profile" -EventId 1002 -EntryType Warning -Message ("Failed to find IP Profile with accessible gateway. `nThe original IP address has been assigned. `nIP Address: " + $ActiveInterface[1].IPAddress + "`nPrefix Length: " + $ActiveInterface[1].prefixLength + "`nGateway: " + $ActiveInterface[2].NextHop + "`nDNS Servers: " + ($DNSServers -join ","))
    }
    Write-Host "Script completed."
}
Catch {
    # Log any errors that occur
    Write-EventLog -LogName "System" -Source "Windows Network IP Profile" -EventId 1003 -EntryType Error -Message ("Failure: `nLine: " + $_.InvocationInfo.Line + "`n" + $_.Exception.Message)
}