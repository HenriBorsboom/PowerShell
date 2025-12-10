<#
Version 1.1
Added error handling to all functions to capture any generated error to $Global:Errors
Added reporting of errors to Send-Report
Updated Function names to confirm with PowerShell's approved verbs
Added $SearchBase to simplify the setup of the script
Moved functions in to order of execution
Allowed for NULL values to be sent to the report and to the Compare function
All functions will now add an error to $Global:Errors if an error occured and return NULL for the function

Version 1

Updated Get-DomainDCs to enable error handling when looking up hostname to DNS
Updated Get-DHCPServers to convert name to string and to upper case before removing $RemoveString
Updated Variable $RemoveString to simplify truncation on names
#>
Function Get-DomainDCs {
    Try {
        $GetDomain = [System.Directoryservices.Activedirectory.Domain]::GetCurrentDomain()
    }
    Catch {
        $Global:Errors += ,($_)
    }
    If ($null -ne $GetDomain) {
        $DCInfo = @()
        ForEach ($DomainController in $GetDomain.DomainControllers) {
            Try {
                $hEntry = [System.Net.Dns]::GetHostByName($DomainController.Name)
                $DCinfo += ,(New-Object -TypeName PSObject -Property @{
                    Name = $DomainController.Name.ToUpper().Replace($ReplaceString, '')
                    IPAddress = $hEntry.AddressList[0].IPAddressToString
                })
            }
            Catch {
                $DCinfo += ,(New-Object -TypeName PSObject -Property @{
                    Name = $DomainController.Name.ToUpper().Replace('.ACDCDYN.CO.ZA', '')
                    IPAddress = '0.0.0.0'
                })
            }
        }
    }
    Else {
        $DCInfo = $nul
    }
    
    Return $DCInfo
}
Function Get-DHCPServers {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $SearchBase)
    
    Try {
        $DHCPInfo = Get-ADObject -SearchBase $SearchBase -Filter 'objectclass -eq "dhcpclass"'
        If ($null -ne $DHCPInfo) {
            $ReturnInfo = @()
            ForEach ($Entry in $DHCPInfo) { 
                If (!($Entry.Name -eq 'DhcpRoot')) { 
                    $ReturnInfo += ,($Entry | Select-Object @{Name="Name"; Expression={$_.Name.ToString().ToUpper().Replace($ReplaceString,'')}})
                }
            }
        }
        Else {
            $ReturnInfo = $null
        }
    }
    Catch {
        $Global:Errors += ($_)
    }
    Return $ReturnInfo
}
Function Get-ADConnectServers {
    Try {
        $ADConnectServers = Get-ADUser -LDAPFilter "(description=*Account created by*)" -Properties description | `
        Select-Object Name, Enabled, @{
            Name='Description';
            Expression={`
                $_.Description.Replace('Account created by the Windows Azure Active Directory Sync tool with installation ', '').`
                Replace('. This account must have directory replication permissions in the local Active Directory and write permission on certain attributes to enable Hybrid Deployment.', '').`
                Replace('running ', '').`
                Replace('computer ','')}
            }
    }
    Catch {
        $Global:Errors += ,($_)
    }
    If ($null -eq $ADConnectServers) {
        $ADConnectServers = $null
    }
    Return $ADConnectServers
}

Function Compare-DHCPtoDC {
    Param (
        [Parameter(Mandatory=$True, Position=1)][AllowNull()]
        [object[]] $DCInfo, `
        [Parameter(Mandatory=$True, Position=2)][AllowNull()]
        [object[]] $DHCPInfo)

    If ($null -eq $DCInfo -or $null -eq $DHCPInfo) {
        Return $DHCPInfo
    }
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

Function New-Fragment {
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
Function New-Body {
    Param (
        [Parameter(Mandatory=$True, Position=1)][AllowNull()]
        [Object[]] $DCInfo,`
        [Parameter(Mandatory=$True, Position=2)][AllowNull()]
        [Object[]] $DHCPInfo, `
        [Parameter(Mandatory=$False, Position=3)][AllowNull()]
        [Object[]] $Errors, `
        [Parameter(Mandatory=$True, Position=4)]
        [String] $OutFile)
    
    $Head = "<title>Active Directory Information</title>
        </head><body>"
    $Paragraph = "<p></p>"
    $Table1Header = "<H1 style='background-color:powderblue'>Domain Controllers</H1>"
    $Table1 = New-Fragment -TableHeaders @("Name", "IPAddress") -TableData $DCInfo
    $Table1Footer = ("<H3 style='color:green'>Count: " + $DCInfo.Count + "</H3>")
        
    $Table2Header = "<H1 style='background-color:powderblue'>DHCP Servers</H1>"
    $Table2 = New-Fragment -TableHeaders @("Name") -TableData $DHCPInfo -UpperCase
    $Table2Footer = ("<H3 style='color:green'>Count: " + $DHCPInfo.Count + "</H3>")
    
    $Foot = "</body></html>"

    If ($Errors.Count -gt 0) {
        $ErrorsHeader = "<H1 style='background-color:red'>Errors</H1>"
        $ErrorsTable = $Errors | ConvertTo-Html -Fragment
        $ErrorsFooter = ("<H3 style='color:red'>Count: " + $Errors.Count + "</H3>")
        $Body = $Head + $Table1Header + $Table1 + $Table1Footer + $Paragraph + $Table2Header + $Table2 + $Table2Footer + $Paragraph + $ErrorsHeader + $ErrorsTable + $ErrorsFooter + $Foot
    }
    Else {
        $Body = $Head + $Table1Header + $Table1 + $Table1Footer + $Paragraph + $Table2Header + $Table2 + $Table2Footer + $Paragraph + $Foot
    }
    
    

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

    $Subject = ($Subject + ' - ' + ('{0:yyyy-MM-dd}' -f (Get-Date)).ToString())
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
$ReplaceString = '.EOHCORP.NET'
$SearchBase = "cn=configuration,DC=EOHCORP,DC=NET"
#Email Variables
$From         = 'eohrt_vm_storage@eoh.com'
$SMTPServer   = 'za-smtp-outbound-1.mimecast.co.za'
$Subject      = 'AD Script'
$SMTPUsername = 'eohrt_vm_storage@eoh.com'
$SMTPPassword = 'v3Rystr0nGP@ssword2019'
$To           = @('svcnowreports@eoh.com';'msadjhb@eoh.com')
$Global:Errors = @()

#Start Processing Information
$DCInfo = Get-DomainDCs
$DHCPServers = Get-DHCPServers -SearchBase $SearchBase
$ADConnectServers = Get-ADConnectServers

#Remove servers from DHCP list that is already in AD list
$DHCPInfo = Compare-DHCPtoDC -DCInfo $DCInfo -DHCPInfo $DHCPServers

#Compile HTML report
$Body = New-Body -DCInfo $DCInfo -DHCPInfo $DHCPInfo -Errors $Global:Errors -OutFile $OutFile

#Send HTML Report
Send-Details -Body $Body -Attachment $OutFile 
