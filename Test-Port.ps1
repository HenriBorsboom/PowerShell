Function Test-Port {
    Param ($Server, $Port)
    Try {
        $IP = [System.Net.Dns]::GetHostAddresses($Server)| Select-Object IPAddressToString -Expandproperty IPAddressToString
        If ($IP.GetType().Name -eq 'Object[]') {
            #If we have several ip's for that address, let's take first one
            $IP = $IP[0]
        }
    } 
    Catch {
        Return $False
    }
    
    $TCPClient = New-Object Net.Sockets.TcpClient
    # We use Try\Catch to remove exception info from console if we can't connect
    Try {
        $TCPClient.Connect($IP, $Port)
    } 
    Catch { }

    If ($TCPClient.Connected) {
        $TCPClient.Close()
        Return "$Server - $Port - Open"
    }
    Else {
        Return "$Server - $Port - Close"
    }
}