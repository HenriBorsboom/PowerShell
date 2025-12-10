Function Get-DHCPServers {
    #$DHCPInfo = Get-ADObject -SearchBase “cn=configuration,dc=eohcorp,dc=net” -Filter 'objectclass -eq "dhcpclass"' | ForEach-Object {$_.Name.Replace('.eohcorp.net','')} | sort Name
    $DHCPInfo = Get-ADObject -SearchBase “cn=configuration,dc=eohcorp,dc=net” -Filter 'objectclass -eq "dhcpclass"' | Select Name | ForEach-Object {$_.Name.Replace('.eohcorp.net','')} | Sort
    $ReturnInfo = @()
    ForEach ($Entry in $DHCPInfo) { 
        If (!($Entry -eq 'DhcpRoot')) { 
            $ReturnInfo += ,($Entry) 
        }
    }
    Return $ReturnInfo
}
Function Get-DomainDCs {
    $getdomain = [System.Directoryservices.Activedirectory.Domain]::GetCurrentDomain()
    $DCInfo = $getdomain | ForEach-Object {$_.DomainControllers} | ForEach-Object {
        $hEntry = [System.Net.Dns]::GetHostByName($_.Name)
        New-Object -TypeName PSObject -Property @{
            Name = $_.Name.Replace('.eohcorp.net', '')
            IPAddress = $hEntry.AddressList[0].IPAddressToString
        }
    }
    Return $DCInfo
}
Function Get-ADConnectServers {
    $ADConnectServers = Get-ADUser -LDAPFilter "(description=*Account created by*)" -Properties description | `
        Select Name, Enabled, @{
            Name='Description';
            Expression={`
                $_.Description.Replace('Account created by the Windows Azure Active Directory Sync tool with installation ', '').`
                Replace('. This account must have directory replication permissions in the local Active Directory and write permission on certain attributes to enable Hybrid Deployment.', '').`
                Replace('running ', '').`
                Replace('computer ','')}
            }
    Return $ADConnectServers
}
Function Send-Details {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Body, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $Attachment)

     # Resolve the IP of the SMTP Server
    $IP = [System.Net.Dns]::GetHostAddresses('za-smtp-outbound-1.mimecast.co.za')| Select-Object IPAddressToString -Expandproperty IPAddressToString
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
    }
    
    $Credential    = New-Object -TypeName System.Management.Automation.PSCredential('eohrt_vm_storage@eoh.com',(ConvertTo-SecureString -String 'v3Rystr0nGP@ssword2019' -AsPlainText -Force))
    #[String] $Body = Get-Content $OutFile

    $Subject = ('AD Script - ' + '{0:yyyy-MM-dd}' -f (Get-Date))
    Send-MailMessage `
        -From 'eohrt_vm_storage@eoh.com' `
        -Body $Body `
        -SmtpServer 'za-smtp-outbound-1.mimecast.co.za' `
        -Subject $Subject `
        -To 'henri.borsboom@eoh.com' `
        -Port $SMTPPort `
        -Credential $Credential `
        -Attachment $Attachment

}
Function Compile-Body {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $DCInfo,`
        [Parameter(Mandatory=$True, Position=2)]
        [Object[]] $ADConnectServers, `
        [Parameter(Mandatory=$True, Position=3)]
        [Object[]] $DHCPInfo)
    
    [String] $DCInfoString = "Name`tIPAddress`n"

    ForEach ($Entry in $DCInfo) {
        $DCInfoString += ($Entry.Name + "`t" + $Entry.IPAddress + "`n")
    }

    [String] $ADConnectString = "Name`tEnabled`tDescription`n"

    ForEach ($Entry in $ADConnectServers) {
        $ADConnectString += ($Entry.Name + "`t" + $Entry.Enabled + "`t" + $Entry.Description + "`n")
    }

    [String] $DHCPInfoString = "Name`n"

    ForEach ($Entry in $DHCPInfo) {
        $DHCPInfoString += ($Entry + "`n")
    }

    [String] $Body = ""
    $Body = "Domain Controllers`n`n"
    $Body += $DCInfoString
    $Body += ("Domain Controller Count`t" + $DCInfo.Count)
    $Body += "`n`n"
    $Body += "`n`nADConnect Servers`n`n"
    $Body += $ADConnectString
    $Body += ("AD Connect Count`t" + $ADConnectServers.Count)
    $Body += "`n`n"
    $Body += "`n`nDHCP Servers`n`n"
    $Body += $DHCPInfoString
    $Body += "Count`t" + $DHCPInfo.Count

    Return $Body
}
Function Compare-DHCPtoDC {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [object[]] $DCInfo, `
        [Parameter(Mandatory=$True, Position=2)]
        [object[]] $DHCPInfo)

    $ReturnDHCPServerList = @()

    ForEach ($DHCPServer in $DHCPInfo) {
        If ($DCInfo.Contains($DHCPServer)) { }
        Else {
            $ReturnDHCPServerList += $DHCPServer
        }
    }
    $ReturnDHCPServerList
}

$OutFile = ('C:\Temp\AD Details - ' + '{0:yyyy-MM-dd}' -f (Get-Date) + ' .txt')

"Domain Controllers" | Out-File $OutFile -Force
$DCInfo = Get-DomainDCs
$DCInfo | Out-File $OutFile -Append
("Domain Controllers Count:" + $DCInfo.Count) | Out-File $OutFile -Append
"AD Connect Servers" | Out-File $OutFile -Append
$ADConnectServers = Get-ADConnectServers
$ADConnectServers | Out-File $OutFile -Append
$DHCPInfo = Compare-DHCPtoDC -DCInfo $DCInfo -DHCPInfo (Get-DHCPServers)
("AD Connect Servers Count:" + $ADConnectServers.Count) | Out-File $OutFile -Append
"DHCP Servers" | Out-File $OutFile -Append
$DHCPInfo | Out-File $OutFile -Append
$Body = Compile-Body -DCInfo $DCInfo -ADConnectServers $ADConnectServers -DHCPInfo $DHCPInfo
("DHCP Servers:" + $DHCPInfo.Count) | Out-File $OutFile -Append
Send-Details -Body $Body -Attachment $OutFile