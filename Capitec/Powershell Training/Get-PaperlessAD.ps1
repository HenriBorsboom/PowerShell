Param (
    [Parameter(Mandatory=$True)]
    [String] $Server
)
$ADServer = 'CBDC002.capitecbank.fin.sky'
Write-Output ('Server OU')
(Get-ADComputer $Server -Properties memberof -server $ADServer | Select-Object DistinguishedName).DistinguishedName
Write-Output ('')
Write-Output ('Server Groups - ' + $Server)
Get-ADComputer $Server -Properties memberof -server $ADServer | Select-Object -ExpandProperty memberof
Write-Output ('')
[Object[]] $ServiceAccounts = Get-ADServiceAccount -Filter ('Description -like "*{0}*"' -f $Server) -Properties Description -Server $ADServer | Select-Object Name, Description

ForEach ($ServiceAccount in $ServiceAccounts) {
    Write-Output ('Service Accounts Groups for ' + $ServiceAccount.Name + ' - ' + $ServiceAccount.Description)
    Get-ADServiceAccount $ServiceAccount.Name -Server $ADServer -Properties MemberOf | Select-Object -ExpandProperty MemberOf
    Write-Output ('')
}