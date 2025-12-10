Param (
    [Parameter(Mandatory = $True, Position = 1)]
    [String] $Zone,
    [Parameter(Mandatory = $True, Position = 2)]
    [String] $Name,
    [Parameter(Mandatory = $True, Position = 3)]
    [INT] $TTL,
    [Parameter(Mandatory = $false, Position = 4)]
    [String] $NewTarget = $null
)
    
$Session = New-PSSession `
    -ComputerName labadexternal `
    -ConfigurationName DnsDelegation

If ($null -eq $NewTarget) {
    Invoke-Command -Session $Session -ScriptBlock {
        param($z,$n,$t,$r)
        Set-DnsTtlCNAME -Zone $z -Name $n -TTLSeconds $t
    } -ArgumentList $Zone, $Name, $TTL
}
Else {
    Invoke-Command -Session $Session -ScriptBlock {
        param($z,$n,$t,$v,$r)
        Set-DnsTtlCNAME -Zone $z -Name $n -TTLSeconds $t -Value $v
    } -ArgumentList $Zone, $Name, $TTL, $NewTarget
}
Remove-PSSession $Session