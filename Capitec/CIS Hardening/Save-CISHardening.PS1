$ErrorActionPreference = 'Stop'
Function Get-Registry {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $Path, `
        [Parameter(Mandatory=$True, Position = 2)]
        [String] $Name, `
        [Parameter(Mandatory=$True, Position = 3)]
        [String] $CIS
    )

    Try {
        $Item = Get-ItemProperty -Path $Path -Name $Name
        $RegType = (get-item $Path).GetValueKind($Name)
        $ReturnValue = (New-Object -TypeName PSObject -Property @{
            Path = $Path
            Name = $Name
            Value = $Item.$Name
            RegType = $RegType
            CIS = $CIS
        })
    }
    Catch {
        $ReturnValue = (New-Object -TypeName PSObject -Property @{
            Path = $Path
            Name = $Name
            Value = "Does not exist"
            RegType = "Does not exist"
            CIS = $CIS
        })
    }
    Return $ReturnValue
}
Function Get-Values {
    $DefaultValues = @()
    $AuditPolicies = @()
    # 2.3.1.1 (L1) Ensure 'Accounts: Block Microsoft accounts' is set to 'Users can't add or log on with Microsoft accounts' (Automated)
    #Write-Host "2.3.1.1 (L1) Ensure 'Accounts: Block Microsoft accounts' is set to 'Users can't add or log on with Microsoft accounts' (Automated)"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'NoConnectedUser' -CIS "2.3.1.1 (L1) Ensure 'Accounts: Block Microsoft accounts' is set to 'Users can't add or log on with Microsoft accounts' (Automated)") # 3 -RegType DWord 

    # 2.3.4.1. (L1) Ensure 'Devices: Allowed to format and eject removable media' is set to 'Administrators'
    #Write-Host "2.3.4.1. (L1) Ensure 'Devices: Allowed to format and eject removable media' is set to 'Administrators'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers' -Name 'AddPrinterDrivers' -CIS "2.3.4.1. (L1) Ensure 'Devices: Allowed to format and eject removable media' is set to 'Administrators'") # 1 -RegType DWORD

    # 2.3.7.2. (L1) Ensure 'Interactive logon: Don't display last signed-in' is set to 'Enabled'
    #Write-Host "2.3.7.2. (L1) Ensure 'Interactive logon: Don't display last signed-in' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'DontDisplayLastUserName' -CIS "2.3.7.2. (L1) Ensure 'Interactive logon: Don't display last signed-in' is set to 'Enabled'") # 1 -RegType DWORD

    # 2.3.7.8 (L1) Ensure 'Interactive logon: Require Domain Controller Authentication to unlock workstation' is set to 'Enabled' (MS only) (Automated)
    #Write-Host "2.3.7.8 (L1) Ensure 'Interactive logon: Require Domain Controller Authentication to unlock workstation' is set to 'Enabled' (MS only) (Automated)"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'ForceUnlockLogon' -CIS "2.3.7.8 (L1) Ensure 'Interactive logon: Require Domain Controller Authentication to unlock workstation' is set to 'Enabled' (MS only) (Automated)") #-RegValue 1 -RegType DWORD

    # 2.3.9.3. (L1) Ensure 'Microsoft network server: Digitally sign communications (if client agrees)' is set to 'Enabled'
    #Write-Host "2.3.9.3. (L1) Ensure 'Microsoft network server: Digitally sign communications (if client agrees)' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters' -Name 'EnableSecuritySignature' -CIS "2.3.9.3. (L1) Ensure 'Microsoft network server: Digitally sign communications (if client agrees)' is set to 'Enabled'") # 1 -RegType DWORD

    # 2.3.9.5. (L1) Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher (MS only)
    #Write-Host "2.3.9.5. (L1) Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher (MS only)"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters' -Name 'SMBServerNameHardeningLevel' -CIS "2.3.9.5. (L1) Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher (MS only)") # 1 -RegType DWORD

    # 2.3.10.12. (L1) Ensure 'Network access: Shares that can be accessed anonymously' is set to 'None'
    #Write-Host "2.3.10.12. (L1) Ensure 'Network access: Shares that can be accessed anonymously' is set to 'None'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters' -Name 'NullSessionShares' -CIS "2.3.10.12. (L1) Ensure 'Network access: Shares that can be accessed anonymously' is set to 'None'") # '' -RegType MultiString

    # 2.3.11.1. (L1) Ensure 'Network security: Allow Local System to use computer identity for NTLM' is set to 'Enabled'
    #Write-Host "2.3.11.1. (L1) Ensure 'Network security: Allow Local System to use computer identity for NTLM' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'UseMachineId' -CIS "2.3.11.1. (L1) Ensure 'Network security: Allow Local System to use computer identity for NTLM' is set to 'Enabled'") # 1 -RegType DWORD

    # 2.3.11.3. (L1) Ensure 'Network Security: Allow PKU2U authentication requests to this computer to use online identities' is set to 'Disabled'
    #Write-Host "2.3.11.3. (L1) Ensure 'Network Security: Allow PKU2U authentication requests to this computer to use online identities' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\pku2u' -Name 'AllowOnlineID' -CIS "2.3.11.3. (L1) Ensure 'Network Security: Allow PKU2U authentication requests to this computer to use online identities' is set to 'Disabled'") # 0 -RegType DWORD

    # 2.3.11.4. (L1) Ensure 'Network security: Configure encryption types allowed for Kerberos' is set to 'AES128_HMAC_SHA1, AES256_HMAC_SHA1, Future encryption types'
    #Write-Host "2.3.11.4. (L1) Ensure 'Network security: Configure encryption types allowed for Kerberos' is set to 'AES128_HMAC_SHA1, AES256_HMAC_SHA1, Future encryption types'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters' -Name 'SupportedEncryptionTypes' -CIS "2.3.11.4. (L1) Ensure 'Network security: Configure encryption types allowed for Kerberos' is set to 'AES128_HMAC_SHA1, AES256_HMAC_SHA1, Future encryption types'") # 2147483640 -RegType DWORD

    # 9.1.1. (L1) Ensure 'Windows Firewall: Domain: Firewall state' is set to 'On (recommended)'
    #Write-Host "9.1.1. (L1) Ensure 'Windows Firewall: Domain: Firewall state' is set to 'On (recommended)'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile' -Name 'EnableFirewall' -CIS "9.1.1. (L1) Ensure 'Windows Firewall: Domain: Firewall state' is set to 'On (recommended)'") # 1 -RegType DWORD

    # 9.1.2. (L1) Ensure 'Windows Firewall: Domain: Inbound connections' is set to 'Block (default)'
    #Write-Host "9.1.2. (L1) Ensure 'Windows Firewall: Domain: Inbound connections' is set to 'Block (default)'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile' -Name 'DefaultInboundAction' -CIS "9.1.2. (L1) Ensure 'Windows Firewall: Domain: Inbound connections' is set to 'Block (default)'") # 1 -RegType DWORD

    # 9.1.3. (L1) Ensure 'Windows Firewall: Domain: Outbound connections' is set to 'Allow (default)'
    #Write-Host "9.1.3. (L1) Ensure 'Windows Firewall: Domain: Outbound connections' is set to 'Allow (default)'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile' -Name 'DefaultOutboundAction' -CIS "9.1.3. (L1) Ensure 'Windows Firewall: Domain: Outbound connections' is set to 'Allow (default)'") # 1 -RegType DWORD

    # 9.1.4. (L1) Ensure 'Windows Firewall: Domain: Settings: Display a notification' is set to 'No'
    #Write-Host "9.1.4. (L1) Ensure 'Windows Firewall: Domain: Settings: Display a notification' is set to 'No'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile' -Name 'DisableNotifications' -CIS "9.1.4. (L1) Ensure 'Windows Firewall: Domain: Settings: Display a notification' is set to 'No'") # 1 -RegType DWORD

    # 9.1.5. (L1) Ensure 'Windows Firewall: Domain: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\domainfw.log'
    #Write-Host "9.1.5. (L1) Ensure 'Windows Firewall: Domain: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\domainfw.log'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging' -Name 'LogFilePath' -CIS  "9.1.5. (L1) Ensure 'Windows Firewall: Domain: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\domainfw.log'") # '%SystemRoot%\System32\logfiles\firewall\domainfw.log' -RegType String

    # 9.1.6. (L1) Ensure 'Windows Firewall: Domain: Logging: Size limit (KB)' is set to '16,384 KB or greater'
    #Write-Host "9.1.6. (L1) Ensure 'Windows Firewall: Domain: Logging: Size limit (KB)' is set to '16,384 KB or greater'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging' -Name 'LogFileSize' -CIS "9.1.6. (L1) Ensure 'Windows Firewall: Domain: Logging: Size limit (KB)' is set to '16,384 KB or greater'") # 16384 -RegType DWORD

    # 9.1.7. (L1) Ensure 'Windows Firewall: Domain: Logging: Log dropped packets' is set to 'Yes'
    #Write-Host "9.1.7. (L1) Ensure 'Windows Firewall: Domain: Logging: Log dropped packets' is set to 'Yes'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging' -Name 'LogDroppedPackets' -CIS "9.1.7. (L1) Ensure 'Windows Firewall: Domain: Logging: Log dropped packets' is set to 'Yes'") # 1 -RegType DWORD

    # 9.1.8. (L1) Ensure 'Windows Firewall: Domain: Logging: Log successful connections' is set to 'Yes'
    #Write-Host "9.1.8. (L1) Ensure 'Windows Firewall: Domain: Logging: Log successful connections' is set to 'Yes'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging' -Name 'LogSuccessfulConnections' -CIS "9.1.8. (L1) Ensure 'Windows Firewall: Domain: Logging: Log successful connections' is set to 'Yes'") # 1 -RegType DWORD

    # 9.2.1. (L1) Ensure 'Windows Firewall: Private: Firewall state' is set to 'On (recommended)'
    #Write-Host "9.2.1. (L1) Ensure 'Windows Firewall: Private: Firewall state' is set to 'On (recommended)'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile' -Name 'EnableFirewall' -CIS "9.2.1. (L1) Ensure 'Windows Firewall: Private: Firewall state' is set to 'On (recommended)'") # 1 -RegType DWORD

    # 9.2.2. (L1) Ensure 'Windows Firewall: Private: Inbound connections' is set to 'Block (default)'
    #Write-Host "9.2.2. (L1) Ensure 'Windows Firewall: Private: Inbound connections' is set to 'Block (default)'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile' -Name 'DefaultInboundAction' -CIS "9.2.2. (L1) Ensure 'Windows Firewall: Private: Inbound connections' is set to 'Block (default)'") # 1 -RegType DWORD

    # 9.2.3. (L1) Ensure 'Windows Firewall: Private: Outbound connections' is set to 'Allow (default)'
    #Write-Host "9.2.3. (L1) Ensure 'Windows Firewall: Private: Outbound connections' is set to 'Allow (default)'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile' -Name 'DisableNotifications' -CIS "9.2.3. (L1) Ensure 'Windows Firewall: Private: Outbound connections' is set to 'Allow (default)'") # 1 -RegType DWORD

    # 9.2.4. (L1) Ensure 'Windows Firewall: Private: Settings: Display a notification' is set to 'No'
    #Write-Host "9.2.4. (L1) Ensure 'Windows Firewall: Private: Settings: Display a notification' is set to 'No'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile' -Name 'DisableNotifications' -CIS  "9.2.4. (L1) Ensure 'Windows Firewall: Private: Settings: Display a notification' is set to 'No'") # 1 -RegType DWORD

    # 9.2.5. (L1) Ensure 'Windows Firewall: Private: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\privatefw.log'
    #Write-Host "9.2.5. (L1) Ensure 'Windows Firewall: Private: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\privatefw.log'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging' -Name 'LogFilePath' -CIS "9.2.5. (L1) Ensure 'Windows Firewall: Private: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\privatefw.log'") # '%SystemRoot%\System32\logfiles\firewall\privatefw.log' -RegType String

    # 9.2.6. (L1) Ensure 'Windows Firewall: Private: Logging: Size limit (KB)' is set to '16,384 KB or greater'
    #Write-Host "9.2.6. (L1) Ensure 'Windows Firewall: Private: Logging: Size limit (KB)' is set to '16,384 KB or greater'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging' -Name 'LogFileSize' -CIS "9.2.6. (L1) Ensure 'Windows Firewall: Private: Logging: Size limit (KB)' is set to '16,384 KB or greater'") # 16384 -RegType DWORD

    # 9.2.7. (L1) Ensure 'Windows Firewall: Private: Logging: Log dropped packets' is set to 'Yes'
    #Write-Host "9.2.7. (L1) Ensure 'Windows Firewall: Private: Logging: Log dropped packets' is set to 'Yes'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging' -Name 'LogDroppedPackets' -CIS "9.2.7. (L1) Ensure 'Windows Firewall: Private: Logging: Log dropped packets' is set to 'Yes'") # 1 -RegType DWORD

    # 9.2.8. (L1) Ensure 'Windows Firewall: Private: Logging: Log successful connections' is set to 'Yes'
    #Write-Host "9.2.8. (L1) Ensure 'Windows Firewall: Private: Logging: Log successful connections' is set to 'Yes'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging' -Name 'LogSuccessfulConnections' -CIS "9.2.8. (L1) Ensure 'Windows Firewall: Private: Logging: Log successful connections' is set to 'Yes'") # 1 -RegType DWORD

    # 9.3.1. (L1) Ensure 'Windows Firewall: Public: Firewall state' is set to 'On (recommended)'
    #Write-Host "9.3.1. (L1) Ensure 'Windows Firewall: Public: Firewall state' is set to 'On (recommended)'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging' -Name 'LogDroppedPackets' -CIS "9.3.1. (L1) Ensure 'Windows Firewall: Public: Firewall state' is set to 'On (recommended)'") # 1 -RegType DWORD

    # 9.3.2. (L1) Ensure 'Windows Firewall: Public: Inbound connections' is set to 'Block (default)'
    #Write-Host "9.3.2. (L1) Ensure 'Windows Firewall: Public: Inbound connections' is set to 'Block (default)'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile' -Name 'DefaultInboundAction' -CIS "9.3.2. (L1) Ensure 'Windows Firewall: Public: Inbound connections' is set to 'Block (default)'") # 1 -RegType DWORD

    # 9.3.3. (L1) Ensure 'Windows Firewall: Public: Outbound connections' is set to 'Allow (default)'
    #Write-Host "9.3.3. (L1) Ensure 'Windows Firewall: Public: Outbound connections' is set to 'Allow (default)'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile' -Name 'DisableNotifications' -CIS "9.3.3. (L1) Ensure 'Windows Firewall: Public: Outbound connections' is set to 'Allow (default)'") # 1 -RegType DWORD

    # 9.3.4. (L1) Ensure 'Windows Firewall: Public: Settings: Display a notification' is set to 'No'
    #Write-Host "9.3.4. (L1) Ensure 'Windows Firewall: Public: Settings: Display a notification' is set to 'No'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile' -Name 'DisableNotifications' -CIS "9.3.4. (L1) Ensure 'Windows Firewall: Public: Settings: Display a notification' is set to 'No'") # 1 -RegType DWORD

    # 9.3.5. (L1) Ensure 'Windows Firewall: Public: Settings: Apply local firewall rules' is set to 'No'
    #Write-Host "9.3.5. (L1) Ensure 'Windows Firewall: Public: Settings: Apply local firewall rules' is set to 'No'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile' -Name 'AllowLocalPolicyMerge' -CIS "9.3.5. (L1) Ensure 'Windows Firewall: Public: Settings: Apply local firewall rules' is set to 'No'") # 0 -RegType DWORD

    # 9.3.6. (L1) Ensure 'Windows Firewall: Public: Settings: Apply local connection security rules' is set to 'No'
    #Write-Host "9.3.6. (L1) Ensure 'Windows Firewall: Public: Settings: Apply local connection security rules' is set to 'No'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile' -Name 'AllowLocalIPsecPolicyMerge' -CIS "9.3.6. (L1) Ensure 'Windows Firewall: Public: Settings: Apply local connection security rules' is set to 'No'") # 0 -RegType DWORD

    # 9.3.7. (L1) Ensure 'Windows Firewall: Public: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\publicfw.log'
    #Write-Host "9.3.7. (L1) Ensure 'Windows Firewall: Public: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\publicfw.log'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging' -Name 'LogFilePath' -CIS "9.3.7. (L1) Ensure 'Windows Firewall: Public: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\publicfw.log'") # '%SystemRoot%\System32\logfiles\firewall\publicfw.log' -RegType String

    # 9.3.8. (L1) Ensure 'Windows Firewall: Public: Logging: Size limit (KB)' is set to '16,384 KB or greater'
    #Write-Host "9.3.8. (L1) Ensure 'Windows Firewall: Public: Logging: Size limit (KB)' is set to '16,384 KB or greater'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging' -Name 'LogFileSize' -CIS "9.3.8. (L1) Ensure 'Windows Firewall: Public: Logging: Size limit (KB)' is set to '16,384 KB or greater'") # 16384 -RegType DWORD

    # 9.3.9. (L1) Ensure 'Windows Firewall: Public: Logging: Log dropped packets' is set to 'Yes'
    #Write-Host "9.3.9. (L1) Ensure 'Windows Firewall: Public: Logging: Log dropped packets' is set to 'Yes'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging' -Name 'LogDroppedPackets' -CIS "9.3.9. (L1) Ensure 'Windows Firewall: Public: Logging: Log dropped packets' is set to 'Yes'") # 1 -RegType DWORD

    # 9.3.10. (L1) Ensure 'Windows Firewall: Public: Logging: Log successful connections' is set to 'Yes'
    #Write-Host "9.3.10. (L1) Ensure 'Windows Firewall: Public: Logging: Log successful connections' is set to 'Yes'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging' -Name 'LogSuccessfulConnections' -CIS "9.3.10. (L1) Ensure 'Windows Firewall: Public: Logging: Log successful connections' is set to 'Yes'") # 1 -RegType DWORD

    # 17.2.1. (L1) Ensure 'Audit Application Group Management' is set to 'Success and Failure'
    #Write-Host "17.2.1. (L1) Ensure 'Audit Application Group Management' is set to 'Success and Failure'"
    $AuditPolicy = auditpol /get /subcategory:"Application Group Management" #/success:enable /failure:enable | Out-Null
    $AuditPolicies += ,(New-Object -TypeName PSObject -Property @{
        SubCategory = ($AuditPolicy[4] -split '  ')[1]
        Value = ($AuditPolicy[4] -split '  ')[-1]
        CIS = "17.2.1. (L1) Ensure 'Audit Application Group Management' is set to 'Success and Failure'"
    })

    # 17.5.3. (L1) Ensure 'Audit Logoff' is set to include 'Success'
    #Write-Host "17.5.3. (L1) Ensure 'Audit Logoff' is set to include 'Success'"
    $AuditPolicy = auditpol /get /subcategory:"Logoff" #/success:enable | Out-Null
    $AuditPolicies += ,(New-Object -TypeName PSObject -Property @{
        SubCategory = ($AuditPolicy[4] -split '  ')[1]
        Value = ($AuditPolicy[4] -split '  ')[-1]
        CIS = "17.5.3. (L1) Ensure 'Audit Logoff' is set to include 'Success'"
    })

    # 17.7.3. (L1) Ensure 'Audit Authorization Policy Change' is set to include 'Success'
    #Write-Host "17.7.3. (L1) Ensure 'Audit Authorization Policy Change' is set to include 'Success'"
    $AuditPolicy = auditpol /get /subcategory:"Authorization Policy Change" #/success:enable | Out-Null
    $AuditPolicies += ,(New-Object -TypeName PSObject -Property @{
        SubCategory = ($AuditPolicy[4] -split '  ')[1]
        Value = ($AuditPolicy[4] -split ' ')[-1]
        CIS = "17.7.3. (L1) Ensure 'Audit Authorization Policy Change' is set to include 'Success'"
    })

    # 17.9.1. (L1) Ensure 'Audit IPsec Driver' is set to 'Success and Failure'
    #Write-Host "17.9.1. (L1) Ensure 'Audit IPsec Driver' is set to 'Success and Failure'"
    $AuditPolicy = auditpol /get /subcategory:"IPsec Driver" #/success:enable /failure:enable | Out-Null
    $AuditPolicies += ,(New-Object -TypeName PSObject -Property @{
        SubCategory = ($AuditPolicy[4] -split '  ')[1]
        Value = ($AuditPolicy[4] -split '  ')[-1]
        CIS = "17.9.1. (L1) Ensure 'Audit IPsec Driver' is set to 'Success and Failure'"
    })

    # 18.1.2.2. (L1) Ensure 'Allow users to enable online speech recognition services' is set to 'Disabled'
    #Write-Host "18.1.2.2. (L1) Ensure 'Allow users to enable online speech recognition services' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization' -Name 'AllowInputPersonalization' -CIS "18.1.2.2. (L1) Ensure 'Allow users to enable online speech recognition services' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.3.2. (L1) Ensure 'Do not allow password expiration time longer than required by policy' is set to 'Enabled' (MS only)
    #Write-Host "18.3.2. (L1) Ensure 'Do not allow password expiration time longer than required by policy' is set to 'Enabled' (MS only)"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\LAPS' -Name 'PwdExpirationProtectionEnabled' -CIS "18.3.2. (L1) Ensure 'Do not allow password expiration time longer than required by policy' is set to 'Enabled' (MS only)") # 1 -RegType DWORD

    # 18.3.4. (L1) Ensure 'Password Settings: Password Complexity' is set to 'Enabled: Large letters + small letters + numbers + special characters' (MS only)
    #Write-Host "18.3.4. (L1) Ensure 'Password Settings: Password Complexity' is set to 'Enabled: Large letters + small letters + numbers + special characters' (MS only)"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\LAPS' -Name 'PasswordComplexity' -CIS "18.3.4. (L1) Ensure 'Password Settings: Password Complexity' is set to 'Enabled: Large letters + small letters + numbers + special characters' (MS only)") # 4 -RegType DWORD

    # 18.3.5. (L1) Ensure 'Password Settings: Password Length' is set to 'Enabled: 15 or more' (MS only)
    #Write-Host "18.3.5. (L1) Ensure 'Password Settings: Password Length' is set to 'Enabled: 15 or more' (MS only)"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\LAPS' -Name 'PasswordLength' -CIS "18.3.5. (L1) Ensure 'Password Settings: Password Length' is set to 'Enabled: 15 or more' (MS only)") # 15 -RegType DWORD

    # 18.3.6. (L1) Ensure 'Password Settings: Password Age (Days)' is set to 'Enabled: 30 or fewer' (MS only)
    #Write-Host "18.3.6. (L1) Ensure 'Password Settings: Password Age (Days)' is set to 'Enabled: 30 or fewer' (MS only)"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\LAPS' -Name 'PasswordAgeDays' -CIS "18.3.6. (L1) Ensure 'Password Settings: Password Age (Days)' is set to 'Enabled: 30 or fewer' (MS only)") # 30 -RegType DWORD

    # 18.4.2. (L1) Ensure 'Configure RPC packet level privacy setting for incoming connections' is set to 'Enabled'
    #Write-Host "18.4.2. (L1) Ensure 'Configure RPC packet level privacy setting for incoming connections' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Print' -Name 'RpcAuthnLevelPrivacyEnabled' -CIS "18.4.2. (L1) Ensure 'Configure RPC packet level privacy setting for incoming connections' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.5.1. (L1) Ensure 'MSS: (AutoAdminLogon) Enable Automatic Logon (not recommended)' is set to 'Disabled'
    #Write-Host "18.5.1. (L1) Ensure 'MSS: (AutoAdminLogon) Enable Automatic Logon (not recommended)' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'AutoAdminLogon' -CIS "18.5.1. (L1) Ensure 'MSS: (AutoAdminLogon) Enable Automatic Logon (not recommended)' is set to 'Disabled'") # 0 -RegType String

    # 18.5.8. (L1) Ensure 'MSS: (SafeDllSearchMode) Enable Safe DLL search mode (recommended)' is set to 'Enabled'
    #Write-Host "18.5.8. (L1) Ensure 'MSS: (SafeDllSearchMode) Enable Safe DLL search mode (recommended)' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'SafeDllSearchMode' -CIS "18.5.8. (L1) Ensure 'MSS: (SafeDllSearchMode) Enable Safe DLL search mode (recommended)' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.5.9. (L1) Ensure 'MSS: (ScreenSaverGracePeriod) The time in seconds before the screen saver grace period expires (0 recommended)' is set to 'Enabled: 5 or fewer seconds'
    #Write-Host "18.5.9. (L1) Ensure 'MSS: (ScreenSaverGracePeriod) The time in seconds before the screen saver grace period expires (0 recommended)' is set to 'Enabled: 5 or fewer seconds'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'ScreenSaverGracePeriod' -CIS "18.5.9. (L1) Ensure 'MSS: (ScreenSaverGracePeriod) The time in seconds before the screen saver grace period expires (0 recommended)' is set to 'Enabled: 5 or fewer seconds'") # 5 -RegType String

    # 18.5.12. (L1) Ensure 'MSS: (WarningLevel) Percentage threshold for the security event log at which the system will generate a warning' is set to 'Enabled: 90% or less'
    #Write-Host "18.5.12. (L1) Ensure 'MSS: (WarningLevel) Percentage threshold for the security event log at which the system will generate a warning' is set to 'Enabled: 90% or less'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Eventlog\Security' -Name 'WarningLevel' -CIS "18.5.12. (L1) Ensure 'MSS: (WarningLevel) Percentage threshold for the security event log at which the system will generate a warning' is set to 'Enabled: 90% or less'") # 90 -RegType DWORD

    # 18.6.4.2. (L1) Ensure 'Configure NetBIOS settings' is set to 'Enabled: Disable NetBIOS name resolution on public networks'
    #Write-Host "18.6.4.2. (L1) Ensure 'Configure NetBIOS settings' is set to 'Enabled: Disable NetBIOS name resolution on public networks'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient' -Name 'EnableNetbios' -CIS "18.6.4.2. (L1) Ensure 'Configure NetBIOS settings' is set to 'Enabled: Disable NetBIOS name resolution on public networks'") # 0 -RegType DWORD

    # 18.6.11.2. (L1) Ensure 'Prohibit installation and configuration of Network Bridge on your DNS domain network' is set to 'Enabled'
    #Write-Host "18.6.11.2. (L1) Ensure 'Prohibit installation and configuration of Network Bridge on your DNS domain network' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections' -Name 'NC_AllowNetBridge_NLA' -CIS "18.6.11.2. (L1) Ensure 'Prohibit installation and configuration of Network Bridge on your DNS domain network' is set to 'Enabled'") # 0 -RegType DWORD

    # 18.6.11.3. (L1) Ensure 'Prohibit use of Internet Connection Sharing on your DNS domain network' is set to 'Enabled'
    #Write-Host "18.6.11.3. (L1) Ensure 'Prohibit use of Internet Connection Sharing on your DNS domain network' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections' -Name 'NC_ShowSharedAccessUI' -CIS "18.6.11.3. (L1) Ensure 'Prohibit use of Internet Connection Sharing on your DNS domain network' is set to 'Enabled'") # 0 -RegType DWORD

    # 18.6.11.4. (L1) Ensure 'Require domain users to elevate when setting a network's location' is set to 'Enabled'
    #Write-Host "18.6.11.4. (L1) Ensure 'Require domain users to elevate when setting a network's location' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections' -Name 'NC_StdDomainUserSetLocation' -CIS "18.6.11.4. (L1) Ensure 'Require domain users to elevate when setting a network's location' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.6.21.1. (L1) Ensure 'Minimize the number of simultaneous connections to the Internet or a Windows Domain' is set to 'Enabled: 3 = Prevent Wi-Fi when on Ethernet'
    #Write-Host "18.6.21.1. (L1) Ensure 'Minimize the number of simultaneous connections to the Internet or a Windows Domain' is set to 'Enabled: 3 = Prevent Wi-Fi when on Ethernet'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy' -Name 'fMinimizeConnections' -CIS "18.6.21.1. (L1) Ensure 'Minimize the number of simultaneous connections to the Internet or a Windows Domain' is set to 'Enabled: 3 = Prevent Wi-Fi when on Ethernet'") # 3 -RegType DWORD

    # 18.7.2. (L1) Ensure 'Configure Redirection Guard' is set to 'Enabled: Redirection Guard Enabled'
    #Write-Host "18.7.2. (L1) Ensure 'Configure Redirection Guard' is set to 'Enabled: Redirection Guard Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers' -Name 'RedirectionguardPolicy' -CIS "18.7.2. (L1) Ensure 'Configure Redirection Guard' is set to 'Enabled: Redirection Guard Enabled'") # 1 -RegType DWORD

    # 18.7.7. (L1) Ensure 'Configure RPC over TCP port' is set to 'Enabled: 0'
    #Write-Host "18.7.7. (L1) Ensure 'Configure RPC over TCP port' is set to 'Enabled: 0'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC' -Name 'RpcProtocols' -CIS "18.7.7. (L1) Ensure 'Configure RPC over TCP port' is set to 'Enabled: 0'") # 5 -RegType DWORD

    # 18.7.9. (L1) Ensure 'Manage processing of Queue-specific files' is set to 'Enabled: Limit Queue-specific files to Color profiles'
    #Write-Host "18.7.9. (L1) Ensure 'Manage processing of Queue-specific files' is set to 'Enabled: Limit Queue-specific files to Color profiles'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers' -Name 'CopyFilesPolicy' -CIS "18.7.9. (L1) Ensure 'Manage processing of Queue-specific files' is set to 'Enabled: Limit Queue-specific files to Color profiles'") # 1 -RegType DWORD

    # 18.9.3.1. (L1) Ensure 'Include command line in process creation events' is set to 'Enabled'
    #Write-Host "18.9.3.1. (L1) Ensure 'Include command line in process creation events' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit' -Name 'ProcessCreationIncludeCmdLine_Enabled' -CIS "18.9.3.1. (L1) Ensure 'Include command line in process creation events' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.9.7.2. (L1) Ensure 'Prevent device metadata retrieval from the Internet' is set to 'Enabled'
    #Write-Host "18.9.7.2. (L1) Ensure 'Prevent device metadata retrieval from the Internet' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata' -Name 'PreventDeviceMetadataFromNetwork' -CIS "18.9.7.2. (L1) Ensure 'Prevent device metadata retrieval from the Internet' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.9.19.5. (L1) Ensure 'Turn off background refresh of Group Policy' is set to 'Disabled'
    #Write-Host "18.9.19.5. (L1) Ensure 'Turn off background refresh of Group Policy' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Group Policy\{827D319E-6EAC-11D2-A4EA-00C04F79F83A}' -Name 'NoGPOListChanges' -CIS "18.9.19.5. (L1) Ensure 'Turn off background refresh of Group Policy' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.9.20.1.1. (L1) Ensure 'Turn off downloading of print drivers over HTTP' is set to 'Enabled'
    #Write-Host "18.9.20.1.1. (L1) Ensure 'Turn off downloading of print drivers over HTTP' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers' -Name 'DisableWebPnPDownload' -CIS "18.9.20.1.1. (L1) Ensure 'Turn off downloading of print drivers over HTTP' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.9.20.1.5. (L1) Ensure 'Turn off Internet download for Web publishing and online ordering wizards' is set to 'Enabled'
    #Write-Host "18.9.20.1.5. (L1) Ensure 'Turn off Internet download for Web publishing and online ordering wizards' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoWebServices' -CIS "18.9.20.1.5. (L1) Ensure 'Turn off Internet download for Web publishing and online ordering wizards' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.9.27.1. (L1) Ensure 'Block user from showing account details on sign-in' is set to 'Enabled'
    #Write-Host "18.9.27.1. (L1) Ensure 'Block user from showing account details on sign-in' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Control Panel\International' -Name 'BlockUserInputMethodsForSignIn' -CIS "18.9.27.1. (L1) Ensure 'Block user from showing account details on sign-in' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.9.27.2. (L1) Ensure 'Do not display network selection UI' is set to 'Enabled'
    #Write-Host "18.9.27.2. (L1) Ensure 'Do not display network selection UI' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'DontDisplayNetworkSelectionUI' -CIS "18.9.27.2. (L1) Ensure 'Do not display network selection UI' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.9.27.3. (L1) Ensure 'Do not enumerate connected users on domain-joined computers' is set to 'Enabled'
    #Write-Host "18.9.27.3. (L1) Ensure 'Do not enumerate connected users on domain-joined computers' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'DontEnumerateConnectedUsers' -CIS "18.9.27.3. (L1) Ensure 'Do not enumerate connected users on domain-joined computers' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.9.27.5. (L1) Ensure 'Turn off app notifications on the lock screen' is set to 'Enabled'
    #Write-Host "18.9.27.5. (L1) Ensure 'Turn off app notifications on the lock screen' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'DisableLockScreenAppNotifications' -CIS "18.9.27.5. (L1) Ensure 'Turn off app notifications on the lock screen' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.9.27.6. (L1) Ensure 'Turn off picture password sign-in' is set to 'Enabled'
    #Write-Host "18.9.27.6. (L1) Ensure 'Turn off picture password sign-in' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'BlockDomainPicturePassword' -CIS "18.9.27.6. (L1) Ensure 'Turn off picture password sign-in' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.9.27.7. (L1) Ensure 'Turn on convenience PIN sign-in' is set to 'Disabled'
    #Write-Host "18.9.27.7. (L1) Ensure 'Turn on convenience PIN sign-in' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'AllowDomainPINLogon' -CIS "18.9.27.7. (L1) Ensure 'Turn on convenience PIN sign-in' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.9.32.6.3. (L1) Ensure 'Require a password when a computer wakes (on battery)' is set to 'Enabled'
    #Write-Host "18.9.32.6.3. (L1) Ensure 'Require a password when a computer wakes (on battery)' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51' -Name 'DCSettingIndex' -CIS "18.9.32.6.3. (L1) Ensure 'Require a password when a computer wakes (on battery)' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.9.32.6.4. (L1) Ensure 'Require a password when a computer wakes (plugged in)' is set to 'Enabled'
    #Write-Host "18.9.32.6.4. (L1) Ensure 'Require a password when a computer wakes (plugged in)' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51' -Name 'ACSettingIndex' -CIS "18.9.32.6.4. (L1) Ensure 'Require a password when a computer wakes (plugged in)' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.9.34.1. (L1) Ensure 'Configure Offer Remote Assistance' is set to 'Disabled'
    #Write-Host "18.9.34.1. (L1) Ensure 'Configure Offer Remote Assistance' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'fAllowUnsolicited' -CIS "18.9.34.1. (L1) Ensure 'Configure Offer Remote Assistance' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.9.34.2. (L1) Ensure 'Configure Solicited Remote Assistance' is set to 'Disabled'
    #Write-Host "18.9.34.2. (L1) Ensure 'Configure Solicited Remote Assistance' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'fAllowToGetHelp' -CIS "18.9.34.2. (L1) Ensure 'Configure Solicited Remote Assistance' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.9.35.1. (L1) Ensure 'Enable RPC Endpoint Mapper Client Authentication' is set to 'Enabled' (MS only)
    #Write-Host "18.9.35.1. (L1) Ensure 'Enable RPC Endpoint Mapper Client Authentication' is set to 'Enabled' (MS only)"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Rpc' -Name 'EnableAuthEpResolution' -CIS "18.9.35.1. (L1) Ensure 'Enable RPC Endpoint Mapper Client Authentication' is set to 'Enabled' (MS only)") # 1 -RegType DWORD

    # 18.10.5.1. (L1) Ensure 'Allow Microsoft accounts to be optional' is set to 'Enabled'
    #Write-Host "18.10.5.1. (L1) Ensure 'Allow Microsoft accounts to be optional' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'MSAOptional' -CIS "18.10.5.1. (L1) Ensure 'Allow Microsoft accounts to be optional' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.10.12.1. (L1) Ensure 'Turn off cloud consumer account state content' is set to 'Enabled'
    #Write-Host "18.10.12.1. (L1) Ensure 'Turn off cloud consumer account state content' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableConsumerAccountStateContent' -CIS "18.10.12.1. (L1) Ensure 'Turn off cloud consumer account state content' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.10.12.3. (L1) Ensure 'Turn off Microsoft consumer experiences' is set to 'Enabled'
    #Write-Host "18.10.12.3. (L1) Ensure 'Turn off Microsoft consumer experiences' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsConsumerFeatures' -CIS "18.10.12.3. (L1) Ensure 'Turn off Microsoft consumer experiences' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.10.13.1. (L1) Ensure 'Require pin for pairing' is set to 'Enabled: First Time' OR 'Enabled: Always'
    #Write-Host "18.10.13.1. (L1) Ensure 'Require pin for pairing' is set to 'Enabled: First Time' OR 'Enabled: Always'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Connect' -Name 'RequirePinForPairing' -CIS "18.10.13.1. (L1) Ensure 'Require pin for pairing' is set to 'Enabled: First Time' OR 'Enabled: Always'") # 1 -RegType DWORD

    # 18.10.14.1. (L1) Ensure 'Do not display the password reveal button' is set to 'Enabled'
    #Write-Host "18.10.14.1. (L1) Ensure 'Do not display the password reveal button' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredUI' -Name 'DisablePasswordReveal' -CIS "18.10.14.1. (L1) Ensure 'Do not display the password reveal button' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.10.14.2. (L1) Ensure 'Enumerate administrator accounts on elevation' is set to 'Disabled'
    #Write-Host "18.10.14.2. (L1) Ensure 'Enumerate administrator accounts on elevation' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\CredUI' -Name 'EnumerateAdministrators' -CIS "18.10.14.2. (L1) Ensure 'Enumerate administrator accounts on elevation' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.10.15.1. (L1) Ensure 'Allow Diagnostic Data' is set to 'Enabled: Diagnostic data off (not recommended)' or 'Enabled: Send required diagnostic data'
    #Write-Host "18.10.15.1. (L1) Ensure 'Allow Diagnostic Data' is set to 'Enabled: Diagnostic data off (not recommended)' or 'Enabled: Send required diagnostic data'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -CIS "18.10.15.1. (L1) Ensure 'Allow Diagnostic Data' is set to 'Enabled: Diagnostic data off (not recommended)' or 'Enabled: Send required diagnostic data'") # 1 -RegType DWORD

    # 18.10.15.3. (L1) Ensure 'Disable OneSettings Downloads' is set to 'Enabled'
    #Write-Host "18.10.15.3. (L1) Ensure 'Disable OneSettings Downloads' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'DisableOneSettingsDownloads' -CIS "18.10.15.3. (L1) Ensure 'Disable OneSettings Downloads' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.10.15.4. (L1) Ensure 'Do not show feedback notifications' is set to 'Enabled'
    #Write-Host "18.10.15.4. (L1) Ensure 'Do not show feedback notifications' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'DoNotShowFeedbackNotifications' -CIS "18.10.15.4. (L1) Ensure 'Do not show feedback notifications' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.10.15.5. (L1) Ensure 'Enable OneSettings Auditing' is set to 'Enabled'
    #Write-Host "18.10.15.5. (L1) Ensure 'Enable OneSettings Auditing' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'EnableOneSettingsAuditing' -CIS "18.10.15.5. (L1) Ensure 'Enable OneSettings Auditing' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.10.15.6. (L1) Ensure 'Limit Diagnostic Log Collection' is set to 'Enabled'
    #Write-Host "18.10.15.6. (L1) Ensure 'Limit Diagnostic Log Collection' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'LimitDiagnosticLogCollection' -CIS "18.10.15.6. (L1) Ensure 'Limit Diagnostic Log Collection' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.10.15.7. (L1) Ensure 'Limit Dump Collection' is set to 'Enabled'
    #Write-Host "18.10.15.7. (L1) Ensure 'Limit Dump Collection' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'LimitDumpCollection' -CIS "18.10.15.7. (L1) Ensure 'Limit Dump Collection' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.10.15.8. (L1) Ensure 'Toggle user control over Insider builds' is set to 'Disabled'
    #Write-Host "18.10.15.8. (L1) Ensure 'Toggle user control over Insider builds' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds' -Name 'AllowBuildPreview' -CIS "18.10.15.8. (L1) Ensure 'Toggle user control over Insider builds' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.10.17.1. (L1) Ensure 'Enable App Installer' is set to 'Disabled'
    #Write-Host "18.10.17.1. (L1) Ensure 'Enable App Installer' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppInstaller' -Name 'EnableAppInstaller' -CIS "18.10.17.1. (L1) Ensure 'Enable App Installer' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.10.17.2. (L1) Ensure 'Enable App Installer Experimental Features' is set to 'Disabled'
    #Write-Host "18.10.17.2. (L1) Ensure 'Enable App Installer Experimental Features' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppInstaller' -Name 'EnableExperimentalFeatures' -CIS "18.10.17.2. (L1) Ensure 'Enable App Installer Experimental Features' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.10.17.3. (L1) Ensure 'Enable App Installer Hash Override' is set to 'Disabled'
    #Write-Host "18.10.17.3. (L1) Ensure 'Enable App Installer Hash Override' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppInstaller' -Name 'EnableHashOverride' -CIS "18.10.17.3. (L1) Ensure 'Enable App Installer Hash Override' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.10.17.4. (L1) Ensure 'Enable App Installer ms-appinstaller protocol' is set to 'Disabled'
    #Write-Host "18.10.17.4. (L1) Ensure 'Enable App Installer ms-appinstaller protocol' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppInstaller' -Name 'EnableMSAppInstallerProtocol' -CIS "18.10.17.4. (L1) Ensure 'Enable App Installer ms-appinstaller protocol' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.10.29.2. (L1) Ensure 'Turn off Data Execution Prevention for Explorer' is set to 'Disabled'
    #Write-Host "18.10.29.2. (L1) Ensure 'Turn off Data Execution Prevention for Explorer' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'NoDataExecutionPrevention' -CIS "18.10.29.2. (L1) Ensure 'Turn off Data Execution Prevention for Explorer' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.10.29.3. (L1) Ensure 'Turn off heap termination on corruption' is set to 'Disabled'
    #Write-Host "18.10.29.3. (L1) Ensure 'Turn off heap termination on corruption' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'NoHeapTerminationOnCorruption' -CIS "18.10.29.3. (L1) Ensure 'Turn off heap termination on corruption' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.10.29.4. (L1) Ensure 'Turn off shell protocol protected mode' is set to 'Disabled'
    #Write-Host "18.10.29.4. (L1) Ensure 'Turn off shell protocol protected mode' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'PreXPSP2ShellProtocolBehavior' -CIS "18.10.29.4. (L1) Ensure 'Turn off shell protocol protected mode' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.10.42.1. (L1) Ensure 'Block all consumer Microsoft account user authentication' is set to 'Enabled'
    #Write-Host "18.10.42.1. (L1) Ensure 'Block all consumer Microsoft account user authentication' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftAccount' -Name 'DisableUserAuth' -CIS "18.10.42.1. (L1) Ensure 'Block all consumer Microsoft account user authentication' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.10.43.5.1. (L1) Ensure 'Configure local setting override for reporting to Microsoftr MAPS' is set to 'Disabled'
    #Write-Host "18.10.43.5.1. (L1) Ensure 'Configure local setting override for reporting to Microsoftr MAPS' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet' -Name 'LocalSettingOverrideSpynetReporting' -CIS "18.10.43.5.1. (L1) Ensure 'Configure local setting override for reporting to Microsoftr MAPS' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured
    #Write-Host "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name '26190899-1602-49e8-8b27-eb1d0a1ce869' -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured") # 1 -RegType String
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name '3b576869-a4ec-4529-8536-b80a7769e899' -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured") # 1 -RegType String
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name '56a863a9-875e-4185-98a7-b882c64b5ce5' -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured") # 1 -RegType String
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name '5beb7efe-fd9a-4556-801d-275e5ffc04cc' -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured") # 1 -RegType String
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name '75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84' -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured") # 1 -RegType String
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name '7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c' -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured") # 1 -RegType String
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name '92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b' -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured") # 1 -RegType String
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name '9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2' -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured") # 1 -RegType String
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name 'b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4' -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured") # 1 -RegType String
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name 'be9ba2d9-53ea-4cdc-84e5-9b1eeee46550' -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured") # 1 -RegType String
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name 'd3e037e1-3eb8-44c8-a917-57927947596d' -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured") # 1 -RegType String
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name 'd4f940ab-401b-4efc-aadc-ad5f3c50688a' -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured") # 1 -RegType String
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' -Name 'e6db77e5-3df2-4cf1-b95a-636979351e5b' -CIS "18.10.43.6.1.2. (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured") # 1 -RegType String

    # 18.10.43.10.3. (L1) Ensure 'Turn on behavior monitoring' is set to 'Enabled'
    #Write-Host "18.10.43.10.3. (L1) Ensure 'Turn on behavior monitoring' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection' -Name 'DisableBehaviorMonitoring' -CIS "18.10.43.10.3. (L1) Ensure 'Turn on behavior monitoring' is set to 'Enabled'") # 0 -RegType DWORD

    # 18.10.43.13.2. (L1) Ensure 'Turn on e-mail scanning' is set to 'Enabled' 
    #Write-Host "18.10.43.13.2. (L1) Ensure 'Turn on e-mail scanning' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan' -Name 'DisableEmailScanning' -CIS "18.10.43.13.2. (L1) Ensure 'Turn on e-mail scanning' is set to 'Enabled'") # 0 -RegType DWORD

    # 18.10.51.1. (L1) Ensure 'Prevent the usage of OneDrive for file storage' is set to 'Enabled'
    #Write-Host "18.10.51.1. (L1) Ensure 'Prevent the usage of OneDrive for file storage' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' -Name 'DisableFileSyncNGSC' -CIS "18.10.51.1. (L1) Ensure 'Prevent the usage of OneDrive for file storage' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.10.57.3.9.3. (L1) Ensure 'Require use of specific security layer for remote (RDP) connections' is set to 'Enabled: SSL'
    #Write-Host "18.10.57.3.9.3. (L1) Ensure 'Require use of specific security layer for remote (RDP) connections' is set to 'Enabled: SSL'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'SecurityLayer' -CIS "18.10.57.3.9.3. (L1) Ensure 'Require use of specific security layer for remote (RDP) connections' is set to 'Enabled: SSL'") # 2 -RegType DWORD

    # 18.10.57.3.9.4. (L1) Ensure 'Require user authentication for remote connections by using Network Level Authentication' is set to 'Enabled'
    #Write-Host "18.10.57.3.9.4. (L1) Ensure 'Require user authentication for remote connections by using Network Level Authentication' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'UserAuthentication' -CIS "18.10.57.3.9.4. (L1) Ensure 'Require user authentication for remote connections by using Network Level Authentication' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.10.57.3.11.1. (L1) Ensure 'Do not delete temp folders upon exit' is set to 'Disabled'
    #Write-Host "18.10.57.3.11.1. (L1) Ensure 'Do not delete temp folders upon exit' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'DeleteTempDirsOnExit' -CIS "18.10.57.3.11.1. (L1) Ensure 'Do not delete temp folders upon exit' is set to 'Disabled'") # 1 -RegType DWORD

    # 18.10.57.3.11.2. (L1) Ensure 'Do not use temporary folders per session' is set to 'Disabled'
    #Write-Host "18.10.57.3.11.2. (L1) Ensure 'Do not use temporary folders per session' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'PerSessionTempDir' -CIS "18.10.57.3.11.2. (L1) Ensure 'Do not use temporary folders per session' is set to 'Disabled'") # 1 -RegType DWORD

    # 18.10.82.1. (L1) Ensure 'Enable MPR notifications for the system' is set to 'Disabled'
    #Write-Host "18.10.82.1. (L1) Ensure 'Enable MPR notifications for the system' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableMPR' -CIS "18.10.82.1. (L1) Ensure 'Enable MPR notifications for the system' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.10.89.1.1. (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'
    #Write-Host "18.10.89.1.1. (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client' -Name 'AllowBasic' -CIS "18.10.89.1.1. (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.10.89.1.2. (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'
    #Write-Host "18.10.89.1.2. (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client' -Name 'AllowUnencryptedTraffic' -CIS "18.10.89.1.2. (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.10.89.1.3. (L1) Ensure 'Disallow Digest authentication' is set to 'Enabled'
    #Write-Host "18.10.89.1.3. (L1) Ensure 'Disallow Digest authentication' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client' -Name 'AllowDigest' -CIS "18.10.89.1.3. (L1) Ensure 'Disallow Digest authentication' is set to 'Enabled'") # 0 -RegType DWORD

    # 18.10.89.2.1. (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'
    #Write-Host "18.10.89.2.1. (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service' -Name 'AllowBasic' -CIS "18.10.89.2.1. (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.10.89.2.3. (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'
    #Write-Host "18.10.89.2.3. (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service' -Name 'AllowUnencryptedTraffic' -CIS "18.10.89.2.3. (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'") # 0 -RegType DWORD

    # 18.10.89.2.4. (L1) Ensure 'Disallow WinRM from storing RunAs credentials' is set to 'Enabled'
    #Write-Host "18.10.89.2.4. (L1) Ensure 'Disallow WinRM from storing RunAs credentials' is set to 'Enabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service' -Name 'DisableRunAs' -CIS "18.10.89.2.4. (L1) Ensure 'Disallow WinRM from storing RunAs credentials' is set to 'Enabled'") # 1 -RegType DWORD

    # 18.10.93.4.1. (L1) Ensure 'Manage preview builds' is set to 'Disabled'
    #Write-Host "18.10.93.4.1. (L1) Ensure 'Manage preview builds' is set to 'Disabled'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'ManagePreviewBuildsPolicyValue' -CIS "18.10.93.4.1. (L1) Ensure 'Manage preview builds' is set to 'Disabled'") # 1 -RegType DWORD

    # 18.10.93.4.2. (L1) Ensure 'Select when Preview Builds and Feature Updates are received' is set to 'Enabled: 180 or more days'
    #Write-Host "18.10.93.4.2. (L1) Ensure 'Select when Preview Builds and Feature Updates are received' is set to 'Enabled: 180 or more days'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'DeferFeatureUpdates' -CIS "18.10.93.4.2. (L1) Ensure 'Select when Preview Builds and Feature Updates are received' is set to 'Enabled: 180 or more days'") # 1 -RegType DWORD
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'DeferFeatureUpdatesPeriodInDays' -CIS "18.10.93.4.2. (L1) Ensure 'Select when Preview Builds and Feature Updates are received' is set to 'Enabled: 180 or more days'") # 180 -RegType DWORD

    # 18.10.93.4.3. (L1) Ensure 'Select when Quality Updates are received' is set to 'Enabled: 0 days'
    #Write-Host "18.10.93.4.3. (L1) Ensure 'Select when Quality Updates are received' is set to 'Enabled: 0 days'"
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'DeferQualityUpdates' -CIS "18.10.93.4.3. (L1) Ensure 'Select when Quality Updates are received' is set to 'Enabled: 0 days'") # 1 -RegType DWORD
    $DefaultValues += ,(Get-Registry -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'DeferQualityUpdatesPeriodInDays' -CIS "18.10.93.4.3. (L1) Ensure 'Select when Quality Updates are received' is set to 'Enabled: 0 days'") # 0 -RegType DWORD
    Return $DefaultValues, $AuditPolicies
}
Function New-ValuesScript {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [Object[]] $DefaultValues, `
        [Parameter(Mandatory=$True, Position = 2)]
        [Object[]] $AuditPolicies
    )

    ForEach ($Entry in $DefaultValues) {
        If ($Entry.Value -eq 'Does not exist') {
            Write-Host ("# " + $Entry.CIS)
            Write-Host ('Write-Host "' + $Entry.CIS + '"')
            Write-Host ("Remove-ItemProperty -Path '" + $Entry.Path + "' -Name '" + $Entry.Name + "'")
            Write-Host ""
        }
        Else {
            Write-Host ("# " + $Entry.CIS)
            Write-Host ('Write-Host "' + $Entry.CIS + '"')
            Write-Host ("Set-Registry -RegPath '" + $Entry.Path + "' -RegName '" + $Entry.Name + "' -RegValue '" + $Entry.Value + "' -RegType " + $Entry.RegType)
            Write-Host ""
        }
    }
    ForEach ($Entry in $AuditPolicies) {
        Write-Host ("# " + $Entry.CIS)
        Write-Host ('Write-Host "' + $Entry.CIS + '"')
        If ($Entry.Value -eq 'Success and Failure') {
            Write-Host ('auditpol /set /subcategory:"' + $Entry.SubCategory + '" /success:enable /failure:enable | Out-Null')
            auditpol /set /subcategory:"Application Group Management" /success:enable /failure:enable | Out-Null
        }
        Elseif ($Entry.Value -eq 'Success') {
            Write-Host ('auditpol /set /subcategory:"' + $Entry.SubCategory + '" /success:enable | Out-Null')
        }
        Write-Host ""
    }
}
Clear-Host

$Values = Get-Values
New-ValuesScript -DefaultValues $Values[0] -AuditPolicies $Values[1]