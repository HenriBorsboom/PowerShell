<#
.SYNOPSIS
    Creates an AD service account and applies DNS permissions for reading zones and updating specific records.

.DESCRIPTION
    - Creates or verifies the service account.
    - Grants read access to specified DNS zones.
    - Grants update access to specific A and CNAME records listed in a CSV file.

.PARAMETERS
    See original script for full parameter documentation.

.NOTES
    Author: Refactored by AI for Scherrit Knoesen
    Date: 17-Jun-2025
    Version: 0.1
.UPDATES
    Author: Henri Borsboom
    Date: 18-Jun-2025
    Version: 0.3

    Removed the creation of the service account

    Author: Henri Borsboom
    Date: 18-Jun-2025
    Version: 0.2

    Added comments
    Updated parameters
    Added validation of permissions when applying to prevent re-applying permissions on zones
    Bug fixes
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
Param (
    [Parameter(Mandatory=$False, Position=1)]
    [String] $ServiceAccountName = 'S_DRAAS_PROD',                                              # AD Service account to create
    [Parameter(Mandatory=$False, Position=2)]
    [String] $ServiceAccountOU = 'OU=Admin,OU=Services,DC=capitecbank,DC=fin,DC=sky',           # AD OU where the service account should be created
    [Parameter(Mandatory=$False, Position=3)]
    [String] $DomainFQDN = 'capitecbank.fin.sky',                                               # Fully qualified domain name where root records are stored
    [Parameter(Mandatory=$False, Position=4)]
    [String] $DnsZoneJumprootFinSky = 'capitecbank.fin.sky',                                    # DNS Sub domain where records are stored
    [Parameter(Mandatory=$False, Position=5)]
    [String] $DnsZoneJump = 'capinet',                                                          # DNS zone where records are kept
    [Parameter(Mandatory=$False, Position=6)]
    [String] $DnsZoneLinuxJump = 'capinet',                                                     # DNS zone where linux records are kept
    [Parameter(Mandatory=$False, Position=7)][ValidateScript({ Test-Path $_ -PathType Leaf })]  # Test if path to CSV file is valid
    [String] $RecordsFilePath  = "D:\Henri\DNS Service Account\records.csv",                    # CSV file of records where permissions needs to be updated
    [Parameter(Mandatory=$False, Position=8)]
    [Switch] $EnableLogging = $True                                                             # Enable script logging
)
Import-Module ActiveDirectory
# Start transcript if logging is enabled
If ($EnableLogging) {
    $logPath = "$env:TEMP\DnsPermissionScript_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    Start-Transcript -Path $logPath
}

# Get the Active Directory path for the specified DNS Zone
Function Get-DnsZoneDN {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $ZoneFqdn,                                                                     # The DNS sub domain
        [Parameter(Mandatory=$True, Position=2)]
        [String] $DomainFQDN                                                                    # Fully qualified domain name where root records are stored
    )
    $DNSPartitionBase = "DC=DomainDnsZones"                                                     # Define the DNS Partition Base where records are kepts
    $DomainComponents = $DomainFQDN.Split('.') | ForEach-Object { "DC=$_" }                     # Split the domain FQDN to compile the new path with the zone
    $DomainDn = $DomainComponents -join ','                                                     # Join the name together
    Return "DC=$ZoneFqdn,CN=MicrosoftDNS,$DNSPartitionBase,$DomainDn"                           # Return the valid Active Directory path for the specified zone
}

# Get the Active Directory path for the specified DNS record
Function Get-RecordDN {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $RecordFqdn,                                                                             # The Active Directory path of the DNS record
        [Parameter(Mandatory=$True, Position=2)]
        [String] $ZoneFqdn,                                                                               # The Active Directory path of the Zone
        [Parameter(Mandatory=$True, Position=3)]
        [String] $DomainFQDN                                                                              # The Active Directory domain FQDN
    )
    $Label = $RecordFqdn.Replace(".$ZoneFqdn", "")                                                        # Removes the Zone FQDN from the path
    Return Get-DnsZoneDN -ZoneFqdn $ZoneFqdn -DomainFQDN $DomainFQDN | ForEach-Object { "DC=$Label,$_"}   # Get the Active Directory path for the specified DNS record
}

