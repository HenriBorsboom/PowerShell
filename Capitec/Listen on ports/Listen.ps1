$port = 8080
$ipAddress = [System.Net.IPAddress]::Any
$listener = [System.Net.Sockets.TcpListener]::new($ipAddress, $port)

$listener.Start()
Write-Host "Listening on port $port..."

while ($true) {
    if ($listener.Pending()) {
        $client = $listener.AcceptTcpClient()
        Write-Host "Connection accepted from $($client.Client.RemoteEndPoint)"
        
        # Optional: Read data from client
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $data = $reader.ReadLine()
        Write-Host "Received: $data"

        # Optional: Respond to client
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.WriteLine("Hello from PowerShell server!")
        $writer.Flush()

        $client.Close()
    }
    Start-Sleep -Milliseconds 100
}