Function All-NATSessions {
    Param ($NATSessions)
    $HTMLBody = "<H2>Windows Azure Pack - All NAT Sessions</H2>"

    $AllNATSessions = @()
    ForEach ($NATSession in $NATSessions) {
        $NATSessionProtocol = $NATSession.Protocol
        If ($NATSessionProtocol -eq 6) { $NATSessionProtocol = "TCP" }
        ElseIf ($NATSessionProtocol -eq 17) { $NATSessionProtocol = "UDP" }
        $AllNATSession = New-Object PSObject -Property @{
            #NatName                    = $NATSession.NatName;
            #InternalRoutingDomainId    = $NATSession.InternalRoutingDomainId;
            #CreationTime               = $NATSession.CreationTime;
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
        $AllNATSessions = $AllNATSessions + $AllNATSession
    }

    #$AllNATSessions = $AllNATSessions | Sort InternalSourceAddress | Select NatName, InternalRoutingDomainId, CreationTime, Protocol, InternalSourceAddress, InternalSourcePort, InternalDestinationAddress, InternalDestinationPort, ExternalSourceAddress, ExternalSourcePort, ExternalDestinationAddress, ExternalDestinationPort
    $AllNATSessions = $AllNATSessions | Sort-Object InternalSourceAddress | Select-Object Protocol, InternalSourceAddress, InternalSourcePort, InternalDestinationAddress, InternalDestinationPort, ExternalSourceAddress, ExternalSourcePort, ExternalDestinationAddress, ExternalDestinationPort
    $ALLHTMLOutput = $AllNATSessions | ConvertTo-Html -Body $HTMLBody -Head $HTMLHeader
    $ALLHTMLOutput | Out-File .\AllNAT.HTML

    Invoke-Expression .\AllNAT.HTML
}
Function TCP-NATSessions {
    Param ($NATSessions)

    $HTMLBody = "<H2>Windows Azure Pack - TCP NAT Sessions</H2>"

    $AllTCPSessions = @()
    $PreviousInternalSoureAddress = $null
    ForEach ($NATSession in $NATSessions) {
        $NATSessionProtocol         = $NATSession.Protocol
        If ($NATSessionProtocol -eq 6) {
            $NATSessionProtocol = "TCP"
            $TCPNATSession = New-Object PSObject -Property @{
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
            #region NAT Output Selection
            $TCPNATSession = $TCPNATSession | Select-Object `
                CreationTime, `
                Protocol, `
                InternalSourceAddress, `
                InternalSourcePort, `
                InternalDestinationAddress, `
                InternalDestinationPort, `
                ExternalSourceAddress, `
                ExternalSourcePort, `
                ExternalDestinationAddress, `
                ExternalDestinationPort
            $AllTCPSessions = $AllTCPSessions + $TCPNATSession
            #endregion
        }
    }
    $PreviousInternalSoureAddress = $null

    $AllTCPSessions = $AllTCPSessions | Sort-Object InternalSourceAddress | Select-Object `
                CreationTime, `
                Protocol, `
                InternalSourceAddress, `
                InternalSourcePort, `
                InternalDestinationAddress, `
                InternalDestinationPort, `
                ExternalSourceAddress, `
                ExternalSourcePort, `
                ExternalDestinationAddress, `
                ExternalDestinationPort
    $TCPHTMLOutput = $AllTCPSessions | ConvertTo-Html -Body $HTMLBody -Head $HTMLHeader

    $TCPHTMLOutput | Out-File .\TCPNAT.HTML
    Invoke-Expression .\TCPNAT.HTML
}
Function UDP-NATSessions {
    Param ($NATSessions)
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
    $HTMLBody = "<H2>Windows Azure Pack - All UDP Sessions</H2>"

    $AllUDPSessions = @()
    ForEach ($NATSession in $NATSessions) {
        $NATSessionProtocol = $NATSession.Protocol
        If ($NATSessionProtocol -eq 17) {
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
            $UDPNATSession = $UDPNATSession | Select-Object NatName, InternalRoutingDomainId, CreationTime, Protocol, InternalSourceAddress, InternalSourcePort, InternalDestinationAddress, InternalDestinationPort, `
            ExternalSourceAddress, ExternalSourcePort, ExternalDestinationAddress, ExternalDestinationPort
            $AllUDPSessions = $ALLUDPSessions + $UDPNATSession
        }
    }
    $AllUDPSessions = $AllUDPSessions | Sort-Object InternalSourcePort | Select-Object `
            CreationTime, `
            Protocol, `
            InternalSourceAddress, `
            InternalSourcePort, `
            InternalDestinationAddress, `
            InternalDestinationPort, `
            ExternalSourceAddress, `
            ExternalSourcePort, `
            ExternalDestinationAddress, `
            ExternalDestinationPort
    $UDPHTMLOutput = $AllUDPSessions | ConvertTo-Html -Body $HTMLBody -Head $HTMLHeader

    $UDPHTMLOutput | Out-File .\UDPNAT.HTML
    Invoke-Expression .\UDPNAT.HTML
}

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
$NATSessions = Get-NetNatSession -Verbose
$NATSessions.Count

All-NATSessions -NATSessions $NATSessions
#TCP-NATSessions -NATSessions $NATSessions
#UDP-NATSessions -NATSessions $NATSessions