# Add the permissions to DNS objects
Function Add-Permission {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $TargetDN,                                                                   # The target where the permissions of the service account should be applied
        [Parameter(Mandatory=$True, Position=2)]
        [System.Security.Principal.SecurityIdentifier] $Sid,                                  # The security ID of the service account
        [Parameter(Mandatory=$True, Position=3)]
        [System.DirectoryServices.ActiveDirectoryRights] $Rights,                             # The security rights that should be assigned
        [Parameter(Mandatory=$False, Position=4)]
        [guid] $ObjectTypeGuid = [guid]::Empty,                                               # The security Object type. Default is Empty
        [Parameter(Mandatory=$False, Position=5)]
        [System.DirectoryServices.ActiveDirectorySecurityInheritance] $Inheritance = 'None',  # The security permission inheritance on lower objects. Default is None
        [Parameter(Mandatory=$False, Position=6)]
        [Switch] $Validate                                                                    # Validate if permissions have already been applied
    )
    Try {
        $ACL = Get-Acl "AD:\$TargetDN"                                                        # Get the current Access Control List
        If ($Validate -eq $True) {
            If ($ACL.AccessToString.Contains($ServiceAccountName)) {                              # Check if the service account has already been assigned
                Write-Host ($ServiceAccountName + ' already has access to ' + $TargetDN)          # Ignore as the account has been assigned already
            }
            Else {
                $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(             # Create a new Access Control Entry
                    $Sid, $Rights, 'Allow', $ObjectTypeGuid, $Inheritance
                )
                $ACL.AddAccessRule($ACE)                                                          # Add the Access Control Entry to the Access Control List
                Set-Acl -Path "AD:\$TargetDN" -AclObject $ACL                                     # Set the Access Control List to the target object
                Write-Host ("Permission applied to " + $TargetDN)
            }
        }
        Else {
        $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(                     # Create a new Access Control Entry
            $Sid, $Rights, 'Allow', $ObjectTypeGuid, $Inheritance
        )
        $ACL.AddAccessRule($ACE)                                                                  # Add the Access Control Entry to the Access Control List
        Set-Acl -Path "AD:\$TargetDN" -AclObject $ACL                                             # Set the Access Control List to the target object
        Write-Host ("Permission applied to " + $TargetDN)
        }
    } 
    Catch {
        Write-Warning ("Failed to apply permission to " + $TargetDN + " : " + $_)
    }
}

# Validate OU
If (-not (Get-ADOrganizationalUnit -Identity $ServiceAccountOU -ErrorAction SilentlyContinue)) { # Look for the Service Account OU in Active Directory
    Throw "ServiceAccountOU '$ServiceAccountOU' not found."                                      # Throw an error as the OU could not be located
}

# Create or get service account
Try {
    $Account = Get-ADUser -Identity $ServiceAccountName -ErrorAction SilentlyContinue            # Get the service account from AD
}
Catch {                                                                                          # Retry getting service account for AD
    $Account = Get-ADUser -Identity $ServiceAccountName -ErrorAction SilentlyContinue            # Get the service account from AD
}
Finally {
    $AccountSid = New-Object System.Security.Principal.SecurityIdentifier ($Account.SID.Value)   # Get the Account SID
}

# Grant zone read permissions
$Zones = @($DnsZoneJumprootFinSky, $DnsZoneJump, $DnsZoneLinuxJump)                              # Define the zones where the permissions should be applied
ForEach ($Zone in $Zones) {
    $ZoneDN = Get-DnsZoneDN -ZoneFqdn $Zone -DomainFQDN $DomainFQDN                              # Get the Active Directory path for the zone
    Add-Permission -TargetDN $zoneDN -Sid $accountSid -Rights 'GenericRead' -Inheritance 'All' -Validate   # Add the permissions to the zone with Generic Read Permissions and enabling inheritance
}

# Process records
$DNSRecordGuid = [guid] "bf9679cc-0de6-11d0-a285-00aa003049e2"                                   # Active Directory GUID for DNS Records
$Records = Import-Csv $RecordsFilePath                                                           # Import the CSV records from the specified file
ForEach ($Record in $Records) {
    $FQDN = $Record.RecordName.Trim()                                                            # Get the DNS record FQDN
    $Type = $Record.RecordType.Trim().ToUpper()                                                  # Get the DNS record type
    If ($Type -notin @("A", "CNAME")) {                                                          # Validate that the record type is valid
        Write-Warning "Skipping unsupported record type: $Type"
        Continue
    }

    $Zone = If ($FQDN.EndsWith(".$DnsZoneJumprootFinSky")) { $DnsZoneJumprootFinSky }            # Determine the zone of the record
            ElseIf ($FQDN.EndsWith(".$DnsZoneLinuxJump")) { $DnsZoneLinuxJump }
            ElseIf ($FQDN.EndsWith(".$DnsZoneJump")) { $DnsZoneJump }
            Else { Write-Warning "Unknown zone for $FQDN"; continue }

    $RecordDN = Get-RecordDN -RecordFqdn $FQDN -ZoneFqdn $Zone -DomainFQDN $DomainFQDN           # Get the Active Directory path for the DNS record
    Add-Permission -TargetDN $recordDN -Sid $accountSid -Rights 'WriteProperty' -ObjectTypeGuid $dnsRecordGuid # Update the permissions on the DNS record that the service account has Write Property permission
}

# End transcript
If ($EnableLogging) {
    Stop-Transcript
    Write-Host "Transcript saved to $logPath"
}