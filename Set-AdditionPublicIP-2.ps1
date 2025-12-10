#Function Set-AdditionalPublicIPs {
Param (
    [Parameter(Mandatory=$True,Position=1)]
    [ValidateScript({$_ -match [IPAddress] $_})] [String] $CurrentPublicIPAddress, `
    [Parameter(Mandatory=$True,Position=2)]
    [ValidateScript({$_ -match [IPAddress] $_})] [String] $VMPrivateIP, `
    [Parameter(Mandatory=$True,Position=3)]
    [ValidateScript({$_ -match [IPAddress] $_})] [String] $NewPublicIPAddress, `
    [Parameter(Mandatory=$True,Position=4)]
    [ValidateRange(1,65535)] [Int32] $StartNATPort, `
    [Parameter(Mandatory=$True,Position=5)]
    [ValidateRange(1,65535)] [ValidateScript({$_ -eq [Int32] $StartNATPort -or $_ -gt [Int32] $StartNATPort})] [Int32] $EndNATPort, `
    [Parameter(Mandatory=$false,Position=6)]
    [Switch] $FullRange, `
    [Parameter(Mandatory=$false,Position=7)]
    [Switch] $SetPorts, `
    [Parameter(Mandatory=$false,Position=8)]
    [Switch] $Ports)

#region Validate Variables
Switch ($FullRange) {
    $true{$StartNATPort = 1; $EndNATPort = 65535}
    $false{
        If (![ValidateRange(1,65535)] $StartNATPort) {
            Try {
                [ValidateRange(1,65535)] 
                [Int32] $StartNATPort = Read-Host "Start NAT Port (1 - 65535): " -ErrorAction Stop
                
                [ValidateRange(1,65535)] 
                [ValidateScript({$_ -eq [Int32] $StartNATPort -or $_ -gt [Int32] $StartNATPort})] 
                [Int32] $EndNATPort = Read-Host "End NAT Port ($StartNATPort - 65535): " -ErrorAction Stop
            }
            Catch {
                Write-OutPut $_
                Break
            }
        }
    }
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
Try {
    Write-Host "Adding $NewPublicIPAddress to NAT Name: $NATName with Start Port 1 and End Port 65535 - " -NoNewline -ErrorAction Stop
        $Empty = Add-NetNatExternalAddress -NatName $NATName -IPAddress $NewPublicIPAddress -PortStart 1 -PortEnd 65535 -ErrorAction Continue
    Write-Host "Complete" -ForegroundColor Green -ErrorAction Stop
}
Catch {
    Write-Host "Failed" -ForegroundColor Red
    Write-Output $_
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
}

#endregion
#}

#Clear-Host
#Set-AdditionalPublicIPs `
#-CurrentPublicIPAddress "198.51.100.10" `
#-VMPrivateIP "10.1.16.12" `
#-NewPublicIPAddress "198.51.100.11" `
#-StartNATPort "4024" `
#-EndNATPort "47999"