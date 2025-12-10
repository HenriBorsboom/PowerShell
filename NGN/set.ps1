Function Set-AdditionalPublicIPs {
Param (
    [Parameter(Mandatory=$True,Position=1)]
    [ValidateScript({$_ -match [IPAddress] $_})] [String] $CurrentPublicIPAddress, `
    [Parameter(Mandatory=$True,Position=2)]
    [ValidateScript({$_ -match [IPAddress] $_})] [String] $VMPrivateIP, `
    [Parameter(Mandatory=$True,Position=3)]
    [ValidateScript({$_ -match [IPAddress] $_})] [String] $NewPublicIPAddress, `
    [Parameter(Mandatory=$false,Position=4)]
    [ValidateRange(1,65535)] [Int32] $StartNATPort, `
    [Parameter(Mandatory=$false,Position=5)]
    [ValidateRange(1,65535)]  [Int32] $EndNATPort, `
    [Parameter(Mandatory=$false,Position=6)]
    [Switch] $FullRange, `
    [Parameter(Mandatory=$false,Position=7)]
    [Switch] $SetPorts, `
    [Parameter(Mandatory=$false,Position=8)]
    [String[]] $Ports, `
    [Parameter(Mandatory=$True, Position=1)]
    [String] $NATName, `
    [Parameter(Mandatory=$false,Position=9)]
    [String] $Protocol, `
    [Parameter(Mandatory=$false,Position=10)]
    [Switch] $AddNAT)

#region Validate Variables
Switch ($FullRange) {
    $true{$StartNATPort = 1; $EndNATPort = 65535}
    #$false{
    #    If (![ValidateRange(1,65535)] $StartNATPort) {
    #        Try {
    #            [ValidateRange(1,65535)] 
    #            [Int32] $StartNATPort = Read-Host "Start NAT Port (1 - 65535): " -ErrorAction Stop
    #            
    #            [ValidateRange(1,65535)] 
    #            [ValidateScript({$_ -eq [Int32] $StartNATPort -or $_ -gt [Int32] $StartNATPort})] 
    #            [Int32] $EndNATPort = Read-Host "End NAT Port ($StartNATPort - 65535): " -ErrorAction Stop
    #        }
    #        Catch {
    #            Write-OutPut $_
    #            Break
    #        }
    #    }
    #}
}
#endregion
#region Get NAT Name
#Try {
#    $GetNATName = Get-NetNatExternalAddress | where {$_.IPAddress -eq $CurrentPublicIPAddress} -ErrorAction Stop
#    [String] $NATName = $GetNATName.Natname
#}
#Catch {
#    Write-OutPut $_
#    Break
#}
#endregion
#region Add Public IP to VM Network
Switch ($AddNAT) {
    $true {
        Try {
            Write-Host "Adding $NewPublicIPAddress to NAT Name: $NATName with Start Port 1 and End Port 65535 - " -NoNewline -ErrorAction Stop
                $Empty = Add-NetNatExternalAddress -NatName $NATName -IPAddress $NewPublicIPAddress -PortStart 1 -PortEnd 65535 -ErrorAction Continue
            Write-Host "Complete" -ForegroundColor Green -ErrorAction Stop
        }
        Catch {
            Write-Host "Failed" -ForegroundColor Red
            Write-Output $_
        }
    }
}
#endregion
#region Open NAT Ports
Switch ($SetPorts) {
    $true {
        Try {
            ForEach ($NATPort in $Ports) {
                Write-Host "Adding $NATPort to $NewPublicIPAddress / $VMPrivateIP on NAT Name: $NATName - " -NoNewline -ErrorAction Stop
                    $Results = Add-NetNatStaticMapping -NatName $NATName -Protocol $Protocol -ExternalIPAddress $NewPublicIPAddress -ExternalPort $NATPort -InternalIPAddress $VMPrivateIP -InternalPort $NATPort -ErrorAction Stop
                If ($Results.Active -eq "True") {Write-Host "Active - Complete" -ForegroundColor Green}
                Else {Write-Host $Results.Active "- Incomplete" -ForegroundColor Yellow}
            }
        }
        Catch {
                Write-Host "Failed" -ForegroundColor Red
                Write-Output $_
                Break
        }
    }
    $False {
        Try {
            For ($NATPort = $StartNATPort; $NATPort -lt ($EndNATPort + 1); $NATPort ++) {
                Write-Host "Adding $NATPort to $NewPublicIPAddress / $VMPrivateIP on NAT Name: $NATName - " -NoNewline -ErrorAction Stop
                    $Results = Add-NetNatStaticMapping -NatName $NATName -Protocol $Protocol -ExternalIPAddress $NewPublicIPAddress -ExternalPort $NATPort -InternalIPAddress $VMPrivateIP -InternalPort $NATPort -ErrorAction Stop
                If ($Results.Active -eq "True") {Write-Host "Active - Complete" -ForegroundColor Green}
                Else {Write-Host $Results.Active "- Incomplete" -ForegroundColor Yellow}
            }
        }
        Catch {
                Write-Host "Failed" -ForegroundColor Red
                Write-Output $_
                Break
        }
    }
}

#endregion
}

