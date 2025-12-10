# Copyright © Microsoft.  All Rights Reserved. 
# This code released under the terms of the  
# Microsoft Public License (MS-PL, http://opensource.org/licenses/ms-pl.html) restated here: 
# Microsoft Public License (MS-PL) 
# This license governs use of the accompanying software. If you use the software, you 
# accept this license. If you do not accept the license, do not use the software. 
# 1. Definitions 
# The terms "reproduce," "reproduction," "derivative works," and "distribution" have the 
# same meaning here as under U.S. copyright law. 
# A "contribution" is the original software, or any additions or changes to the software. 
# A "contributor" is any person that distributes its contribution under this license. 
# "Licensed patents" are a contributor's patent claims that read directly on its contribution. 
# 2. Grant of Rights 
# (A) Copyright Grant- Subject to the terms of this license, including the license conditions and limitations in section 3, each contributor grants you a non-exclusive, worldwide, royalty-free copyright license to reproduce its contribution, prepare derivative works of its contribution, and distribute its contribution or any derivative works that you create. 
# (B) Patent Grant- Subject to the terms of this license, including the license conditions and limitations in section 3, each contributor grants you a non-exclusive, worldwide, royalty-free license under its licensed patents to make, have made, use, sell, offer for sale, import, and/or otherwise dispose of its contribution in the software or derivative works of the contribution in the software. 
# 3. Conditions and Limitations 
# (A) No Trademark License- This license does not grant you rights to use any contributors' name, logo, or trademarks. 
# (B) If you bring a patent claim against any contributor over patents that you claim are infringed by the software, your patent license from such contributor to the software ends automatically. 
# (C) If you distribute any portion of the software, you must retain all copyright, patent, trademark, and attribution notices that are present in the software. 
# (D) If you distribute any portion of the software in source code form, you may do so only under this license by including a complete copy of this license with your distribution. If you distribute any portion of the software in compiled or object code form, you may only do so under a license that complies with this license. 
# (E) The software is licensed "as-is." You bear the risk of using it. The contributors give no express warranties, guarantees or conditions. You may have additional consumer rights under your local laws which this license cannot change. To the extent permitted under your local laws, the contributors exclude the implied warranties of merchantability, fitness for a particular purpose and non-infringement. 
#  
# 
# 
# 
# Synopsis:  
# 
#       This script provides permissions for the user you created to run the Exchange cmdlets required 
#       for the System Center ConfigMgr 2012 Exchange Connector.  
#       In order to facilitate this, a group role will be created and the user will be assigned to that role. 
# 
# Required cmdlets: 
# 
#       Get-ActiveSyncDeviceAccessRule 
#       Get-ActiveSyncDevice 
#       Get-ActiveSyncDeviceStatistics 
#       Get-ActiveSyncMailboxPolicy 
#       Get-ActiveSyncOrganizationSettings 
#       Get-CasMailbox 
#       Get-ExchangeServer 
#       Get-Recipient 
#       Clear-ActiveSyncDevice 
#       New-ActiveSyncDeviceAccessRule 
#       New-ActiveSyncMailboxPolicy 
#       Set-ActiveSyncDeviceAccessRule 
#       Set-ActiveSyncMailboxPolicy 
#       Set-ActiveSyncOrganizationSettings 
#       Set-ADServerSettings 
#       Set-CasMailbox 
#       Remove-ActiveSyncDevice      
# 
# Usage:  
#    
#   AddCmdletPermissionsToConnectorUser.ps1 User1 
#   Adds a user with permissions to run the above cmdlets 
# 

param(
[parameter(Mandatory=$true,
            ValueFromPipeline=$true)]
            [String]
            $userName)

# When an error occurs, stop the program
$ErrorActionPreference = "Stop"
			
###########################################################################################
# Creates a management role if one does not exist and removes unnecessary cmdlets for this 
# management role.
# $roleName   : The name of the management role
# $parentRole : The name of the parent role 
# $cmdletsToEnable: The cmdlets that this management role will have permissions to run
############################################################################################
function CreateManagementRolesAndEnableCmdlets([String] $roleName, [String] $parentRole, $cmdletsToEnable)
{
    Write-Host "Creating a new management role '$roleName' from '$parentRole' and providing permissions for the required cmdlets"
    
    $roleExists = Get-ManagementRole | where { $_.Name -eq $roleName }
    if ($roleExists)
    {   
        Write-Host "Removing '$roleName' because it already exists"
        Remove-ManagementRole $roleName -Confirm:$false    
    }    
    
	# Prevent output to screen (it will, however, print errors)
    New-ManagementRole -Name $roleName -parent $parentRole | out-null
    
    # Disable all cmdlets that do not exist in the $cmdletsToEnable list
    Get-ManagementRoleEntry $roleName"\*" | Where {$cmdletsToEnable -notcontains $_.Name } | Remove-ManagementRoleEntry -Confirm:$false
        
    Write-Host "'$roleName' created"
}			

$cmdlets = @(
    "Get-ActiveSyncOrganizationSettings",
    "Get-ExchangeServer",
    "Get-CasMailbox",
    "Get-ActiveSyncDeviceStatistics", 
    "Get-ActiveSyncDevice",
    "Get-Recipient",
    "Get-ActiveSyncMailboxPolicy", 
    "Get-ActiveSyncDeviceAccessRule",
    "Set-ActiveSyncOrganizationSettings", 
    "Set-CasMailbox", 
    "Set-ActiveSyncMailboxPolicy",
	"Set-ActiveSyncDeviceAccessRule",
    "Set-ADServerSettings",
    "New-ActiveSyncMailboxPolicy", 
    "New-ActiveSyncDeviceAccessRule",
    "Remove-ActiveSyncDevice", 
	"Clear-ActiveSyncDevice")

$groupName = "ConfigMgr 2012 Exchange Connector"
$connectorGroup = Get-RoleGroup | where { $_.Name -eq $groupName }
if ($connectorGroup)
{
    Write-Host "Removing role group '$connectorGroup' because it already exists"
    Remove-RoleGroup $groupName -Confirm:$false    
}

$exchangeServersRole =          "ConfigMgr 2012 ExchangeConnector ExchangeServers"
$organizationClientAccessRole = "ConfigMgr 2012 ExchangeConnector OrganizationClientAccess" 
$receipientPoliciesRole =       "ConfigMgr 2012 ExchangeConnector RecipientPolicies"
$mailRecipientsRole =           "ConfigMgr 2012 ExchangeConnector MailRecipients"

# Creating management roles:
# Because every parent role has a different set of run permissions, permissions are applied across 
# several roles
CreateManagementRolesAndEnableCmdlets $exchangeServersRole          "Exchange Servers"           $cmdlets
CreateManagementRolesAndEnableCmdlets $organizationClientAccessRole "Organization Client Access" $cmdlets
CreateManagementRolesAndEnableCmdlets $receipientPoliciesRole       "Recipient Policies"         $cmdlets
CreateManagementRolesAndEnableCmdlets $mailRecipientsRole           "Mail Recipients"            $cmdlets

Write-Host "Creating a role group '$groupName'"
$connectorGroup = New-RoleGroup -Name $groupName -Roles $exchangeServersRole, $organizationClientAccessRole, $receipientPoliciesRole, $mailRecipientsRole
Write-Host "'$groupName' created"

Write-Host "Assigning role group '$groupName' to '$userName'"
Add-RoleGroupMember -Identity $connectorGroup -Member $userName

Write-Host "User '$userName' now has run permissions for the following cmdlets:"
$cmdlets
