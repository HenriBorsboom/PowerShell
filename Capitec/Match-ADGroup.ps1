Param (
    [Parameter(Mandatory=$True, Position=1)]
    [String] $UserAccount, `
    [Parameter(Mandatory=$True, Position=2)]
    [String] $Group
)

$Server = 'CBDC004.capitecbank.fin.sky'

Try {
    $Groups = Get-ADUser $UserAccount -Properties MemberOf -Server $Server | Select-Object -ExpandProperty MemberOf
    $Groups -like ("*$Group*")
}
Catch {
    $Groups = Get-ADUser $UserAccount -Properties MemberOf -Server $Server | Select-Object -ExpandProperty MemberOf
    $Groups -like ("*$Group*")
}