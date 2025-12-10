Function Get-DHCPServers {
    $DHCPInfo = Get-ADObject -SearchBase “cn=configuration,dc=eohcorp,dc=net” -Filter 'objectclass -eq "dhcpclass"'
    $ReturnInfo = @()
    ForEach ($Entry in $DHCPInfo) { 
        If (!($Entry.Name -eq 'DhcpRoot')) { 
            $ReturnInfo += ,($Entry | Select @{Name="Name"; Expression={$Entry.Name.Replace('.eohcorp.net','')}})
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
Function Compare-DHCPtoDC {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [object[]] $DCInfo, `
        [Parameter(Mandatory=$True, Position=2)]
        [object[]] $DHCPInfo)

    $ReturnDHCPServerList = @()

    $ADandDHCPServers = Compare-Object $DHCPServers $DCInfo -Property Name -ExcludeDifferent -IncludeEqual

    If ($ADandDHCPServers.Count -gt 0) {
        ForEach ($Server in $DHCPInfo) {
            If ($ADandDHCPServers.Name.Contains($Server.Name)) { }
            Else {
                $ReturnDHCPServerList += $Server
            }
        }
        Return $ReturnDHCPServerList
    }
    Else {
        Return $DHCPInfo
    }
}
Function Make-Fragment {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $TableHeaders, `
        [Parameter(Mandatory=$True, Position=2)]
        [Object[]] $TableData, `
        [Parameter(Mandatory=$False, Position=3)]
        [Switch] $UpperCase)

    $FragmentStart =  "<table border = '1'> <colgroup> "
    For ($ColumnCount = 0; $ColumnCount -lt $TableHeaders.Count; $ColumnCount ++) {
        $FragmentStart +=  "<col/>"
    }
    $FragmentStart += "</colgroup>"
          
    $HeadersString = ""
    $TableString = ""
    $FragmentEnd = "</table>"
    
    $HeadersString += "<tr>"
    ForEach($Head in $TableHeaders) {
        $HeadersString += "<th>" + $Head + "</th>"
    }
    $HeadersString += "</tr>"
    Switch ($UpperCase) {
        $True {
            For ($RowCount = 0; $RowCount -lt $TableData.Count; $RowCount ++) {
                $TableString += "<tr>"
                For ($ColumnCount = 0; $ColumnCount -lt $TableHeaders.Count; $ColumnCount ++) {
                    $TableString += "<td>" + $TableData[$RowCount].($TableHeaders[$ColumnCount]).ToUpper() + "</td>"
                }
                $TableString += "</tr>"
            }
        }
        $False {
            For ($RowCount = 0; $RowCount -lt $TableData.Count; $RowCount ++) {
                $TableString += "<tr>"
                For ($ColumnCount = 0; $ColumnCount -lt $TableHeaders.Count; $ColumnCount ++) {
                    $TableString += "<td>" + $TableData[$RowCount].($TableHeaders[$ColumnCount]) + "</td>"
                }
                $TableString += "</tr>"
            }
        }
    }
    $Fragment = $FragmentStart + $HeadersString + $TableString + $FragmentEnd
    Return $Fragment
}
Function Compile-Body {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $DCInfo,`
        [Parameter(Mandatory=$True, Position=2)]
        [Object[]] $ADConnectServers, `
        [Parameter(Mandatory=$True, Position=3)]
        [Object[]] $DHCPInfo, `
        [Parameter(Mandatory=$True, Position=4)]
        [String] $OutFile)
    
    $Head = "<title>Active Directory Information</title>
        </head><body>"
    $Paragraph = "<p></p>"
    $Table1Header = "<H1 style='background-color:powderblue'>Domain Controllers</H1>"
    $Table1 = Make-Fragment -TableHeaders @("Name", "IPAddress") -TableData $DCInfo
    $Table1Footer = ("<H3 style='color:green'>Count: " + $DCInfo.Count + "</H3>")
    
    $Table2Header = "<H1 style='background-color:powderblue'>AD Connect Servers</H1>"
    $Table2 = Make-Fragment -TableHeaders @("Name", "Enabled", "Description") -TableData $ADConnectServers
    $Table2Footer = ("<H3 style='color:green'>Count: " + $ADConnectServers.Count + "</H3>")
    
    $Table3Header = "<H1 style='background-color:powderblue'>DHCP Servers</H1>"
    $Table3 = Make-Fragment -TableHeaders @("Name") -TableData $DHCPInfo -UpperCase
    $Table3Footer = ("<H3 style='color:green'>Count: " + $DHCPInfo.Count + "</H3>")
    
    $Foot = "</body></html>"

    $Body = $Head + $Table1Header + $Table1 + $Table1Footer + $Paragraph + $Table2Header + $Table2 + $Table2Footer + $Paragraph + $Table3Header + $Table3 + $Table3Footer + $Foot

    $Body | Out-file $OutFile -Force
    Return $Body
}
Function Send-Details {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Body, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $Attachment)

    $IP = [System.Net.Dns]::GetHostAddresses($SMTPServer)| Select-Object IPAddressToString -Expandproperty IPAddressToString
    If ($IP.GetType().Name -eq 'Object[]') { $IP = $IP[0] }
    $TCPClient = New-Object Net.Sockets.TcpClient
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
    
    $Credential    = New-Object -TypeName System.Management.Automation.PSCredential($SMTPUsername,(ConvertTo-SecureString -String $SMTPPassword -AsPlainText -Force))

    $EmailSubject = ($Subject + ' - ' + '{0:yyyy-MM-dd}' -f (Get-Date))
    Send-MailMessage `
        -From $From `
        -Body $Body `
        -BodyAsHtml `
        -SmtpServer $SMTPServer `
        -Subject $Subject `
        -To $To `
        -Port $SMTPPort `
        -Credential $Credential `
        -Attachment $Attachment

}

#Variables
$OutFile = ('C:\Temp\AD Details - ' + '{0:yyyy-MM-dd}' -f (Get-Date) + ' .html')
#Email Variables
$From         = 'eohrt_vm_storage@eoh.com'
$SMTPServer   = 'za-smtp-outbound-1.mimecast.co.za'
$Subject      = 'AD Script'
$SMTPUsername = 'eohrt_vm_storage@eoh.com'
$SMTPPassword = 'v3Rystr0nGP@ssword2019'
$To           = @('henri.borsboom@eoh.com', 'ryan.smuts@eoh.com')

#Start Processing Information
$DCInfo = Get-DomainDCs
$ADConnectServers = Get-ADConnectServers
$DHCPServers = Get-DHCPServers

#Remove servers from DHCP list that is already in AD list
$DHCPInfo = Compare-DHCPtoDC -DCInfo $DCInfo -DHCPInfo $DHCPServers

#Compile HTML report
$Body = Compile-Body -DCInfo $DCInfo -ADConnectServers $ADConnectServers -DHCPInfo $DHCPInfo -OutFile $OutFile

#Send HTML Report
Send-Details -Body $Body -Attachment $OutFile