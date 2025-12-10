Function Test-Port {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $IP,
        [Parameter(Mandatory=$True, Position=2)]
        [Int] $Port, `
        [Parameter(Mandatory=$False, Position=3)]
        [Int] $Timeout = 25)

    $requestCallback = $state = $null
    $client = New-Object System.Net.Sockets.TcpClient
    $beginConnect = $client.BeginConnect($IP,$Port,$requestCallback,$state)
    Start-Sleep -Milliseconds $Timeout
    if ($client.Connected) { $State = $true } else { $State = $false }
    $client.Close()
    $ReturnValue = New-Object -TypeName PSObject -Property @{
        IP = $IP
        Open = $State
        Port = $Port
    } | Select IP, Open, Port
    Return $ReturnValue
}

$StartPort = 1024
$EndPort = 65535

$OpenPorts = @()
For ($port = $StartPort; $port -lt ($EndPort + 1); $port ++) {
    #Write-Progress “Scanning ports” $port -PercentComplete (($port/9000)*100)
    Write-Progress -Activity "Scanning Ports" -Status $port -PercentComplete (($port/($EndPort + 1))*100)
    $PortStatus = Test-Port -IP 192.168.1.103 -Port $port
    If ($PortStatus.Open -eq $True) {
        $PortStatus
        $OpenPorts += $PortStatus
    }
}