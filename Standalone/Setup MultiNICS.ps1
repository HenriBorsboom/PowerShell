$EthernetIPLast = "248"
$ExternalIPLast = "218"

$EthernetIPFirst = "10.10.16."
$EthernetSubnet = "255.255.255.128"
$EthernetGateway = "10.10.16.129"
$DNS1 = "10.10.16.142"

$ExternalIPFirst = "165.233.159."
$ExternalSubnet = "255.255.254.0"
$ExternalGateway = "165.233.158.1"

$EthernetIP = $EthernetIPFirst + $EthernetIPLast
Netsh interface ipv4 set address ethernet static $EthernetIP $EthernetSubnet $EthernetGateway
Netsh interface ipv4 delete dnsservers ethernet all
Netsh interface ipv4 add dnsserver ethernet $DNS1

$ExternalIP = $ExternalIPFirst + $ExternalIPLast
Netsh interface ipv4 set address external static $ExternalIP $ExternalSubnet $ExternalGateway
Netsh interface ipv4 delete dnsservers ethernet all

Route -p add 10.10.0.0 mask 255.255.0.0 10.10.16.129
route -p delete 0.0.0.0 mask 0.0.0.0 10.10.16.129

Ping 10.10.16.129
Ping 165.233.158.1
