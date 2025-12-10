$ReportingEnvironment = New-Object -TypeName PSObject -Property @{
    'System Name' = 'Replication';
    'IP Address'  = '10.1.0.83';
    'Common Name' = 'ERWAT - Replication';
    'Platform'    = 'VMWare'; # Valid Options are HyperVCluster, HyperVStandalone, VMWare, Dummy
    'Username'    = 'administrator@vsphere.local';
    'Password'    = 'Pl@net8521';
}
$SMTPServer               = 'za-smtp-outbound-1.mimecast.co.za'  
$To                       = 'mscloud@eoh.com'
$From                     = 'eohrt_vm_storage@eoh.com'
$MailPassword             = 'v3Rystr0nGP@ssword2019'
Function Load-Modules(){
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet("VMware", "HyperVCluster","HyperV")]
        [String] $HyperVisor)

    $Modules = @()

    Switch ($HyperVisor) {
        "VMWare" {
            $Modules += ,("VMware.VimAutomation.Core")
        }
        "HyperVCluster" {
            $Modules += ,("FailoverClusters")
            $Modules += ,("HyperV")
        }
        "HyperV" {
            $Modules += ,("HyperV")
        }
    }

    $LoadedModules     = Get-Module -Name $Modules -ErrorAction Ignore | ForEach-Object {$_.Name}
    $RegisteredModules = Get-Module -Name $Modules -ListAvailable -ErrorAction Ignore | ForEach-Object {$_.Name}

    ForEach ($Module in $RegisteredModules) {
        If ($LoadedModules -notcontains $Module) {
            Import-Module $Module -ErrorAction SilentlyContinue
        }
   }
}
Function Send-Report {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Client, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $File, `
        [Parameter(Mandatory=$False, Position=4)]
        [String] $Address)

                           
    If ($Address -ne '') { $To = $Address }

    $Credential    = New-Object -TypeName System.Management.Automation.PSCredential($From,(ConvertTo-SecureString -String $MailPassword -AsPlainText -Force))
    [String] $Body = Get-Content $File

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
    }
    $Subject = ('Daily RT - ' + $Client + ' - ' + '{0:yyyy-MM-dd}' -f (Get-Date))
    Send-MailMessage -From $From -BodyAsHtml -Body $Body -SmtpServer $SMTPServer -Subject $Subject -To $To -Port $SMTPPort -Attachments $File -Credential $Credential
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
        [Object[]] $ProdEvents, `
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $DREvents)

    $Head = "<title>Replication Information</title>
        </head><body>"
    $Paragraph = "<p></p>"

    $Table1Header = "<h1 align = 'center' style='background-color:lightblue'>Production Replication</h1>"
    #$Table1 = $ProdEvents | ConvertTo-Html -Fragment
    $Table1 = Make-Fragment -TableHeaders @("CreatedTime","FullFormattedMessage", "VMName") -TableData $ProdEvents


    $Table2Header = "<h1 align = 'center' style='background-color:lightblue'>DR Replication</h1>"
    #$Table2 = $DREvents | ConvertTo-Html -Fragment
    $Table2 = Make-Fragment -TableHeaders @("CreatedTime","FullFormattedMessage", "VMName") -TableData $DREvents

    $Foot = "</body></html>"

    $Body = $Head + $Table1Header + $Table1 + $Paragraph + $Table2Header + $Table2 + $Foot
    Return $Body
}

$ReportDate = (Get-Date -Format 'dd-MM-yyyy')
$ReplFile    = ("C:\EOH_RT\ERWAT - Replication - " + $ReportDate + ".html")

$Credentials = New-Object -TypeName System.Management.Automation.PSCredential($ReportingEnvironment.'Username', (ConvertTo-SecureString -String $ReportingEnvironment.'Password' -AsPlainText -Force))
Write-Host "Loading VMWare Modules"
Load-Modules -HyperVisor VMware

# DR
Write-Host "Connecting to DR"
Connect-VIServer -Server $ReportingEnvironment.'IP Address' -Credential $Credentials -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null

Write-host "Getting events"
$DREvents = get-vievent -maxsamples 500 | Where { $_.EventTypeId -like "hbr.primary.*" -and $_.CreatedTime -gt ((Get-date).AddDays(-1)) } | select CreatedTime, FullFormattedMessage, @{Name="VMName"; Expression={$_.VM.Name}}, @{Name="Size"; Expression={$_.Arguments.value}}
Write-host "Disconnecting from DR"
Disconnect-VIServer -Confirm:$false

#Prod
Write-Host "Connecting to Prod"
Connect-VIServer -Server '10.1.0.82' -Credential $Credentials -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null

Write-host "Getting events"
#get-vievent -maxsamples 2000 | Where { $_.EventTypeId -like "hbr.primary.*" -and $_.CreatedTime -gt ((Get-date).AddDays(-1)) } | select CreatedTime, FullFormattedMessage, @{Name="VMName"; Expression={$_.VM.Name}}, @{Name="Size"; Expression={$_.Arguments.value}} | Out-file $ProdFile
$ProdEvents = get-vievent -maxsamples 500 | Where { $_.EventTypeId -like "hbr.primary.*" -and $_.CreatedTime -gt ((Get-date).AddDays(-1)) } | select CreatedTime, FullFormattedMessage, @{Name="VMName"; Expression={$_.VM.Name}}, @{Name="Size"; Expression={$_.Arguments.value}}
Write-host "Disconnecting from Prod"
Disconnect-VIServer -Confirm:$false


Write-host "Compiling reporting"
Compile-Body -ProdEvents $ProdEvents -DREvents $DREvents | Out-File $ReplFile -Force
Write-host "Sending report"
Send-Report -Client $ReportingEnvironment.'Common Name' -File $ReplFile
#& "$ReplFile"