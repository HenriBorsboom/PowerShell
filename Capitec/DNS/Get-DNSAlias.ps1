<#
.SYNOPSIS
   Finds all CNAMEs pointing at a given A-record.

.DESCRIPTION
   Uses the DnsServer module to enumerate CNAMEs in all zones,
   filtering to those whose alias matches your target FQDN.

.PARAMETER TargetFqdn
   The fully-qualified A record you want to check.  
   Example: 'server.capitecbank.fin.sky'

.PARAMETER DnsServer
   The DNS server to query.  
   Example: '10.224.97.200'
   Example: 'cbdc004'

.EXAMPLE
   Get-DNSAlias `
     -TargetFqdn 'server.capitecbank.fin.sky'
     -DnsServer 'cbdc004'

.EXAMPLE
   Get-DNSAlias `
     -TargetFqdn 'server.capitecbank.fin.sky'
     -DnsServer '10.224.97.200'

.NOTES
    Author: Henri Borsboom
    Date: 19-Jun-2025
    Version: 0.1

.UPDATES
    
#>
Param(
    [Parameter(Mandatory=$True, Position=1)]
    [String] $TargetFqdn,                      # e.g. "server.capitecbank.fin.sky"
    [Parameter(Mandatory=$True, Position=2)]
    [String] $DnsServer                        # IPConfig /all will provide the local configured name servers
)
# Gets all the primary DNS zones
Function Get-DnsZones {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, Position=1)]
        [String] $DnsServer                    # Dns Server to query the zones
    )
    # Get all the primary zones and ignore forwarder zones
    $Zones = Get-DnsServerZone -ComputerName $DnsServer |
        Where-Object ZoneType -eq 'Primary' |
        Select-Object ZoneName, ZoneType, @{n='DsIntegrated';e={$_.IsDsIntegrated}}
    Return $Zones
}
# Get all the DNS zones
$Zones = Get-DnsZones -DnsServer $DnsServer
$Details = @()
ForEach ($ZoneName in $Zones.Zonename) {
    # Grab all CNAME records in the zone
    $cnames = Get-DnsServerResourceRecord `
        -ComputerName $DnsServer `
        -RRType CNAME `
        -ZoneName $ZoneName
    # Filter to those whose HostNameAlias equals our target A-record FQDN
    $matchesFound = $cnames | Where-Object {
        $_.RecordData.HostNameAlias.TrimEnd('.') -ieq $TargetFqdn.TrimEnd('.')
    }

    if ($matchesFound) {
        $Results = $matchesFound | Select-Object @{n='Alias';e={$_.HostName + '.' + $ZoneName}}, @{n='HostName';e={$_.RecordData.HostNameAlias}}
        # Populate all the results into a array
        ForEach ($Result in $Results) {
            $Details += ,(New-Object -TypeName PSObject -Property @{
                Hostname = $Result.Hostname
                Alias = $Result.Alias
            })
        }
    }
    else {
        Write-Verbose "No CNAME found pointing to $TargetFqdn in zone $ZoneName"
    }
}
# Output the details
$Details