Param (
    [Parameter(Mandatory = $True, Position = 1)]
    [String] $Zone,
    [Parameter(Mandatory = $True, Position = 2)]
    [String] $Name,
    [Parameter(Mandatory = $True, Position = 3)]
    [INT] $TTL
)

$Session = New-PSSession `
    -ComputerName labadexternal `
    -ConfigurationName DnsDelegation

Invoke-Command -Session $Session -ScriptBlock {
    param($z,$n,$t,$r)
    Set-DnsTtlA -Zone $z -Name $n -TTLSeconds $t
} -ArgumentList $Zone, $Name, $TTL
    
Remove-PSSession $Session