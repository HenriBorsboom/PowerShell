Function Get-VMNetworkName {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $RoutingDomainID)

    $SCVMNetwork = Get-SCVMNetwork | Where RoutingDomainID -eq $RoutingDomainID
    Return $SCVMNetwork.Name
}
Function Get-VMNameFromIP {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $SCVMNetworkName, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $VMIPAddress)
            
    
    $ReturnVMName = $SCVMNames | Where-Object { $_.VMNetwork -like "$SCVMNetworkName*" -and $_.IPv4Addresses -like $VMIPAddress } | Select Name
    Return $ReturnVMName.Name
}
Function Get-NATSessions {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String[]] $GatewayServers)

    $SecurePWD = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force
    $Credentials = New-Object PSCredential("localadmin",$SecurePWD)
    
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
    ForEach ($GatewayServer in $GatewayServers) {
        Write-Host "Collecting NAT Sesssions on - " -NoNewline; Write-Host $GatewayServer -ForegroundColor Yellow -NoNewline; Write-Host " - " -NoNewline
        If ($GatewayServer -eq "RRAS-01") { $NATSessions = Invoke-Command -Credential $Credentials -ComputerName $GatewayServer -ScriptBlock { Get-NetNatSession -Verbose } }
        Else { $NATSessions = Invoke-Command -Computername $GatewayServer -ScriptBlock { Get-NetNatSession -Verbose } }
        
        $VMNetworkName = ""
        $VMName = ""
        ForEach ($NATSession in $NATSessions) {
            If ($NATSession.Protocol -eq 6) { break; $NATSessionProtocol = "TCP" }
            ElseIf ($NATSession.Protocol -eq 17) { $NATSessionProtocol = "UDP" }
            Else { $NATSessionProtocol = $NATSession.Protocol }
            
            If ($VMNetworkName -ne $NATSession.NatName) { $VMNetworkName = Get-VMNetworkName -RoutingDomainID $NATSession.NatName }
            If ($VMName -ne $NATSession.InternalSourceAddress) { $VMName = Get-VMNameFromIP -SCVMNetworkName $VMNetworkName -VMIPAddress $NATSession.InternalSourceAddress }
            
            $SingleNATSession = New-Object PSObject -Property @{
                "Gateway Server"               = $GatewayServer;
                "VM Network Name"              = $VMNetworkName;
                #"Nat Name"                     = $NATSession.NatName;
                #"Internal Routing Domain Id"   = $NATSession.InternalRoutingDomainId;
                "Creation Time"                = $NATSession.CreationTime;
                "Protocol"                     = $NATSessionProtocol;
                "VM Name"                      = $VMName;
                "Internal Source Address"      = $NATSession.InternalSourceAddress;
                "Internal Source Port"         = $NATSession.InternalSourcePort;
                "Internal Destination Address" = $NATSession.InternalDestinationAddress;
                "Internal Destination Port"    = $NATSession.InternalDestinationPort;
                "External Source Address"      = $NATSession.ExternalSourceAddress;
                "External Source Port"         = $NATSession.ExternalSourcePort;
                "External Destination Address" = $NATSession.ExternalDestinationAddress;
                "External Destination Port"    = $NATSession.ExternalDestinationPort;
            }
            $AllNATSessions += $SingleNATSession
        }
        $VMNetworkName = $null
        $VMName = $null
        Write-Host "Complete" -ForegroundColor Green
    }
    $AllNATSessions = $AllNATSessions | Sort InternalSourceAddress | `
        Select `
            "Gateway Server", `
            "VM Network Name", `
#            "Nat Name", `
#            "Internal Routing Domain Id", `
            "Creation Time", `
            "Protocol", `
            "VM Name", `
            "Internal Source Address", `
            "Internal Source Port", `
            "Internal Destination Address", `
            "Internal Destination Port", `
            "External Source Address", `
            "External Source Port", `
            "External Destination Address", `
            "External Destination Port"
    $HTMLOutput = $AllNATSessions | ConvertTo-Html -Body $HTMLBody -Head $HTMLHeader
    $HTMLOutput | Out-File C:\Temp\NAT.HTML -Force
    Invoke-Expression C:\Temp\NAT.HTML
}

Clear-Host

Write-Host "Getting list of ALL Virtual Machines - " -NoNewline
    $SCVirtualMachine = Get-SCVirtualMachine
    $SCVMNames = @()
    ForEach ($SCVM in $SCVirtualMachine) {
        $SCVMName = $SCVM | Select -expand VirtualNetworkAdapters | Select VMNetwork, IPv4Addresses, Name
        $SCVMNames += $SCVMName
    }
Write-Host "Complete" -ForegroundColor Green

Get-NATSessions -GatewayServer @("RRAS-01")


