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
Try {
    $GetNATName = Get-NetNatExternalAddress | where {$_.IPAddress -eq $CurrentPublicIPAddress} -ErrorAction Stop
    [String] $NATName = $GetNATName.Natname
}
Catch {
    Write-OutPut $_
    Break
}
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
                    $Results = Add-NetNatStaticMapping -NatName $NATName -Protocol TCP -ExternalIPAddress $NewPublicIPAddress -ExternalPort $NATPort -InternalIPAddress $VMPrivateIP -InternalPort $NATPort -ErrorAction Stop
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

#Clear-Host
#Set-AdditionalPublicIPs `
#-CurrentPublicIPAddress "198.51.100.10" `
#-VMPrivateIP "10.1.16.12" `
#-NewPublicIPAddress "198.51.100.11" `
#-StartNATPort "4024" `
#-EndNATPort "47999"

#Set-AdditionalPublicIPs -CurrentPublicIPAddress "198.51.100.10" -VMPrivateIP "10.1.16.12" -NewPublicIPAddress "165.233.158.184" -StartNATPort "5060" -EndNATPort "5060" -Protocol "UDP"
#Set-AdditionalPublicIPs -CurrentPublicIPAddress "198.51.100.10" -VMPrivateIP "10.12.16.11" -NewPublicIPAddress "165.233.158.185" -StartNATPort "5060" -EndNATPort "5060" -Protocol "UDP"
#$ClientPorts = @("25","80","110","443","587","995")
#Set-AdditionalPublicIPs -CurrentPublicIPAddress "198.51.100.10" -VMPrivateIP "10.12.16.42" -NewPublicIPAddress "165.233.158.40" -SetPorts -Ports $ClientPorts -Protocol "TCP" -AddNAT
#Set-AdditionalPublicIPs -CurrentPublicIPAddress "198.51.100.10" -VMPrivateIP "10.12.16.32" -NewPublicIPAddress "165.233.158.41" -SetPorts -Ports $ClientPorts -Protocol "TCP" -AddNAT
#Set-AdditionalPublicIPs -CurrentPublicIPAddress "198.51.100.10" -VMPrivateIP "10.12.16.43" -NewPublicIPAddress "165.233.158.42" -SetPorts -Ports $ClientPorts -Protocol "TCP" -AddNAT
#Set-AdditionalPublicIPs -CurrentPublicIPAddress "198.51.100.10" -VMPrivateIP "10.12.16.27" -NewPublicIPAddress "165.233.158.43" -SetPorts -Ports $ClientPorts -Protocol "TCP" -AddNAT
#Set-AdditionalPublicIPs -CurrentPublicIPAddress "198.51.100.10" -VMPrivateIP "10.12.16.30" -NewPublicIPAddress "165.233.158.44" -SetPorts -Ports $ClientPorts -Protocol "TCP" -AddNAT
#Set-AdditionalPublicIPs -CurrentPublicIPAddress "198.51.100.10" -VMPrivateIP "10.12.16.17" -NewPublicIPAddress "165.233.158.45" -SetPorts -Ports $ClientPorts -Protocol "TCP" -AddNAT
#Set-AdditionalPublicIPs -CurrentPublicIPAddress "198.51.100.10" -VMPrivateIP "10.12.16.20" -NewPublicIPAddress "165.233.158.46" -SetPorts -Ports $ClientPorts -Protocol "TCP" -AddNAT
#Set-AdditionalPublicIPs -CurrentPublicIPAddress "198.51.100.10" -VMPrivateIP "10.12.16.34" -NewPublicIPAddress "165.233.158.47" -SetPorts -Ports $ClientPorts -Protocol "TCP" -AddNAT
#Set-AdditionalPublicIPs -CurrentPublicIPAddress "198.51.100.10" -VMPrivateIP "10.12.16.35" -NewPublicIPAddress "165.233.158.48" -SetPorts -Ports $ClientPorts -Protocol "TCP" -AddNAT
#Set-AdditionalPublicIPs -CurrentPublicIPAddress "198.51.100.10" -VMPrivateIP "10.12.16.41" -NewPublicIPAddress "165.233.158.49" -SetPorts -Ports $ClientPorts -Protocol "TCP" -AddNAT
#Set-AdditionalPublicIPs -CurrentPublicIPAddress "198.51.100.10" -VMPrivateIP "10.12.16.22" -NewPublicIPAddress "165.233.158.50" -SetPorts -Ports $ClientPorts -Protocol "TCP" -AddNAT
#Set-AdditionalPublicIPs -CurrentPublicIPAddress "198.51.100.10" -VMPrivateIP "10.12.16.25" -NewPublicIPAddress "165.233.158.51" -SetPorts -Ports $ClientPorts -Protocol "TCP" -AddNAT
#Set-AdditionalPublicIPs -CurrentPublicIPAddress "198.51.100.10" -VMPrivateIP "10.12.16.13" -NewPublicIPAddress "165.233.158.52" -SetPorts -Ports $ClientPorts -Protocol "TCP" -AddNAT


# NS1	10.12.16.35	165.233.158.48	UDP	53	53
Set-AdditionalPublicIPs -CurrentPublicIPAddress "198.51.100.10" -VMPrivateIP "10.12.16.35" -NewPublicIPAddress "165.233.158.48" -SetPorts -Ports @(53) -Protocol "UDP" -AddNAT