$SMTPServer               = 'za-smtp-outbound-1.mimecast.co.za'  
$To                       = 'MSVMandStorageJHB@eoh.onmicrosoft.com'
$From                     = 'eohrt_vm_storage@eoh.com'
$MailPassword             = 'v3Rystr0nGP@ssword2019'
$TCPPorts = @(587, 25)

$Credential    = New-Object -TypeName System.Management.Automation.PSCredential($From,(ConvertTo-SecureString -String $MailPassword -AsPlainText -Force))
$IPs = [System.Net.Dns]::GetHostAddresses($SMTPServer)| Select-Object IPAddressToString -Expandproperty IPAddressToString

If ($IPs.GetType().Name -eq 'Object[]') { 
    # Multiple IP addresses for SMTP Server
    ForEach ($TCPPort in $TCPPorts) {
        ForEach ($IP in $IPs) {
            $TCPClient = New-Object Net.Sockets.TcpClient
            Try {
                $TCPClient.Connect($IP, $TCPPort)
                If ($TCPClient.Connected) {
                    $TCPClient.Close()
                    $SMTPPort = $TCPPort
                    Write-Color -Text "Successfully connected to ", $IP, " on port ", $TCPPort -ForegroundColor White, Green, White, Green
                }
            }
            Catch {
                Write-Color -Text "Unable to connect to ", $IP, " on port ", $TCPPort -ForegroundColor White, Red, White, Red
            }
        }
    }
}
Else {
    ForEach ($TCPPort in $TCPPorts) {
        $IP = $IPs
        $TCPClient = New-Object Net.Sockets.TcpClient
        Try {
            $TCPClient.Connect($IP, $TCPPort)
            If ($TCPClient.Connected) {
                $TCPClient.Close()
                $SMTPPort = $TCPPort
                Write-Color -Text "Successfully connected to ", $IP, " on port ", $TCPPort -ForegroundColor White, Green, White, Green
            }
        }
        Catch {
            Write-Color -Text "Unable to connect to ", $IP, " on port ", $TCPPort -ForegroundColor White, Red, White, Red
        }
    }
}
Write-Host "Sending mail - " -NoNewline
Send-MailMessage -From $From -BodyAsHtml -Body "Test" -SmtpServer $SMTPServer -Subject "Test" -To $To -Port $SMTPPort -Credential $Credential
Write-Host "Complete" -ForegroundColor Green