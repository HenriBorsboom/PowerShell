Clear-Host

$Details = @()
$LocalGroups = Get-LocalGroup
For ($x = 0; $x -lt $LocalGroups.Count; $x ++) {
    $Members = Get-LocalGroupMember -Group $LocalGroups[$x].Name
    If ($Members.Count -gt 0) {
        For ($MemberI = 0; $MemberI -lt $Members.Count; $MemberI ++) {
            $Details += ,(New-Object -TypeName PSObject -Property @{
                Server = $env:COMPUTERNAME
                LocalGroup = $LocalGroups[$x].Name
                Member = $Members[$MemberI].Name
            })
        }
    }
}
$Details | Select Server, LocalGroup, Member

