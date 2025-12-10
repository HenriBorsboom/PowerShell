$AzureAdminUsername        = 'admin@company.com'
$SubscriptionId            = '53e7ca41-4ae4-4e6f-874d-3fb20a19d443'
$Creds                     = Get-Credential -Message "Please enter your Azure Subscription credentials" -UserName $AzureAdminUsername

$aadClientID               = '4fd22e53-6d66-4466-a139-873e0abd1480'
$aadClientSecret           = '7115679b-21a5-4240-844a-d4e14a081bb0'
$diskEncryptionKeyVaultUrl = 'https://SYSPROAZURERG.vault.azure.net'
$keyVaultResourceId        = '/subscriptions/ea1154ea-8a3e-4794-a7a7-c479865cae6a/resourceGroups/SYSPROAZURERG/providers/Microsoft.KeyVault/vaults/SYSPROAZURERG'

$keyVaultName              = 'SYSPROAZURERG'
$aadAppName                = 'SYSPROAZURERG'

$resourceGroupName         = 'SYSPROAZURERG'
$location                  = 'westeurope'
$VMName                    = 'sysprddcinfra1'

Login-AzureRmAccount -Credential $Creds -SubscriptionId $SubscriptionId
Set-AzureRmVmDiskEncryptionExtension -ResourceGroupName $resourceGroupName -VMName $VMName -AadClientID $aadClientID -AadClientSecret $aadClientSecret -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $keyVaultResourceId

$resourceGroupName         = 'SYSAZUPOC'
$VMName                    = 'sysazupocdc01'
$location                  = 'southeastasia'
Set-AzureRmVmDiskEncryptionExtension -ResourceGroupName $resourceGroupName -VMName $VMName -AadClientID $aadClientID -AadClientSecret $aadClientSecret -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $keyVaultResourceId

$resourceGroupName         = 'SYSAZUPOC'
$VMName                    = 'sysazupocsql01'
$location                  = 'southeastasia'
Set-AzureRmVmDiskEncryptionExtension -ResourceGroupName $resourceGroupName -VMName $VMName -AadClientID $aadClientID -AadClientSecret $aadClientSecret -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $keyVaultResourceId

<#
PS C:\Windows\system32> Set-AzureRmVmDiskEncryptionExtension -ResourceGroupName $resourceGroupName -VMName $VMName -AadClientID $aadClientID -AadClientSecret $aadClientSecret -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $keyVaultResourceId
Set-AzureRmVmDiskEncryptionExtension : The client has permission to perform action 'Microsoft.KeyVault/vaults/deploy/action' on scope 
'/subscriptions/53e7ca41-4ae4-4e6f-874d-3fb20a19d443/resourceGroups/SYSPROAZURERG/providers/Microsoft.Compute/virtualMachines/sysprddcinfra1', however the current tenant '829c6251-e39b-4053-894b-6f4fcd723d7f' is not authorized to access linked subscription 
'ea1154ea-8a3e-4794-a7a7-c479865cae6a'.
ErrorCode: LinkedAuthorizationFailed
ErrorMessage: The client has permission to perform action 'Microsoft.KeyVault/vaults/deploy/action' on scope '/subscriptions/53e7ca41-4ae4-4e6f-874d-3fb20a19d443/resourceGroups/SYSPROAZURERG/providers/Microsoft.Compute/virtualMachines/sysprddcinfra1', 
however the current tenant '829c6251-e39b-4053-894b-6f4fcd723d7f' is not authorized to access linked subscription 'ea1154ea-8a3e-4794-a7a7-c479865cae6a'.
StatusCode: 403
ReasonPhrase: Forbidden
OperationID : d8f651e6-0c0a-4e4c-9363-6c4e2a62dfcf
At line:1 char:1
+ Set-AzureRmVmDiskEncryptionExtension -ResourceGroupName $resourceGroupName -VMNa ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : CloseError: (:) [Set-AzureRmVMDiskEncryptionExtension], ComputeCloudException
    + FullyQualifiedErrorId : Microsoft.Azure.Commands.Compute.Extension.AzureDiskEncryption.SetAzureDiskEncryptionExtensionCommand
#>