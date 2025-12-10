Function Get-ADGroupDetails {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Group
    )
    $DC = 'CBDC004.capitecbank.fin.sky'
    Get-ADGroup $Group -Server $DC -Properties ManagedBy, Description | Select-Object Name, Description, @{Name="Mangedby"; Expression={$_.ManagedBy.Split(',')[0].Replace('CN=','')}}
}