$ErrorActionPreference = 'Stop'
Function Set-Registry {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $RegPath, `
        [Parameter(Mandatory=$True, Position = 2)]
        [String] $RegName, `
        [Parameter(Mandatory=$True, Position = 3)][AllowEmptyString()]
        [String] $RegValue, `
        [Parameter(Mandatory=$True, Position = 4)][ValidateSet('Binary','DWORD','ExpandString','MultiString','QWORD','String')]
        [String] $RegType
    )

    Try {
        Get-ItemProperty -Path $RegPath -Name $RegName | Out-Null
        Set-ItemProperty -Path $RegPath -Name $RegName -Value $RegValue | Out-Null
    }
    Catch {
        If (Test-Path $RegPath) {
            # Path Exists
        }
        Else {
            $SplitPath = $RegPath -split '\\'
            For ($i = 0; $i -le ($SplitPath.Count - 1); $i ++) {
                If (Test-Path -LiteralPath (($SplitPath[0..$i]) -join '\')) {
                    #folder exists
                }
                Else {
                    New-Item (($SplitPath[0..$i]) -join '\') | Out-Null
                }
            }
        }
        New-ItemProperty -Path $RegPath -Name $RegName -Value $RegValue -PropertyType $RegType | Out-Null
    }
}

# 1.1.6. (L1) Ensure 'Relax minimum password length limits' is set to 'Enabled'
Write-Host "1.1.6. (L1) Ensure 'Relax minimum password length limits' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\System\CurrentControlSet\Control\SAM' -RegName 'MinimumPasswordLengthLimits'  -RegValue 1 -RegType DWORD

# 2.3.1.1 (L1) Ensure 'Accounts: Block Microsoft accounts' is set to 'Users can't add or log on with Microsoft accounts' (Automated)
Write-Host "2.3.1.1 (L1) Ensure 'Accounts: Block Microsoft accounts' is set to 'Users can't add or log on with Microsoft accounts' (Automated)"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -RegName 'NoConnectedUser' -RegValue 3 -RegType DWord 

# 2.3.4.1. (L1) Ensure 'Devices: Allowed to format and eject removable media' is set to 'Administrators'
Write-Host "2.3.4.1. (L1) Ensure 'Devices: Allowed to format and eject removable media' is set to 'Administrators'"
Set-Registry -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers' -RegName 'AddPrinterDrivers' -RegValue 1 -RegType DWORD

# 2.3.7.2. (L1) Ensure 'Interactive logon: Don't display last signed-in' is set to 'Enabled'
Write-Host "2.3.7.2. (L1) Ensure 'Interactive logon: Don't display last signed-in' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -RegName 'DontDisplayLastUserName' -RegValue 1 -RegType DWORD

# 2.3.7.8 (L1) Ensure 'Interactive logon: Require Domain Controller Authentication to unlock workstation' is set to 'Enabled' (MS only) (Automated)
Write-Host "2.3.7.8 (L1) Ensure 'Interactive logon: Require Domain Controller Authentication to unlock workstation' is set to 'Enabled' (MS only) (Automated)"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -RegName 'ForceUnlockLogon'-RegValue 1 -RegType DWORD

# 2.3.9.3. (L1) Ensure 'Microsoft network server: Digitally sign communications (if client agrees)' is set to 'Enabled'
Write-Host "2.3.9.3. (L1) Ensure 'Microsoft network server: Digitally sign communications (if client agrees)' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters' -RegName 'EnableSecuritySignature' -RegValue 1 -RegType DWORD

# 2.3.9.5. (L1) Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher (MS only)
Write-Host "2.3.9.5. (L1) Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher (MS only)"
Set-Registry -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters' -Regname 'SMBServerNameHardeningLevel' -RegValue 1 -RegType DWORD

# 2.3.10.12. (L1) Ensure 'Network access: Shares that can be accessed anonymously' is set to 'None'
Write-Host "2.3.10.12. (L1) Ensure 'Network access: Shares that can be accessed anonymously' is set to 'None'"
Set-Registry -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters' -RegName 'NullSessionShares' -RegValue '' -RegType MultiString

# 2.3.11.1. (L1) Ensure 'Network security: Allow Local System to use computer identity for NTLM' is set to 'Enabled'
Write-Host "2.3.11.1. (L1) Ensure 'Network security: Allow Local System to use computer identity for NTLM' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -RegName 'UseMachineId' -RegValue 1 -RegType DWORD

# 2.3.11.3. (L1) Ensure 'Network Security: Allow PKU2U authentication requests to this computer to use online identities' is set to 'Disabled'
Write-Host "2.3.11.3. (L1) Ensure 'Network Security: Allow PKU2U authentication requests to this computer to use online identities' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\pku2u' -RegName 'AllowOnlineID' -RegValue 0 -RegType DWORD

# 2.3.11.4. (L1) Ensure 'Network security: Configure encryption types allowed for Kerberos' is set to 'AES128_HMAC_SHA1, AES256_HMAC_SHA1, Future encryption types'
Write-Host "2.3.11.4. (L1) Ensure 'Network security: Configure encryption types allowed for Kerberos' is set to 'AES128_HMAC_SHA1, AES256_HMAC_SHA1, Future encryption types'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters' -RegName 'SupportedEncryptionTypes' -RegValue 2147483640 -RegType DWORD

# 2.3.11.9. (L1) Ensure 'Network security: Minimum session security for NTLM SSP based (including secure RPC) clients' is set to 'Require NTLMv2 session security, Require 128-bit encryption'
Write-Host "2.3.11.9. (L1) Ensure 'Network security: Minimum session security for NTLM SSP based (including secure RPC) clients' is set to 'Require NTLMv2 session security, Require 128-bit encryption'"
Set-Registry -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0' -Regname 'NTLMMinClientSec' -RegValue 537395200 -RegType DWORD

# 2.3.11.10. (L1) Ensure 'Network security: Minimum session security for NTLM SSP based (including secure RPC) servers' is set to 'Require NTLMv2 session security, Require 128-bit encryption'
Write-Host "2.3.11.10. (L1) Ensure 'Network security: Minimum session security for NTLM SSP based (including secure RPC) servers' is set to 'Require NTLMv2 session security, Require 128-bit encryption'"
Set-Registry -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0' -Regname 'NTLMMinServerSec' -RegValue 537395200 -RegType DWORD

# 9.1.1. (L1) Ensure 'Windows Firewall: Domain: Firewall state' is set to 'On (recommended)'
Write-Host "9.1.1. (L1) Ensure 'Windows Firewall: Domain: Firewall state' is set to 'On (recommended)'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile' -RegName 'EnableFirewall' -RegValue 1 -RegType DWORD

# 9.1.2. (L1) Ensure 'Windows Firewall: Domain: Inbound connections' is set to 'Block (default)'
Write-Host "9.1.2. (L1) Ensure 'Windows Firewall: Domain: Inbound connections' is set to 'Block (default)'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile' -RegName 'DefaultInboundAction' -RegValue 1 -RegType DWORD

# 9.1.3. (L1) Ensure 'Windows Firewall: Domain: Outbound connections' is set to 'Allow (default)'
Write-Host "9.1.3. (L1) Ensure 'Windows Firewall: Domain: Outbound connections' is set to 'Allow (default)'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile' -RegName 'DefaultOutboundAction' -RegValue 0 -RegType DWORD

# 9.1.4. (L1) Ensure 'Windows Firewall: Domain: Settings: Display a notification' is set to 'No'
Write-Host "9.1.4. (L1) Ensure 'Windows Firewall: Domain: Settings: Display a notification' is set to 'No'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile' -RegName 'DisableNotifications' -RegValue 1 -RegType DWORD

# 9.1.5. (L1) Ensure 'Windows Firewall: Domain: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\domainfw.log'
Write-Host "9.1.5. (L1) Ensure 'Windows Firewall: Domain: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\domainfw.log'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging' -RegName 'LogFilePath' -RegValue '%SystemRoot%\System32\logfiles\firewall\domainfw.log' -RegType String

# 9.1.6. (L1) Ensure 'Windows Firewall: Domain: Logging: Size limit (KB)' is set to '16,384 KB or greater'
Write-Host "9.1.6. (L1) Ensure 'Windows Firewall: Domain: Logging: Size limit (KB)' is set to '16,384 KB or greater'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging' -RegName 'LogFileSize' -RegValue 16384 -RegType DWORD

# 9.1.7. (L1) Ensure 'Windows Firewall: Domain: Logging: Log dropped packets' is set to 'Yes'
Write-Host "9.1.7. (L1) Ensure 'Windows Firewall: Domain: Logging: Log dropped packets' is set to 'Yes'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging' -RegName 'LogDroppedPackets' -RegValue 1 -RegType DWORD

# 9.1.8. (L1) Ensure 'Windows Firewall: Domain: Logging: Log successful connections' is set to 'Yes'
Write-Host "9.1.8. (L1) Ensure 'Windows Firewall: Domain: Logging: Log successful connections' is set to 'Yes'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging' -RegName 'LogSuccessfulConnections' -RegValue 1 -RegType DWORD

# 9.2.1. (L1) Ensure 'Windows Firewall: Private: Firewall state' is set to 'On (recommended)'
Write-Host "9.2.1. (L1) Ensure 'Windows Firewall: Private: Firewall state' is set to 'On (recommended)'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile' -RegName 'EnableFirewall' -RegValue 1 -RegType DWORD

# 9.2.2. (L1) Ensure 'Windows Firewall: Private: Inbound connections' is set to 'Block (default)'
Write-Host "9.2.2. (L1) Ensure 'Windows Firewall: Private: Inbound connections' is set to 'Block (default)'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile' -RegName 'DefaultInboundAction' -RegValue 1 -RegType DWORD

# 9.2.3. (L1) Ensure 'Windows Firewall: Private: Outbound connections' is set to 'Allow (default)'
Write-Host "9.2.3. (L1) Ensure 'Windows Firewall: Private: Outbound connections' is set to 'Allow (default)'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile' -RegName 'DefaultOutboundAction' -RegValue 0 -RegType DWORD

# 9.2.4. (L1) Ensure 'Windows Firewall: Private: Settings: Display a notification' is set to 'No'
Write-Host "9.2.4. (L1) Ensure 'Windows Firewall: Private: Settings: Display a notification' is set to 'No'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile' -RegName 'DisableNotifications' -RegValue 1 -RegType DWORD

# 9.2.5. (L1) Ensure 'Windows Firewall: Private: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\privatefw.log'
Write-Host "9.2.5. (L1) Ensure 'Windows Firewall: Private: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\privatefw.log'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging' -RegName 'LogFilePath' -RegValue '%SystemRoot%\System32\logfiles\firewall\privatefw.log' -RegType String

# 9.2.6. (L1) Ensure 'Windows Firewall: Private: Logging: Size limit (KB)' is set to '16,384 KB or greater'
Write-Host "9.2.6. (L1) Ensure 'Windows Firewall: Private: Logging: Size limit (KB)' is set to '16,384 KB or greater'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging' -RegName 'LogFileSize' -RegValue 16384 -RegType DWORD

# 9.2.7. (L1) Ensure 'Windows Firewall: Private: Logging: Log dropped packets' is set to 'Yes'
Write-Host "9.2.7. (L1) Ensure 'Windows Firewall: Private: Logging: Log dropped packets' is set to 'Yes'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging' -RegName 'LogDroppedPackets' -RegValue 1 -RegType DWORD

# 9.2.8. (L1) Ensure 'Windows Firewall: Private: Logging: Log successful connections' is set to 'Yes'
Write-Host "9.2.8. (L1) Ensure 'Windows Firewall: Private: Logging: Log successful connections' is set to 'Yes'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging' -RegName 'LogSuccessfulConnections' -RegValue 1 -RegType DWORD

# 9.3.1. (L1) Ensure 'Windows Firewall: Public: Firewall state' is set to 'On (recommended)'
Write-Host "9.3.1. (L1) Ensure 'Windows Firewall: Public: Firewall state' is set to 'On (recommended)'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging' -RegName 'EnableFirewall' -RegValue 1 -RegType DWORD

# 9.3.2. (L1) Ensure 'Windows Firewall: Public: Inbound connections' is set to 'Block (default)'
Write-Host "9.3.2. (L1) Ensure 'Windows Firewall: Public: Inbound connections' is set to 'Block (default)'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile' -RegName 'DefaultInboundAction' -RegValue 1 -RegType DWORD

# 9.3.3. (L1) Ensure 'Windows Firewall: Public: Outbound connections' is set to 'Allow (default)'
Write-Host "9.3.3. (L1) Ensure 'Windows Firewall: Public: Outbound connections' is set to 'Allow (default)'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile' -RegName 'DefaultOutboundAction' -RegValue 0 -RegType DWORD

# 9.3.4. (L1) Ensure 'Windows Firewall: Public: Settings: Display a notification' is set to 'No'
Write-Host "9.3.4. (L1) Ensure 'Windows Firewall: Public: Settings: Display a notification' is set to 'No'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile' -RegName 'DisableNotifications' -RegValue 1 -RegType DWORD

# 9.3.5. (L1) Ensure 'Windows Firewall: Public: Settings: Apply local firewall rules' is set to 'No'
Write-Host "9.3.5. (L1) Ensure 'Windows Firewall: Public: Settings: Apply local firewall rules' is set to 'No'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile' -RegName 'AllowLocalPolicyMerge' -RegValue 0 -RegType DWORD

# 9.3.6. (L1) Ensure 'Windows Firewall: Public: Settings: Apply local connection security rules' is set to 'No'
Write-Host "9.3.6. (L1) Ensure 'Windows Firewall: Public: Settings: Apply local connection security rules' is set to 'No'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile' -RegName 'AllowLocalIPsecPolicyMerge' -RegValue 0 -RegType DWORD

# 9.3.7. (L1) Ensure 'Windows Firewall: Public: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\publicfw.log'
Write-Host "9.3.7. (L1) Ensure 'Windows Firewall: Public: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\publicfw.log'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging' -RegName 'LogFilePath' -RegValue '%SystemRoot%\System32\logfiles\firewall\publicfw.log' -RegType String

# 9.3.8. (L1) Ensure 'Windows Firewall: Public: Logging: Size limit (KB)' is set to '16,384 KB or greater'
Write-Host "9.3.8. (L1) Ensure 'Windows Firewall: Public: Logging: Size limit (KB)' is set to '16,384 KB or greater'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging' -RegName 'LogFileSize' -RegValue 16384 -RegType DWORD

# 9.3.9. (L1) Ensure 'Windows Firewall: Public: Logging: Log dropped packets' is set to 'Yes'
Write-Host "9.3.9. (L1) Ensure 'Windows Firewall: Public: Logging: Log dropped packets' is set to 'Yes'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging' -RegName 'LogDroppedPackets' -RegValue 1 -RegType DWORD

# 9.3.10. (L1) Ensure 'Windows Firewall: Public: Logging: Log successful connections' is set to 'Yes'
Write-Host "9.3.10. (L1) Ensure 'Windows Firewall: Public: Logging: Log successful connections' is set to 'Yes'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging' -RegName 'LogSuccessfulConnections' -RegValue 1 -RegType DWORD

# 17.2.1. (L1) Ensure 'Audit Application Group Management' is set to 'Success and Failure'
Write-Host "17.2.1. (L1) Ensure 'Audit Application Group Management' is set to 'Success and Failure'"
auditpol /set /subcategory:"Application Group Management" /success:enable /failure:enable | Out-Null

# 17.5.3. (L1) Ensure 'Audit Logoff' is set to include 'Success'
Write-Host "17.5.3. (L1) Ensure 'Audit Logoff' is set to include 'Success'"
auditpol /set /subcategory:"Logoff" /success:enable | Out-Null

# 17.7.3. (L1) Ensure 'Audit Authorization Policy Change' is set to include 'Success'
Write-Host "17.7.3. (L1) Ensure 'Audit Authorization Policy Change' is set to include 'Success'"
auditpol /set /subcategory:"Authorization Policy Change" /success:enable | Out-Null

# 17.9.1. (L1) Ensure 'Audit IPsec Driver' is set to 'Success and Failure'
Write-Host "17.9.1. (L1) Ensure 'Audit IPsec Driver' is set to 'Success and Failure'"
auditpol /set /subcategory:"IPsec Driver" /success:enable /failure:enable | Out-Null

# 18.1.2.2. (L1) Ensure 'Allow users to enable online speech recognition services' is set to 'Disabled'
Write-Host "18.1.2.2. (L1) Ensure 'Allow users to enable online speech recognition services' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization' -RegName 'AllowInputPersonalization' -RegValue 0 -RegType DWORD

# 18.3.2. (L1) Ensure 'Do not allow password expiration time longer than required by policy' is set to 'Enabled' (MS only)
Write-Host "18.3.2. (L1) Ensure 'Do not allow password expiration time longer than required by policy' is set to 'Enabled' (MS only)"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\LAPS' -RegName 'PwdExpirationProtectionEnabled' -RegValue 1 -RegType DWORD

# 18.3.4. (L1) Ensure 'Password Settings: Password Complexity' is set to 'Enabled: Large letters + small letters + numbers + special characters' (MS only)
Write-Host "18.3.4. (L1) Ensure 'Password Settings: Password Complexity' is set to 'Enabled: Large letters + small letters + numbers + special characters' (MS only)"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\LAPS' -RegName 'PasswordComplexity' -RegValue 4 -RegType DWORD

# 18.3.5. (L1) Ensure 'Password Settings: Password Length' is set to 'Enabled: 15 or more' (MS only)
Write-Host "18.3.5. (L1) Ensure 'Password Settings: Password Length' is set to 'Enabled: 15 or more' (MS only)"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\LAPS' -RegName 'PasswordLength' -RegValue 15 -RegType DWORD

# 18.3.6. (L1) Ensure 'Password Settings: Password Age (Days)' is set to 'Enabled: 30 or fewer' (MS only)
Write-Host "18.3.6. (L1) Ensure 'Password Settings: Password Age (Days)' is set to 'Enabled: 30 or fewer' (MS only)"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\LAPS' -RegName 'PasswordAgeDays' -RegValue 30 -RegType DWORD

# 18.4.2. (L1) Ensure 'Configure RPC packet level privacy setting for incoming connections' is set to 'Enabled'
Write-Host "18.4.2. (L1) Ensure 'Configure RPC packet level privacy setting for incoming connections' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Print' -RegName 'RpcAuthnLevelPrivacyEnabled' -RegValue 1 -RegType DWORD

# 18.5.1. (L1) Ensure 'MSS: (AutoAdminLogon) Enable Automatic Logon (not recommended)' is set to 'Disabled'
Write-Host "18.5.1. (L1) Ensure 'MSS: (AutoAdminLogon) Enable Automatic Logon (not recommended)' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -RegName 'AutoAdminLogon' -RegValue 0 -RegType String

# 18.5.8. (L1) Ensure 'MSS: (SafeDllSearchMode) Enable Safe DLL search mode (recommended)' is set to 'Enabled'
Write-Host "18.5.8. (L1) Ensure 'MSS: (SafeDllSearchMode) Enable Safe DLL search mode (recommended)' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -RegName 'SafeDllSearchMode' -RegValue 1 -RegType DWORD

# 18.5.9. (L1) Ensure 'MSS: (ScreenSaverGracePeriod) The time in seconds before the screen saver grace period expires (0 recommended)' is set to 'Enabled: 5 or fewer seconds'
Write-Host "18.5.9. (L1) Ensure 'MSS: (ScreenSaverGracePeriod) The time in seconds before the screen saver grace period expires (0 recommended)' is set to 'Enabled: 5 or fewer seconds'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -RegName 'ScreenSaverGracePeriod' -RegValue 0 -RegType String

# 18.5.10. (L2) Ensure 'MSS: (TcpMaxDataRetransmissions IPv6) How many times unacknowledged data is retransmitted' is set to 'Enabled: 3'
Write-Host "18.5.10. (L2) Ensure 'MSS: (TcpMaxDataRetransmissions IPv6) How many times unacknowledged data is retransmitted' is set to 'Enabled: 3'"
Set-Registry -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP6\Parameters' -RegName 'TcpMaxDataRetransmissions' -RegValue 3 -RegType DWORD

# 18.5.12. (L1) Ensure 'MSS: (WarningLevel) Percentage threshold for the security event log at which the system will generate a warning' is set to 'Enabled: 90% or less'
Write-Host "18.5.12. (L1) Ensure 'MSS: (WarningLevel) Percentage threshold for the security event log at which the system will generate a warning' is set to 'Enabled: 90% or less'"
Set-Registry -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\Eventlog\Security' -RegName 'WarningLevel' -RegValue 90 -RegType DWORD

# 18.6.4.2. (L1) Ensure 'Configure NetBIOS settings' is set to 'Enabled: Disable NetBIOS name resolution on public networks'
Write-Host "18.6.4.2. (L1) Ensure 'Configure NetBIOS settings' is set to 'Enabled: Disable NetBIOS name resolution on public networks'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient' -RegName 'EnableNetbios' -RegValue 0 -RegType DWORD

# 18.6.11.2. (L1) Ensure 'Prohibit installation and configuration of Network Bridge on your DNS domain network' is set to 'Enabled'
Write-Host "18.6.11.2. (L1) Ensure 'Prohibit installation and configuration of Network Bridge on your DNS domain network' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections' -RegName 'NC_AllowNetBridge_NLA' -RegValue 0 -RegType DWORD

# 18.6.11.3. (L1) Ensure 'Prohibit use of Internet Connection Sharing on your DNS domain network' is set to 'Enabled'
Write-Host "18.6.11.3. (L1) Ensure 'Prohibit use of Internet Connection Sharing on your DNS domain network' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections' -RegName 'NC_ShowSharedAccessUI' -RegValue 0 -RegType DWORD

# 18.6.11.4. (L1) Ensure 'Require domain users to elevate when setting a network's location' is set to 'Enabled'
Write-Host "18.6.11.4. (L1) Ensure 'Require domain users to elevate when setting a network's location' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections' -RegName 'NC_StdDomainUserSetLocation' -RegValue 1 -RegType DWORD

# 18.6.19.2.1. (L2) Disable IPv6 (Ensure TCPIP6 Parameter 'DisabledComponents' is set to '0xff (255)')
Write-Host "18.6.19.2.1. (L2) Disable IPv6 (Ensure TCPIP6 Parameter 'DisabledComponents' is set to '0xff (255)')"
Set-Registry -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP6\Parameters' -RegName 'DisabledComponents' -RegValue 255 -RegType DWORD

# 18.6.21.1. (L1) Ensure 'Minimize the number of simultaneous connections to the Internet or a Windows Domain' is set to 'Enabled: 3 = Prevent Wi-Fi when on Ethernet'
Write-Host "18.6.21.1. (L1) Ensure 'Minimize the number of simultaneous connections to the Internet or a Windows Domain' is set to 'Enabled: 3 = Prevent Wi-Fi when on Ethernet'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy' -RegName 'fMinimizeConnections' -RegValue 3 -RegType DWORD

# 18.7.2. (L1) Ensure 'Configure Redirection Guard' is set to 'Enabled: Redirection Guard Enabled'
Write-Host "18.7.2. (L1) Ensure 'Configure Redirection Guard' is set to 'Enabled: Redirection Guard Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers' -RegName 'RedirectionguardPolicy' -RegValue 1 -RegType DWORD

# 18.7.7. (L1) Ensure 'Configure RPC over TCP port' is set to 'Enabled: 0'
Write-Host "18.7.7. (L1) Ensure 'Configure RPC over TCP port' is set to 'Enabled: 0'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC' -RegName 'RpcProtocols' -RegValue 0 -RegType DWORD

# 18.7.9. (L1) Ensure 'Manage processing of Queue-specific files' is set to 'Enabled: Limit Queue-specific files to Color profiles'
Write-Host "18.7.9. (L1) Ensure 'Manage processing of Queue-specific files' is set to 'Enabled: Limit Queue-specific files to Color profiles'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers' -RegName 'CopyFilesPolicy' -RegValue 1 -RegType DWORD

# 18.9.3.1. (L1) Ensure 'Include command line in process creation events' is set to 'Enabled'
Write-Host "18.9.3.1. (L1) Ensure 'Include command line in process creation events' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit' -RegName 'ProcessCreationIncludeCmdLine_Enabled' -RegValue 1 -RegType DWORD

# 18.9.7.2. (L1) Ensure 'Prevent device metadata retrieval from the Internet' is set to 'Enabled'
Write-Host "18.9.7.2. (L1) Ensure 'Prevent device metadata retrieval from the Internet' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata' -RegName 'PreventDeviceMetadataFromNetwork' -RegValue 1 -RegType DWORD

# 18.9.19.5. (L1) Ensure 'Turn off background refresh of Group Policy' is set to 'Disabled'
Write-Host "18.9.19.5. (L1) Ensure 'Turn off background refresh of Group Policy' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Group Policy\{827D319E-6EAC-11D2-A4EA-00C04F79F83A}' -RegName 'NoGPOListChanges' -RegValue 0 -RegType DWORD

# 18.9.20.1.1. (L1) Ensure 'Turn off downloading of print drivers over HTTP' is set to 'Enabled'
Write-Host "18.9.20.1.1. (L1) Ensure 'Turn off downloading of print drivers over HTTP' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers' -RegName 'DisableWebPnPDownload' -RegValue 1 -RegType DWORD

# 18.9.20.1.5. (L1) Ensure 'Turn off Internet download for Web publishing and online ordering wizards' is set to 'Enabled'
Write-Host "18.9.20.1.5. (L1) Ensure 'Turn off Internet download for Web publishing and online ordering wizards' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -RegName 'NoWebServices' -RegValue 1 -RegType DWORD

# 18.9.25.1. (L1) Ensure 'Allow Custom SSPs and APs to be loaded into LSASS' is set to 'Disabled'
Write-Host "18.9.25.1. (L1) Ensure 'Allow Custom SSPs and APs to be loaded into LSASS' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -RegName 'AllowCustomSSPsAPs' -RegValue 0 -RegType DWORD

# 18.9.27.1. (L1) Ensure 'Block user from showing account details on sign-in' is set to 'Enabled'
Write-Host "18.9.27.1. (L1) Ensure 'Block user from showing account details on sign-in' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Control Panel\International' -RegName 'BlockUserInputMethodsForSignIn' -RegValue 1 -RegType DWORD

# 18.9.27.2. (L1) Ensure 'Do not display network selection UI' is set to 'Enabled'
Write-Host "18.9.27.2. (L1) Ensure 'Do not display network selection UI' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -RegName 'DontDisplayNetworkSelectionUI' -RegValue 1 -RegType DWORD

# 18.9.27.3. (L1) Ensure 'Do not enumerate connected users on domain-joined computers' is set to 'Enabled'
Write-Host "18.9.27.3. (L1) Ensure 'Do not enumerate connected users on domain-joined computers' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -RegName 'DontEnumerateConnectedUsers' -RegValue 1 -RegType DWORD

# 18.9.27.5. (L1) Ensure 'Turn off app notifications on the lock screen' is set to 'Enabled'
Write-Host "18.9.27.5. (L1) Ensure 'Turn off app notifications on the lock screen' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -RegName 'DisableLockScreenAppNotifications' -RegValue 1 -RegType DWORD

# 18.9.27.6. (L1) Ensure 'Turn off picture password sign-in' is set to 'Enabled'
Write-Host "18.9.27.6. (L1) Ensure 'Turn off picture password sign-in' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -RegName 'BlockDomainPicturePassword' -RegValue 1 -RegType DWORD

# 18.9.27.7. (L1) Ensure 'Turn on convenience PIN sign-in' is set to 'Disabled'
Write-Host "18.9.27.7. (L1) Ensure 'Turn on convenience PIN sign-in' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -RegName 'AllowDomainPINLogon' -RegValue 0 -RegType DWORD

# 18.9.32.6.3. (L1) Ensure 'Require a password when a computer wakes (on battery)' is set to 'Enabled'
Write-Host "18.9.32.6.3. (L1) Ensure 'Require a password when a computer wakes (on battery)' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51' -RegName 'DCSettingIndex' -RegValue 1 -RegType DWORD

# 18.9.32.6.4. (L1) Ensure 'Require a password when a computer wakes (plugged in)' is set to 'Enabled'
Write-Host "18.9.32.6.4. (L1) Ensure 'Require a password when a computer wakes (plugged in)' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51' -RegName 'ACSettingIndex' -RegValue 1 -RegType DWORD

# 18.9.34.1. (L1) Ensure 'Configure Offer Remote Assistance' is set to 'Disabled'
Write-Host "18.9.34.1. (L1) Ensure 'Configure Offer Remote Assistance' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -RegName 'fAllowUnsolicited' -RegValue 0 -RegType DWORD

# 18.9.34.2. (L1) Ensure 'Configure Solicited Remote Assistance' is set to 'Disabled'
Write-Host "18.9.34.2. (L1) Ensure 'Configure Solicited Remote Assistance' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -RegName 'fAllowToGetHelp' -RegValue 0 -RegType DWORD

# 18.9.35.1. (L1) Ensure 'Enable RPC Endpoint Mapper Client Authentication' is set to 'Enabled' (MS only)
Write-Host "18.9.35.1. (L1) Ensure 'Enable RPC Endpoint Mapper Client Authentication' is set to 'Enabled' (MS only)"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Rpc' -RegName 'EnableAuthEpResolution' -RegValue 1 -RegType DWORD

# 18.9.50.1.1. (L2) Ensure 'Enable Windows NTP Client' is set to 'Enabled'
Write-Host "18.9.50.1.1. (L2) Ensure 'Enable Windows NTP Client' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\W32Time\TimeProviders\NtpClient' -RegName 'Enabled' -RegValue 1 -RegType DWORD

# 18.10.5.1. (L1) Ensure 'Allow Microsoft accounts to be optional' is set to 'Enabled'
Write-Host "18.10.5.1. (L1) Ensure 'Allow Microsoft accounts to be optional' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -RegName 'MSAOptional' -RegValue 1 -RegType DWORD

# 18.10.12.1. (L1) Ensure 'Turn off cloud consumer account state content' is set to 'Enabled'
Write-Host "18.10.12.1. (L1) Ensure 'Turn off cloud consumer account state content' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -RegName 'DisableConsumerAccountStateContent' -RegValue 1 -RegType DWORD

# 18.10.12.2. (L2) Ensure 'Turn off cloud optimized content' is set to 'Enabled'
Write-Host "18.10.12.2. (L2) Ensure 'Turn off cloud optimized content' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -RegName 'DisableCloudOptimizedContent' -RegValue 1 -RegType DWORD

# 18.10.12.3. (L1) Ensure 'Turn off Microsoft consumer experiences' is set to 'Enabled'
Write-Host "18.10.12.3. (L1) Ensure 'Turn off Microsoft consumer experiences' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -RegName 'DisableWindowsConsumerFeatures' -RegValue 1 -RegType DWORD

# 18.10.13.1. (L1) Ensure 'Require pin for pairing' is set to 'Enabled: First Time' OR 'Enabled: Always'
Write-Host "18.10.13.1. (L1) Ensure 'Require pin for pairing' is set to 'Enabled: First Time' OR 'Enabled: Always'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Connect' -RegName 'RequirePinForPairing' -RegValue 1 -RegType DWORD

# 18.10.14.1. (L1) Ensure 'Do not display the password reveal button' is set to 'Enabled'
Write-Host "18.10.14.1. (L1) Ensure 'Do not display the password reveal button' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredUI' -RegName 'DisablePasswordReveal' -RegValue 1 -RegType DWORD

# 18.10.14.2. (L1) Ensure 'Enumerate administrator accounts on elevation' is set to 'Disabled'
Write-Host "18.10.14.2. (L1) Ensure 'Enumerate administrator accounts on elevation' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\CredUI' -RegName 'EnumerateAdministrators' -RegValue 0 -RegType DWORD

# 18.10.15.1. (L1) Ensure 'Allow Diagnostic Data' is set to 'Enabled: Diagnostic data off (not recommended)' or 'Enabled: Send required diagnostic data'
Write-Host "18.10.15.1. (L1) Ensure 'Allow Diagnostic Data' is set to 'Enabled: Diagnostic data off (not recommended)' or 'Enabled: Send required diagnostic data'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -RegName 'AllowTelemetry' -RegValue 0 -RegType DWORD

# 18.10.15.3. (L1) Ensure 'Disable OneSettings Downloads' is set to 'Enabled'
Write-Host "18.10.15.3. (L1) Ensure 'Disable OneSettings Downloads' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -RegName 'DisableOneSettingsDownloads' -RegValue 1 -RegType DWORD

# 18.10.15.4. (L1) Ensure 'Do not show feedback notifications' is set to 'Enabled'
Write-Host "18.10.15.4. (L1) Ensure 'Do not show feedback notifications' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -RegName 'DoNotShowFeedbackNotifications' -RegValue 1 -RegType DWORD

# 18.10.15.5. (L1) Ensure 'Enable OneSettings Auditing' is set to 'Enabled'
Write-Host "18.10.15.5. (L1) Ensure 'Enable OneSettings Auditing' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -RegName 'EnableOneSettingsAuditing' -RegValue 1 -RegType DWORD

# 18.10.15.6. (L1) Ensure 'Limit Diagnostic Log Collection' is set to 'Enabled'
Write-Host "18.10.15.6. (L1) Ensure 'Limit Diagnostic Log Collection' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -RegName 'LimitDiagnosticLogCollection' -RegValue 1 -RegType DWORD

# 18.10.15.7. (L1) Ensure 'Limit Dump Collection' is set to 'Enabled'
Write-Host "18.10.15.7. (L1) Ensure 'Limit Dump Collection' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -RegName 'LimitDumpCollection' -RegValue 1 -RegType DWORD

# 18.10.15.8. (L1) Ensure 'Toggle user control over Insider builds' is set to 'Disabled'
Write-Host "18.10.15.8. (L1) Ensure 'Toggle user control over Insider builds' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds' -RegName 'AllowBuildPreview' -RegValue 0 -RegType DWORD

# 18.10.17.1. (L1) Ensure 'Enable App Installer' is set to 'Disabled'
Write-Host "18.10.17.1. (L1) Ensure 'Enable App Installer' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppInstaller' -RegName 'EnableAppInstaller' -RegValue 0 -RegType DWORD

# 18.10.17.2. (L1) Ensure 'Enable App Installer Experimental Features' is set to 'Disabled'
Write-Host "18.10.17.2. (L1) Ensure 'Enable App Installer Experimental Features' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppInstaller' -RegName 'EnableExperimentalFeatures' -RegValue 0 -RegType DWORD

# 18.10.17.3. (L1) Ensure 'Enable App Installer Hash Override' is set to 'Disabled'
Write-Host "18.10.17.3. (L1) Ensure 'Enable App Installer Hash Override' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppInstaller' -RegName 'EnableHashOverride' -RegValue 0 -RegType DWORD

# 18.10.17.4. (L1) Ensure 'Enable App Installer ms-appinstaller protocol' is set to 'Disabled'
Write-Host "18.10.17.4. (L1) Ensure 'Enable App Installer ms-appinstaller protocol' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppInstaller' -RegName 'EnableMSAppInstallerProtocol' -RegValue 0 -RegType DWORD

# 18.10.26.2.2. (L1) Ensure 'Security: Specify the maximum log file size (KB)' is set to 'Enabled: 196,608 or greater'
Write-Host "18.10.26.2.2. (L1) Ensure 'Security: Specify the maximum log file size (KB)' is set to 'Enabled: 196,608 or greater'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\Security' -RegName 'MaxSize' -RegValue 196608 -RegType DWORD

# 18.10.26.3.2. (L1) Ensure 'Setup: Specify the maximum log file size (KB)' is set to 'Enabled: 32,768 or greater'
Write-Host "18.10.26.3.2. (L1) Ensure 'Setup: Specify the maximum log file size (KB)' is set to 'Enabled: 32,768 or greater'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\Setup' -RegName 'MaxSize' -RegValue 32768 -RegType DWORD

# 18.10.29.2. (L1) Ensure 'Turn off Data Execution Prevention for Explorer' is set to 'Disabled'
Write-Host "18.10.29.2. (L1) Ensure 'Turn off Data Execution Prevention for Explorer' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -RegName 'NoDataExecutionPrevention' -RegValue 0 -RegType DWORD

# 18.10.29.3. (L1) Ensure 'Turn off heap termination on corruption' is set to 'Disabled'
Write-Host "18.10.29.3. (L1) Ensure 'Turn off heap termination on corruption' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -RegName 'NoHeapTerminationOnCorruption' -RegValue 0 -RegType DWORD

# 18.10.29.4. (L1) Ensure 'Turn off shell protocol protected mode' is set to 'Disabled'
Write-Host "18.10.29.4. (L1) Ensure 'Turn off shell protocol protected mode' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -RegName 'PreXPSP2ShellProtocolBehavior' -RegValue 0 -RegType DWORD

# 18.10.42.1. (L1) Ensure 'Block all consumer Microsoft account user authentication' is set to 'Enabled'
Write-Host "18.10.42.1. (L1) Ensure 'Block all consumer Microsoft account user authentication' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftAccount' -RegName 'DisableUserAuth' -RegValue 1 -RegType DWORD

# 18.10.43.5.1. (L1) Ensure 'Configure local setting override for reporting to Microsoft MAPS' is set to 'Disabled'
Write-Host "18.10.43.5.1. (L1) Ensure 'Configure local setting override for reporting to Microsoftr MAPS' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet' -RegName 'LocalSettingOverrideSpynetReporting' -RegValue 0 -RegType DWORD

# 18.10.43.5.2. (L2) Ensure 'Join Microsoft MAPS' is set to 'Disabled'
Write-Host "18.10.43.5.2. (L2) Ensure 'Join Microsoft MAPS' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet' -RegName 'SpynetReporting' -RegValue 0 -RegType DWORD

# 18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured
Write-Host "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -RegName '26190899-1602-49e8-8b27-eb1d0a1ce869' -RegValue 1 -RegType String
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -RegName '3b576869-a4ec-4529-8536-b80a7769e899' -RegValue 1 -RegType String
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -RegName '56a863a9-875e-4185-98a7-b882c64b5ce5' -RegValue 1 -RegType String
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -RegName '5beb7efe-fd9a-4556-801d-275e5ffc04cc' -RegValue 1 -RegType String
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -RegName '75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84' -RegValue 1 -RegType String
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -RegName '7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c' -RegValue 1 -RegType String
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -RegName '92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b' -RegValue 1 -RegType String
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -RegName '9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2' -RegValue 1 -RegType String
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -RegName 'b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4' -RegValue 1 -RegType String
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -RegName 'be9ba2d9-53ea-4cdc-84e5-9b1eeee46550' -RegValue 1 -RegType String
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -RegName 'd3e037e1-3eb8-44c8-a917-57927947596d' -RegValue 1 -RegType String
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -RegName 'd4f940ab-401b-4efc-aadc-ad5f3c50688a' -RegValue 1 -RegType String
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -RegName 'e6db77e5-3df2-4cf1-b95a-636979351e5b' -RegValue 1 -RegType String

# 18.10.43.7.1. (L2) Ensure 'Enable file hash computation feature' is set to 'Enabled'
Write-Host "18.10.43.7.1. (L2) Ensure 'Enable file hash computation feature' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine' -RegName 'EnableFileHashComputation' -RegValue 1 -RegType DWORD

# 18.10.43.10.3. (L1) Ensure 'Turn on behavior monitoring' is set to 'Enabled'
Write-Host "18.10.43.10.3. (L1) Ensure 'Turn on behavior monitoring' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection' -RegName 'DisableBehaviorMonitoring' -RegValue 0 -RegType DWORD

# 18.10.43.12.1. (L2) Ensure 'Configure Watson events' is set to 'Disabled'
Write-Host "18.10.43.12.1. (L2) Ensure 'Configure Watson events' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting' -RegName 'DisableGenericRePorts' -RegValue 1 -RegType DWORD

# 18.10.43.13.2. (L1) Ensure 'Turn on e-mail scanning' is set to 'Enabled' 
Write-Host "18.10.43.13.2. (L1) Ensure 'Turn on e-mail scanning' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan' -RegName 'DisableEmailScanning' -RegValue 0 -RegType DWORD

# 18.10.51.1. (L1) Ensure 'Prevent the usage of OneDrive for file storage' is set to 'Enabled'
Write-Host "18.10.51.1. (L1) Ensure 'Prevent the usage of OneDrive for file storage' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' -RegName 'DisableFileSyncNGSC' -RegValue 1 -RegType DWORD

# 18.10.56.1. (L2) Ensure 'Turn off Push To Install service' is set to 'Enabled'
Write-Host "18.10.56.1. (L2) Ensure 'Turn off Push To Install service' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\PushToInstall' -RegName 'DisablePushToInstall' -RegValue 1 -RegType DWORD

# 18.10.57.3.3.1. (L2) Ensure 'Allow UI Automation redirection' is set to 'Disabled'
Write-Host "18.10.57.3.3.1. (L2) Ensure 'Allow UI Automation redirection' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -RegName 'EnableUiaRedirection' -RegValue 1 -RegType DWORD

# 18.10.57.3.3.2. (L2) Ensure 'Do not allow COM port redirection' is set to 'Enabled'
Write-Host "18.10.57.3.3.2. (L2) Ensure 'Do not allow COM port redirection' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -RegName 'fDisableCcm' -RegValue 1 -RegType DWORD

# 18.10.57.3.3.4. (L2) Ensure 'Do not allow location redirection' is set to 'Enabled'
Write-Host "18.10.57.3.3.4. (L2) Ensure 'Do not allow location redirection' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -RegName 'fDisableLocationRedir' -RegValue 1 -RegType DWORD

# 18.10.57.3.3.5. (L2) Ensure 'Do not allow LPT port redirection' is set to 'Enabled'
Write-Host "18.10.57.3.3.5. (L2) Ensure 'Do not allow LPT port redirection' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -RegName 'fDisableLPT' -RegValue 1 -RegType DWORD

# 18.10.57.3.3.6. (L2) Ensure 'Do not allow supported Plug and Play device redirection' is set to 'Enabled'
Write-Host "18.10.57.3.3.6. (L2) Ensure 'Do not allow supported Plug and Play device redirection' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -RegName 'fDisablePNPRedir' -RegValue 1 -RegType DWORD

# 18.10.57.3.3.7. (L2) Ensure 'Do not allow WebAuthn redirection' is set to 'Enabled'
Write-Host "18.10.57.3.3.7. (L2) Ensure 'Do not allow WebAuthn redirection' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -RegName 'fDisableWebAuthn' -RegValue 1 -RegType DWORD

# 18.10.57.3.9.3. (L1) Ensure 'Require use of specific security layer for remote (RDP) connections' is set to 'Enabled: SSL'
Write-Host "18.10.57.3.9.3. (L1) Ensure 'Require use of specific security layer for remote (RDP) connections' is set to 'Enabled: SSL'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -RegName 'SecurityLayer' -RegValue 2 -RegType DWORD

# 18.10.57.3.9.4. (L1) Ensure 'Require user authentication for remote connections by using Network Level Authentication' is set to 'Enabled'
Write-Host "18.10.57.3.9.4. (L1) Ensure 'Require user authentication for remote connections by using Network Level Authentication' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -RegName 'UserAuthentication' -RegValue 1 -RegType DWORD

# 18.10.57.3.11.1. (L1) Ensure 'Do not delete temp folders upon exit' is set to 'Disabled'
Write-Host "18.10.57.3.11.1. (L1) Ensure 'Do not delete temp folders upon exit' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -RegName 'DeleteTempDirsOnExit' -RegValue 1 -RegType DWORD

# 18.10.57.3.11.2. (L1) Ensure 'Do not use temporary folders per session' is set to 'Disabled'
Write-Host "18.10.57.3.11.2. (L1) Ensure 'Do not use temporary folders per session' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -RegName 'PerSessionTempDir' -RegValue 1 -RegType DWORD

# 18.10.59.4. (L2) Ensure 'Allow search highlights' is set to 'Disabled'
Write-Host "18.10.59.4. (L2) Ensure 'Allow search highlights' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -RegName 'EnableDynamicContentInWSB' -RegValue 1 -RegType DWORD

# 18.10.82.1. (L1) Ensure 'Enable MPR notifications for the system' is set to 'Disabled'
Write-Host "18.10.82.1. (L1) Ensure 'Enable MPR notifications for the system' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -RegName 'EnableMPR' -RegValue 0 -RegType DWORD

# 18.10.89.1.1. (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'
Write-Host "18.10.89.1.1. (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client' -RegName 'AllowBasic' -RegValue 0 -RegType DWORD

# 18.10.89.1.2. (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'
Write-Host "18.10.89.1.2. (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client' -RegName 'AllowUnencryptedTraffic' -RegValue 0 -RegType DWORD

# 18.10.89.1.3. (L1) Ensure 'Disallow Digest authentication' is set to 'Enabled'
Write-Host "18.10.89.1.3. (L1) Ensure 'Disallow Digest authentication' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client' -RegName 'AllowDigest' -RegValue 0 -RegType DWORD

# 18.10.89.2.1. (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'
Write-Host "18.10.89.2.1. (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service' -RegName 'AllowBasic' -RegValue 0 -RegType DWORD

# 18.10.89.2.3. (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'
Write-Host "18.10.89.2.3. (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service' -RegName 'AllowUnencryptedTraffic' -RegValue 0 -RegType DWORD

# 18.10.89.2.4. (L1) Ensure 'Disallow WinRM from storing RunAs credentials' is set to 'Enabled'
Write-Host "18.10.89.2.4. (L1) Ensure 'Disallow WinRM from storing RunAs credentials' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service' -RegName 'DisableRunAs' -RegValue 1 -RegType DWORD

# 18.10.92.2.1. (L1) Ensure 'Prevent users from modifying settings' is set to 'Enabled'
Write-Host "18.10.92.2.1. (L1) Ensure 'Prevent users from modifying settings' is set to 'Enabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\App and Browser protection' -RegName 'DisallowExploitProtectionOverride' -RegValue 1 -RegType DWORD


# 18.10.93.4.1. (L1) Ensure 'Manage preview builds' is set to 'Disabled'
Write-Host "18.10.93.4.1. (L1) Ensure 'Manage preview builds' is set to 'Disabled'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -RegName 'ManagePreviewBuildsPolicyValue' -RegValue 1 -RegType DWORD

# 18.10.93.4.2. (L1) Ensure 'Select when Preview Builds and Feature Updates are received' is set to 'Enabled: 180 or more days'
Write-Host "18.10.93.4.2. (L1) Ensure 'Select when Preview Builds and Feature Updates are received' is set to 'Enabled: 180 or more days'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -RegName 'DeferFeatureUpdates' -RegValue 1 -RegType DWORD
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -RegName 'DeferFeatureUpdatesPeriodInDays' -RegValue 180 -RegType DWORD

# 18.10.93.4.3. (L1) Ensure 'Select when Quality Updates are received' is set to 'Enabled: 0 days'
Write-Host "18.10.93.4.3. (L1) Ensure 'Select when Quality Updates are received' is set to 'Enabled: 0 days'"
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -RegName 'DeferQualityUpdates' -RegValue 1 -RegType DWORD
Set-Registry -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -RegName 'DeferQualityUpdatesPeriodInDays' -RegValue 0 -RegType DWORD
