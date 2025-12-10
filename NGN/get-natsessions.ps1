Clear-Host

$HTMLHeader="<style>                                               
    BODY{font-family: Arial; font-size: 8pt;}                                              
    H1{font-size: 16px;}                                               
    H2{font-size: 14px;}                                               
    H3{font-size: 12px;}                                               
    TABLE{border: 1px solid black; border-collapse: collapse; font-size: 8pt;}                                         
    TH{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}                                           
    TD{border: 1px solid black; padding: 5px; }                                            
    td.pass{background: #7FFF00;}                                             
    td.warn{background: #FFE600;}                                             
    td.fail{background: #FF0000; color: #ffffff;}                                          
    </style>"
$HTMLBody = "<H2>Windows Azure Pack Tenants</H2>"

$AllNATSessions = @()
$AllTCPSessions = @()
$AllUDPSessions = @()
$NATSessions = Get-NetNatSession -Verbose

ForEach ($NATSession in $NATSessions) {
    $NATSessionProtocol = $NATSession.Protocol
    If ($NATSessionProtocol -eq 6) {
        $NATSessionProtocol = "TCP"
        $TCPNATSession = New-Object PSObject -Property @{
            NatName                    = $NATSession.NatName;
            InternalRoutingDomainId    = $NATSession.InternalRoutingDomainId;
            CreationTime               = $NATSession.CreationTime;
            Protocol                   = $NATSessionProtocol;
            InternalSourceAddress      = $NATSession.InternalSourceAddress;
            InternalSourcePort         = $NATSession.InternalSourcePort;
            InternalDestinationAddress = $NATSession.InternalDestinationAddress;
            InternalDestinationPort    = $NATSession.InternalDestinationPort;
            ExternalSourceAddress      = $NATSession.ExternalSourceAddress;
            ExternalSourcePort         = $NATSession.ExternalSourcePort;
            ExternalDestinationAddress = $NATSession.ExternalDestinationAddress;
            ExternalDestinationPort    = $NATSession.ExternalDestinationPort;
        }
        $TCPNATSession = $TCPNATSession | Select NatName, InternalRoutingDomainId, CreationTime, Protocol, InternalSourceAddress, InternalSourcePort, InternalDestinationAddress, InternalDestinationPort, `
        ExternalSourceAddress, ExternalSourcePort, ExternalDestinationAddress, ExternalDestinationPort
        $AllTCPSessions = $AllTCPSessions + $TCPNATSession
        $AllNATSessions = $AllNATSessions + $TCPNATSession
    }
    ElseIf ($NATSessionProtocol -eq 17) {
        $NATSessionProtocol = "UDP"
        $UDPNATSession = New-Object PSObject -Property @{
            NatName                    = $NATSession.NatName;
            InternalRoutingDomainId    = $NATSession.InternalRoutingDomainId;
            CreationTime               = $NATSession.CreationTime;
            Protocol                   = $NATSessionProtocol;
            InternalSourceAddress      = $NATSession.InternalSourceAddress;
            InternalSourcePort         = $NATSession.InternalSourcePort;
            InternalDestinationAddress = $NATSession.InternalDestinationAddress;
            InternalDestinationPort    = $NATSession.InternalDestinationPort;
            ExternalSourceAddress      = $NATSession.ExternalSourceAddress;
            ExternalSourcePort         = $NATSession.ExternalSourcePort;
            ExternalDestinationAddress = $NATSession.ExternalDestinationAddress;
            ExternalDestinationPort    = $NATSession.ExternalDestinationPort;
        }
        $UDPNATSession = $UDPNATSession | Select NatName, InternalRoutingDomainId, CreationTime, Protocol, InternalSourceAddress, InternalSourcePort, InternalDestinationAddress, InternalDestinationPort, `
        ExternalSourceAddress, ExternalSourcePort, ExternalDestinationAddress, ExternalDestinationPort
        $AllUDPSessions = $ALLUDPSessions + $UDPNATSession
        $AllNATSessions = $AllNATSessions + $UDPNATSession
    }
    
}

$AllTCPSessions = $AllTCPSessions | Sort InternalSourceAddress | Select NatName, InternalRoutingDomainId, CreationTime, Protocol, InternalSourceAddress, InternalSourcePort, InternalDestinationAddress, InternalDestinationPort, `
ExternalSourceAddress, ExternalSourcePort, ExternalDestinationAddress, ExternalDestinationPort
$TCPHTMLOutput = $AllTCPSessions | ConvertTo-Html -Body $HTMLBody -Head $HTMLHeader

$AllUDPSessions = $AllUDPSessions | Sort InternalSourceAddress | Select NatName, InternalRoutingDomainId, CreationTime, Protocol, InternalSourceAddress, InternalSourcePort, InternalDestinationAddress, InternalDestinationPort, `
ExternalSourceAddress, ExternalSourcePort, ExternalDestinationAddress, ExternalDestinationPort
$UDPHTMLOutput = $AllUDPSessions | ConvertTo-Html -Body $HTMLBody -Head $HTMLHeader

$AllNATSessions = $AllNATSessions | Sort InternalSourceAddress | Select NatName, InternalRoutingDomainId, CreationTime, Protocol, InternalSourceAddress, InternalSourcePort, InternalDestinationAddress, InternalDestinationPort, `
ExternalSourceAddress, ExternalSourcePort, ExternalDestinationAddress, ExternalDestinationPort
$ALLHTMLOutput = $AllNATSessions | ConvertTo-Html -Body $HTMLBody -Head $HTMLHeader

$TCPHTMLOutput | Out-File .\TCPNAT.HTML
$UDPHTMLOutput | Out-File .\UDPNAT.HTML
$ALLHTMLOutput | Out-File .\ALLNAT.HTML

Invoke-Expression .\TCPNAT.HTML
Invoke-Expression .\UDPNAT.HTML
Invoke-Expression .\ALLNAT.HTML
