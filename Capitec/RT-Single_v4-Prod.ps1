Param (
    [Parameter(Mandatory=$False, Position=1)]
    [String] $SystemName = 'VCSAPRD01', `
    [Parameter(Mandatory=$False, Position=2)]
    [String] $IPAddress = '10.10.222.60', `
    [Parameter(Mandatory=$False, Position=3)]
    [String] $CommonName = 'VCSAPRD01', `
    [Parameter(Mandatory=$False, Position=4)] # Valid Options are HyperVCluster, HyperVStandalone, VMWare
    [String] $Platform = 'VMWare', `
    [Parameter(Mandatory=$False, Position=5)]
    [String] $Username = 'dailyrt@vsphere.local', `
    [Parameter(Mandatory=$False, Position=6)]
    [String] $Password = 'MercB@nk1', `
    [Parameter(Mandatory=$False, Position=7)] 
    [Switch] $Debugging = $False # Default is False
    )

[String] $Global:ScriptVersion = '4.1.2'

#region Variables
[XML] $Config = Get-Content 'C:\iOCO Tools\Scripts\iOCO_RT_Config.xml'
$LogFile = ($Config.Settings.Sources.LogFolder + $SystemName + '_' + ('{0:yyyy-MM-dd HH.mm.ss}' -f (Get-Date)) + '.log')


