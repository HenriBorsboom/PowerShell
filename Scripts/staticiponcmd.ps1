[string] $IP = 118
$Address = "10.12.11."
$IPAddress = $Address + $IP

$Command = 'netsh interface ipv4 set address "Local Area Connection" static $IPAddress 255.255.255.128 10.10.16.129'
Invoke-Expression $Command
