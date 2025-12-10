Param (
    [Parameter(Mandatory=$True, Position=1)]
    [String] $ADAccount
)

$DC = 'cbdc004.capitecbank.fin.sky'

$Groups = Get-ADUser $ADAccount -Properties MemberOf -Server $DC | Select-Object -Expand MemberOf
$Details = @()
ForEach ($Group in $GRoups) {
    $Details += ,(New-Object -TypeName PSObject -Property @{
        User = $ADAccount
        Group = $Group.Split(',')[0].Replace('CN=','')
    })
}
$Details | Out-GridView