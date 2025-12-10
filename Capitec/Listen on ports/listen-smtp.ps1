
$port = 25
$ipAddress = [System.Net.IPAddress]::Any
$listener = [System.Net.Sockets.TcpListener]::new($ipAddress, $port)

$listener.Start()
Write-Host "SMTP simulation listening on port $port..."

while ($true) {
    if ($listener.Pending()) {
        $client = $listener.AcceptTcpClient()
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.AutoFlush = $true

        # SMTP greeting
        $writer.WriteLine("220 smtp.example.com Simple Mail Transfer Service Ready")

        while ($client.Connected -and !$reader.EndOfStream) {
            $line = $reader.ReadLine()
            Write-Host "Client: $line"

            switch -Regex ($line) {
                "^HELO"     { $writer.WriteLine("250 Hello") }
                "^EHLO"     { $writer.WriteLine("250-Hello`n250-SIZE 35882577`n250-PIPELINING`n250 HELP") }
                "^MAIL FROM:" { $writer.WriteLine("250 OK") }
                "^RCPT TO:"   { $writer.WriteLine("250 OK") }
                "^DATA"       { 
                    $writer.WriteLine("354 Start mail input; end with <CRLF>.<CRLF>")
                    # Read until "." on a line by itself
                    do {
                        $dataLine = $reader.ReadLine()
                        Write-Host "Data: $dataLine"
                    } while ($dataLine -ne ".")
                    $writer.WriteLine("250 OK: queued as 12345")
                }
                "^QUIT"       {
                    $writer.WriteLine("221 Bye")
                    break
                }
                default       { $writer.WriteLine("500 Unrecognized command") }
            }
        }

        $client.Close()
    }
    Start-Sleep -Milliseconds 100
}
