Param (
    [Parameter(Mandatory=$True)]
    [String] $Server
)
$ADServer = 'CBDC002.capitecbank.fin.sky'
[Object[]] $ServiceAccounts = Get-ADServiceAccount -Filter ('Description -like "*Pipeline *{0}*"' -f $Server) -Properties Description -Server $ADServer | Select-Object Name, Description

ForEach ($ServiceAccount in $ServiceAccounts) {
    Write-Output ('Service Accounts Groups for ' + $ServiceAccount.Name + ' - ' + $ServiceAccount.Description)
    Get-ADServiceAccount $ServiceAccount.Name -Server $ADServer -Properties MemberOf | Select-Object -ExpandProperty MemberOf | Sort-Object
    Write-Output ('')
}