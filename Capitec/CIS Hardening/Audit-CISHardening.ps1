$ErrorActionPreference = 'Stop'
Function Get-Registry {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $Path, `
        [Parameter(Mandatory=$True, Position = 2)]
        [String] $Name, `
        [Parameter(Mandatory=$True, Position = 3)]
        [String] $CIS, `
        [Parameter(Mandatory=$True, Position = 4)][AllowEmptyString()]
        [String] $CorrectValue
    )

    Try {
        $Item = Get-ItemProperty -Path $Path -Name $Name
        $RegType = (get-item $Path).GetValueKind($Name)
        If ($Item.$Name -eq $CorrectValue) { 
            $Correct = $True
        }
        Else {
            $Correct = $False
        }
        $ReturnValue = (New-Object -TypeName PSObject -Property @{
            Path = $Path
            Name = $Name
            Value = $Item.$Name
            CorrectValue = $CorrectValue
            RegType = $RegType
            CIS = $CIS
            Correct = $Correct
        })
    }
    Catch {
        $Correct = $False
        $ReturnValue = (New-Object -TypeName PSObject -Property @{
            Path = $Path
            Name = $Name
            Value = "Does not exist"
            CorrectValue = $CorrectValue
            RegType = "Does not exist"
            CIS = $CIS
            Correct = $Correct
        })
    }
    Return $ReturnValue
}

$SetItems = @()
$AuditPolicies = @()

# 1.1.6. (L1) Ensure 'Relax minimum password length limits' is set to 'Enabled'
Write-Host "1.1.6. (L1) Ensure 'Relax minimum password length limits' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\System\CurrentControlSet\Control\SAM' -Name 'MinimumPasswordLengthLimits' -CorrectValue 1 -CIS "1.1.6. (L1) Ensure 'Relax minimum password length limits' is set to 'Enabled'")

# 2.3.1.1 (L1) Ensure 'Accounts: Block Microsoft accounts' is set to 'Users can't add or log on with Microsoft accounts' (Automated)
Write-Host "2.3.1.1 (L1) Ensure 'Accounts: Block Microsoft accounts' is set to 'Users can't add or log on with Microsoft accounts' (Automated)"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'NoConnectedUser' -CorrectValue 3 -CIS "2.3.1.1 (L1) Ensure 'Accounts: Block Microsoft accounts' is set to 'Users can't add or log on with Microsoft accounts' (Automated)")

# 2.3.4.1. (L1) Ensure 'Devices: Allowed to format and eject removable media' is set to 'Administrators'
Write-Host "2.3.4.1. (L1) Ensure 'Devices: Allowed to format and eject removable media' is set to 'Administrators'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers' -Name 'AddPrinterDrivers' -CorrectValue 1 -CIS "2.3.4.1. (L1) Ensure 'Devices: Allowed to format and eject removable media' is set to 'Administrators'"  ) # -RegType DWORD

# 2.3.7.2. (L1) Ensure 'Interactive logon: Don't display last signed-in' is set to 'Enabled'
Write-Host "2.3.7.2. (L1) Ensure 'Interactive logon: Don't display last signed-in' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'DontDisplayLastUserName' -CorrectValue 1 -CIS "2.3.7.2. (L1) Ensure 'Interactive logon: Don't display last signed-in' is set to 'Enabled'"  ) # -RegType DWORD

# 2.3.7.8 (L1) Ensure 'Interactive logon: Require Domain Controller Authentication to unlock workstation' is set to 'Enabled' (MS only) (Automated)
Write-Host "2.3.7.8 (L1) Ensure 'Interactive logon: Require Domain Controller Authentication to unlock workstation' is set to 'Enabled' (MS only) (Automated)"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'ForceUnlockLogon'-CorrectValue 1 -CIS "2.3.7.8 (L1) Ensure 'Interactive logon: Require Domain Controller Authentication to unlock workstation' is set to 'Enabled' (MS only) (Automated)"  ) # -RegType DWORD

# 2.3.9.3. (L1) Ensure 'Microsoft network server: Digitally sign communications (if client agrees)' is set to 'Enabled'
Write-Host "2.3.9.3. (L1) Ensure 'Microsoft network server: Digitally sign communications (if client agrees)' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters' -Name 'EnableSecuritySignature' -CorrectValue 1 -CIS "2.3.9.3. (L1) Ensure 'Microsoft network server: Digitally sign communications (if client agrees)' is set to 'Enabled'"  ) # -RegType DWORD

# 2.3.9.5. (L1) Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher (MS only)
Write-Host "2.3.9.5. (L1) Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher (MS only)"
$SetItems += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters' -Name 'SMBServerNameHardeningLevel' -CorrectValue 1 -CIS "2.3.9.5. (L1) Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher (MS only)"  ) # -RegType DWORD

# 2.3.10.12. (L1) Ensure 'Network access: Shares that can be accessed anonymously' is set to 'None'
Write-Host "2.3.10.12. (L1) Ensure 'Network access: Shares that can be accessed anonymously' is set to 'None'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters' -Name 'NullSessionShares' -CorrectValue '' -CIS "2.3.10.12. (L1) Ensure 'Network access: Shares that can be accessed anonymously' is set to 'None'" ) # -RegType MultiString

# 2.3.11.1. (L1) Ensure 'Network security: Allow Local System to use computer identity for NTLM' is set to 'Enabled'
Write-Host "2.3.11.1. (L1) Ensure 'Network security: Allow Local System to use computer identity for NTLM' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'UseMachineId' -CorrectValue 1 -CIS "2.3.11.1. (L1) Ensure 'Network security: Allow Local System to use computer identity for NTLM' is set to 'Enabled'"  ) # -RegType DWORD

# 2.3.11.3. (L1) Ensure 'Network Security: Allow PKU2U authentication requests to this computer to use online identities' is set to 'Disabled'
Write-Host "2.3.11.3. (L1) Ensure 'Network Security: Allow PKU2U authentication requests to this computer to use online identities' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\pku2u' -Name 'AllowOnlineID' -CorrectValue 0 -CIS "2.3.11.3. (L1) Ensure 'Network Security: Allow PKU2U authentication requests to this computer to use online identities' is set to 'Disabled'"  ) # -RegType DWORD

# 2.3.11.4. (L1) Ensure 'Network security: Configure encryption types allowed for Kerberos' is set to 'AES128_HMAC_SHA1, AES256_HMAC_SHA1, Future encryption types'
Write-Host "2.3.11.4. (L1) Ensure 'Network security: Configure encryption types allowed for Kerberos' is set to 'AES128_HMAC_SHA1, AES256_HMAC_SHA1, Future encryption types'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters' -Name 'SupportedEncryptionTypes' -CorrectValue 2147483640 -CIS "2.3.11.4. (L1) Ensure 'Network security: Configure encryption types allowed for Kerberos' is set to 'AES128_HMAC_SHA1, AES256_HMAC_SHA1, Future encryption types'"  ) # -RegType DWORD

# 2.3.11.9. (L1) Ensure 'Network security: Minimum session security for NTLM SSP based (including secure RPC) clients' is set to 'Require NTLMv2 session security, Require 128-bit encryption'
Write-Host "2.3.11.9. (L1) Ensure 'Network security: Minimum session security for NTLM SSP based (including secure RPC) clients' is set to 'Require NTLMv2 session security, Require 128-bit encryption'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0' -Name 'NTLMMinClientSec' -CorrectValue 537395200 -CIS "2.3.11.9. (L1) Ensure 'Network security: Minimum session security for NTLM SSP based (including secure RPC) clients' is set to 'Require NTLMv2 session security, Require 128-bit encryption'"  ) # -RegType DWORD

# 2.3.11.10. (L1) Ensure 'Network security: Minimum session security for NTLM SSP based (including secure RPC) servers' is set to 'Require NTLMv2 session security, Require 128-bit encryption'
Write-Host "2.3.11.10. (L1) Ensure 'Network security: Minimum session security for NTLM SSP based (including secure RPC) servers' is set to 'Require NTLMv2 session security, Require 128-bit encryption'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0' -Name 'NTLMMinServerSec' -CorrectValue 537395200 -CIS "2.3.11.10. (L1) Ensure 'Network security: Minimum session security for NTLM SSP based (including secure RPC) servers' is set to 'Require NTLMv2 session security, Require 128-bit encryption'"  ) # -RegType DWORD

# 9.1.1. (L1) Ensure 'Windows Firewall: Domain: Firewall state' is set to 'On (recommended)'
Write-Host "9.1.1. (L1) Ensure 'Windows Firewall: Domain: Firewall state' is set to 'On (recommended)'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile' -Name 'EnableFirewall' -CorrectValue 1 -CIS "9.1.1. (L1) Ensure 'Windows Firewall: Domain: Firewall state' is set to 'On (recommended)'"  ) # -RegType DWORD

# 9.1.2. (L1) Ensure 'Windows Firewall: Domain: Inbound connections' is set to 'Block (default)'
Write-Host "9.1.2. (L1) Ensure 'Windows Firewall: Domain: Inbound connections' is set to 'Block (default)'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile' -Name 'DefaultInboundAction' -CorrectValue 1 -CIS "9.1.2. (L1) Ensure 'Windows Firewall: Domain: Inbound connections' is set to 'Block (default)'"  ) # -RegType DWORD

# 9.1.3. (L1) Ensure 'Windows Firewall: Domain: Outbound connections' is set to 'Allow (default)'
Write-Host "9.1.3. (L1) Ensure 'Windows Firewall: Domain: Outbound connections' is set to 'Allow (default)'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile' -Name 'DefaultOutboundAction' -CorrectValue 0 -CIS "9.1.3. (L1) Ensure 'Windows Firewall: Domain: Outbound connections' is set to 'Allow (default)'"  ) # -RegType DWORD

# 9.1.4. (L1) Ensure 'Windows Firewall: Domain: Settings: Display a notification' is set to 'No'
Write-Host "9.1.4. (L1) Ensure 'Windows Firewall: Domain: Settings: Display a notification' is set to 'No'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile' -Name 'DisableNotifications' -CorrectValue 1 -CIS "9.1.4. (L1) Ensure 'Windows Firewall: Domain: Settings: Display a notification' is set to 'No'"  ) # -RegType DWORD

# 9.1.5. (L1) Ensure 'Windows Firewall: Domain: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\domainfw.log'
Write-Host "9.1.5. (L1) Ensure 'Windows Firewall: Domain: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\domainfw.log'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging' -Name 'LogFilePath' -CorrectValue '%SystemRoot%\System32\logfiles\firewall\domainfw.log' -CIS "9.1.5. (L1) Ensure 'Windows Firewall: Domain: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\domainfw.log'"  ) # -RegType String

# 9.1.6. (L1) Ensure 'Windows Firewall: Domain: Logging: Size limit (KB)' is set to '16,384 KB or greater'
Write-Host "9.1.6. (L1) Ensure 'Windows Firewall: Domain: Logging: Size limit (KB)' is set to '16,384 KB or greater'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging' -Name 'LogFileSize' -CorrectValue 16384 -CIS "9.1.6. (L1) Ensure 'Windows Firewall: Domain: Logging: Size limit (KB)' is set to '16,384 KB or greater'"  ) # -RegType DWORD

# 9.1.7. (L1) Ensure 'Windows Firewall: Domain: Logging: Log dropped packets' is set to 'Yes'
Write-Host "9.1.7. (L1) Ensure 'Windows Firewall: Domain: Logging: Log dropped packets' is set to 'Yes'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging' -Name 'LogDroppedPackets' -CorrectValue 1 -CIS "9.1.7. (L1) Ensure 'Windows Firewall: Domain: Logging: Log dropped packets' is set to 'Yes'"  ) # -RegType DWORD

# 9.1.8. (L1) Ensure 'Windows Firewall: Domain: Logging: Log successful connections' is set to 'Yes'
Write-Host "9.1.8. (L1) Ensure 'Windows Firewall: Domain: Logging: Log successful connections' is set to 'Yes'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging' -Name 'LogSuccessfulConnections' -CorrectValue 1 -CIS "9.1.8. (L1) Ensure 'Windows Firewall: Domain: Logging: Log successful connections' is set to 'Yes'"  ) # -RegType DWORD

# 9.2.1. (L1) Ensure 'Windows Firewall: Private: Firewall state' is set to 'On (recommended)'
Write-Host "9.2.1. (L1) Ensure 'Windows Firewall: Private: Firewall state' is set to 'On (recommended)'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile' -Name 'EnableFirewall' -CorrectValue 1 -CIS "9.2.1. (L1) Ensure 'Windows Firewall: Private: Firewall state' is set to 'On (recommended)'"  ) # -RegType DWORD

# 9.2.2. (L1) Ensure 'Windows Firewall: Private: Inbound connections' is set to 'Block (default)'
Write-Host "9.2.2. (L1) Ensure 'Windows Firewall: Private: Inbound connections' is set to 'Block (default)'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile' -Name 'DefaultInboundAction' -CorrectValue 1 -CIS "9.2.2. (L1) Ensure 'Windows Firewall: Private: Inbound connections' is set to 'Block (default)'"  ) # -RegType DWORD

# 9.2.3. (L1) Ensure 'Windows Firewall: Private: Outbound connections' is set to 'Allow (default)'
Write-Host "9.2.3. (L1) Ensure 'Windows Firewall: Private: Outbound connections' is set to 'Allow (default)'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile' -Name 'DefaultOutboundAction' -CorrectValue 0 -CIS "9.2.3. (L1) Ensure 'Windows Firewall: Private: Outbound connections' is set to 'Allow (default)'"  ) # -RegType DWORD

# 9.2.4. (L1) Ensure 'Windows Firewall: Private: Settings: Display a notification' is set to 'No'
Write-Host "9.2.4. (L1) Ensure 'Windows Firewall: Private: Settings: Display a notification' is set to 'No'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile' -Name 'DisableNotifications' -CorrectValue 1 -CIS "9.2.4. (L1) Ensure 'Windows Firewall: Private: Settings: Display a notification' is set to 'No'"  ) # -RegType DWORD

# 9.2.5. (L1) Ensure 'Windows Firewall: Private: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\privatefw.log'
Write-Host "9.2.5. (L1) Ensure 'Windows Firewall: Private: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\privatefw.log'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging' -Name 'LogFilePath' -CorrectValue '%SystemRoot%\System32\logfiles\firewall\privatefw.log' -CIS "9.2.5. (L1) Ensure 'Windows Firewall: Private: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\privatefw.log'"  ) # -RegType String

# 9.2.6. (L1) Ensure 'Windows Firewall: Private: Logging: Size limit (KB)' is set to '16,384 KB or greater'
Write-Host "9.2.6. (L1) Ensure 'Windows Firewall: Private: Logging: Size limit (KB)' is set to '16,384 KB or greater'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging' -Name 'LogFileSize' -CorrectValue 16384 -CIS "9.2.6. (L1) Ensure 'Windows Firewall: Private: Logging: Size limit (KB)' is set to '16,384 KB or greater'"  ) # -RegType DWORD

# 9.2.7. (L1) Ensure 'Windows Firewall: Private: Logging: Log dropped packets' is set to 'Yes'
Write-Host "9.2.7. (L1) Ensure 'Windows Firewall: Private: Logging: Log dropped packets' is set to 'Yes'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging' -Name 'LogDroppedPackets' -CorrectValue 1 -CIS "9.2.7. (L1) Ensure 'Windows Firewall: Private: Logging: Log dropped packets' is set to 'Yes'"  ) # -RegType DWORD

# 9.2.8. (L1) Ensure 'Windows Firewall: Private: Logging: Log successful connections' is set to 'Yes'
Write-Host "9.2.8. (L1) Ensure 'Windows Firewall: Private: Logging: Log successful connections' is set to 'Yes'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging' -Name 'LogSuccessfulConnections' -CorrectValue 1 -CIS "9.2.8. (L1) Ensure 'Windows Firewall: Private: Logging: Log successful connections' is set to 'Yes'"  ) # -RegType DWORD

# 9.3.1. (L1) Ensure 'Windows Firewall: Public: Firewall state' is set to 'On (recommended)'
Write-Host "9.3.1. (L1) Ensure 'Windows Firewall: Public: Firewall state' is set to 'On (recommended)'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging' -Name 'EnableFirewall' -CorrectValue 1 -CIS "9.3.1. (L1) Ensure 'Windows Firewall: Public: Firewall state' is set to 'On (recommended)'"  ) # -RegType DWORD

# 9.3.2. (L1) Ensure 'Windows Firewall: Public: Inbound connections' is set to 'Block (default)'
Write-Host "9.3.2. (L1) Ensure 'Windows Firewall: Public: Inbound connections' is set to 'Block (default)'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile' -Name 'DefaultInboundAction' -CorrectValue 1 -CIS "9.3.2. (L1) Ensure 'Windows Firewall: Public: Inbound connections' is set to 'Block (default)'"  ) # -RegType DWORD

# 9.3.3. (L1) Ensure 'Windows Firewall: Public: Outbound connections' is set to 'Allow (default)'
Write-Host "9.3.3. (L1) Ensure 'Windows Firewall: Public: Outbound connections' is set to 'Allow (default)'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile' -Name 'DefaultOutboundAction' -CorrectValue 0 -CIS "9.3.3. (L1) Ensure 'Windows Firewall: Public: Outbound connections' is set to 'Allow (default)'"  ) # -RegType DWORD

# 9.3.4. (L1) Ensure 'Windows Firewall: Public: Settings: Display a notification' is set to 'No'
Write-Host "9.3.4. (L1) Ensure 'Windows Firewall: Public: Settings: Display a notification' is set to 'No'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile' -Name 'DisableNotifications' -CorrectValue 1 -CIS "9.3.4. (L1) Ensure 'Windows Firewall: Public: Settings: Display a notification' is set to 'No'"  ) # -RegType DWORD

# 9.3.5. (L1) Ensure 'Windows Firewall: Public: Settings: Apply local firewall rules' is set to 'No'
Write-Host "9.3.5. (L1) Ensure 'Windows Firewall: Public: Settings: Apply local firewall rules' is set to 'No'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile' -Name 'AllowLocalPolicyMerge' -CorrectValue 0 -CIS "9.3.5. (L1) Ensure 'Windows Firewall: Public: Settings: Apply local firewall rules' is set to 'No'"  ) # -RegType DWORD

# 9.3.6. (L1) Ensure 'Windows Firewall: Public: Settings: Apply local connection security rules' is set to 'No'
Write-Host "9.3.6. (L1) Ensure 'Windows Firewall: Public: Settings: Apply local connection security rules' is set to 'No'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile' -Name 'AllowLocalIPsecPolicyMerge' -CorrectValue 0 -CIS "9.3.6. (L1) Ensure 'Windows Firewall: Public: Settings: Apply local connection security rules' is set to 'No'"  ) # -RegType DWORD

# 9.3.7. (L1) Ensure 'Windows Firewall: Public: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\publicfw.log'
Write-Host "9.3.7. (L1) Ensure 'Windows Firewall: Public: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\publicfw.log'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging' -Name 'LogFilePath' -CorrectValue '%SystemRoot%\System32\logfiles\firewall\publicfw.log' -CIS "9.3.7. (L1) Ensure 'Windows Firewall: Public: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\publicfw.log'"  ) # -RegType String

# 9.3.8. (L1) Ensure 'Windows Firewall: Public: Logging: Size limit (KB)' is set to '16,384 KB or greater'
Write-Host "9.3.8. (L1) Ensure 'Windows Firewall: Public: Logging: Size limit (KB)' is set to '16,384 KB or greater'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging' -Name 'LogFileSize' -CorrectValue 16384 -CIS "9.3.8. (L1) Ensure 'Windows Firewall: Public: Logging: Size limit (KB)' is set to '16,384 KB or greater'"  ) # -RegType DWORD

# 9.3.9. (L1) Ensure 'Windows Firewall: Public: Logging: Log dropped packets' is set to 'Yes'
Write-Host "9.3.9. (L1) Ensure 'Windows Firewall: Public: Logging: Log dropped packets' is set to 'Yes'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging' -Name 'LogDroppedPackets' -CorrectValue 1 -CIS "9.3.9. (L1) Ensure 'Windows Firewall: Public: Logging: Log dropped packets' is set to 'Yes'"  ) # -RegType DWORD

# 9.3.10. (L1) Ensure 'Windows Firewall: Public: Logging: Log successful connections' is set to 'Yes'
Write-Host "9.3.10. (L1) Ensure 'Windows Firewall: Public: Logging: Log successful connections' is set to 'Yes'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging' -Name 'LogSuccessfulConnections' -CorrectValue 1 -CIS "9.3.10. (L1) Ensure 'Windows Firewall: Public: Logging: Log successful connections' is set to 'Yes'"  ) # -RegType DWORD

# 17.2.1. (L1) Ensure 'Audit Application Group Management' is set to 'Success and Failure'
#Write-Host "17.2.1. (L1) Ensure 'Audit Application Group Management' is set to 'Success and Failure'"
$AuditPolicy = auditpol /get /subcategory:"Application Group Management" #/success:enable /failure:enable | Out-Null
$CorrectValue = 'Success and Failure'
If (($AuditPolicy[4] -split '  ')[-1] -eq $CorrectValue) {
    $AuditPolicies += ,(New-Object -TypeName PSObject -Property @{
        SubCategory = ($AuditPolicy[4] -split '  ')[1]
        Value = ($AuditPolicy[4] -split '  ')[-1]
        CorrectValue = $CorrectValue
        CIS = "17.2.1. (L1) Ensure 'Audit Application Group Management' is set to 'Success and Failure'"
        Correct = $True
    })
}
Else {
    $AuditPolicies += ,(New-Object -TypeName PSObject -Property @{
        SubCategory = ($AuditPolicy[4] -split '  ')[1]
        Value = ($AuditPolicy[4] -split '  ')[-1]
        CorrectValue = $CorrectValue
        CIS = "17.2.1. (L1) Ensure 'Audit Application Group Management' is set to 'Success and Failure'"
        Correct = $False
    })
}

# 17.5.3. (L1) Ensure 'Audit Logoff' is set to include 'Success'
#Write-Host "17.5.3. (L1) Ensure 'Audit Logoff' is set to include 'Success'"
$AuditPolicy = auditpol /get /subcategory:"Logoff" #/success:enable | Out-Null
$CorrectValue = 'Success'
If (($AuditPolicy[4] -split '  ')[-1] -eq $CorrectValue) {
    $AuditPolicies += ,(New-Object -TypeName PSObject -Property @{
        SubCategory = ($AuditPolicy[4] -split '  ')[1]
        Value = ($AuditPolicy[4] -split '  ')[-1]
        CorrectValue = $CorrectValue
        CIS = "17.5.3. (L1) Ensure 'Audit Logoff' is set to include 'Success'"
        Correct = $True
    })
}
Else {
    $AuditPolicies += ,(New-Object -TypeName PSObject -Property @{
        SubCategory = ($AuditPolicy[4] -split '  ')[1]
        Value = ($AuditPolicy[4] -split '  ')[-1]
        CorrectValue = $CorrectValue
        CIS = "17.5.3. (L1) Ensure 'Audit Logoff' is set to include 'Success'"
        Correct = $False
    })
}

# 17.7.3. (L1) Ensure 'Audit Authorization Policy Change' is set to include 'Success'
#Write-Host "17.7.3. (L1) Ensure 'Audit Authorization Policy Change' is set to include 'Success'"
$AuditPolicy = auditpol /get /subcategory:"Authorization Policy Change" #/success:enable | Out-Null
$CorrectValue = 'Success'
If (($AuditPolicy[4] -split ' ')[-1] -eq $CorrectValue) {
    $AuditPolicies += ,(New-Object -TypeName PSObject -Property @{
        SubCategory = ($AuditPolicy[4] -split '  ')[1]
        Value = ($AuditPolicy[4] -split ' ')[-1]
        CorrectValue = $CorrectValue
        CIS = "17.7.3. (L1) Ensure 'Audit Authorization Policy Change' is set to include 'Success'"
        Correct = $True
    })
}
Else {
    $AuditPolicies += ,(New-Object -TypeName PSObject -Property @{
        SubCategory = ($AuditPolicy[4] -split '  ')[1]
        Value = ($AuditPolicy[4] -split ' ')[-1]
        CorrectValue = $CorrectValue
        CIS = "17.7.3. (L1) Ensure 'Audit Authorization Policy Change' is set to include 'Success'"
        Correct = $False
    })
}

# 17.9.1. (L1) Ensure 'Audit IPsec Driver' is set to 'Success and Failure'
#Write-Host "17.9.1. (L1) Ensure 'Audit IPsec Driver' is set to 'Success and Failure'"
$AuditPolicy = auditpol /get /subcategory:"IPsec Driver" #/success:enable /failure:enable | Out-Null
$CorrectValue = 'Success and Failure'
If (($AuditPolicy[4] -split '  ')[-1] -eq $CorrectValue) {
    $AuditPolicies += ,(New-Object -TypeName PSObject -Property @{
        SubCategory = ($AuditPolicy[4] -split '  ')[1]
        Value = ($AuditPolicy[4] -split '  ')[-1]
        CorrectValue = $CorrectValue
        CIS = "17.9.1. (L1) Ensure 'Audit IPsec Driver' is set to 'Success and Failure'"
        Correct = $True
    })
}
Else {
    $AuditPolicies += ,(New-Object -TypeName PSObject -Property @{
        SubCategory = ($AuditPolicy[4] -split '  ')[1]
        Value = ($AuditPolicy[4] -split '  ')[-1]
        CorrectValue = $CorrectValue
        CIS = "17.9.1. (L1) Ensure 'Audit IPsec Driver' is set to 'Success and Failure'"
        Correct = $False
    })
}

# 18.1.2.2. (L1) Ensure 'Allow users to enable online speech recognition services' is set to 'Disabled'
Write-Host "18.1.2.2. (L1) Ensure 'Allow users to enable online speech recognition services' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization' -Name 'AllowInputPersonalization' -CorrectValue 0 -CIS "18.1.2.2. (L1) Ensure 'Allow users to enable online speech recognition services' is set to 'Disabled'"  ) # -RegType DWORD

# 18.3.2. (L1) Ensure 'Do not allow password expiration time longer than required by policy' is set to 'Enabled' (MS only)
Write-Host "18.3.2. (L1) Ensure 'Do not allow password expiration time longer than required by policy' is set to 'Enabled' (MS only)"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\LAPS' -Name 'PwdExpirationProtectionEnabled' -CorrectValue 1 -CIS "18.3.2. (L1) Ensure 'Do not allow password expiration time longer than required by policy' is set to 'Enabled' (MS only)"  ) # -RegType DWORD

# 18.3.4. (L1) Ensure 'Password Settings: Password Complexity' is set to 'Enabled: Large letters + small letters + numbers + special characters' (MS only)
Write-Host "18.3.4. (L1) Ensure 'Password Settings: Password Complexity' is set to 'Enabled: Large letters + small letters + numbers + special characters' (MS only)"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\LAPS' -Name 'PasswordComplexity' -CorrectValue 4 -CIS "18.3.4. (L1) Ensure 'Password Settings: Password Complexity' is set to 'Enabled: Large letters + small letters + numbers + special characters' (MS only)"  ) # -RegType DWORD

# 18.3.5. (L1) Ensure 'Password Settings: Password Length' is set to 'Enabled: 15 or more' (MS only)
Write-Host "18.3.5. (L1) Ensure 'Password Settings: Password Length' is set to 'Enabled: 15 or more' (MS only)"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\LAPS' -Name 'PasswordLength' -CorrectValue 15 -CIS "18.3.5. (L1) Ensure 'Password Settings: Password Length' is set to 'Enabled: 15 or more' (MS only)"  ) # -RegType DWORD

# 18.3.6. (L1) Ensure 'Password Settings: Password Age (Days)' is set to 'Enabled: 30 or fewer' (MS only)
Write-Host "18.3.6. (L1) Ensure 'Password Settings: Password Age (Days)' is set to 'Enabled: 30 or fewer' (MS only)"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\LAPS' -Name 'PasswordAgeDays' -CorrectValue 30 -CIS "18.3.6. (L1) Ensure 'Password Settings: Password Age (Days)' is set to 'Enabled: 30 or fewer' (MS only)"  ) # -RegType DWORD

# 18.4.2. (L1) Ensure 'Configure RPC packet level privacy setting for incoming connections' is set to 'Enabled'
Write-Host "18.4.2. (L1) Ensure 'Configure RPC packet level privacy setting for incoming connections' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Print' -Name 'RpcAuthnLevelPrivacyEnabled' -CorrectValue 1 -CIS "18.4.2. (L1) Ensure 'Configure RPC packet level privacy setting for incoming connections' is set to 'Enabled'"  ) # -RegType DWORD

# 18.5.1. (L1) Ensure 'MSS: (AutoAdminLogon) Enable Automatic Logon (not recommended)' is set to 'Disabled'
Write-Host "18.5.1. (L1) Ensure 'MSS: (AutoAdminLogon) Enable Automatic Logon (not recommended)' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'AutoAdminLogon' -CorrectValue 0 -CIS "18.5.1. (L1) Ensure 'MSS: (AutoAdminLogon) Enable Automatic Logon (not recommended)' is set to 'Disabled'"  ) # -RegType String

# 18.5.8. (L1) Ensure 'MSS: (SafeDllSearchMode) Enable Safe DLL search mode (recommended)' is set to 'Enabled'
Write-Host "18.5.8. (L1) Ensure 'MSS: (SafeDllSearchMode) Enable Safe DLL search mode (recommended)' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'SafeDllSearchMode' -CorrectValue 1 -CIS "18.5.8. (L1) Ensure 'MSS: (SafeDllSearchMode) Enable Safe DLL search mode (recommended)' is set to 'Enabled'"  ) # -RegType DWORD

# 18.5.9. (L1) Ensure 'MSS: (ScreenSaverGracePeriod) The time in seconds before the screen saver grace period expires (0 recommended)' is set to 'Enabled: 5 or fewer seconds'
Write-Host "18.5.9. (L1) Ensure 'MSS: (ScreenSaverGracePeriod) The time in seconds before the screen saver grace period expires (0 recommended)' is set to 'Enabled: 5 or fewer seconds'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'ScreenSaverGracePeriod' -CorrectValue 0 -CIS "18.5.9. (L1) Ensure 'MSS: (ScreenSaverGracePeriod) The time in seconds before the screen saver grace period expires (0 recommended)' is set to 'Enabled: 5 or fewer seconds'"  ) # -RegType String

# 18.5.10. (L2) Ensure 'MSS: (TcpMaxDataRetransmissions IPv6) How many times unacknowledged data is retransmitted' is set to 'Enabled: 3'
Write-Host "18.5.10. (L2) Ensure 'MSS: (TcpMaxDataRetransmissions IPv6) How many times unacknowledged data is retransmitted' is set to 'Enabled: 3'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP6\Parameters' -Name 'TcpMaxDataRetransmissions' -CorrectValue 3 -CIS "18.5.10. (L2) Ensure 'MSS: (TcpMaxDataRetransmissions IPv6) How many times unacknowledged data is retransmitted' is set to 'Enabled: 3'"  ) # -RegType String

# 18.5.12. (L1) Ensure 'MSS: (WarningLevel) Percentage threshold for the security event log at which the system will generate a warning' is set to 'Enabled: 90% or less'
Write-Host "18.5.12. (L1) Ensure 'MSS: (WarningLevel) Percentage threshold for the security event log at which the system will generate a warning' is set to 'Enabled: 90% or less'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Eventlog\Security' -Name 'WarningLevel' -CorrectValue 90 -CIS "18.5.12. (L1) Ensure 'MSS: (WarningLevel) Percentage threshold for the security event log at which the system will generate a warning' is set to 'Enabled: 90% or less'"  ) # -RegType DWORD

# 18.6.4.2. (L1) Ensure 'Configure NetBIOS settings' is set to 'Enabled: Disable NetBIOS name resolution on public networks'
Write-Host "18.6.4.2. (L1) Ensure 'Configure NetBIOS settings' is set to 'Enabled: Disable NetBIOS name resolution on public networks'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient' -Name 'EnableNetbios' -CorrectValue 0 -CIS "18.6.4.2. (L1) Ensure 'Configure NetBIOS settings' is set to 'Enabled: Disable NetBIOS name resolution on public networks'"  ) # -RegType DWORD

# 18.6.11.2. (L1) Ensure 'Prohibit installation and configuration of Network Bridge on your DNS domain network' is set to 'Enabled'
Write-Host "18.6.11.2. (L1) Ensure 'Prohibit installation and configuration of Network Bridge on your DNS domain network' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections' -Name 'NC_AllowNetBridge_NLA' -CorrectValue 0 -CIS "18.6.11.2. (L1) Ensure 'Prohibit installation and configuration of Network Bridge on your DNS domain network' is set to 'Enabled'"  ) # -RegType DWORD

# 18.6.11.3. (L1) Ensure 'Prohibit use of Internet Connection Sharing on your DNS domain network' is set to 'Enabled'
Write-Host "18.6.11.3. (L1) Ensure 'Prohibit use of Internet Connection Sharing on your DNS domain network' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections' -Name 'NC_ShowSharedAccessUI' -CorrectValue 0 -CIS "18.6.11.3. (L1) Ensure 'Prohibit use of Internet Connection Sharing on your DNS domain network' is set to 'Enabled'"  ) # -RegType DWORD

# 18.6.11.4. (L1) Ensure 'Require domain users to elevate when setting a network's location' is set to 'Enabled'
Write-Host "18.6.11.4. (L1) Ensure 'Require domain users to elevate when setting a network's location' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections' -Name 'NC_StdDomainUserSetLocation' -CorrectValue 1 -CIS "18.6.11.4. (L1) Ensure 'Require domain users to elevate when setting a network's location' is set to 'Enabled'"  ) # -RegType DWORD

# 18.6.19.2.1. (L2) Disable IPv6 (Ensure TCPIP6 Parameter 'DisabledComponents' is set to '0xff (255)')
Write-Host "18.6.19.2.1. (L2) Disable IPv6 (Ensure TCPIP6 Parameter 'DisabledComponents' is set to '0xff (255)')"
$SetItems += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP6\Parameters' -Name 'DisabledComponents' -CorrectValue 255 -CIS "18.6.19.2.1. (L2) Disable IPv6 (Ensure TCPIP6 Parameter 'DisabledComponents' is set to '0xff (255)')"  ) # -RegType DWORD

# 18.6.21.1. (L1) Ensure 'Minimize the number of simultaneous connections to the Internet or a Windows Domain' is set to 'Enabled: 3 = Prevent Wi-Fi when on Ethernet'
Write-Host "18.6.21.1. (L1) Ensure 'Minimize the number of simultaneous connections to the Internet or a Windows Domain' is set to 'Enabled: 3 = Prevent Wi-Fi when on Ethernet'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy' -Name 'fMinimizeConnections' -CorrectValue 3 -CIS "18.6.21.1. (L1) Ensure 'Minimize the number of simultaneous connections to the Internet or a Windows Domain' is set to 'Enabled: 3 = Prevent Wi-Fi when on Ethernet'"  ) # -RegType DWORD

# 18.7.2. (L1) Ensure 'Configure Redirection Guard' is set to 'Enabled: Redirection Guard Enabled'
Write-Host "18.7.2. (L1) Ensure 'Configure Redirection Guard' is set to 'Enabled: Redirection Guard Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers' -Name 'RedirectionguardPolicy' -CorrectValue 1 -CIS "18.7.2. (L1) Ensure 'Configure Redirection Guard' is set to 'Enabled: Redirection Guard Enabled'"  ) # -RegType DWORD

# 18.7.7. (L1) Ensure 'Configure RPC over TCP port' is set to 'Enabled: 0'
Write-Host "18.7.7. (L1) Ensure 'Configure RPC over TCP port' is set to 'Enabled: 0'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC' -Name 'RpcProtocols' -CorrectValue 0 -CIS "18.7.7. (L1) Ensure 'Configure RPC over TCP port' is set to 'Enabled: 0'"  ) # -RegType DWORD

# 18.7.9. (L1) Ensure 'Manage processing of Queue-specific files' is set to 'Enabled: Limit Queue-specific files to Color profiles'
Write-Host "18.7.9. (L1) Ensure 'Manage processing of Queue-specific files' is set to 'Enabled: Limit Queue-specific files to Color profiles'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers' -Name 'CopyFilesPolicy' -CorrectValue 1 -CIS "18.7.9. (L1) Ensure 'Manage processing of Queue-specific files' is set to 'Enabled: Limit Queue-specific files to Color profiles'"  ) # -RegType DWORD

# 18.9.3.1. (L1) Ensure 'Include command line in process creation events' is set to 'Enabled'
Write-Host "18.9.3.1. (L1) Ensure 'Include command line in process creation events' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit' -Name 'ProcessCreationIncludeCmdLine_Enabled' -CorrectValue 1 -CIS "18.9.3.1. (L1) Ensure 'Include command line in process creation events' is set to 'Enabled'"  ) # -RegType DWORD

# 18.9.7.2. (L1) Ensure 'Prevent device metadata retrieval from the Internet' is set to 'Enabled'
Write-Host "18.9.7.2. (L1) Ensure 'Prevent device metadata retrieval from the Internet' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata' -Name 'PreventDeviceMetadataFromNetwork' -CorrectValue 1 -CIS "18.9.7.2. (L1) Ensure 'Prevent device metadata retrieval from the Internet' is set to 'Enabled'"  ) # -RegType DWORD

# 18.9.19.5. (L1) Ensure 'Turn off background refresh of Group Policy' is set to 'Disabled'
Write-Host "18.9.19.5. (L1) Ensure 'Turn off background refresh of Group Policy' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Group Policy\{827D319E-6EAC-11D2-A4EA-00C04F79F83A}' -Name 'NoGPOListChanges' -CorrectValue 0 -CIS "18.9.19.5. (L1) Ensure 'Turn off background refresh of Group Policy' is set to 'Disabled'"  ) # -RegType DWORD

# 18.9.20.1.1. (L1) Ensure 'Turn off downloading of print drivers over HTTP' is set to 'Enabled'
Write-Host "18.9.20.1.1. (L1) Ensure 'Turn off downloading of print drivers over HTTP' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers' -Name 'DisableWebPnPDownload' -CorrectValue 1 -CIS "18.9.20.1.1. (L1) Ensure 'Turn off downloading of print drivers over HTTP' is set to 'Enabled'"  ) # -RegType DWORD

# 18.9.20.1.5. (L1) Ensure 'Turn off Internet download for Web publishing and online ordering wizards' is set to 'Enabled'
Write-Host "18.9.20.1.5. (L1) Ensure 'Turn off Internet download for Web publishing and online ordering wizards' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoWebServices' -CorrectValue 1 -CIS "18.9.20.1.5. (L1) Ensure 'Turn off Internet download for Web publishing and online ordering wizards' is set to 'Enabled'"  ) # -RegType DWORD

# 18.9.25.1. (L1) Ensure 'Allow Custom SSPs and APs to be loaded into LSASS' is set to 'Disabled'
Write-Host "18.9.25.1. (L1) Ensure 'Allow Custom SSPs and APs to be loaded into LSASS' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'AllowCustomSSPsAPs' -CorrectValue 0 -CIS "18.9.25.1. (L1) Ensure 'Allow Custom SSPs and APs to be loaded into LSASS' is set to 'Disabled'"  ) # -RegType DWORD

# 18.9.27.1. (L1) Ensure 'Block user from showing account details on sign-in' is set to 'Enabled'
Write-Host "18.9.27.1. (L1) Ensure 'Block user from showing account details on sign-in' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Control Panel\International' -Name 'BlockUserInputMethodsForSignIn' -CorrectValue 1 -CIS "18.9.27.1. (L1) Ensure 'Block user from showing account details on sign-in' is set to 'Enabled'"  ) # -RegType DWORD

# 18.9.27.2. (L1) Ensure 'Do not display network selection UI' is set to 'Enabled'
Write-Host "18.9.27.2. (L1) Ensure 'Do not display network selection UI' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'DontDisplayNetworkSelectionUI' -CorrectValue 1 -CIS "18.9.27.2. (L1) Ensure 'Do not display network selection UI' is set to 'Enabled'"  ) # -RegType DWORD

# 18.9.27.3. (L1) Ensure 'Do not enumerate connected users on domain-joined computers' is set to 'Enabled'
Write-Host "18.9.27.3. (L1) Ensure 'Do not enumerate connected users on domain-joined computers' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'DontEnumerateConnectedUsers' -CorrectValue 1 -CIS "18.9.27.3. (L1) Ensure 'Do not enumerate connected users on domain-joined computers' is set to 'Enabled'"  ) # -RegType DWORD

# 18.9.27.5. (L1) Ensure 'Turn off app notifications on the lock screen' is set to 'Enabled'
Write-Host "18.9.27.5. (L1) Ensure 'Turn off app notifications on the lock screen' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'DisableLockScreenAppNotifications' -CorrectValue 1 -CIS "18.9.27.5. (L1) Ensure 'Turn off app notifications on the lock screen' is set to 'Enabled'"  ) # -RegType DWORD

# 18.9.27.6. (L1) Ensure 'Turn off picture password sign-in' is set to 'Enabled'
Write-Host "18.9.27.6. (L1) Ensure 'Turn off picture password sign-in' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'BlockDomainPicturePassword' -CorrectValue 1 -CIS "18.9.27.6. (L1) Ensure 'Turn off picture password sign-in' is set to 'Enabled'"  ) # -RegType DWORD

# 18.9.27.7. (L1) Ensure 'Turn on convenience PIN sign-in' is set to 'Disabled'
Write-Host "18.9.27.7. (L1) Ensure 'Turn on convenience PIN sign-in' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'AllowDomainPINLogon' -CorrectValue 0 -CIS "18.9.27.7. (L1) Ensure 'Turn on convenience PIN sign-in' is set to 'Disabled'"  ) # -RegType DWORD

# 18.9.32.6.3. (L1) Ensure 'Require a password when a computer wakes (on battery)' is set to 'Enabled'
Write-Host "18.9.32.6.3. (L1) Ensure 'Require a password when a computer wakes (on battery)' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51' -Name 'DCSettingIndex' -CorrectValue 1 -CIS "18.9.32.6.3. (L1) Ensure 'Require a password when a computer wakes (on battery)' is set to 'Enabled'"  ) # -RegType DWORD

# 18.9.32.6.4. (L1) Ensure 'Require a password when a computer wakes (plugged in)' is set to 'Enabled'
Write-Host "18.9.32.6.4. (L1) Ensure 'Require a password when a computer wakes (plugged in)' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51' -Name 'ACSettingIndex' -CorrectValue 1 -CIS "18.9.32.6.4. (L1) Ensure 'Require a password when a computer wakes (plugged in)' is set to 'Enabled'"  ) # -RegType DWORD

# 18.9.34.1. (L1) Ensure 'Configure Offer Remote Assistance' is set to 'Disabled'
Write-Host "18.9.34.1. (L1) Ensure 'Configure Offer Remote Assistance' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'fAllowUnsolicited' -CorrectValue 0 -CIS "18.9.34.1. (L1) Ensure 'Configure Offer Remote Assistance' is set to 'Disabled'"  ) # -RegType DWORD

# 18.9.34.2. (L1) Ensure 'Configure Solicited Remote Assistance' is set to 'Disabled'
Write-Host "18.9.34.2. (L1) Ensure 'Configure Solicited Remote Assistance' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'fAllowToGetHelp' -CorrectValue 0 -CIS "18.9.34.2. (L1) Ensure 'Configure Solicited Remote Assistance' is set to 'Disabled'"  ) # -RegType DWORD

# 18.9.35.1. (L1) Ensure 'Enable RPC Endpoint Mapper Client Authentication' is set to 'Enabled' (MS only)
Write-Host "18.9.35.1. (L1) Ensure 'Enable RPC Endpoint Mapper Client Authentication' is set to 'Enabled' (MS only)"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Rpc' -Name 'EnableAuthEpResolution' -CorrectValue 1 -CIS "18.9.35.1. (L1) Ensure 'Enable RPC Endpoint Mapper Client Authentication' is set to 'Enabled' (MS only)"  ) # -RegType DWORD

# 18.9.50.1.1. (L2) Ensure 'Enable Windows NTP Client' is set to 'Enabled'
Write-Host "18.9.50.1.1. (L2) Ensure 'Enable Windows NTP Client' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\W32Time\TimeProviders\NtpClient' -Name 'Enabled' -CorrectValue 1 -CIS "18.9.50.1.1. (L2) Ensure 'Enable Windows NTP Client' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.5.1. (L1) Ensure 'Allow Microsoft accounts to be optional' is set to 'Enabled'
Write-Host "18.10.5.1. (L1) Ensure 'Allow Microsoft accounts to be optional' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'MSAOptional' -CorrectValue 1 -CIS "18.10.5.1. (L1) Ensure 'Allow Microsoft accounts to be optional' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.12.1. (L1) Ensure 'Turn off cloud consumer account state content' is set to 'Enabled'
Write-Host "18.10.12.1. (L1) Ensure 'Turn off cloud consumer account state content' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableConsumerAccountStateContent' -CorrectValue 1 -CIS "18.10.12.1. (L1) Ensure 'Turn off cloud consumer account state content' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.12.1. (L1) Ensure 'Turn off cloud consumer account state content' is set to 'Enabled'
Write-Host "18.10.12.2. (L2) Ensure 'Turn off cloud optimized content' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableCloudOptimizedContent' -CorrectValue 1 -CIS "18.10.12.2. (L2) Ensure 'Turn off cloud optimized content' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.12.3. (L1) Ensure 'Turn off Microsoft consumer experiences' is set to 'Enabled'
Write-Host "18.10.12.3. (L1) Ensure 'Turn off Microsoft consumer experiences' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsConsumerFeatures' -CorrectValue 1 -CIS "18.10.12.3. (L1) Ensure 'Turn off Microsoft consumer experiences' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.13.1. (L1) Ensure 'Require pin for pairing' is set to 'Enabled: First Time' OR 'Enabled: Always'
Write-Host "18.10.13.1. (L1) Ensure 'Require pin for pairing' is set to 'Enabled: First Time' OR 'Enabled: Always'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Connect' -Name 'RequirePinForPairing' -CorrectValue 1 -CIS "18.10.13.1. (L1) Ensure 'Require pin for pairing' is set to 'Enabled: First Time' OR 'Enabled: Always'"  ) # -RegType DWORD

# 18.10.14.1. (L1) Ensure 'Do not display the password reveal button' is set to 'Enabled'
Write-Host "18.10.14.1. (L1) Ensure 'Do not display the password reveal button' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredUI' -Name 'DisablePasswordReveal' -CorrectValue 1 -CIS "18.10.14.1. (L1) Ensure 'Do not display the password reveal button' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.14.2. (L1) Ensure 'Enumerate administrator accounts on elevation' is set to 'Disabled'
Write-Host "18.10.14.2. (L1) Ensure 'Enumerate administrator accounts on elevation' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\CredUI' -Name 'EnumerateAdministrators' -CorrectValue 0 -CIS "18.10.14.2. (L1) Ensure 'Enumerate administrator accounts on elevation' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.15.1. (L1) Ensure 'Allow Diagnostic Data' is set to 'Enabled: Diagnostic data off (not recommended)' or 'Enabled: Send required diagnostic data'
Write-Host "18.10.15.1. (L1) Ensure 'Allow Diagnostic Data' is set to 'Enabled: Diagnostic data off (not recommended)' or 'Enabled: Send required diagnostic data'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -CorrectValue 0 -CIS "18.10.15.1. (L1) Ensure 'Allow Diagnostic Data' is set to 'Enabled: Diagnostic data off (not recommended)' or 'Enabled: Send required diagnostic data'"  ) # -RegType DWORD

# 18.10.15.3. (L1) Ensure 'Disable OneSettings Downloads' is set to 'Enabled'
Write-Host "18.10.15.3. (L1) Ensure 'Disable OneSettings Downloads' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'DisableOneSettingsDownloads' -CorrectValue 1 -CIS "18.10.15.3. (L1) Ensure 'Disable OneSettings Downloads' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.15.4. (L1) Ensure 'Do not show feedback notifications' is set to 'Enabled'
Write-Host "18.10.15.4. (L1) Ensure 'Do not show feedback notifications' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'DoNotShowFeedbackNotifications' -CorrectValue 1 -CIS "18.10.15.4. (L1) Ensure 'Do not show feedback notifications' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.15.5. (L1) Ensure 'Enable OneSettings Auditing' is set to 'Enabled'
Write-Host "18.10.15.5. (L1) Ensure 'Enable OneSettings Auditing' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'EnableOneSettingsAuditing' -CorrectValue 1 -CIS "18.10.15.5. (L1) Ensure 'Enable OneSettings Auditing' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.15.6. (L1) Ensure 'Limit Diagnostic Log Collection' is set to 'Enabled'
Write-Host "18.10.15.6. (L1) Ensure 'Limit Diagnostic Log Collection' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'LimitDiagnosticLogCollection' -CorrectValue 1 -CIS "18.10.15.6. (L1) Ensure 'Limit Diagnostic Log Collection' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.15.7. (L1) Ensure 'Limit Dump Collection' is set to 'Enabled'
Write-Host "18.10.15.7. (L1) Ensure 'Limit Dump Collection' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'LimitDumpCollection' -CorrectValue 1 -CIS "18.10.15.7. (L1) Ensure 'Limit Dump Collection' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.15.8. (L1) Ensure 'Toggle user control over Insider builds' is set to 'Disabled'
Write-Host "18.10.15.8. (L1) Ensure 'Toggle user control over Insider builds' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds' -Name 'AllowBuildPreview' -CorrectValue 0 -CIS "18.10.15.8. (L1) Ensure 'Toggle user control over Insider builds' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.17.1. (L1) Ensure 'Enable App Installer' is set to 'Disabled'
Write-Host "18.10.17.1. (L1) Ensure 'Enable App Installer' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppInstaller' -Name 'EnableAppInstaller' -CorrectValue 0 -CIS "18.10.17.1. (L1) Ensure 'Enable App Installer' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.17.2. (L1) Ensure 'Enable App Installer Experimental Features' is set to 'Disabled'
Write-Host "18.10.17.2. (L1) Ensure 'Enable App Installer Experimental Features' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppInstaller' -Name 'EnableExperimentalFeatures' -CorrectValue 0 -CIS "18.10.17.2. (L1) Ensure 'Enable App Installer Experimental Features' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.17.3. (L1) Ensure 'Enable App Installer Hash Override' is set to 'Disabled'
Write-Host "18.10.17.3. (L1) Ensure 'Enable App Installer Hash Override' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppInstaller' -Name 'EnableHashOverride' -CorrectValue 0 -CIS "18.10.17.3. (L1) Ensure 'Enable App Installer Hash Override' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.17.4. (L1) Ensure 'Enable App Installer ms-appinstaller protocol' is set to 'Disabled'
Write-Host "18.10.17.4. (L1) Ensure 'Enable App Installer ms-appinstaller protocol' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppInstaller' -Name 'EnableMSAppInstallerProtocol' -CorrectValue 0 -CIS "18.10.17.4. (L1) Ensure 'Enable App Installer ms-appinstaller protocol' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.26.2.2. (L1) Ensure 'Security: Specify the maximum log file size (KB)' is set to 'Enabled: 196,608 or greater'
Write-Host "18.10.26.2.2. (L1) Ensure 'Security: Specify the maximum log file size (KB)' is set to 'Enabled: 196,608 or greater'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\Security' -Name 'MaxSize' -CorrectValue 196608 -CIS "18.10.26.2.2. (L1) Ensure 'Security: Specify the maximum log file size (KB)' is set to 'Enabled: 196,608 or greater'"  ) # -RegType DWORD

# 18.10.26.3.2. (L1) Ensure 'Setup: Specify the maximum log file size (KB)' is set to 'Enabled: 32,768 or greater'
Write-Host "18.10.26.3.2. (L1) Ensure 'Setup: Specify the maximum log file size (KB)' is set to 'Enabled: 32,768 or greater'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\Setup' -Name 'MaxSize' -CorrectValue 32768 -CIS "18.10.26.3.2. (L1) Ensure 'Setup: Specify the maximum log file size (KB)' is set to 'Enabled: 32,768 or greater'"  ) # -RegType DWORD

# 18.10.29.2. (L1) Ensure 'Turn off Data Execution Prevention for Explorer' is set to 'Disabled'
Write-Host "18.10.29.2. (L1) Ensure 'Turn off Data Execution Prevention for Explorer' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'NoDataExecutionPrevention' -CorrectValue 0 -CIS "18.10.29.2. (L1) Ensure 'Turn off Data Execution Prevention for Explorer' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.29.3. (L1) Ensure 'Turn off heap termination on corruption' is set to 'Disabled'
Write-Host "18.10.29.3. (L1) Ensure 'Turn off heap termination on corruption' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'NoHeapTerminationOnCorruption' -CorrectValue 0 -CIS "18.10.29.3. (L1) Ensure 'Turn off heap termination on corruption' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.29.4. (L1) Ensure 'Turn off shell protocol protected mode' is set to 'Disabled'
Write-Host "18.10.29.4. (L1) Ensure 'Turn off shell protocol protected mode' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'PreXPSP2ShellProtocolBehavior' -CorrectValue 0 -CIS "18.10.29.4. (L1) Ensure 'Turn off shell protocol protected mode' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.42.1. (L1) Ensure 'Block all consumer Microsoft account user authentication' is set to 'Enabled'
Write-Host "18.10.42.1. (L1) Ensure 'Block all consumer Microsoft account user authentication' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftAccount' -Name 'DisableUserAuth' -CorrectValue 1 -CIS "18.10.42.1. (L1) Ensure 'Block all consumer Microsoft account user authentication' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.43.5.1. (L1) Ensure 'Configure local setting override for reporting to Microsoftr MAPS' is set to 'Disabled'
Write-Host "18.10.43.5.1. (L1) Ensure 'Configure local setting override for reporting to Microsoftr MAPS' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet' -Name 'LocalSettingOverrideSpynetReporting' -CorrectValue 0 -CIS "18.10.43.5.1. (L1) Ensure 'Configure local setting override for reporting to Microsoftr MAPS' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.43.5.2. (L2) Ensure 'Join Microsoft MAPS' is set to 'Disabled'
Write-Host "18.10.43.5.2. (L2) Ensure 'Join Microsoft MAPS' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet' -Name 'SpynetReporting' -CorrectValue 0 -CIS "18.10.43.5.2. (L2) Ensure 'Join Microsoft MAPS' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured
Write-Host "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name '26190899-1602-49e8-8b27-eb1d0a1ce869' -CorrectValue 1 -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured"  ) # -RegType String
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name '3b576869-a4ec-4529-8536-b80a7769e899' -CorrectValue 1 -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured"  ) # -RegType String
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name '56a863a9-875e-4185-98a7-b882c64b5ce5' -CorrectValue 1 -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured"  ) # -RegType String
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name '5beb7efe-fd9a-4556-801d-275e5ffc04cc' -CorrectValue 1 -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured"  ) # -RegType String
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name '75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84' -CorrectValue 1 -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured"  ) # -RegType String
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name '7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c' -CorrectValue 1 -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured"  ) # -RegType String
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name '92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b' -CorrectValue 1 -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured"  ) # -RegType String
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name '9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2' -CorrectValue 1 -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured"  ) # -RegType String
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name 'b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4' -CorrectValue 1 -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured"  ) # -RegType String
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name 'be9ba2d9-53ea-4cdc-84e5-9b1eeee46550' -CorrectValue 1 -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured"  ) # -RegType String
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name 'd3e037e1-3eb8-44c8-a917-57927947596d' -CorrectValue 1 -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured"  ) # -RegType String
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name 'd4f940ab-401b-4efc-aadc-ad5f3c50688a' -CorrectValue 1 -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured"  ) # -RegType String
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name 'e6db77e5-3df2-4cf1-b95a-636979351e5b' -CorrectValue 1 -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured"  ) # -RegType String

# 18.10.43.7.1. (L2) Ensure 'Enable file hash computation feature' is set to 'Enabled'
Write-Host "18.10.43.7.1. (L2) Ensure 'Enable file hash computation feature' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine' -Name 'EnableFileHashComputation' -CorrectValue 1 -CIS "18.10.43.7.1. (L2) Ensure 'Enable file hash computation feature' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.43.10.3. (L1) Ensure 'Turn on behavior monitoring' is set to 'Enabled'
Write-Host "18.10.43.10.3. (L1) Ensure 'Turn on behavior monitoring' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection' -Name 'DisableBehaviorMonitoring' -CorrectValue 0 -CIS "18.10.43.10.3. (L1) Ensure 'Turn on behavior monitoring' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.43.12.1. (L2) Ensure 'Configure Watson events' is set to 'Disabled'
Write-Host "18.10.43.12.1. (L2) Ensure 'Configure Watson events' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting' -Name 'DisableGenericRePorts' -CorrectValue 1 -CIS "18.10.43.12.1. (L2) Ensure 'Configure Watson events' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.43.13.2. (L1) Ensure 'Turn on e-mail scanning' is set to 'Enabled' 
Write-Host "18.10.43.13.2. (L1) Ensure 'Turn on e-mail scanning' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan' -Name 'DisableEmailScanning' -CorrectValue 0 -CIS "18.10.43.13.2. (L1) Ensure 'Turn on e-mail scanning' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.51.1. (L1) Ensure 'Prevent the usage of OneDrive for file storage' is set to 'Enabled'
Write-Host "18.10.51.1. (L1) Ensure 'Prevent the usage of OneDrive for file storage' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' -Name 'DisableFileSyncNGSC' -CorrectValue 1 -CIS "18.10.51.1. (L1) Ensure 'Prevent the usage of OneDrive for file storage' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.56.1. (L2) Ensure 'Turn off Push To Install service' is set to 'Enabled'
Write-Host "18.10.56.1. (L2) Ensure 'Turn off Push To Install service' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\PushToInstall' -Name 'DisablePushToInstall' -CorrectValue 1 -CIS "18.10.56.1. (L2) Ensure 'Turn off Push To Install service' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.57.3.3.1. (L2) Ensure 'Allow UI Automation redirection' is set to 'Disabled'
Write-Host "18.10.57.3.3.1. (L2) Ensure 'Allow UI Automation redirection' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'EnableUiaRedirection' -CorrectValue 1 -CIS "18.10.57.3.3.1. (L2) Ensure 'Allow UI Automation redirection' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.57.3.3.2. (L2) Ensure 'Do not allow COM port redirection' is set to 'Enabled'
Write-Host "18.10.57.3.3.2. (L2) Ensure 'Do not allow COM port redirection' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'fDisableCcm' -CorrectValue 1 -CIS "18.10.57.3.3.2. (L2) Ensure 'Do not allow COM port redirection' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.57.3.3.4. (L2) Ensure 'Do not allow location redirection' is set to 'Enabled'
Write-Host "18.10.57.3.3.4. (L2) Ensure 'Do not allow location redirection' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'fDisableLocationRedir' -CorrectValue 1 -CIS "18.10.57.3.3.4. (L2) Ensure 'Do not allow location redirection' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.57.3.3.5. (L2) Ensure 'Do not allow LPT port redirection' is set to 'Enabled'
Write-Host "18.10.57.3.3.5. (L2) Ensure 'Do not allow LPT port redirection' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'fDisableLPT' -CorrectValue 1 -CIS "18.10.57.3.3.5. (L2) Ensure 'Do not allow LPT port redirection' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.57.3.3.6. (L2) Ensure 'Do not allow supported Plug and Play device redirection' is set to 'Enabled'
Write-Host "18.10.57.3.3.6. (L2) Ensure 'Do not allow supported Plug and Play device redirection' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'fDisablePNPRedir' -CorrectValue 1 -CIS "18.10.57.3.3.6. (L2) Ensure 'Do not allow supported Plug and Play device redirection' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.57.3.3.7. (L2) Ensure 'Do not allow WebAuthn redirection' is set to 'Enabled'
Write-Host "18.10.57.3.3.7. (L2) Ensure 'Do not allow WebAuthn redirection' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'fDisableWebAuthn' -CorrectValue 1 -CIS "18.10.57.3.3.7. (L2) Ensure 'Do not allow WebAuthn redirection' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.57.3.9.3. (L1) Ensure 'Require use of specific security layer for remote (RDP) connections' is set to 'Enabled: SSL'
Write-Host "18.10.57.3.9.3. (L1) Ensure 'Require use of specific security layer for remote (RDP) connections' is set to 'Enabled: SSL'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'SecurityLayer' -CorrectValue 2 -CIS "18.10.57.3.9.3. (L1) Ensure 'Require use of specific security layer for remote (RDP) connections' is set to 'Enabled: SSL'"  ) # -RegType DWORD

# 18.10.57.3.9.4. (L1) Ensure 'Require user authentication for remote connections by using Network Level Authentication' is set to 'Enabled'
Write-Host "18.10.57.3.9.4. (L1) Ensure 'Require user authentication for remote connections by using Network Level Authentication' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'UserAuthentication' -CorrectValue 1 -CIS "18.10.57.3.9.4. (L1) Ensure 'Require user authentication for remote connections by using Network Level Authentication' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.57.3.11.1. (L1) Ensure 'Do not delete temp folders upon exit' is set to 'Disabled'
Write-Host "18.10.57.3.11.1. (L1) Ensure 'Do not delete temp folders upon exit' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'DeleteTempDirsOnExit' -CorrectValue 1 -CIS "18.10.57.3.11.1. (L1) Ensure 'Do not delete temp folders upon exit' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.57.3.11.2. (L1) Ensure 'Do not use temporary folders per session' is set to 'Disabled'
Write-Host "18.10.57.3.11.2. (L1) Ensure 'Do not use temporary folders per session' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'PerSessionTempDir' -CorrectValue 1 -CIS "18.10.57.3.11.2. (L1) Ensure 'Do not use temporary folders per session' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.59.4. (L2) Ensure 'Allow search highlights' is set to 'Disabled'
Write-Host "18.10.59.4. (L2) Ensure 'Allow search highlights' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'EnableDynamicContentInWSB' -CorrectValue 1 -CIS "18.10.59.4. (L2) Ensure 'Allow search highlights' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.82.1. (L1) Ensure 'Enable MPR notifications for the system' is set to 'Disabled'
Write-Host "18.10.82.1. (L1) Ensure 'Enable MPR notifications for the system' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableMPR' -CorrectValue 0 -CIS  "18.10.82.1. (L1) Ensure 'Enable MPR notifications for the system' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.89.1.1. (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'
Write-Host "18.10.89.1.1. (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client' -Name 'AllowBasic' -CorrectValue 0 -CIS "18.10.89.1.1. (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.89.1.2. (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'
Write-Host "18.10.89.1.2. (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client' -Name 'AllowUnencryptedTraffic' -CorrectValue 0 -CIS "18.10.89.1.2. (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.89.1.3. (L1) Ensure 'Disallow Digest authentication' is set to 'Enabled'
Write-Host "18.10.89.1.3. (L1) Ensure 'Disallow Digest authentication' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client' -Name 'AllowDigest' -CorrectValue 0 -CIS "18.10.89.1.3. (L1) Ensure 'Disallow Digest authentication' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.89.2.1. (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'
Write-Host "18.10.89.2.1. (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service' -Name 'AllowBasic' -CorrectValue 0 -CIS "18.10.89.2.1. (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.89.2.3. (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'
Write-Host "18.10.89.2.3. (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service' -Name 'AllowUnencryptedTraffic' -CorrectValue 0 -CIS "18.10.89.2.3. (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.89.2.4. (L1) Ensure 'Disallow WinRM from storing RunAs credentials' is set to 'Enabled'
Write-Host "18.10.89.2.4. (L1) Ensure 'Disallow WinRM from storing RunAs credentials' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service' -Name 'DisableRunAs' -CorrectValue 1 -CIS "18.10.89.2.4. (L1) Ensure 'Disallow WinRM from storing RunAs credentials' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.92.2.1. (L1) Ensure 'Prevent users from modifying settings' is set to 'Enabled'
Write-Host "18.10.92.2.1. (L1) Ensure 'Prevent users from modifying settings' is set to 'Enabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\App and Browser protection' -Name 'DisallowExploitProtectionOverride' -CorrectValue 1 -CIS "18.10.92.2.1. (L1) Ensure 'Prevent users from modifying settings' is set to 'Enabled'"  ) # -RegType DWORD

# 18.10.93.4.1. (L1) Ensure 'Manage preview builds' is set to 'Disabled'
Write-Host "18.10.93.4.1. (L1) Ensure 'Manage preview builds' is set to 'Disabled'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'ManagePreviewBuildsPolicyValue' -CorrectValue 1 -CIS "18.10.93.4.1. (L1) Ensure 'Manage preview builds' is set to 'Disabled'"  ) # -RegType DWORD

# 18.10.93.4.2. (L1) Ensure 'Select when Preview Builds and Feature Updates are received' is set to 'Enabled: 180 or more days'
Write-Host "18.10.93.4.2. (L1) Ensure 'Select when Preview Builds and Feature Updates are received' is set to 'Enabled: 180 or more days'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'DeferFeatureUpdates' -CorrectValue 1 -CIS "18.10.93.4.2. (L1) Ensure 'Select when Preview Builds and Feature Updates are received' is set to 'Enabled: 180 or more days'"  ) # -RegType DWORD
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'DeferFeatureUpdatesPeriodInDays' -CorrectValue 180 -CIS "18.10.93.4.2. (L1) Ensure 'Select when Preview Builds and Feature Updates are received' is set to 'Enabled: 180 or more days'"  ) # -RegType DWORD

# 18.10.93.4.3. (L1) Ensure 'Select when Quality Updates are received' is set to 'Enabled: 0 days'
Write-Host "18.10.93.4.3. (L1) Ensure 'Select when Quality Updates are received' is set to 'Enabled: 0 days'"
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'DeferQualityUpdates' -CorrectValue 1 -CIS "18.10.93.4.3. (L1) Ensure 'Select when Quality Updates are received' is set to 'Enabled: 0 days'"  ) # -RegType DWORD
$SetItems += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'DeferQualityUpdatesPeriodInDays' -CorrectValue 0 -CIS "18.10.93.4.3. (L1) Ensure 'Select when Quality Updates are received' is set to 'Enabled: 0 days'"  ) # -RegType DWORD

$RegistryAuditFile = ('D:\Apps\CISHardening_Registry ' + (Get-Date -Format ('yyyy-MM-dd HH-mm-ss')) + '.csv')
$AuditPolicyFile = ('D:\Apps\CISHardening_AuditPol ' + (Get-Date -Format ('yyyy-MM-dd HH-mm-ss')) + '.csv')

$SetItems | Select-Object CIS, Path, Name, Value, CorrectValue, RegType, Correct | Out-GridView
$SetItems | Select-Object CIS, Path, Name, Value, CorrectValue, RegType, Correct | Export-Csv -Path $RegistryAuditFile -Encoding ASCII -Delimiter ',' -NoTypeInformation -Force
Write-Host ("Registry Policies exported to: " + $RegistryAuditFile)

$AuditPolicies | Select-Object CIS, SubCategory, Value, CorrectValue, Correct | Out-GridView
$AuditPolicies | Select-Object CIS, SubCategory, Value, CorrectValue, Correct | Export-Csv -Path $AuditPolicyFile -Encoding ASCII -Delimiter ',' -NoTypeInformation -Force
Write-Host ("Audit Policies exported to: " + $AuditPolicyFile)