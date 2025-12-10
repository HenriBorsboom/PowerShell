<#
    .Synopsis
        Get groups where account is a member of
    .DESCRIPTION
        Get groups where account is a member of
    .EXAMPLE
        Get-ADUserGroups -Account "Administrator"
        This will return the groups that the domain account Administrator belongs to
    .EXAMPLE
        Get-ADUserGroups -Filter "*service*"
        This will return the accounts that contains "service" and the groups that it
        belongs to
    #>

Param (
    [Parameter(Mandatory = $false, Position = 1)]
    [String]   $Account, `
    [Parameter(Mandatory = $false, Position = 1)]
    [String[]] $Filter)

Import-Module ActiveDirectory

If ($Account -ne "" -and $Account -ne $null) {
    Write-Host $Account
    Get-ADUser -Filter { "Name -eq '$Account'" } -Properties "MemberOf"
}
ElseIf ($Filter -ne "" -and $Filter -ne $null) {
    $Users = (Get-ADUser -Filter { "Name -eq '$Filter'" } -Properties "MemberOf")
    ForEach ($ADUser in $Users) {
        Write-Host $ADUser
        Get-ADUser $ADUser -Properties "MemberOf"
        Write-host ""
    }
}