Clear-Host

$CurrentPublicIP = "198.51.100.10"
$GetNATName = Get-NetNatExternalAddress | where {$_.IPAddress -eq $CurrentPublicIP} -ErrorAction Stop; [String] $NATName = $GetNATName.NatName

Function SetIP184 {

$CurrentPublicIP = "198.51.100.10"
$GetNATName = Get-NetNatExternalAddress | where {$_.IPAddress -eq $CurrentPublicIP} -ErrorAction Stop; [String] $NATName = $GetNATName.NatName

$NewPublicIP     = "165.233.158.184"
$VMIP            = "10.1.16.12"
$Protocol        = "UDP"
$StartPort       = "49152"
$EndPort         = "65535"
$Ports = @("5060")

#165.233.158.184	10.1.16.12	UDP	49152-65535
#165.233.158.184	10.1.16.12	UDP	@("5060")

#Set-AdditionalPublicIPs -NATName $NATName -CurrentPublicIPAddress $CurrentPublicIP -VMPrivateIP $VMIP -NewPublicIPAddress $NewPublicIP -StartNATPort $StartPort -EndNATPort $EndPort -Protocol $Protocol -AddNAT
Set-AdditionalPublicIPs -NATName $NATName -CurrentPublicIPAddress $CurrentPublicIP -VMPrivateIP $VMIP -NewPublicIPAddress $NewPublicIP -SetPorts -Ports $Ports -Protocol $Protocol
} # 01 Done
Function SetIP185 {

$NewPublicIP     = "165.233.158.185"
$VMIP            = "10.12.16.11"
$Protocol        = "UDP"
$StartPort       = "49152"
$EndPort         = "65535"
$Ports = @("5060")

#165.233.158.185	10.12.16.11	UDP	49152-65535
#165.233.158.185	10.12.16.11	UDP	@("5060")

#Set-AdditionalPublicIPs -NATName $NATName -CurrentPublicIPAddress $CurrentPublicIP -VMPrivateIP $VMIP -NewPublicIPAddress $NewPublicIP -StartNATPort $StartPort -EndNATPort $EndPort -Protocol $Protocol -AddNAT
Set-AdditionalPublicIPs -NATName $NATName -CurrentPublicIPAddress $CurrentPublicIP -VMPrivateIP $VMIP -NewPublicIPAddress $NewPublicIP -SetPorts -Ports $Ports -Protocol $Protocol
} # 02 Done
Function SetIP041 {

$NewPublicIP     = "165.233.158.41"
$VMIP            = "10.12.16.32"
$Protocol        = "TCP"
$Ports = @("25","80","110","443","587","995")

#165.233.158.41	10.12.16.32	TCP	@("25","80","110","443","587","995")

Set-AdditionalPublicIPs -NATName $NATName -CurrentPublicIPAddress $CurrentPublicIP -VMPrivateIP $VMIP -NewPublicIPAddress $NewPublicIP -SetPorts -Ports $Ports -Protocol $Protocol -AddNAT
} # 04
Function SetIP042 {

$NewPublicIP     = "165.233.158.42"
$VMIP            = "10.12.16.43"
$Protocol        = "TCP"
$Ports = @("25","80","110","443","587","995")

#165.233.158.42	10.12.16.43	TCP	@("25","80","110","443","587","995")

Set-AdditionalPublicIPs -NATName $NATName -CurrentPublicIPAddress $CurrentPublicIP -VMPrivateIP $VMIP -NewPublicIPAddress $NewPublicIP -SetPorts -Ports $Ports -Protocol $Protocol -AddNAT
} # 05
Function SetIP043 {

$NewPublicIP     = "165.233.158.43"
$VMIP            = "10.12.16.27"
$Protocol        = "TCP"
$Ports = @("25","80","110","443","587","995")

#165.233.158.43	10.12.16.27	TCP	@("25","80","110","443","587","995")

Set-AdditionalPublicIPs -NATName $NATName -CurrentPublicIPAddress $CurrentPublicIP -VMPrivateIP $VMIP -NewPublicIPAddress $NewPublicIP -SetPorts -Ports $Ports -Protocol $Protocol -AddNAT
} # 06
Function SetIP044 {

$NewPublicIP     = "165.233.158.44"
$VMIP            = "10.12.16.30"
$Protocol        = "TCP"
$Ports = @("25","80","110","443","587","995")

#165.233.158.44	10.12.16.30	TCP	@("25","80","110","443","587","995")

Set-AdditionalPublicIPs -NATName $NATName -CurrentPublicIPAddress $CurrentPublicIP -VMPrivateIP $VMIP -NewPublicIPAddress $NewPublicIP -SetPorts -Ports $Ports -Protocol $Protocol -AddNAT
} # 07
Function SetIP045 {

$NewPublicIP     = "165.233.158.45"
$VMIP            = "10.12.16.17"
$Protocol        = "TCP"
$Ports = @("25","80","110","443","587","995")

#165.233.158.45	10.12.16.17	TCP	@("25","80","110","443","587","995")

Set-AdditionalPublicIPs -NATName $NATName -CurrentPublicIPAddress $CurrentPublicIP -VMPrivateIP $VMIP -NewPublicIPAddress $NewPublicIP -SetPorts -Ports $Ports -Protocol $Protocol -AddNAT
} # 08
Function SetIP046 {

$NewPublicIP     = "165.233.158.46"
$VMIP            = "10.12.16.20"
$Protocol        = "TCP"
$Ports = @("25","80","110","443","587","995")

#165.233.158.46	10.12.16.20	TCP	@("25","80","110","443","587","995")

Set-AdditionalPublicIPs -NATName $NATName -CurrentPublicIPAddress $CurrentPublicIP -VMPrivateIP $VMIP -NewPublicIPAddress $NewPublicIP -SetPorts -Ports $Ports -Protocol $Protocol -AddNAT
} # 09
Function SetIP047 {
$NewPublicIP     = "165.233.158.47"
$VMIP            = "10.12.16.34"
$Protocol        = "TCP"
$Ports = @("25","80","110","443","587","995")

#165.233.158.47	10.12.16.34	TCP	@("25","80","110","443","587","995")

Set-AdditionalPublicIPs -NATName $NATName -CurrentPublicIPAddress $CurrentPublicIP -VMPrivateIP $VMIP -NewPublicIPAddress $NewPublicIP -SetPorts -Ports $Ports -Protocol $Protocol -AddNAT
} # 10
Function SetIP048 {
$NewPublicIP     = "165.233.158.48"
$VMIP            = "10.12.16.35"
#$Protocol        = "TCP"
#$Ports = @("25","80","110","443","587","995","53")

#165.233.158.48	10.12.16.35	TCP	@("25","80","110","443","587","995","53")

#Set-AdditionalPublicIPs -NATName $NATName -CurrentPublicIPAddress $CurrentPublicIP -VMPrivateIP $VMIP -NewPublicIPAddress $NewPublicIP -SetPorts -Ports $Ports -Protocol $Protocol -AddNAT
$Protocol        = "UDP"
$Ports = @("53")
Set-AdditionalPublicIPs -NATName $NATName -CurrentPublicIPAddress $CurrentPublicIP -VMPrivateIP $VMIP -NewPublicIPAddress $NewPublicIP -SetPorts -Ports $Ports -Protocol $Protocol
} # 11 Issue
Function SetIP049 {
$NewPublicIP     = "165.233.158.49"
$VMIP            = "10.12.16.41"
$Protocol        = "TCP"
$Ports = @("25","80","110","443","587","995")

#165.233.158.49	10.12.16.41	TCP	@("25","80","110","443","587","995")

Set-AdditionalPublicIPs -NATName $NATName -CurrentPublicIPAddress $CurrentPublicIP -VMPrivateIP $VMIP -NewPublicIPAddress $NewPublicIP -SetPorts -Ports $Ports -Protocol $Protocol -AddNAT
} # 12
Function SetIP050 {
$NewPublicIP     = "165.233.158.50"
$VMIP            = "10.12.16.22"
$Protocol        = "TCP"
$Ports = @("25","80","110","443","587","995")

#165.233.158.50	10.12.16.22	TCP	@("25","80","110","443","587","995")

Set-AdditionalPublicIPs -NATName $NATName -CurrentPublicIPAddress $CurrentPublicIP -VMPrivateIP $VMIP -NewPublicIPAddress $NewPublicIP -SetPorts -Ports $Ports -Protocol $Protocol -AddNAT
} # 13
Function SetIP051 {
$NewPublicIP     = "165.233.158.51"
$VMIP            = "10.12.16.25"
$Protocol        = "TCP"
$Ports = @("25","80","110","443","587","995")

#165.233.158.51	10.12.16.25	TCP	@("25","80","110","443","587","995")

Set-AdditionalPublicIPs -NATName $NATName -CurrentPublicIPAddress $CurrentPublicIP -VMPrivateIP $VMIP -NewPublicIPAddress $NewPublicIP -SetPorts -Ports $Ports -Protocol $Protocol -AddNAT
} # 14
Function SetIP052 {
$NewPublicIP     = "165.233.158.52"
$VMIP            = "10.12.16.13"
$Protocol        = "TCP"
$Ports = @("25","80","110","443","587","995")

#165.233.158.52	10.12.16.13	TCP	@("25","80","110","443","587","995")

Set-AdditionalPublicIPs -NATName $NATName -CurrentPublicIPAddress $CurrentPublicIP -VMPrivateIP $VMIP -NewPublicIPAddress $NewPublicIP -SetPorts -Ports $Ports -Protocol $Protocol -AddNAT
} # 15

SetIP184
