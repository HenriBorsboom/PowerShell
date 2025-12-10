#Authentication
Function Get-Token {
    $user = 'henri.borsboom'
    $passwordSec = ConvertTo-SecureString -String 'YourPasswordHere' -AsPlainText -Force

    $password= [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordSec))

    <# Retrieve the  token.  #>
    $auth=Invoke-RestMethod https://api.livevault.com/api/authorize -Method Post -Body "grant_type=password&username=$user&password=$password"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", 'Bearer ' + $auth.access_token)
    Return $headers
}

#Agents
Function Get-Agents {
    Invoke-RestMethod ('https://api.livevault.com/api/v1/agents') -Headers $headers
    
    
} # Get a list of agents
Function Get-AgentbyID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/agents/' + $ID) -Headers $headers
} # Get agent
Function Get-AgentBackupPolicyByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/agents/' + $ID + '/backuppolicies') -Headers $headers
} # Get list of agent backup policies

#Appliances
Function Get-Appliances {
    Invoke-RestMethod ('https://api.livevault.com/api/v1/appliances') -Headers $headers
} #get list of appliances
Function Get-ApplianceByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/appliances/' + $ID) -Headers $headers
} # get appliance
Function Get-ApplianceBackupPolicyByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/appliances/' + $ID + '/backuppolicies') -Headers $headers
} # get list of appliance backup policies

# Backup
Function Get-BackupPolicies {
    Invoke-RestMethod ('https://api.livevault.com/api/v1/backuppolicies') -Headers $headers
} # Get list of backup policies
Function Get-BackupPolicyByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/backuppolicies/' + $ID) -Headers $headers
} # Get backup policy

#Customers
Function Get-Customers {
    Invoke-RestMethod ('https://api.livevault.com/api/v1/customers') -Headers $headers
} # Get list of Customers
Function Get-CustomerByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/customers/' + $ID) -Headers $headers
} # Get Customer
Function Get-CustomerRoleByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/customers/' + $ID + '/roles') -Headers $headers
} # Get list of customer roles
Function Get-CustomerUsersByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/customers/' + $ID + '/users') -Headers $headers
} # Get list of customer user accounts
Function Get-CustomerAgentsByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/customers/' + $ID + '/agents') -Headers $headers
} # Get list of customer agents
Function Get-CustomerApplianceByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/customers/' + $ID + '/appliances') -Headers $headers
} # Get list of customer appliances
Function Get-CustomerBackupPolicyByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/customers/' + $ID + '/backuppolicies') -Headers $headers
} # Get list of customer backup policies

#Partners
Function Get-Partners {
    Invoke-RestMethod ('https://api.livevault.com/api/v1/partners') -Headers $headers
} # Get list of partners
Function Get-PartnersByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/partners/' + $ID) -Headers $headers
} # Get partner

# Reports
Function Get-ServerReportByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/reports/server/' + $ID) -Headers $headers
} # Server Status Report by Partner, Customer, Group ID
Function Get-AdvancedServerReportByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/reports/advancedserver/' + $ID) -Headers $headers
} # Advanced Server Status Report
Function Get-EnhancedServerReportById {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/reports/enhancedserver/' + $ID) -Headers $headers
} # Enahnced Server Status Report
Function Get-ApplianceReportByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/reports/appliance/' + $ID) -Headers $headers
} # Appliance Summary Report
Function Get-BackupHistoryReportByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/reports/backuphistory/' + $ID) -Headers $headers
} # Backup History Report
Function Get-BackupUsageReportByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/reports/usagereport/backup/' + $ID) -Headers $headers
} # Backup Usage Report
Function Get-RestoreUsageReportByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/reports/usagereport/restore/' + $ID) -Headers $headers
} # Restore Usage Report

# Users
Function Get-Users {
    Invoke-RestMethod ('https://api.livevault.com/api/v1/users') -Headers $headers
} # Get list of user accounts
Function Get-UserByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Invoke-RestMethod ('https://api.livevault.com/api/v1/users/' + $ID) -Headers $headers
} # Get user account

#Authenticate
$headers = Get-Token

#BuildCollections of all options
$Agents = Get-Agents
$Appliances = Get-Appliances
$BackupPolicies = Get-BackupPolicies
$Customers = Get-Customers

#Customer Name - get customer
#Server Status
#Offsite Backup
#Current Backup Failures
#Backup Warnings
#Group
#Server
#Server ID
#Update Available
#Agent Version
#Policy
#Policy ID
#Schedule
#Retention
#Last Backup to Vault
#Policy Size in GBs
#Policy Files
#Disconnected Days
#Last Upgrade Check Time

#LHC Customer ID: 1128532
#PIMG001 ID: 1172245