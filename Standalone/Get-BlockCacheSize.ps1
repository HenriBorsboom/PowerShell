<#
.Synopsis
   Get the Block Cache Size set for Failover Clusters in a domain
.DESCRIPTION
   Get the Block Cache Size set for Failover Clusters in a domain,
   a small Block Cache Size will minimize the impact of multiple
   Virtual Machines starting together
.EXAMPLE
   Get-BlockCacheSize -Domain <Your AD Domain>
#>
[CmdletBinding()]
[OutputType([int])]
Param
(
    # Your AD Domain
    [Parameter(Mandatory = $True,
                ValueFromPipelineByPropertyName = $True,
                Position=0)]
    [String] $Domain)

Begin {
    If ($Domain -eq "" -or $Domain -eq $null) { Return }
}
Process {
    ForEach ($Cluster in (Get-Cluster -Domain $Domain)) { 
        Write-Host ($Cluster.ToString() + "-" + (Get-Cluster -Name $Cluster.Name).BlockCacheSize.ToString())
    }
}