#region Primary Functions
Function Update-Modules(){
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet('VMware', 'HyperVCluster','HyperV')]
        [String] $HyperVisor)

    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Setting Modules Array"
    $Modules = @()

    Switch ($HyperVisor) {
        'VMWare' {
            $Modules += ,('VMware.VimAutomation.Core')
        }
        'HyperVCluster' {
            $Modules += ,('FailoverClusters')
            $Modules += ,('HyperV')
        }
        'HyperV' {
            $Modules += ,('HyperV')
        }
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "The following modules were added to the array: $Modules"
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Getting loaded modules"
    $LoadedModules     = Get-Module -Name $Modules -ErrorAction Ignore | ForEach-Object {$_.Name}
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Getting registered modules"
    $RegisteredModules = Get-Module -Name $Modules -ListAvailable -ErrorAction Ignore | ForEach-Object {$_.Name}

    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Looping through modules to load unloaded modules"
    ForEach ($Module in $RegisteredModules) {
        If ($LoadedModules -notcontains $Module) {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Importing $module"
            Import-Module $Module -ErrorAction SilentlyContinue
        }
   }
   Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "End of Update-Modules Function"
}
Function Send-Report {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Client, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $File, `
        [Parameter(Mandatory=$False, Position=3)]
        [String] $Subject = '', `
        [Parameter(Mandatory=$False, Position=4)]
        [String[]] $Address, `
        [Parameter(Mandatory=$False, Position=5)]
        [Int] $SMTPPort = 25, `
        [Parameter(Mandatory=$False, Position=6)]
        [String] $Attachment)

    Function Get-SMTPPort {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Resolving the IP of the SMTP Server with DNS'
        $IP = [System.Net.Dns]::GetHostAddresses($Config.Settings.EmailSetup.SMTPServer)| Select-Object IPAddressToString -Expandproperty IPAddressToString
        If ($IP.GetType().Name -eq 'Object[]') { 
            $IP = $IP[0] 
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Multiple IP addresses found. Set IP to ' + $IP)
        }
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting SMTP Port to 0'
        $SMTPPort = 0
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating TCP Client'
        $TCPClient = New-Object Net.Sockets.TcpClient
        # We use Try\Catch to remove exception info from console if we can't connect
        
        Try {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Trying to connect to IP on port 587'
            $TCPClient.Connect($IP, 587)
            If ($TCPClient.Connected) {
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'TCP Client Connected. Closing Sessions.'
                $TCPClient.Close()
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting SMTPPort to 587'
                $SMTPPort = 587
            }
        } 
        Catch { 
            Write-Log -LogFile $LogFile -Level Warning -Component $MyInvocation.MyCommand.Name -Message 'Failed to connect to IP on port 587'
        }

        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Checking if SMTP Port is greater than 0'
        If ($SMTPPort -eq 0) {
            Try {
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Trying to Connect to IP on port 25'
                $TCPClient.Connect($IP, 25)
                If ($TCPClient.Connected) {
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'TCP Client Connected. Closing Session'
                    $TCPClient.Close()
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting SMTPPort to 25'
                    $SMTPPort = 25
                }             
            } 
            Catch { 
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Failed to connect to IP on port 25'
            }
        }
        Else {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'SMTP Port already set'
        }
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Returning SMTPPort'
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Get-SMTPPort Function Complete'
        Return $SMTPPort
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Checking if SMTP Port is specified'
    If ($SMTPPort -eq 0) {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Calling Get-SMTPPort'
        $SMTPPort = Get-SMTPPort
    }
    Else {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'SMTP Port Specified'
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Checking if Addresses specified'
    If ($null -ne $Address) { 
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting To field to Addresses'
        $To = $Address 
    }
    Else { 
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting To field to Config File addresses'
        $To = $Config.Settings.EmailSetup.To
    }
    #Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating mail Credential variable'
    #$MailCredential    = New-Object -TypeName System.Management.Automation.PSCredential($Config.Settings.EmailSetup.From,(Get-Content $Config.Settings.Sources.MailFile | ConvertTo-SecureString))
    
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting the body of the mail to the content of the file'
    [String] $Body = Get-Content $File

    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Checking if Subject has been passed'
    If ($Subject -eq '') {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting Subject to standard subject'
        $Subject = ('Daily RT - ' + $Client + ' - ' + '{0:yyyy-MM-dd}' -f (Get-Date))
    }
    Else {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Custom Subject set'
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Sending mail message'
    Send-MailMessage -From $Config.Settings.EmailSetup.From -BodyAsHtml -Body $Body -SmtpServer $Config.Settings.EmailSetup.SMTPServer -Subject $Subject -To $To -Port $SMTPPort -Attachments $Attachment #-Credential $MailCredential
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Send-Report function complete'
}
Function Write-log {
    [CmdletBinding()]
    Param(
          [parameter(Mandatory=$true, Position=1)]
          [String]$Logfile,
          [parameter(Mandatory=$true, Position=2)]
          [String]$Message,
          [parameter(Mandatory=$true, Position=3)]
          [String]$Component,
          [Parameter(Mandatory=$true,Position=4)][ValidateSet("Info", "Warning", "Error")]
          [String]$Level
    )

    switch ($Level) {
        "Info" { [int]$Level = 1 }
        "Warning" { [int]$Level = 2 }
        "Error" { [int]$Level = 3 }
    }

    # Create a log entry
    $Content = "<![LOG[$Message]LOG]!>" +`
        "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
        "date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
        "component=`"$Component`" " +`
        "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
        "type=`"$Level`" " +`
        "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
        "file=`"`">"

    # Write the line to the log file
    Add-Content -Path $Logfile -Value $Content
}
#endregion
#region HTML Functions
Function New-HTMLImage {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $ImagePath, `
        [Parameter(Mandatory=$True, Position=2)]
        [Int] $SquareSize, `
        [Parameter(Mandatory=$False, Position=3)]
        [Switch] $Center)

    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Getting Content of PNG file and convert to Bits'
    $ImageBits =  [Convert]::ToBase64String((Get-Content $ImagePath -Encoding Byte))
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Getting the ImageFile from the ImagePath'
    $ImageFile = Get-Item $ImagePath
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Get the extension of the ImageFile'
    $ImageType = $ImageFile.Extension.Substring(1) #strip off the leading .
    If ($Center) {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Message switch set for center'
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating Image Tag Data'
        $ImageTag = "<Img src='data:image/$ImageType;base64,$($ImageBits)' Alt='$($ImageFile.Name)' style='float:center' width='$($SquareSize)' height='$($SquareSize)' hspace=10>"
    }
    Else {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Message switch not set. Aligning left'
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating Image Tag Data'
        $ImageTag = "<Img src='data:image/$ImageType;base64,$($ImageBits)' Alt='$($ImageFile.Name)' style='float:left' width='$($SquareSize)' height='$($SquareSize)' hspace=10>"
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Returning ImageTag'
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'New-HTMLImage Complete'
    Return $ImageTag
}
Function New-HTMLReport {
    Param (
        [Parameter(Mandatory=$True, Position=1)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()]
        [Object] $ReportingEnvironment, `
        [Parameter(Mandatory=$True, Position=2)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()]
        [Object[]] $ReportAlarms, `
        [Parameter(Mandatory=$True, Position=3)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()]
        [Object[]] $ReportHosts, `
        [Parameter(Mandatory=$True, Position=4)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()]
        [Object[]] $ReportDatastores, `
        [Parameter(Mandatory=$True, Position=5)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()]
        [Object[]] $ReportVMS, `
        [Parameter(Mandatory=$True, Position=6)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()]
        [Object[]] $ReportSnapshots)

    $ReportDate = (Get-Date -Format 'yyyy-MM-dd')
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Report Date set to: ' + $ReportDate)
    $OutFile    = ($Config.Settings.Sources.ReportFolder + $ReportingEnvironment.'Common Name' + " - " + $ReportDate + ".html")
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('OutFile set to: ' + $OutFile)

    Write-Host ("Generating HTML to " + $OutFile + " - ") -ForegroundColor Yellow -NoNewLine
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating Empty Fragments array for HTML fragments'
    $Fragments  = @()
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting Title on HTML'
    $Fragments += "<title>$($ReportingEnvironment.'Common Name')</title>"
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting header and align center'
    $Fragments += "<h1 align='center'>$($ReportingEnvironment.'Common Name')</h1>"
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting report date and time'
    $Fragments += "<h1 align='center'>$(Get-Date -Format 'dd-MM-yyyy HH:mm')</h1>"
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Calling Start-OverallHealthProcessing'
    $Fragments += (Start-OverallHealthProcessing)
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Calling Start-AlarmsProcessing'
    $Fragments += (Start-AlarmsProcessing -ReportAlarms $ReportAlarms)
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Calling Start-HostsProcessing'
    $Fragments += (Start-HostsProcessing -ReportHosts $ReportHosts)
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Calling Start-DatastoresProcessing'
    $Fragments += (Start-DatastoresProcessing -ReportDatastores $ReportDatastores)
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Calling Start-VMsProcessing'
    $Fragments += (Start-VMsProcessing -ReportVMs $ReportVMs)
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Calling Start-Snapshotprocessing'
    $Fragments += (Start-SnapshotsProcessing -ReportSnapshots $ReportSnapshots)
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Calling Start-ScriptExecutionProcessing'
    $Fragments += (Start-ScriptExecutionProcessing)

    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Defining head of HTML document'
$head = @"
<style>
    body {
        background-color:#E5E4E2;
        font-family:Monospace;
        font-size:10pt;
    }
    td, th {
        border:0px solid black;
        border-collapse:collapse;
        white-space:pre;
    }
    th {
        color:white;
        background-color:black;
    }
    table, tr, td, th {
        padding: 2px; margin: 0px ;white-space:pre;
    }
    tr:nth-child(odd) {
        background-color: lightgray
    }
    table {
        width:95%;
        margin-left:5px;
        margin-bottom:20px;
    }
    h1 {
        font-family:Tahoma;
        font-size: 24px;
        color:#6D7B8D
    }
    h2 {
        font-family:Tahoma;
        font-size: 20px;
        color:#6D7B8D;
    }
    h3 {
        font-family:Tahoma;
        font-size: 16px;
        color:#6D7B8D;
    }
    h4 {
        font-family:Tahoma;
        font-size: 14px;
        color:#6D7B8D;
    }
    .alert {
        color: red;
    }
    .healthy {
        color: green;
    }
    .warning {
        color: orange;
    }
    .footer {
        color:green;
        margin-left:10px;
        font-family:Tahoma;
        font-size:8pt;
        font-style:italic;
    }
</style>
"@
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting ConvertParams array to Head and Fragments'
    $ConvertParams = @{
        head = $Head
        body = $fragments
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating HTML document and saving to Outfile'
    ConvertTo-Html @ConvertParams | Out-File $OutFile -Force
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Returning Outfile'
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'New-HTMLReport Complete'
    Return $OutFile
}
#endregion
#region Data Collection Functions
Function Get-Alarms {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Platform, `
        [Parameter(Mandatory=$False, Position=2)]
        [String] $VMHost = $env:COMPUTERNAME)

    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Checking which platform to load"
    If ($Platform -like 'Hyper*') { 
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Platform found to contain Hyper* and platform set to HyperV"
        $Platform = 'HyperV' 
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting ReportAlarms array'
    $ReportAlarms = @()
    Switch ($Platform) {
        'HyperV' {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Running Get-WinEvent with ErrorActionSilentlyContinue'
            $AllAlarms    = Get-WinEvent -FilterHashtable @{LogName='System';StartTime=(Get-Date).AddDays([Int] $Config.Settings.Alarms.AlarmDateRangeInDays);Level=(1..3);} -ComputerName $VMHost -ErrorAction SilentlyContinue
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ($AllAlarms.Count.ToString() + ' messages found')
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Filteringing messages that contain *hyper* or *cluster*'
            $ActiveAlarms = $AllAlarms | Where-Object {$_.Message -like "*hyper*" -or $_.Message -like "*cluster*"}
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ($ActiveAlarms.Count.ToString() + ' found')
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through Active alarms'
            ForEach ($ActiveAlarm in $ActiveAlarms) {
                If ($ActiveAlarm.LevelDisplayName -eq 'Error')        { 
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Alarm LevelDisplayName is Error. Setting AlarmHealthIcon to [CriticalImage]'
                    $AlarmHealthIcon = "[CriticalImage]" 
                }
                ElseIf ($ActiveAlarm.LevelDisplayName -eq 'Critical') { 
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Alarm LevelDisplayName is Critical. Setting AlarmHealthIcon to [CriticalImage]'
                    $AlarmHealthIcon = "[CriticalImage]" 
                }
                ElseIf ($ActiveAlarm.LevelDisplayName -eq 'Warning')  { 
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Alarm LevelDisplayName is Warning. Setting AlarmHealthIcon to [WarningImage]'
                    $AlarmHealthIcon = "[WarningImage]" 
                }
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding to $ReportAlarms array'
                $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                    Source   = $ActiveAlarms.ProviderName
                    Event    = $ActiveAlarm.Message
                    Category = $ActiveAlarm.LevelDisplayName
                    Time     = $ActiveAlarm.TimeCreated
                    Health   = $AlarmHealthIcon
                })
            }
        }
        'VMWare' {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Getting triggered Alarms with "(Get-Datacenter).ExtensionData.TriggeredAlarmState"'
            $ActiveAlarms = (Get-Datacenter).ExtensionData.TriggeredAlarmState
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through ActiveAlarms'
            ForEach ($ActiveAlarm in $ActiveAlarms) {
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Checking OverallStatus of Alarm'
                If ($ActiveAlarm.OverallStatus -eq 'red') { 
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Alarm OverallStatus equals red. Setting $AlarmHealthIcon to [CriticalImage]'
                    $AlarmHealthIcon = "[CriticalImage]" 
                }
                ElseIf ($ActiveAlarm.OverallStatus -eq 'yellow') { 
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Alarm OverallStatus equals yellow. Setting $AlarmHealthIcon to [WarningImage]'
                    $AlarmHealthIcon = "[WarningImage]" 
                }
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Checking Alarm Entity Value or type'
                If ($ActiveAlarm.Entity.Value -like "*host*") { 
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Entity Value contains *host*. Setting $AlarmSource to ' + (Get-VMHost -Id $ActiveAlarm.Entity).Name)
                    $AlarmSource = (Get-VMHost -Id $ActiveAlarm.Entity).Name 
                }
                ElseIf ($ActiveAlarm.Entity.Type -like "*VirtualMachine*") { 
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Entity Type like *VirtualMachine*. Setting $AlarmSource to ' + (Get-VM -Id $ActiveAlarm.Entity).Name)
                    $AlarmSource = (Get-VM -Id $ActiveAlarm.Entity).Name 
                }
                ElseIf ($ActiveAlarm.Entity.Type -like "*Datastore*") { 
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Entity Type like *Datastore*. Setting $AlarmSource to ' + (Get-Datastore -Id $ActiveAlarm.Entity).Name)
                    $AlarmSource = (Get-Datastore -Id $ActiveAlarm.Entity).Name 
                }
                Else { 
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ("Setting AlarmSource to Unknown. ActiveAlarm: " + $ActiveAlarm)
                    $AlarmSource = "Unknown" 
                }

                $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                    Source     = $AlarmSource
                    Event      = (Get-AlarmDefinition -Id $ActiveAlarm.Alarm).Name
                    Category   = $ActiveAlarm.OverallStatus
                    Time       = $ActiveAlarm.Time
                    Health     = $AlarmHealthIcon
                })
            }
        }
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Active Alarm looping complete'
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('ReportAlarms = ' + $ReportAlarms)
    If ($ReportAlarms.Count -gt 0) { `
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Alarm Count greater than 0'
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $Global:AlarmIcon to [CriticalImage]'
        $Global:AlarmIcon = "[CriticalImage]" 
    }
    Else { 
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $Global:AlarmIcon to [NonCriticalImage]'
        $Global:AlarmIcon = "[NonCriticalImage]"
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Returning ReportAlarms')
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Get-Alarms Function complete'
    Return $ReportAlarms | Select-Object Source, Event, Category, Time, Health
}
Function Get-Hosts {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Platform, `
        [Parameter(Mandatory=$False, Position=2)]
        [String] $VMHost = $env:COMPUTERNAME)

    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Checking which platform to load"
    If ($Platform -like 'Hyper*') { 
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Platform found to contain Hyper* and platform set to HyperV"
        $Platform = 'HyperV' 
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating ReportHosts Array'
    $ReportHosts = @()
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating HostUnhealthyCount with value of 0'
    $HostUnhealthyCounter = 0

    $State = @()
    Switch ($Platform) {
        'HyperV' {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Testing connection to ' + $VMHost)
            If (Test-Connection $VMHost -Quiet -ErrorAction Stop) {
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $HealthIcon to [NonCriticalImage]'
                $HealthIcon = '[NonCriticalImage]'
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $State to PoweredOn'
                $State      = 'PoweredOn'
            }
            Else {
                $HostUnhealthyCounter += 1
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Incrementing $HostUnhealthyCounter by 1. New value ' + $HostUnhealthyCounter.ToString())
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $HealthIcon to [CriticalImage]'
                $HealthIcon = '[CriticalImage]'
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $State to PoweredOff'
                $State      = 'PoweredOff'
            }
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding Host details to $ReportHosts'
            $ReportHosts = (New-Object -TypeName PSObject -Property @{
                'Name'        = $VMHost
                'State'       = $State
                'Power State' = $State
                'Health'      = $HealthIcon
            })
        }
        'VMWare' {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Getting VMWare Hosts'
            $ESXHosts = Get-VMHost | Select-Object Name, ConnectionState, PowerState | Sort-Object Name
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through each ESX Host'
            ForEach ($ESXHost in $ESXHosts) {
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Processing ' + $ESXHost.Name)
                If ($ESXHost.ConnectionState -eq 'Connected' -and $ESXHost.PowerState -eq 'PoweredOn') {
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $State OK'
                    $State      += 'OK'
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $Health to [NonCriticalImage]'
                    $HealthIcon = '[NonCriticalImage]'
                }
                ElseIf ($ESXHost.ConnectionState -eq 'Maintenance' -and $ESXHost.PowerState -eq 'PoweredOn') {
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $State Warning'
                    $State      += 'Warning'
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $Health to [WarningImage]'
                    $HealthIcon = '[WarningImage]'
                }
                Else {
                    $HostUnhealthyCounter += 1
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Incrementing $HostUnhealthyCounter by 1. New Value ' + $HostUnhealthyCounter)
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $State to Fail'
                    $State      += 'Fail'
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $HealthIcon to [CriticalImage]'
                    $HealthIcon = '[CriticalImage]'
                }
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding Host details to $ReportHosts'
                $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                    'Name'        = $ESXHost.Name
                    'State'       = $ESXHost.ConnectionState
                    'Power State' = $ESXHost.PowerState
                    'Health'      = $HealthIcon
                })
            }
        }
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Finished looping through hosts'
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('ReportHosts = ' + $ReportHosts.Count)
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Checking if $HostUnhealthyCounter equal to 0'
    If ($State -contains ('Warning') ) {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $Global:HostIcon to [WarningImage]'
        $Global:HostIcon = '[WarningImage]'
    }
    ElseIf ($State -contains ('Fail') ) {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $Global:HostIcon to [CriticalImage]'
        $Global:HostIcon = '[CriticalImage]'
    }
    Else {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $Global:HostIcon to [NonCriticalImage]'
        $Global:HostIcon = '[NonCriticalImage]'
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Returning ' + $ReportHosts)
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Get-Hosts Function complete'
    Return $ReportHosts | Select-Object 'Name', 'State', 'Power State', 'Health'
}
Function Get-VMSRunning {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Platform, `
        [Parameter(Mandatory=$False, Position=2)]
        [String] $VMHost = $env:COMPUTERNAME)

    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Checking which platform to load"
    If ($Platform -like 'Hyper*') { 
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Platform found to contain Hyper* and platform set to HyperV"
        $Platform = 'HyperV' 
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating ReportVMs array'
    $ReportVMs = @()
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating VMWarningCounter with value of 0'
    $VMWarningCounter = 0
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating VMCriticalCounter with value of 0'
    $VMCriticalCounter = 0

    Switch ($Platform) {
        'HyperV' {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Getting OS Caption with WMI'
            $OSCaption = (Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption' -ComputerName $VMHost).Caption
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('OS Caption is ' + $OSCaption)
            If ($OSCaption -like '*201*')    { 
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting VMs on ' + $VMHost + ' with Get-VM')
                $VMs = Get-VM -ComputerName $VMHost | Sort-Object Name
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ($VMs.Count.ToString() + ' Found')
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through VMs'
                ForEach ($VM in $VMs) {
                    If ($VM.State -ne 'Running') {
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'VM State not equals Running'
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Incrementing VMCriticalCounter by 1'
                        $VMCriticalCounter  += 1
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting VMHealthIcon to [CriticalImage]'
                        $VMHealthIcon         = "[CriticalImage]"
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting VMState to PoweredOff'
                        $VMState              = 'PoweredOff'
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through VMExclusions'
                        ForEach ($Exclusion in $Config.Settings.VMExclusions.Exclusion) {
                            If ($VM.Name -like $Exclusion) {
                                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('VM Name: ' + $VM.Name + ' matches ' + $Exclusion)
                                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting VMHealthIcon to [WarningImage]'
                                $VMHealthIcon = "[WarningImage]"
                                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Decrementing VMCritical counter by 1'
                                $VMCriticalCounter -= 1
                                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Incrementing VMWarning Counter by 1'
                                $VMWarningCounter += 1
                            }
                        }
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Finished looping Exclusions'
                    }
                    Else {
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting VMHealthIcon to [NonCriticalImage]'
                        $VMHealthIcon         = "[NonCriticalImage]"
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting VMState to PoweredOn'
                        $VMState              = 'PoweredOn'
                    }
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Checking if $VM.NetworkAdapters.IPAddresses contains information'
                    If ($null -eq $VM.NetworkAdapters.IPAddresses) {
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Not found. Setting VMIPaddress to ""'
                        $VMIPAdress = ''
                    }
                    Else {
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Found IP Address(es)'
                        If ($VM.NetworkAdapters.IPAddresses.GetType().Name -eq 'Object[]') { 
                            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Found IP Addresses in array'
                            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through array for IPv4 address'
                            ForEach ($VMIP in $VM.NetworkAdapters.IPAddresses) {
                                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Validating if found IP addresses are of IPv4 Family'
                                If (([System.Net.IPAddress] $VMIP).AddressFamily -ne 'InterNetworkV6') { 
                                    $VMIPAddress = $VMIP 
                                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('$VMIPAddress set to' + $VMIPAddress)
                                }
                            }
                            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Finished looping through IP Addresses'
                        }
                        Else {
                            $VMIPAddress = $VM.NetworkAdapters.IPAddresses
                            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('$VMIPAddress set to ' + $VMIPAddress)
                        }
                    }
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Tool State with Get-VM on ' + $VMHost)
                    $ToolsState = (Get-VM $VM.Name -ComputerName $VMHost | Select-Object IntegrationServicesVersion).IntegrationServicesVersion
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('ToolState = ' + $ToolsState)
                    $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                        'Name'        = $VM.Name
                        'IP Address'  = $VMIPAddress
                        'State'       = $VMState
                        'Tools State' = $ToolsState
                        'Health'      = $VMHealthIcon
                    })
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding details to ReportVMs'
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Resetting VMIPAddress to $null'
                    $VMIPAddress = $null
                }
            }
            Else { 
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting VMs on ' + $VMHost + ' using WMI in root\virtualization\MSVM_ComputerSystem')
                $VMs = Get-WmiObject -Query "Select * from MSVM_ComputerSystem Where Caption = 'Virtual Machine'" -Namespace 'root\virtualization'  -ComputerName $VMHost | Sort-Object ElementName
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ($VMs.Count.ToString() + ' Found')
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through VMs'
                ForEach ($VM in $VMs) {
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Checking $VM.Enabled state'
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Current Value: ' + $VM.EnabledState.ToString())
                    If ($VM.EnabledState -eq 3) {
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Incrementing VMCriticalCounter by 1'
                        $VMCriticalCounter  += 1
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('VMCriticalCounter value ' + $VMCriticalCounter.ToString())
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting VMHealthIcon to [CriticalImage]'
                        $VMHealthIcon         = "[CriticalImage]"
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting VMState to PoweredOff'
                        $VMState              = 'PoweredOff'
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Checking if VM Name in VM Exclusions'
                        ForEach ($Exclusion in $VMCriticalExclusionList) {
                            If ($VM.ElementName -like $Exclusion) {
                                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'VM Name listed in VM Exclusions'
                                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting VMHealthIcon to [WarningImage]'
                                $VMHealthIcon = "[WarningImage]"
                                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Decrementing VMCriticalcounter by 1'
                                $VMCriticalCounter -= 1
                                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('VMCriticalCounter value ' + $VMCriticalCounter.ToString())
                                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Incrementing VMWarningCounter by 1'
                                $VMWarningCounter += 1
                                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('VMWarning Counter value ' + $VMWarningCounter)
                            }
                        }
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Finished looping through exclusions'
                    }
                    Else {
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting VMHealthIcon to [NonCriticalImage]'
                        $VMHealthIcon         = "[NonCriticalImage]"
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting VMState to PoweredOn'
                        $VMState              = 'PoweredOn'
                    }
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding details to ReportVMs'
                    $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                        'Name'        = $VM.ElementName
                        'IP Address'  = 'Not available on this host'
                        'State'       = $VMState
                        'Tools State' = ''
                        'Health'      = $VMHealthIcon
                    })
                }
            }
        }
        'VMWare' {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through all VMs'
            ForEach ($VM in (Get-VM | Select-Object Name, PowerState, @{Name="IPAddress";Expression={@($_.Guest.IPAddress[0])}}, @{Name="ToolsRunning";Expression={$_.ExtensionData.Guest.ToolsStatus}}) | Sort-Object Name) {
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Processing ' + $VM.Name)
                If ($VM.PowerState -ne 'PoweredOn') {
                    Write-Log -LogFile $LogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ($VM.Name + ' Powerstate not equal PoweredOn')
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through VM Exclusions'
                    ForEach ($Exclusion in $Config.Settings.VMExclusions.Exclusion) {
                        If ($VM.Name.ToLower() -like $Exclusion.ToLower()) {
                            Write-Log -LogFile $LogFile -Level Warning -Component $MyInvocation.MyCommand.Name -Message ($VM.Name.ToLower() + ' matches ' + $Exclusion.ToLower())
                            $State = 'Warning'
                        }
                    }
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Finished Looping VM Exclusions'
                    If ($State -ne 'Warning') {
                        Write-Log -LogFile $LogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message 'Setting VMHealthIcon to [CriticalImage]'
                        $VMHealthIcon        = "[CriticalImage]"
                        $VMCriticalCounter += 1 
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Incrementing VMCriticalCounter by 1. New Value ' + $VMCriticalCounter.ToString())
                    }
                    Else {
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting VMHealthIcon to [WarningImage]'
                        $VMHealthIcon        = "[WarningImage]"
                        $VMWarningCounter   += 1
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Incremented VMWarningCounter by 1. New Value ' + $VMWarningCounter.ToString())
                    }
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $State to $null'
                    $State = $null
                }
                ElseIf ($VM.ToolsRunning -eq 'toolsNotRunning') {
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'VM Tools not running'
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting VMHealthIcon to [CriticalImage]'
                    $VMHealthIcon        = "[CriticalImage]"
                    $VMCriticalCounter += 1 
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Incrementing VMCriticalCounter by 1. New Value ' + $VMCriticalCounter.ToString())
                }
                Else {
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting VMHealthIcon to [NonCriticalImage]'
                    $VMHealthIcon        = "[NonCriticalImage]"
                }
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding details to $ReportVMs'
                $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                    'Name'        = $VM.Name
                    'IP Address'  = $VM.IPAddress
                    'State'       = $VM.PowerState
                    'Tools State' = $VM.ToolsRunning
                    'Health'      = $VMHealthIcon
                })
            }
        }
    }
    

    If ($VMWarningCounter -gt 0) {
        #$Global:VMImage = $WarningImage48
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'VMWarningCounter greater than 0'
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $Global:VMIcon to [WarningImage]'
        $Global:VMIcon = "[WarningImage]"
    }
    ElseIf ($VMCriticalCounter -gt 0) {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'VMCriticalCounter greater than 0'
        #$Global:VMImage = $CriticalImage48
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $Global:VMIcon to [CriticalImage]'
        $Global:VMIcon = "[CriticalImage]" 
    }
    Else {
        #$Global:VMImage = $NonCriticalImage48
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $Global:VMIcon to [NonCriticalImage]'
        $Global:VMIcon = "[NonCriticalImage]"
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Returning $ReportVms ' + $ReportVMs)
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Get-VMsRunning Function Complete'
    Return $ReportVMs | Select-Object 'Name', 'IP Address', 'State', 'Tools State', 'Health'
}
Function Get-SnapShots {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Platform, `
        [Parameter(Mandatory=$False, Position=2)]
        [String] $VMHost = $env:COMPUTERNAME)

        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Checking which platform to load"
        If ($Platform -like 'Hyper*') { 
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Platform found to contain Hyper* and platform set to HyperV"
            $Platform = 'HyperV' 
        }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating ReportSnapshots array'
    $ReportSnapshots        = @()
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating SnapshotsOldAgeCount with value 0'
    $SnapshotsOldAgeCounter = 0

    Switch ($Platform) {
        'HyperV' {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Getting OS info via WMI'
            $OSCaption = (Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption' -ComputerName $VMHost).Caption
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('OS Caption: ' + $OSCaption)

            If ($OSCaption -like '*2008*')    { 
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting WMI Namespace to root\virtualization'
                $Namespace = 'root\virtualization' 
            }
            ElseIf ($OSCaption -like '*201*') { 
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting WMI Namespace to root\virtualization\v2'
                $Namespace = 'root\virtualization\v2' 
            }
            Else { 
                Write-Log -LogFile $LogFile -Level Warning -Component $MyInvocation.MyCommand.Name -Message 'OS Caption undertimed. Setting WMI namespace to root\virtualization'
                $Namespace = 'root\virtualization' 
            }
            
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Getting VMs via WMI'
            $VMs = Get-WmiObject -Query "Select * from MSVM_ComputerSystem Where Caption = 'Virtual Machine'" -Namespace $Namespace -ComputerName $VMHost
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ($VMs.Count.ToString() + ' found')
            ForEach ($VM in $VMS) {
                $Query     = ("Select * From Msvm_ComputerSystem Where ElementName='" + $VM.ElementName + "'")
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Set WMI Query to: ' + $Query)
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Getting SourceVM WMI Object'
                $SourceVm  = Get-WmiObject -Namespace $Namespace -Query $Query -ComputerName $VMHost
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Getting Snapshot associators of VM via WMI'
                $Snapshots = Get-WmiObject -Namespace $Namespace -Query "Associators Of {$SourceVm} Where AssocClass=Msvm_ElementSettingData ResultClass=Msvm_VirtualSystemSettingData" -ComputerName $VMHost
                If ($null -ne $Snapshots) {
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Snapshots found to be greater than 0'
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Converting WMI Date/Time to PowerShell DateTime'
                    $SnapshotCreationTime = [Management.ManagementDateTimeConverter]::ToDateTime($Snapshots.CreationTime)
                    If (((Get-Date) - $SnapshotCreationTime).Days -gt ([Int] $Config.Settings.Snapshots.AllowedSnapshotAge)) {
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Snapshot age found to be greater than allowed age: ' + $Config.Settings.Snapshots.AllowedSnapshotAge)
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Incrementing SnapShotOldAgeCounter by 1'
                        $SnapshotsOldAgeCounter += 1
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('SnapshotOldAgeCounter Value: '+ $SnapshotsOldAgeCounter.ToString())
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting SnapshotHealthIcon to [CriticalImage]'
                        $SnapshotHealthIcon = "[CriticalImage]"
                    }
                    Else {
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Snapshot age found to be less than allowed age: ' + $Config.Settings.Snapshots.AllowedSnapshotAge)
                        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting SnapshotHealthIcon to [WarningImage]'
                        $SnapshotHealthIcon = "[WarningImage]"
                    }
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding snapshot to ReportSnapshots'
                    $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                        'VM'            = $VM.ElementName
                        'Name'          = $Snapshots.ElementName
                        'Creation Time' = '{0:yyyy/MM/dd HH:mm:ss}' -f $SnapshotCreationTime
                        'Age'           = ((Get-Date) - $SnapshotCreationTime).Days
                        'Health'        = $SnapshotHealthIcon
                    })
                }
            }
        }
        'VMWare' {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Getting Snapshots'
            $Snapshots = Get-VM | Get-Snapshot | Select-Object VM, Name, Created
            #Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ($Snapshots.Count.ToString() + ' Found')
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through Snapshots'
            ForEach ($Snapshot in $Snapshots) {
                If (((Get-Date) - $Snapshot.Created).Days -gt $Config.Settings.Snapshots.AllowedSnapshotAge) {
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Snapshot age found to be greater than allowed age: ' + $Config.Settings.Snapshots.AllowedSnapshotAge)
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Incrementing SnapShotOldAgeCounter by 1'
                    $SnapshotsOldAgeCounter += 1
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('SnapshotOldAgeCounter Value: '+ $SnapshotsOldAgeCounter.ToString())
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting SnapshotHealthIcon to [CriticalImage]'
                    $SnapshotHealthIcon      = "[CriticalImage]"
                }
                Else {
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Snapshot age found to be less than allowed age: ' + $Config.Settings.Snapshots.AllowedSnapshotAge)
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting SnapshotHealthIcon to [WarningImage]'
                    $SnapshotHealthIcon      = "[WarningImage]"
                }
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding snapshot to ReportSnapshots'
                $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                        'VM'            = $Snapshot.VM
                        'Name'          = $Snapshot.Name
                        'Creation Time' = '{0:yyyy/MM/dd HH:mm:ss}' -f $Snapshot.Created
                        'Age'           = ((Get-Date) - $Snapshot.Created).Days
                        'Health'        = $SnapshotHealthIcon
                    })
            }
        }
    }
    If ($ReportSnapshots.Count -eq 0) {
        #$Global:SnapshotImage = $NonCriticalImage48
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'ReportSnapshot count equals 0'
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting Global:Snapshoticon to [NonCriticalImage]'
        $Global:SnapshotIcon = "[NonCriticalImage]"
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating an empty $ReportSnapshots variable'
        $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
            'VM'            = $null
            'Name'          = $null
            'Creation Time' = $null
            'Age'           = $null
            'Health'        = $null
        })
    }
    ElseIf ($ReportSnapshots.Count -gt 0) {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Report snapshots count greater than 0. Value :' + $ReportSnapshots.Count.ToString())
        #$Global:SnapshotImage = $WarningImage48
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting Global:Snapshoticon to [WarningImage]'
        $Global:SnapshotIcon = "[WarningImage]"
    }
    If ($SnapshotsOldAgeCounter -gt 0) {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Snapshot OldAgeCounter greater than 0. Value: ' + $SnapshotsOldAgeCounter.ToString())
        #$Global:SnapshotImage = $CriticalImage48
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting Global:SnapShotIcon to [CriticalImage]'
        $Global:SnapshotIcon = "[CriticalImage]"
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Returning ReportSnapshots' + $ReportSnapshots)
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Function Get-Snapshots complete'
    Return $ReportSnapshots | Select-Object 'VM', 'Name', 'Creation Time', 'Age', 'Health'
}
Function Get-Datastores {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Platform, `
        [Parameter(Mandatory=$False, Position=2)]
        [String] $VMHost = $env:COMPUTERNAME, `
        [Parameter(Mandatory=$False, Position=3)]
        [String] $Cluster)

    Function Format-Size {
        Param (
            [Parameter(Mandatory=$True, Position=1)]
            [Int64] $Size)

        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Size Supplied: ' + $Size.ToString())
        If ($Size -le 1024) { 
            $FormattedSize = ($Size.ToString() + " B") 
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Formatted size to (B): ' + $FormattedSize.ToString())
        }
        ElseIf ($Size -ge 1025 -and $Size -le 1048576) { 
            $FormattedSize = [Math]::Round($Size / 1024, 2).ToString() + " KB" 
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Formatted size to (KB): ' + $FormattedSize.ToString())
        }
        ElseIf ($Size -ge 1048577 -and $Size -le 1073741824) { 
            $FormattedSize = [Math]::Round($Size / 1024 / 1024, 2).ToString() + " MB" 
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Formatted size to (MB): ' + $FormattedSize.ToString())
        }
        ElseIf ($Size -ge 1073741825 -and $Size -le 1099511627776) { 
            $FormattedSize = [Math]::Round($Size / 1024 / 1024 / 1024, 2).ToString() + " GB" 
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Formatted size to (GB): ' + $FormattedSize.ToString())
        }
        ElseIf ($Size -ge 1099511627777 -and $Size -le 1125899906842624) { 
            $FormattedSize = [Math]::Round($Size / 1024 / 1024 / 1024 / 1024, 2).ToString() + " TB" 
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Formatted size to (TB): ' + $FormattedSize.ToString())
        }
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Returning Formatted size: ' + $FormattedSize)
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Format-Size Function Complete'
        Return $FormattedSize
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting WarningStores to False'
    $WarningStores     = $False
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting CriticalStores to False'
    $CriticalStores    = $False
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating Empty ReportDatastores Array'
    $ReportDatastores  = @()

    Switch ($Platform) {
        'HyperVStandalone' {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Getting Datastores via WMI where DriveType = 3'
            $Datastores = Get-WmiObject -Query "Select DeviceID, Size, FreeSpace from Win32_LogicalDisk where DriveType = 3" -ComputerName $VMHost
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping Through Datastores'
            ForEach ($Datastore in $Datastores) {
                If ([Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0) -ge ([Int] $Config.Settings.Alarms.DatastoreCriticalRange + 1) -and [Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0) -le ([Int] $Config.Settings.Alarms.DatastoreWarningRange)) {
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Datastore free space found to be ' + ([Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0)))
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting WarningStores to True'
                    $WarningStores   = $True
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting DataStoreHealth to [WarningImage]'
                    $DatastoreHealth = "[WarningImage]"
                }
                ElseIf ([Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0) -le ([Int] $Config.Settings.Alarms.DatastoreCriticalRange)) {
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Datastore free space found to be ' + ([Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0)))
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting CriticalStores to True'
                    $CriticalStores   = $True
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting DatastoreHealth to [CriticalImage]'
                    $DatastoreHealth = "[CriticalImage]"
                }
                Else {
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting DatastoreHealth to [NonCriticalImage]'
                    $DatastoreHealth = "[NonCriticalImage]"
                }
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding Datastore to ReportDatastores and calling Format-Size with -Size'
                $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                    'Name'       = $Datastore.DeviceID
                    'Free Space' = (Format-Size -Size $Datastore.FreeSpace)
                    'Capacity'   = (Format-Size -Size $Datastore.Size)
                    'Free %'     = [Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0)
                    'Health'     = $DatastoreHealth
                })
            }
        }
        'HyperVCluster' {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Getting Cluster Shared Volumes'
            $Datastores       = Get-ClusterSharedVolume -Cluster $Cluster
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through datastores'
            ForEach ($Datastore in $Datastores) {
                If ([Math]::Round(($Datastore.SharedVolumeInfo.Partition.FreeSpace / $Datastore.SharedVolumeInfo.Partition.Size * 100), 0) -ge ([Int] $Config.Settings.Alarms.DatastoreCriticalRange + 1) -and [Math]::Round(($Datastore.SharedVolumeInfo.Partition.FreeSpace / $Datastore.SharedVolumeInfo.Partition.Size * 100), 0) -le ([Int] $Config.Settings.Alarms.DatastoreWarningRange)) {
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Datastore free space found to be ' + ([Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0)))
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting WarningStores to True'
                    $WarningStores = $True
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting DatastoreHealth to [WarningImage]'
                    $DatastoreHealth = "[WarningImage]"
                }
                ElseIf ([Math]::Round(($Datastore.SharedVolumeInfo.Partition.FreeSpace / $Datastore.SharedVolumeInfo.Partition.Size * 100), 0) -le ([Int] $Config.Settings.Alarms.DatastoreCriticalRange)) {
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Datastore free space found to be ' + ([Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0)))
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting CriticalStores to True'
                    $CriticalStores = $True
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting DatastoreHealth to [CriticalImage]'
                    $DatastoreHealth = "[CriticalImage]"
                }
                Else {
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting Datastorehealth to [NonCriticalImage]'
                    $DatastoreHealth = "[NonCriticalImage]"
                }
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding datastore to ReportDatastores and calling Format-Size with -Size'
                $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                    'Name'       = $Datastore.SharedVolumeInfo.FriendlyVolumeName
                    'Free Space' = (Format-Size -Size $Datastore.SharedVolumeInfo.Partition.FreeSpace)
                    'Capacity'   = (Format-Size -Size $Datastore.SharedVolumeInfo.Partition.Size)
                    'Free %'     = [Math]::Round(($Datastore.SharedVolumeInfo.Partition.FreeSpace / $Datastore.SharedVolumeInfo.Partition.Size * 100), 0)
                    'Health'     = $DatastoreHealth
                })
            }
        }
        'VMWare' {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Getting Datastores and sorting by name'
            $Datastores = Get-Datastore | Sort-Object Name
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through datastores'
            For ($DatastoreI = 0; $DatastoreI -lt $Datastores.Count; $DatastoreI ++) {
            #ForEach ($Datastore in $Datastores) {
                If ([Math]::Round(($Datastores[$DatastoreI].FreeSpaceMB / $Datastores[$DatastoreI].CapacityMB * 100), 0) -ge ([Int] $Config.Settings.Alarms.DatastoreCriticalRange + 1) -and [Math]::Round(($Datastores[$DatastoreI].FreeSpaceMB / $Datastores[$DatastoreI].CapacityMB * 100), 0) -le ([Int] $Config.Settings.Alarms.DatastoreWarningRange)) {
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Processing Datastore Index ' + $DatastoreI + '. DatastoreName ' + $Datastores[$DatastoreI].Name)
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Datastore free space found to be ' + ([Math]::Round(($Datastores[$DatastoreI].FreeSpaceMB / $Datastores[$DatastoreI].CapacityMB * 100), 0)))
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting WarningStores to True'
                    $WarningStores = $True
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting DatastoreHealth to [WarningImage]'
                    $DatastoreHealth = "[WarningImage]"
                }
                ElseIf ([Math]::Round(($Datastores[$DatastoreI].FreeSpaceMB / $Datastores[$DatastoreI].CapacityMB * 100), 0) -le ([Int] $Config.Settings.Alarms.DatastoreCriticalRange)) {
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Datastore free space found to be ' + ([Math]::Round(($Datastores[$DatastoreI].FreeSpaceMB / $Datastores[$DatastoreI].CapacityMB * 100), 0)))
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting CriticalStores to True'
                    $CriticalStores = $True
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting DatastoreHealth to [CriticalImage]'
                    $DatastoreHealth = "[CriticalImage]"
                }
                Else {
                    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting DatastoreHealth to [NonCriticalImage]'
                    $DatastoreHealth = "[NonCriticalImage]"
                }
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding datastore to ReportDatastores and calling Format-Size with -Size'
                $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                    'Name'       = $Datastores[$DatastoreI].Name
                    'Free Space' = (Format-Size -Size ($Datastores[$DatastoreI].FreeSpaceMB * 1024 * 1024))
                    'Capacity'   = (Format-Size -Size ($Datastores[$DatastoreI].CapacityMB * 1024 * 1024))
                    'Free %'     = [Math]::Round(($Datastores[$DatastoreI].FreeSpaceMB / $Datastores[$DatastoreI].CapacityMB * 100), 0)
                    'Health'     = $DatastoreHealth
                })
            }
        }
    }
    If ($CriticalStores -eq $True) {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Critical Stores found to be set to true'
        #$Global:DatastoreImage = $CriticalImage48
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting Global:DatastoreIcon to [CriticalImage]'
        $Global:DatastoreIcon = "[CriticalImage]"
    }
    ElseIf ($WarningStores -eq $True) {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Warning Stores found to be set to true'
        #$Global:DatastoreImage = $WarningImage48
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting Global:DatastoreIcon to [WarningImage]'
        $Global:DatastoreIcon = "[WarningImage]"
    }
    Else {
        #$Global:DatastoreImage = $NonCriticalImage48
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting Global:DatastoreIcon to [NonCriticalImage]'
        $Global:DatastoreIcon = "[NonCriticalImage]"
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Returning ReportDatastores'
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Get-Datastore Function complete'
    Return $ReportDatastores | Select-Object 'Name', 'Free Space', 'Capacity', 'Free %', 'Health'
}
#endregion
#region Processing Functions
Function Set-Images {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [XML] $Fragment, `
        [Parameter(Mandatory=$True, Position=2)]
        [Int] $ImageSize)

    Switch ($ImageSize) {
        96 {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting NonCriticalImage96 to standard NonCriticalImage'
            $NonCriticalImage = $NonCriticalImage96
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting WarningImage96 to standard WarningImage'
            $WarningImage     = $WarningImage96
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting CriticalImage96 to standard CriticalImage'
            $CriticalImage    = $CriticalImage96
        }
        24 {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting NonCriticalImage24 to standard NonCriticalImage'
            $NonCriticalImage = $NonCriticalImage24
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting WarningImage24 to standard WarningImage'
            $WarningImage     = $WarningImage24
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting CriticalImage24 to standard CriticalImage'
            $CriticalImage    = $CriticalImage24
        }
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Checking if Fragment contains [WarningImage],[NonCriticalImage],[CriticalImage]'
    If ($Fragment.InnerXml.Contains("[WarningImage]") -or $Fragment.InnerXml.Contains("[NonCriticalImage]") -or $Fragment.InnerXml.Contains("[CriticalImage]")) {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message '[WarningImage],[NonCriticalImage],[CriticalImage] Found in fragment. Replacing with ImageTag'
        $ReplacementFragment = $Fragment.InnerXml.Replace("[WarningImage]",$WarningImage).Replace("[NonCriticalImage]",$NonCriticalImage).Replace("[CriticalImage]",$CriticalImage)
    }
    Else {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Not Found'
        $ReplacementFragment = $Fragment.InnerXml
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Returning ReplacementFragment'
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Set-Images complete'
    Return $ReplacementFragment
}
Function Start-OverallHealthProcessing {
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating empty ReturnFragment array'
    $ReturnFragment = @()
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding Overall Health header'
    $ReturnFragment+= "<H2 align='center'>Overall Health</H2>"
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating Global Health Object'
    $GlobalHealth = New-Object -TypeName PSObject -Property @{
        Alarms     = $Global:AlarmIcon
        Hosts      = $Global:HostIcon
        Datastores = $Global:DatastoreIcon
        VMs        = $Global:VMIcon
        Snapshots  = $Global:SnapshotIcon
    } | Select-Object Alarms, Hosts, Datastores, VMs, Snapshots

    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Converting Global Health Object to XML'
    [XML] $GlobalHealthHTML = $GlobalHealth | ConvertTo-Html -Fragment
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting images in ReturnFragment by calling Set-Images with -Fragment GlobalHealthHTML and -ImageSize 96'
    $ReturnFragment += Set-Images -Fragment $GlobalHealthHTML -ImageSize 96
    Return $ReturnFragment
}
Function Start-AlarmsProcessing {
    Param (
        [Parameter(Mandatory=$False, Position=1)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()]
        [Object[]] $ReportAlarms)

    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating empty ReturnFragment variable'
    $ReturnFragment = @()
    #$ReturnFragment += $Global:AlarmImage
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding header Alarms and aligning center'
    $ReturnFragment+= "<H2 align='center'>Alarms</H2>"
    
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Supplied Alarm count: ' + $ReportAlarms.Count.ToString())
    If ($ReportAlarms.Count -gt 0) {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Converting ReportAlarms to AlarmsHTML XML Fragment'
        [XML] $AlarmsHTML = $ReportAlarms | ConvertTo-Html -Fragment
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through AlarmsHTML Table rows'
        For ($AlarmsHTMLIndex = 1; $AlarmsHTMLIndex -le $AlarmsHTML.table.tr.count - 1; $AlarmsHTMLIndex++) {
            If ($AlarmsHTML.table.tr[$AlarmsHTMLIndex].td[4] -eq "[CriticalImage]") { 
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Found [CriticalImage] in table data. Creating attribute Class')
                $class = $AlarmsHTML.CreateAttribute("class")
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting Class value to alert'
                $class.value = 'alert' 
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Apppending $Class to Table Row Attributes'
                $AlarmsHTML.table.tr[$AlarmsHTMLIndex].attributes.append($class) | out-null
            }
            If ($AlarmsHTML.table.tr[$AlarmsHTMLIndex].td[4] -eq "[WarningImage]")  { 
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Found [WarningImage] in table data. Creating attribute Class')
                $class = $AlarmsHTML.CreateAttribute("class")
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting Class value to warning'
                $class.value = 'warning' 
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Apppending $Class to Table Row Attributes'
                $AlarmsHTML.table.tr[$AlarmsHTMLIndex].attributes.append($class) | out-null
            }
        }
    }
    Else {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating empty ReportAlarms Array'
        $ReportAlarms = ,(New-Object -TypeName PSObject -Property @{
            Source     = $null
            Event      = $null
            Category   = $null
            Time       = $null
            Health     = $null
        })
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Converting ReportAlarms into AlarmsHTML in XML'
        [XML] $AlarmsHTML = $ReportAlarms | ConvertTo-Html -Fragment
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Calling Set-Images with -Fragment $AlarmsHTML and -ImageSize 24'
    $ReturnFragment+= Set-Images -Fragment $AlarmsHTML -ImageSize 24
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Returning Returnfragment'
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Start-vCenterAlarmProcessing Complete'
    Return $ReturnFragment
}
Function Start-HostsProcessing {
    Param (
        [Parameter(Mandatory=$False, Position=1)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()]
        [Object[]] $ReportHosts)

    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating empty ReturnFragment'
    $ReturnFragment = @()
    #$ReturnFragment += $Global:HostImage
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding header Hosts and aligning center'
    $ReturnFragment += "<H2 align='center'>Hosts</H2>"
    
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Supplied host count: ' + $ReportHosts.Count.ToString())
    If ($ReportHosts.Count -gt 0) {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Converting ReportHosts to ReportHostsHTML in XML'
        [XML] $ReportHostsHTML = $ReportHosts | ConvertTo-Html -Fragment
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through table rows in ReportHostsHTML'
        For ($ReportHostsHTMLIndex = 1; $ReportHostsHTMLIndex -le $ReportHostsHTML.table.tr.count - 1; $ReportHostsHTMLIndex++) {
            If ($ReportHostsHTML.table.tr[$ReportHostsHTMLIndex].td[3] -eq "[CriticalImage]") {
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating attribute Class'
                $class = $ReportHostsHTML.CreateAttribute("class")
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting value of Class to alert'
                $class.value = 'alert'
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Appending Class Attribute to table row'
                $ReportHostsHTML.table.tr[$ReportHostsHTMLIndex].attributes.append($class) | out-null
            }
            If ($ReportHostsHTML.table.tr[$ReportHostsHTMLIndex].td[3] -eq "[WarningImage]") {
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating attribute Class'
                $class = $ReportHostsHTML.CreateAttribute("class")
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting value of Class to warning'
                $class.value = 'warning'
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Appending Class Attribute to table row'
                $ReportHostsHTML.table.tr[$ReportHostsHTMLIndex].attributes.append($class) | out-null
            }
        }
    }
    Else {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating empty ReportHosts Array'
        $ReportHosts = New-Object -TypeName PSObject -Property @{
            'Name'        = $null
            'State'       = $null
            'Power State' = $null
            'Health'      = $null
        }
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Converting ReportHosts into ReportHostsHTML in XML'
        [XML] $ReportHostsHTML = $ReportHosts | ConvertTo-Html -Fragment
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Calling Set-Images with -Fragment $ReportHostsHTML and -Size 24'
    $ReturnFragment += Set-Images -Fragment $ReportHostsHTML -ImageSize 24
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Returning ReturnFragment'
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Start-HostProcessing Complete'
    Return $ReturnFragment
}
Function Start-DatastoresProcessing {
    Param (
        [Parameter(Mandatory=$False, Position=1)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()]
        [Object[]] $ReportDatastores)

    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating empty ReturnFragment'
    $ReturnFragment = @()
    #$ReturnFragment += $Global:DatastoreImage
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding header Datastores to ReturnFragment and aligning Center'
    $ReturnFragment += "<H2 align='center'>Datastores</H2>"
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Reportdatastore Count: ' + $ReportDatastores.Count.ToString())
    If ($ReportDatastores.Count -gt 0) {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Converting ReportDatastores in DatastoresHTML in XML'
        [XML] $DatastoresHTML = $ReportDatastores | ConvertTo-Html -Fragment
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through DataStoreHTML table rows'
        For ($DatastoresHTMLIndex = 1; $DatastoresHTMLIndex -le $DatastoresHTML.table.tr.count - 1; $DatastoresHTMLIndex++) {
            If ($DatastoresHTML.table.tr[$DatastoresHTMLIndex].td[4] -eq "[CriticalImage]") {
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating attribute Class'
                $class = $DatastoresHTML.CreateAttribute("class")
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting value of Class to alert'
                $class.value = 'alert'
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Appending Class Attribute to table row'
                $DatastoresHTML.table.tr[$DatastoresHTMLIndex].attributes.append($class) | out-null
            }
            If ($DatastoresHTML.table.tr[$DatastoresHTMLIndex].td[4] -eq "[WarningImage]") {
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating attribute Class'
                $class = $DatastoresHTML.CreateAttribute("class")
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting value of Class to alert'
                $class.value = 'warning'
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Appending Class Attribute to table row'
                $DatastoresHTML.table.tr[$DatastoresHTMLIndex].attributes.append($class) | out-null
            }
        }
    }
    Else {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating Empty ReportDatastores object'
        $ReportDatastores = New-Object -TypeName PSOBject -Property @{
            'Name'       = $null
            'Free Space' = $null
            'Capacity'   = $null
            'Free %'     = $null
            'Health'     = $null
        }
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Converting ReportDatastores to DatastoresHTML in XML'
        [XML] $DatastoresHTML = $ReportDatastores | ConvertTo-Html -Fragment
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Calling Set-Image with -Fragment and -ImageSize 24'
    $ReturnFragment += Set-Images -Fragment $DatastoresHTML -ImageSize 24
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Start-DatastoresProcessing Complete'
    Return $ReturnFragment
}
Function Start-VMsProcessing {
    Param (
        [Parameter(Mandatory=$False, Position=1)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()]
        [Object[]] $ReportVMs)

    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating empty ReturnFragment array'
    $ReturnFragment = @()
    #$ReturnFragment += $Global:VMImage
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding header VMs and aligning center'
    $ReturnFragment += "<H2 align='center'>VMs</H2>"
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Supplied VMs count: ' + $ReportVms.Count.ToString())
    If ($ReportVMs.count -gt 0) {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Converting ReportVMs into VMsHTML as XML'
        [XML] $VMsHTML = $ReportVMs | ConvertTo-Html -Fragment
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through VMsHTML Table rows'
        For ($VMsHTMLIndex = 1; $VMsHTMLIndex -le $VMsHTML.table.tr.count - 1; $VMsHTMLIndex++) {
            If ($VMsHTML.table.tr[$VMsHTMLIndex].td[4] -eq "[CriticalImage]") {
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating attribute Class'
                $class = $VMsHTML.CreateAttribute("class")
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting value of Class to alert'
                $class.value = 'alert'
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Appending Class Attribute to table row'
                $VMsHTML.table.tr[$VMsHTMLIndex].attributes.append($class) | out-null
            }
            If ($VMsHTML.table.tr[$VMsHTMLIndex].td[4] -eq "[WarningImage]") {
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating attribute Class'
                $class = $VMsHTML.CreateAttribute("class")
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting value of Class to warning'
                $class.value = 'warning'
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Appending Class Attribute to table row'
                $VMsHTML.table.tr[$VMsHTMLIndex].attributes.append($class) | out-null
            }
        }
    }
    Else {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating empty ReportVMs array'
        $ReportVMs = New-Object -TypeName PSObject -Property @{
            'Name'       = $null
            'IP Address' = $null
            'State'      = $null
            'Tools State' = $null
            'Health'     = $null
        }
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Converting ReportVMs into VMsHTML as XML'
        [XML] $VMsHTML = $ReportVMs | ConvertTo-Html -Fragment
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Calling Set-Images with -Fragment and -ImageSize 24'
    $ReturnFragment += Set-Images -Fragment $VMsHTML -ImageSize 24
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Returning ReturnFragment'
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Start-VMsProcessing Complete'
    Return $ReturnFragment
}
Function Start-SnapshotsProcessing {
    Param (
        [Parameter(Mandatory=$False, Position=1)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()]
        [Object[]] $ReportSnapshots)

    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating empty ReturnFragment'
    $ReturnFragment = @()
    #$ReturnFragment += $Global:SnapshotImage
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding header VM Snapshots and aligning center'
    $ReturnFragment += "<H2 align='center'>VM Snapshots</H2>"
    
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Supplied Snapshot count: ' + $ReportSnapshots.Count.ToString())
    If ($ReportSnapshots.Count -gt 0) {    
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Converting ReportSnapshots to VMSnapshotsHTML in XML'
        [XML] $VMSnapshotsHTML = $ReportSnapshots | ConvertTo-Html -Fragment
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through table rows in VMSnapshotsHTML'
        For ($VMSnapshotsHTMLIndex = 1; $VMSnapshotsHTMLIndex -le $VMSnapshotsHTML.table.tr.count - 1; $VMSnapshotsHTMLIndex++) {
            If ($VMSnapshotsHTML.table.tr[$VMSnapshotsHTMLIndex].td[4] -eq "[CriticalImage]") {
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating attribute Class'
                $class = $VMSnapshotsHTML.CreateAttribute("class")
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting value of Class to alert'
                $class.value = 'alert'
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Appending Class Attribute to table row'
                $VMSnapshotsHTML.table.tr[$VMSnapshotsHTMLIndex].attributes.append($class) | out-null
            }
            If ($VMSnapshotsHTML.table.tr[$VMSnapshotsHTMLIndex].td[4] -eq "[WarningImage]") {
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating attribute Class'
                $class = $VMSnapshotsHTML.CreateAttribute("class")
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting value of Class to warning'
                $class.value = 'warning'
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Appending Class Attribute to table row'
                $VMSnapshotsHTML.table.tr[$VMSnapshotsHTMLIndex].attributes.append($class) | out-null
            }
        }
    }
    Else {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating empty ReportSnapshots Array'
        $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
            'VM'            = $null
            'Name'          = $null
            'Creation Time' = $null
            'Age'           = $null
            'Health'        = $null
        })
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Converting ReportSnapshots into VMSnapshotsHTML in XML'
        [XML] $VMSnapshotsHTML = $ReportSnapshots | ConvertTo-Html -Fragment
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Calling Set-Images with -Fragment $VMSnapshotsHTML and -Size 24'
    $ReturnFragment += Set-Images -Fragment $VMSnapshotsHTML -ImageSize 24
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Returning ReturnFragment'
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Start-SnapshotProcessing Complete'
    Return $ReturnFragment
}
Function Start-ScriptExecutionProcessing {
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating empty ReturnFragment array'
    $ReturnFragment = @()
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding header Script Execution Details'
    $ReturnFragment += "<H3>Script Execution Details</H3>"
    
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating ScriptHostDetails with execution host'
    $ScriptHostDetails = New-Object -TypeName PSObject -Property @{
        'Execution Host' = $env:COMPUTERNAME
        'Version'        = $Global:ScriptVersion.ToString()
    } | Select-Object 'Execution Host', 'Version'
    
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding header Source System and aligning center'
    $ReturnFragment += "<H4 align='center'>Source System</H4>"
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Converting ScriptHostDetails to ScriptHostDetailsHTML in XML'
    [XML] $ScriptHostDetailsHTML = $ScriptHostDetails | ConvertTo-Html -Fragment
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Converting ReportingEnvironment to ReportingEnvironmentHTML in XML'
    [XML] $ReportingEnvironmentHTML = $ReportingEnvironment | Select-Object 'System Name', 'IP Address', 'Common Name', 'Platform' | ConvertTo-HTML
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding ScriptHostDetails to Fragment'
    $ReturnFragment += $ScriptHostDetailsHTML.InnerXml
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding header Target System and aligning center'
    $ReturnFragment += "<H4 align='center'>Target System</H4>"
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding ReportingEnvironment to Fragment'
    $ReturnFragment += $ReportingEnvironmentHTML.InnerXml
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding header Configuration and aligning center'
    $ReturnFragment += "<H3 align='center'>Configuration Used</H4>"
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding header Alarm Limits and aligning center'
    $ReturnFragment += "<H4 align='center'>Alarm Limits</H4>"
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Converting Config File Alarm Limites to ReportConfigAlarms in XML'
    [XML] $ReportConfigAlarms = $Config.Settings.Alarms.ChildNodes | Select-Object Name, '#text' | ConvertTo-Html -Fragment
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding ReportConfigAlarms to Fragment'
    $ReturnFragment += $ReportConfigAlarms.InnerXml
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding header VM Exclusions and aligning center'
    $ReturnFragment += "<H4 align='center'>VM Exclusions</H4>"
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Converting Config File VM Exclusions to ReportConfigVMExclusions in XML'
    [XML] $ReportConfigVMExclusions = $Config.Settings.VMExclusions.ChildNodes | Select-Object Name, '#text' | ConvertTo-Html -Fragment
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding ReportConfigVMExclusions to ReturnFragment'
    $ReturnFragment += $ReportConfigVMExclusions.InnerXml
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding header Snapshots and aligning center'
    $ReturnFragment += "<H4 align='center'>Snapshots</H4>"
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Converting Config File Snapshot settings to ReportConfigSnapshots in XML'
    [XML] $ReportConfigSnapshots = $Config.Settings.Snapshots.ChildNodes | Select-Object Name, '#text' | ConvertTo-Html -Fragment
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Adding ReportConfigSnapshots to ReturnFragment'
    $ReturnFragment += $ReportConfigSnapshots.InnerXml
    
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Returning ReturnFragment'
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Start-ScriptExecutionProcessing Complete'
    Return $ReturnFragment
}
#endregion
#region Post Processing
Function Move-OldReports {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Int] $Days)
    
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Files from: ' + $Config.Settings.Sources.ReportFolder)
    $Files = Get-ChildItem $Config.Settings.Sources.ReportFolder -File
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ($Files.Count.ToString() + ' found')
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through files'
    ForEach ($File in $Files) {
        If (((Get-Date) - $File.CreationTime).Days -gt $Days ) {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ($File.Fullname + ' old. Moving to ' + $Config.Settings.Sources.OldReportFolder)
            Move-Item -Path $File.FullName -Destination $Config.Settings.Sources.OldReportFolder -Force | Out-Null
        }
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Move-OldReports Function Complete'
}
Function Remove-OldLogs {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Int] $Days)
        
    Write-log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Logs in ' + $Config.Settings.Sources.LogFolder)
    $Files = Get-ChildItem $Config.Settings.Sources.LogFolder -File
    Write-log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ($Files.Count.ToString() + ' found')
    Write-log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Looping through files'
    ForEach ($File in $Files) {
        If (((Get-Date) - $File.CreationTime).Days -gt $Days ) {
            Write-log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ($File.Fullname + ' is old and will be deleted')
            Remove-Item -Path $File.FullName -Force | Out-Null
        }
    }
    Write-log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Remove-OldLogs Completed'
}
#endregion

#Module Loading
Write-log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Script Version set to $Global:ScriptVersion" 
Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message '$Config loaded from "C:\iOCO Tools\Scripts\iOCO_RT_Config.xml"'
Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Logfile set to $LogFile"
Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Disabling Invalid Certificate issue"
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
$ReportingEnvironment = New-Object -TypeName PSObject -Property @{
    'System Name'        = $SystemName;
    'IP Address'         = $IPAddress;
    'Common Name'        = $CommonName;
    'Platform'           = $Platform; # Valid Options are HyperVCluster, HyperVStandalone, VMWare, Dummy
    'Username'           = $Username;
    'Password'           = $Password;
}
Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Reporting environment loaded'
Write-Host ("Loading Modules - ") -ForegroundColor White -NoNewLine
    Switch ($ReportingEnvironment.'Platform') {
        "Vmware"           {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Creating VMWare credentials"
            $Credentials = New-Object -TypeName System.Management.Automation.PSCredential($ReportingEnvironment.'Username', (ConvertTo-SecureString -String $ReportingEnvironment.'Password' -AsPlainText -Force))
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Calling Update-Modules Function with '-HyperVisor VMWare'"
            Update-Modules -HyperVisor VMware
        }
        "HyperVStandalone" { 
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Calling Update-Modules Function with '-HyperVisor HyperV'"
            Update-Modules -HyperVisor HyperV 
        }
        "HyperVCluster"    { 
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Calling Update-Modules Function with '-HyperVisor HyperVCluster'"
            Update-Modules -HyperVisor HyperVCluster 
        }
    }
Write-Host "Complete"
Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Finshed loading modules"
#Collecting Data
Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ("Collecting Data for " + $ReportingEnvironment.'Common Name')
Write-Host ("Collecting data for " + $ReportingEnvironment.'Common Name' + " - ") -ForegroundColor Yellow -NoNewLine
Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $ServerConnect to $False'
$ServerConnect = $False
Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ("Testing if " + $ReportingEnvironment.'IP Address' + " is online")
Try {
    If ($ReportingEnvironment.Platform -eq 'VMWare') {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ("Connecting to VI Server on " + $ReportingEnvironment.'IP Address' + " with VMWare credentials")
        Connect-VIServer -Server $ReportingEnvironment.'IP Address' -Credential $Credentials -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Setting $ServerConnect to $True'
        $ServerConnect = $True
    }
    Else {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ("Testing connection to " + $ReportingEnvironment.'IP Address')
        $ServerConnect = Test-Connection -ComputerName $ReportingEnvironment.'IP Address' -Count 1 -Quiet
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message '$ServerConnect set to Test-NetConnection (Quiet) results'
    }
}
Catch { 
    Write-Host $_ -ForegroundColor Red
    Write-Log -LogFile $LogFile -Level Warning -Component $MyInvocation.MyCommand.Name -Message ("Try statement ran into error." + $_)
    $ServerConnect = $False 
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message '$ServerConnect set to $False'
}
Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Checking state of $ServerConnect'
If ($ServerConnect -ne $False) {
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message '$ServerConnect equals $True'
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Checking Platform specified"
    If ($ReportingEnvironment.Platform -eq 'HyperVCluster') {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message "Platform is set to 'HyperVCluster'"
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating $ReportAlarms Array'
        $ReportAlarms     = @()
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating $ReportHosts Array'
        $ReportHosts      = @()
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating $ReportVMs Array'
        $ReportVMs        = @()
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating ReportSnapshots Array'
        $ReportSnapshots  = @()
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting cluster nodes from' + $ReportingEnvironment.'IP Address' + ' and looping through Nodes')
        ForEach ($ClusterHost in (Get-ClusterNode -Cluster $ReportingEnvironment.'IP Address')) {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Calling Get-Alarms Function with -VMHost ' + $ClusterHost.Name)
            ForEach ($ReturnAlarm in (Get-Alarms -Platform $ReportingEnvironment.Platform -VMHost $ClusterHost.Name)) { 
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Adding ' + $ReturnAlarm + ' to $ReportAlarms array')
                $ReportAlarms += $ReturnAlarm 
            }
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Calling Get-Hosts Function with -VMHost ' + $ClusterHost.Name)
            ForEach ($ReturnHost in (Get-Hosts -Platform $ReportingEnvironment.Platform -VMHost $ClusterHost.Name)) { 
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Adding ' + $ReturnHost + ' to $ReportHosts array')
                $ReportHosts += $ReturnHost 
            }
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Calling Get-VMSRunning with -VMHost ' + $ClusterHost.Name)
            ForEach ($ReturnVM in (Get-VMSRunning -Platform $ReportingEnvironment.Platform -VMHost $ClusterHost.Name)) { 
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Adding ' + $ReturnVM + ' to $ReportVMs')
                $ReportVMs += $ReturnVM 
            }
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Calling Get-Snapshots with -VMHost ' + $ClusterHost.Name)
            ForEach ($ReturnSnapshot in (Get-SnapShots -Platform $ReportingEnvironment.Platform -VMHost $ClusterHost.Name)) { 
                Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Adding ' + $ReturnSnapshot + ' to ReportSnapshots')
                $ReportSnapshots += $ReturnSnapshot 
            }
        }
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Calling Get-Datastores with -Cluster ' + $ReportingEnvironment.'IP Address')
        $ReportDatastores = Get-Datastores -Platform $ReportingEnvironment.Platform -Cluster $ReportingEnvironment.'IP Address'
    }
    Else {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Calling Get-Alarms with -VMHost ' + $ReportingEnvironment.'System Name')
        $ReportAlarms     = Get-Alarms -Platform $ReportingEnvironment.Platform -VMHost $ReportingEnvironment.'System Name'
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Calling Get-Hosts with -VMHost ' + $ReportingEnvironment.'System Name')
        $ReportHosts      = Get-Hosts -Platform $ReportingEnvironment.Platform -VMHost $ReportingEnvironment.'System Name'
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Calling Get-VMsRunning with -VMHost ' + $ReportingEnvironment.'System Name')
        $ReportVMs        = Get-VMsRunning -Platform $ReportingEnvironment.Platform -VMHost $ReportingEnvironment.'System Name'
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Calling Get-Snapshots with -VMHost ' + $ReportingEnvironment.'System Name')
        $ReportSnapshots  = Get-SnapShots -Platform $ReportingEnvironment.Platform -VMHost $ReportingEnvironment.'System Name'
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Calling Get-Datastores with -VMHost ' + $ReportingEnvironment.'System Name')
        $ReportDatastores = Get-Datastores -Platform $ReportingEnvironment.Platform -VMHost $ReportingEnvironment.'System Name'
    }
    
    If ($ReportingEnvironment.Platform -eq 'VMWare') {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Disconnecting from VIServer'
        Disconnect-VIServer * -Confirm:$false
    }
    #region Generated Web Images
    #96x96x32
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Set NonCriticalImage96 by calling New-HTMLImage with -ImagePage Non-Critical (96x96x32).png -SquareSize 96'
    $NonCriticalImage96 = New-HTMLImage -ImagePath ($Config.Settings.Sources.ImageFolder + 'Non-Critical (96x96x32).png') -SquareSize 96
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Set NonCriticalImage96 by calling New-HTMLImage with -ImagePage Warning (96x96x32).png -SquareSize 96'
    $WarningImage96     = New-HTMLImage -ImagePath ($Config.Settings.Sources.ImageFolder + 'Warning (96x96x32).png')      -SquareSize 96
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Set NonCriticalImage96 by calling New-HTMLImage with -ImagePage Critical (96x96x32).png -SquareSize 96'
    $CriticalImage96    = New-HTMLImage -ImagePath ($Config.Settings.Sources.ImageFolder + 'Critical (96x96x32).png')     -SquareSize 96

    #24x24x32
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Set NonCriticalImage96 by calling New-HTMLImage with -ImagePage Non-Critical (24x24x32).png -SquareSize 24'
    $NonCriticalImage24 = New-HTMLImage -ImagePath ($Config.Settings.Sources.ImageFolder + 'Non-Critical (24x24x32).png') -SquareSize 24
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Set NonCriticalImage96 by calling New-HTMLImage with -ImagePage Warning (24x24x32).png -SquareSize 24'
    $WarningImage24     = New-HTMLImage -ImagePath ($Config.Settings.Sources.ImageFolder + 'Warning (24x24x32).png')      -SquareSize 24
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Set NonCriticalImage96 by calling New-HTMLImage with -ImagePage Critical (24x24x32).png -SquareSize 24'
    $CriticalImage24    = New-HTMLImage -ImagePath ($Config.Settings.Sources.ImageFolder + 'Critical (24x24x32).png')     -SquareSize 24
    #endregion
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Creating Reporting file by calling New-HtmlReport'
    $ReportFile = New-HTMLReport -ReportingEnvironment $ReportingEnvironment -ReportAlarms $ReportAlarms -ReportHosts $ReportHosts -ReportDatastores $ReportDatastores -ReportVMS $ReportVMs -ReportSnapshots $ReportSnapshots
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Debugging switch set to: ' + $Debugging)
    Switch ($Debugging) {
        $False { 
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Calling Send-Report with -Client and -File'
            Send-Report -Client $ReportingEnvironment.'Common Name' -File $ReportFile -Attachment $LogFile
        }
        $True {
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Debuggined is set to True. No emails are sent'
        }
    }
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Calling Move-Oldreports with -Days' + $Config.Settings.OldFiles.KeepReportsFor)
    Move-OldReports -Days ([Int] $Config.Settings.OldFiles.KeepReportsFor)
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Processing of ReportEnvironment Complete'
    Write-Host "Complete"
}
Else {
    Write-Log -LogFile $LogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message 'ServerConnect = False.'
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Report Failed to run'
    Write-Host "Report Failed" -ForegroundColor Red
}
Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Removing old Logs'
Remove-OldLogs -Days ([Int] $Config.Settings.OldFiles.KeepLogsFor)
Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Debugging switch set to: ' + $Debugging)
<#Switch ($Debugging) {
    $False { 
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Calling Send-Report with -Client -File -Address -Subject'
        Send-Report -Client $ReportingEnvironment.'Common Name' -File $LogFile -Address $Config.Settings.EmailSetup.DebugAddress -Subject ('RT Log ' + $ReportingEnvironment.'Common Name') 
    }
    $True {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message 'Debugging is set to True. No Emails are sent'
    }
}#>