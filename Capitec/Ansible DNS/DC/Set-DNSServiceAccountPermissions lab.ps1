[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
Param (
    [Parameter(Mandatory=$False, Position=1)]
    [String] $ServiceAccountName = 's_draas_dns_prod',                                                               # AD Service account to create
    [Parameter(Mandatory=$False, Position=2)]
    [String] $ServiceAccountOU = 'OU=ServiceAccounts,DC=ansible,DC=local',                                                                 # AD OU where the service account should be created
    [Parameter(Mandatory=$False, Position=3)]
    [String] $DomainFQDN = 'ansible.local'                                                         # Enable script logging
)

# Create or get service account
$Account = Get-ADUser -Identity $ServiceAccountName -ErrorAction SilentlyContinue                # Get the service account from AD
If (-not $account) {                                                                             # Check if the account exists
    Write-Host "Creating service account..."
    $Password = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force                 # Create a new random password for the account
    # Create the service account
    New-ADUser -Name $ServiceAccountName -SamAccountName $ServiceAccountName `
        -UserPrincipalName ($ServiceAccountName + '@' + $DomainFQDN) `
        -Path $ServiceAccountOU `
        -Enabled $True `
        -AccountPassword $Password `
        -ChangePasswordAtLogon $False `
        -Description "Service account for DRaaS DNS updates"
    $Account = Get-ADUser -Identity $ServiceAccountName                                          # Get the service account from AD
}
