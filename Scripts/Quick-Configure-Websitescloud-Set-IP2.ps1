Function SetIP {
    Param($IP, $InterfaceAlias)
    If ($IP -like "10.10.*") {
        $Subnet = "255.255.255.128"
        $Gateway = "10.10.16.129"
        $DNS = "10.10.16.142"
        Netsh interface ipv4 set address $InterfaceAlias static $IP $Subnet $Gateway
        Write-host "Waiting 5 Seconds..."; Sleep 5
        Netsh interface ipv4 delete dnsservers $InterfaceAlias all
        Netsh interface ipv4 add dnsserver $InterfaceAlias $DNS
        Write-host "Waiting 5 Seconds..."; Sleep 5
        route delete 0.0.0.0 mask 0.0.0.0 10.10.16.129
        route add -p 10.10.0.0 mask 255.255.0.0 10.10.16.129}
    ElseIf ($IP -like "165.233.*") {
        $Subnet = "255.255.254.0"
        $Gateway = "165.233.158.1"
        Netsh interface ipv4 set address $InterfaceAlias static $IP $Subnet $Gateway}
    Else {
        Write-Host "Invalid IP"
        Break}}
$IP = "10.10.16.241"; $InterfaceAlias = "Ethernet"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
$IP = "165.233.159.211"; $InterfaceAlias = "External"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias

$IP = "165.233.159.212"; $InterfaceAlias = "External"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
$IP = "10.10.16.242"; $InterfaceAlias = "Ethernet"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias

$IP = "10.10.16.243"; $InterfaceAlias = "Ethernet"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
$IP = "165.233.159.213"; $InterfaceAlias = "External"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias

$IP = "10.10.16.244"; $InterfaceAlias = "Ethernet"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
$IP = "165.233.159.214"; $InterfaceAlias = "External"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias

$IP = "165.233.159.215"; $InterfaceAlias = "External"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
$IP = "10.10.16.245"; $InterfaceAlias = "Ethernet"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias

$IP = "10.10.16.246"; $InterfaceAlias = "Ethernet"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
$IP = "165.233.159.216"; $InterfaceAlias = "External"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias

$IP = "10.10.16.249"; $InterfaceAlias = "Ethernet"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
$IP = "165.233.159.217"; $InterfaceAlias = "External"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias

$IP = "165.233.159.218"; $InterfaceAlias = "External"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
$IP = "10.10.16.248"; $InterfaceAlias = "Ethernet"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias