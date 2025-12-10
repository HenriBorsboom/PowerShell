[DateTime] $LastLogonDate = (Get-Date).AddMonths(-3)
$InactiveServers = Get-ADComputer -Filter {LastLogonDate -lt $LastLogonDate -and OperatingSystem -like '*server*'} -Properties Name, LastLogonDate, Enabled, DistinguishedName 

$InactiveServers | Export-Csv -Path ('c:\temp\AD-InactiveServers ' + (get-date -f "yyyy-MM-dd") + '.csv') -Force -NoClobber -NoTypeInformation -Encoding ASCII -Delimiter ';'
$InactiveServers | Set-ADComputer -Enabled:$false
