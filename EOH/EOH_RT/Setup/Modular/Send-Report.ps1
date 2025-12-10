Function Send-Report {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Client, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $File, `
        [Parameter(Mandatory=$False, Position=4)]
        [String] $Address)

                           $SMTPServer = 'za-smtp-outbound-1.mimecast.co.za'
    If ($Address -eq '') { $To         = 'mscloud@eoh.com' }
    Else                 { $To         = $Address }
                           $From       = 'eohrt_vm_storage@eoh.com'
                           $Subject    = ('Daily RT - ' + $Client + ' - ' + '{0:yyyy-MM-dd}' -f (Get-Date))
                           $Credential = New-Object -TypeName System.Management.Automation.PSCredential('eohrt_vm_storage@eoh.com',(ConvertTo-SecureString -String 'v3Rystr0nGP@ssword2019' -AsPlainText -Force))
                  [String] $Body       = Get-Content $File

    # Resolve the IP of the SMTP Server
    $IP = [System.Net.Dns]::GetHostAddresses($SMTPServer)| Select-Object IPAddressToString -Expandproperty IPAddressToString
    If ($IP.GetType().Name -eq 'Object[]') { $IP = $IP[0] }
    # Test connectivity to port 587 and 25 respectively
    $TCPClient = New-Object Net.Sockets.TcpClient
    # We use Try\Catch to remove exception info from console if we can't connect
    Try {
        $TCPClient.Connect($IP, 587)
    } 
    Catch { }

    If ($TCPClient.Connected) {
        $TCPClient.Close()
        $SMTPPort = 587
    }
    Else {
        Try {
            $TCPClient.Connect($IP, 25)
        } 
        Catch { }
        
        If ($TCPClient.Connected) {
            $TCPClient.Close()
            $SMTPPort = 25
        }             
        Else { 
            Return $False
        }            
    }
    Send-MailMessage -From $From -BodyAsHtml -Body $Body -SmtpServer $SMTPServer -Subject $Subject -To $To -Port $SMTPPort -Attachments $File -Credential $Credential
}