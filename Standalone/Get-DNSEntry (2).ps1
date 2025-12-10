Function Get-DnsEntry($iphost)
{
 If($ipHost -match "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$")
  {
    [System.Net.Dns]::GetHostEntry($iphost).HostName
  }
 ElseIf( $ipHost -match "^.*\.\.*")
   {
    ForEach ($DNSIP in ([System.Net.Dns]::GetHostEntry($iphost).AddressList.IPAddressToString)) { If ($DNSIP -like "10.*") {Write-Host $DNSIP }}
   } 
 ELSE { Throw "Specify either an IP V4 address or a hostname" }
} #end Get-DnsEntry

Get-DnsEntry "TSSERVER201.domain2.local"
