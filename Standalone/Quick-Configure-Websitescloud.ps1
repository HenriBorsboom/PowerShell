Function Copy-Script {
$Folder = "C:\Temp2"
$empty = New-Item -Path $Folder -ItemType Directory -Force
$empty = Copy-Item .\*.* -Destination $Folder
}
Copy-Script
Function SetIP {
    Param($IP, $InterfaceAlias)

    If ($IP -like "10.10.*") {
        $Subnet = "255.255.255.128"
        $Gateway = "10.10.16.129"
        $DNS = "10.10.16.142"
        $CMDCommand = 'Netsh interface ipv4 set address $InterfaceAlias static $IP $Subnet $Gateway'
        RunCommand $CMDCommand
        Write-host "Waiting 5 Seconds..."; Sleep 5
        $CMDCommand = 'Netsh interface ipv4 delete dnsservers $InterfaceAlias all'
        RunCommand $CMDCommand
        $CMDCommand = 'Netsh interface ipv4 add dnsserver $InterfaceAlias $DNS'
        RunCommand $CMDCommand
    }
    ElseIf ($IP -like "165.233.*") {
        $Subnet = "255.255.254.0"
        $Gateway = "165.233.158.1"
        
        $CMDCommand = 'Netsh interface ipv4 set address $InterfaceAlias static $IP $Gateway $DNS'
        RunCommand $CMDCommand
    }
    Else {
        Write-Host "Invalid IP"
        Break
    }
    Write-host "Waiting 5 Seconds..."; Sleep 5
    $CMDCommand = 'route delete 0.0.0.0 mask 0.0.0.0 10.10.16.129'
    RunCommand $CMDCommand
    $CMDCommand = 'route add -p 10.10.0.0 mask 255.255.0.0 10.10.16.129'
    RunCommand $CMDCommand
}

Function RunCommand {
    Param($RemoteCommand)
    Try {Invoke-Command $RemoteCommand -ErrorAction Stop}
    Catch {Write-Host $_}
}

Function Execute {
If ($env:COMPUTERNAME -eq $Server) {
$Server = "NRAZUREWEB301"
$IP = "10.10.16.241"; $InterfaceAlias = "Ethernet"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
$IP = "165.233.159.211"; $InterfaceAlias = "External"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
}
ElseIf ($env:COMPUTERNAME -eq $Server) {
$Server = "NRAZUREWEB302"
$IP = "165.233.159.212"; $InterfaceAlias = "External"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
$IP = "10.10.16.242"; $InterfaceAlias = "Ethernet"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
}
ElseIf ($env:COMPUTERNAME -eq $Server) {
$Server = "NRAZUREWEB303"
$IP = "10.10.16.243"; $InterfaceAlias = "Ethernet"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
$IP = "165.233.159.213"; $InterfaceAlias = "External"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
}
ElseIf ($env:COMPUTERNAME -eq $Server) {
$Server = "NRAZUREWEB304"
$IP = "10.10.16.244"; $InterfaceAlias = "Ethernet"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
$IP = "165.233.159.214"; $InterfaceAlias = "External"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
}
ElseIf ($env:COMPUTERNAME -eq $Server) {
$Server = "NRAZUREWEB305"
$IP = "165.233.159.215"; $InterfaceAlias = "External"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
$IP = "10.10.16.245"; $InterfaceAlias = "Ethernet"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
}
ElseIf ($env:COMPUTERNAME -eq $Server) {
$Server = "NRAZUREWEB306"
$IP = "10.10.16.246"; $InterfaceAlias = "Ethernet"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
$IP = "165.233.159.216"; $InterfaceAlias = "External"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
}
ElseIf ($env:COMPUTERNAME -eq $Server) {
$Server = "NRAZUREWEB307"
$IP = "10.10.16.249"; $InterfaceAlias = "Ethernet"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
$IP = "165.233.159.217"; $InterfaceAlias = "External"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
}
ElseIf ($env:COMPUTERNAME -eq $Server) {
$Server = "NRAZUREWEB308"
$IP = "165.233.159.218"; $InterfaceAlias = "External"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
$IP = "10.10.16.248"; $InterfaceAlias = "Ethernet"; SetIP -IP $IP -InterfaceAlias $InterfaceAlias
}
Else {
    Write-Host "Computername mismatch - "$env:COMPUTERNAME
}
}