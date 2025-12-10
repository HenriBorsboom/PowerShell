Param (
    [Parameter(Mandatory=$False, Position=1)]
    [String] $SystemName = 'IMSSD', `
    [Parameter(Mandatory=$False, Position=2)]
    [String] $IPAddress = '10.12.255.110', `
    [Parameter(Mandatory=$False, Position=3)]
    [String] $CommonName = 'IMSSD', `
    [Parameter(Mandatory=$False, Position=4)] # Valid Options are HyperVCluster, HyperVStandalone, VMWare, Dummy
    [String] $Platform = 'VMWare', `
    [Parameter(Mandatory=$False, Position=5)]
    [String] $Username = 'administrator@vsphere.local', `
    [Parameter(Mandatory=$False, Position=6)]
    [String] $Password = 'P@ssw0rd' )
[String] $Global:ScriptVersion = '4.0.0'
#region Variables
[xml] $Test = Get-Content .\EOHRT_Config.xml

#region Primary Functions
Function Load-Modules(){
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet("VMware", "HyperVCluster","HyperV")]
        [String] $HyperVisor)

    $Modules = @()

    Switch ($HyperVisor) {
        "VMWare" {
            $Modules += ,("VMware.VimAutomation.Core")
            $Modules += ,("VMware.VimAutomation.Vds")
            $Modules += ,("VMware.VimAutomation.Cloud")
            $Modules += ,("VMware.VimAutomation.PCloud")
            $Modules += ,("VMware.VimAutomation.Cis.Core")
            $Modules += ,("VMware.VimAutomation.Storage")
            $Modules += ,("VMware.VimAutomation.HorizonView")
            $Modules += ,("VMware.VimAutomation.HA")
            $Modules += ,("VMware.VimAutomation.vROps")
            $Modules += ,("VMware.VumAutomation")
            $Modules += ,("VMware.DeployAutomation")
            $Modules += ,("VMware.ImageBuilder")
            $Modules += ,("VMware.VimAutomation.License")
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
#endregion
#region HTML Functions
Function Generate-HTMLImage {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $ImagePath, `
        [Parameter(Mandatory=$True, Position=2)]
        [Int] $SquareSize, `
        [Parameter(Mandatory=$False, Position=3)]
        [Switch] $Center)

    $ImageBits =  [Convert]::ToBase64String((Get-Content $ImagePath -Encoding Byte))
    $ImageFile = Get-Item $ImagePath
    $ImageType = $ImageFile.Extension.Substring(1) #strip off the leading .
    If ($Center) {
        $ImageTag = "<Img src='data:image/$ImageType;base64,$($ImageBits)' Alt='$($ImageFile.Name)' style='float:center' width='$($SquareSize)' height='$($SquareSize)' hspace=10>"
    }
    Else {
        $ImageTag = "<Img src='data:image/$ImageType;base64,$($ImageBits)' Alt='$($ImageFile.Name)' style='float:left' width='$($SquareSize)' height='$($SquareSize)' hspace=10>"
    }
    Return $ImageTag
}
Function Generate-HTMLReport {
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

    $ReportDate = (Get-Date -Format 'dd-MM-yyyy HH-mm')
    $OutFile    = ("C:\EOH_RT\" + $ReportingEnvironment.'Common Name' + " - " + $ReportDate + ".html")
    Write-Host ("Generating HTML to " + $OutFile + " - ") -ForegroundColor Yellow -NoNewLine
    $Fragments  = @()
    $Fragments += "<title>$($ReportingEnvironment.'Common Name')</title>"
    $Fragments += "<h1 align='center'>$($ReportingEnvironment.'Common Name')</h1>"
    $Fragments += "<h1 align='center'>$(Get-Date -Format 'dd-MM-yyyy HH:mm')</h1>"
    $Fragments += (Process-OverallHealth)
    $Fragments += (Process-vCenterAlarms -ReportAlarms $ReportAlarms)
    $Fragments += (Process-vCenterHosts -ReportHosts $ReportHosts)
    $Fragments += (Process-vCenterDatastores -ReportDatastores $ReportDatastores)
    $Fragments += (Process-vCenterVMs -ReportVMs $ReportVMs)
    $Fragments += (Process-vCenterSnapshots -ReportSnapshots $ReportSnapshots)
    $Fragments += (Process-ScriptExecution)

    
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
    $ConvertParams = @{
        head = $Head
        body = $fragments
    }

    ConvertTo-Html @ConvertParams | Out-File $OutFile -Force
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

    If ($Platform -like 'Hyper*') { $Platform = 'HyperV' }
    $ReportAlarms = @()
    Switch ($Platform) {
        'HyperV' {
            $AllAlarms    = Get-WinEvent -FilterHashtable @{LogName='System';StartTime=(Get-Date).AddDays($AlarmDateRangeInDays);Level=(1..3);} -ComputerName $VMHost -ErrorAction SilentlyContinue
            $ActiveAlarms = $AllAlarms | Where-Object {$_.Message -like "*hyper*" -or $_.Message -like "*cluster*"}
            ForEach ($ActiveAlarm in $ActiveAlarms) {
                If ($ActiveAlarm.LevelDisplayName -eq 'Error')        { $AlarmHealthIcon = "[CriticalImage]" }
                ElseIf ($ActiveAlarm.LevelDisplayName -eq 'Critical') { $AlarmHealthIcon = "[CriticalImage]" }
                ElseIf ($ActiveAlarm.LevelDisplayName -eq 'Warning')  { $AlarmHealthIcon = "[WarningImage]" }
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
            $ActiveAlarms = (Get-Datacenter).ExtensionData.TriggeredAlarmState
            ForEach ($ActiveAlarm in $ActiveAlarms) {
                If ($ActiveAlarm.OverallStatus -eq 'red')                  { $AlarmHealthIcon = "[CriticalImage]" }
                ElseIf ($ActiveAlarm.OverallStatus -eq 'yellow')           { $AlarmHealthIcon = "[WarningImage]" }
                
                If ($ActiveAlarm.Entity.Value -like "*host*")              { $AlarmSource = (Get-VMHost -Id $ActiveAlarm.Entity).Name }
                ElseIf ($ActiveAlarm.Entity.Type -like "*VirtualMachine*") { $AlarmSource = (Get-VM -Id $ActiveAlarm.Entity).Name }
                ElseIf ($ActiveAlarm.Entity.Type -like "*Datastore*")      { $AlarmSource = (Get-Datastore -Id $ActiveAlarm.Entity).Name }
                Else                                                       { $AlarmSource = "Unknown" }

                $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                    Source     = $AlarmSource
                    Event      = (Get-AlarmDefinition -Id $ActiveAlarm.Alarm).Name
                    Category   = $ActiveAlarm.OverallStatus
                    Time       = $ActiveAlarm.Time
                    Health     = $AlarmHealthIcon
                })
            }
        }
        'Dummy' {
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                Source     = "VM"
                Event      = "Test VM Alarm Name"
                Category   = "Red"
                Time       = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                Health     = "[CriticalImage]"
            }) #Red
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                Source     = "VM"
                Event      = "Test VM Alarm Name"
                Category   = "Yellow"
                Time       = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                Health     = "[WarningImage]"
            }) #Yellow
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                Source     = "VM"
                Event      = "Test VM Alarm Name"
                Category   = "Green"
                Time       = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                Health     = "[NonCriticalImage]"
            }) #Green
            #Hosts
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                Source     = "Host"
                Event      = "Test Host Alarm Name"
                Category   = "Red"
                Time       = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                Health     = "[CriticalImage]"
            }) #Red
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                Source     = "Host"
                Event      = "Test Host Alarm Name"
                Category   = "Yellow"
                Time       = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                Health     = "[WarningImage]"
            }) #Yellow
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                Source     = "Host"
                Event      = "Test Host Alarm Name"
                Category   = "Green"
                Time       = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                Health     = "[NonCriticalImage]"
            }) #Green
            #Datastores
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                Source     = "Datastore"
                Event      = "Test Datastore Alarm Name"
                Category   = "Red"
                Time       = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                Health     = "[CriticalImage]"
            }) #Red
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                Source     = "Datastore"
                Event      = "Test Datastore Alarm Name"
                Category   = "Yellow"
                Time       = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                Health     = "[WarningImage]"
            }) #Yellow
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{ 
                Source     = "Datastore"
                Event      = "Test Datastore Alarm Name"
                Category   = "Green"
                Time       = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                Health     = "[NonCriticalImage]"
            }) #Green
        }
    }
    If ($ReportAlarms.Count -gt 0) { `
        $Global:AlarmImage = $CriticalImage48
        $Global:AlarmIcon = "[CriticalImage]" 
    }
    Else { 
        $Global:AlarmImage = $NonCriticalImage48
        $Global:AlarmIcon = "[NonCriticalImage]"
    }

    Return $ReportAlarms | Select Source, Event, Category, Time, Health
}
Function Get-Hosts {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Platform, `
        [Parameter(Mandatory=$False, Position=2)]
        [String] $VMHost = $env:COMPUTERNAME)

    If ($Platform -like 'Hyper*') { $Platform = 'HyperV' }
    
    $ReportHosts = @()
    $HostUnhealthyCounter = 0

    Switch ($Platform) {
        'HyperV' {
            If (Test-Connection $VMHost -Quiet -ErrorAction Stop) {
                $HealthIcon = '[NonCriticalImage]'
                $State      = 'PoweredOn'
            }
            Else {
                $HostUnhealthyCounter += 1
                $HealthIcon = '[CriticalImage]'
                $State      = 'PoweredOff'
            }
    
            $ReportHosts = (New-Object -TypeName PSObject -Property @{
                'Name'        = $VMHost
                'State'       = $State
                'Power State' = $State
                'Health'      = $HealthIcon
            })
        }
        'VMWare' {
            $ESXHosts = Get-VMHost | Select-Object Name, ConnectionState, PowerState
            $HostUnhealthyCounter = 0
            ForEach ($ESXHost in $ESXHosts) {
                If ($ESXHost.ConnectionState -eq 'Connected' -and $ESXHost.PowerState -eq 'PoweredOn') {
                    $State      = 'OK'
                    $HealthIcon = '[NonCriticalImage]'
                }
                Else {
                    $HostUnhealthyCounter += 1
                    $State      = 'Fail'
                    $HealthIcon = '[CriticalImage]'
                }
                $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                    'Name'        = $ESXHost.Name
                    'State'       = $ESXHost.ConnectionState
                    'Power State' = $ESXHost.PowerState
                    'Health'      = $HealthIcon
                })
            }
        }
        'Dummy' {
            $HostUnhealthyCounter = 2
            $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                'Name'        = 'Test Host 1'
                'State'       = 'Connected'
                'Power State' = 'PoweredOn'
                'Health'      = '[NonCriticalImage]'
            }) # Non Critical
            $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                'Name'        = 'Test Host 2'
                'State'       = 'Not Connected'
                'Power State' = 'PoweredOff'
                'Health'      = '[CriticalImage]'
            }) # Critical
            $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                'Name'        = 'Test Host 3'
                'State'       = 'Connected'
                'Power State' = 'PoweredOff'
                'Health'      = '[WarningImage]'
            }) # Warning
        }
    }

    If ($HostUnhealthyCounter -eq 0) {
        $Global:HostImage = $NonCriticalImage48
        $Global:HostIcon = '[NonCriticalImage]'
    }
    ElseIf ($HostUnhealthyCounter -lt ($ReportHosts.Count / 2)) {
        $Global:HostImage = $WarningImage48
        $Global:HostIcon = '[WarningImage]'
    }
    Else {
        $Global:HostImage = $CriticalImage48
        $Global:HostIcon = '[CriticalImage]'
    }
    Return $ReportHosts | Select-Object 'Name', 'State', 'Power State', 'Health'
}
Function Get-VMSRunning {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Platform, `
        [Parameter(Mandatory=$False, Position=2)]
        [String] $VMHost = $env:COMPUTERNAME)

    If ($Platform -like 'Hyper*') { $Platform = 'HyperV' }
    
    $ReportVMs = @()
    $VMWarningCounter = 0
    $VMCriticalCounter = 0

    Switch ($Platform) {
        'HyperV' {
            $OSCaption = (Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption' -ComputerName $VMHost).Caption
            If ($OSCaption -like '*201*')    { 
                $Namespace = 'root\virtualization\v2' 
                $VMs = Get-VM -ComputerName $VMHost
                ForEach ($VM in $VMs) {
                    If ($VM.State -ne 'Running') {
                        $VMUnhealthyCounter  += 1
                        $VMHealthIcon         = "[CriticalImage]"
                        $VMState              = 'PoweredOff'
                        ForEach ($Exclusion in $VMCriticalExclusionList) {
                            If ($VM.Name -like $Exclusion) {
                                $VMHealthIcon = "[WarningImage]"
                            }
                        }
                    }
                    Else {
                        $VMHealthIcon         = "[NonCriticalImage]"
                        $VMState              = 'PoweredOn'
                    }
                    If ($VM.NetworkAdapters.IPAddresses -eq $null) {
                        $VMIPAdress = ''
                    }
                    Else {
                        If ($VM.NetworkAdapters.IPAddresses.GetType().Name -eq 'Object[]') { 
                            ForEach ($VMIP in $VM.NetworkAdapters.IPAddresses) {
                                If (([System.Net.IPAddress] $VMIP).AddressFamily -ne 'InterNetworkV6') { $VMIPAddress = $VMIP }
                            }
                        }
                        Else {$VMIPAddress = $VM.NetworkAdapters.IPAddresses}
                    }
                    $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                        'Name'       = $VM.Name
                        'IP Address' = $VMIPAddress
                        'State'      = $VMState
                        'Tools State' = ''
                        'Health'     = $VMHealthIcon
                    })
                    $VMIPAddress = $null
                }
            }
            Else { 
                $VMs = Get-WmiObject -Query "Select * from MSVM_ComputerSystem Where Caption = 'Virtual Machine'" -Namespace 'root\virtualization'  -ComputerName $VMHost
    
                ForEach ($VM in $VMs) {
                    If ($VM.EnabledState -eq 3) {
                        $VMUnhealthyCounter  += 1
                        $VMHealthIcon         = "[CriticalImage]"
                        $VMState              = 'PoweredOff'
                        ForEach ($Exclusion in $VMCriticalExclusionList) {
                            If ($VM.ElementName -like $Exclusion) {
                                $VMHealthIcon = "[WarningImage]"
                            }
                        }
                    }
                    Else {
                        $VMHealthIcon         = "[NonCriticalImage]"
                        $VMState              = 'PoweredOn'
                    }
                    
                    $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                        'Name'       = $VM.ElementName
                        'IP Address' = 'Not available on this host'
                        'State'      = $VMState
                        'Tools State' = ''
                        'Health'     = $VMHealthIcon
                    })
                }
            }
        }
        'VMWare' {
            ForEach ($VM in (Get-VM | Select Name, PowerState, @{N="IPAddress";E={@($_.Guest.IPAddress[0])}}, @{N="ToolsRunning";E={$_.ExtensionData.Guest.ToolsStatus}})) {
                If ($VM.PowerState -ne 'PoweredOn') {
                    ForEach ($Exclusion in $VMCriticalExclusionList) {
                        If ($VM.Name.ToLower() -like $Exclusion.ToLower()) {
                            $State = 'Warning'
                        }
                    }
                    If ($State -ne 'Warning') {
                        $VMHealthIcon        = "[CriticalImage]"
                        $VMCriticalCounter += 1 
                    }
                    Else {
                        $VMHealthIcon        = "[WarningImage]"
                        $VMWarningCounter   += 1
                    }
                    $State = $null
                }
                ElseIf ($VM.ToolsRunning -eq 'toolsNotRunning') {
                    $VMHealthIcon        = "[CriticalImage]"
                    $VMCriticalCounter += 1 
                }
                Else {
                    $VMHealthIcon        = "[NonCriticalImage]"
                }
                $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                    'Name'       = $VM.Name
                    'IP Address' = $VM.IPAddress
                    'State'      = $VM.PowerState
                    'Tools State' = $VM.ToolsRunning
                    'Health'     = $VMHealthIcon
                })
            }
        }
        'Dummy' {
            $VMCritcalCounter = 2
            $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                'Name'       = 'Test VM 1'
                'IP Address' = '1.1.1.1'
                'State'      = 'PoweredOn'
                'Tools State' = 'running'
                'Health'     = '[NonCriticalImage]'
            }) # Non Critical
            $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                'Name'       = 'Test VM 2'
                'IP Address' = '2.2.2.2'
                'State'      = 'PoweredOff'
                'Tools State' = 'notRunning'
                'Health'     = '[CriticalImage]'
            }) # Critical
            $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                'Name'       = 'Test VM 3'
                'IP Address' = '3.3.3.3'
                'State'      = 'PoweredMissing'
                'Tools State' = 'notRunning'
                'Health'     = '[WarningImage]'
            }) # Warning
        }
    }
    If ($VMCriticalCounter -eq 0 -and $VMWarningCounter -eq 0) {
        $Global:VMImage = $NonCriticalImage48
        $Global:VMIcon = "[NonCriticalImage]" 
    }
    ElseIf ($VMCriticalCounter -eq 0 -and $VMWarningCounter -gt 0) {
        $Global:VMImage = $WarningImage48
        $Global:VMIcon = "[WarningImage]"
    }
    Else {
        $Global:VMImage = $CriticalImage48
        $Global:VMIcon = "[CriticalImage]" 
    }
    Return $ReportVMs | Select-Object 'Name', 'IP Address', 'State', 'Tools State', 'Health'
}
Function Get-SnapShots {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Platform, `
        [Parameter(Mandatory=$False, Position=2)]
        [String] $VMHost = $env:COMPUTERNAME)

    If ($Platform -like 'Hyper*') { $Platform = 'HyperV' }
    
    $ReportSnapshots        = @()
    $SnapshotsOldAgeCounter = 0

    Switch ($Platform) {
        'HyperV' {
            $OSCaption = (Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption' -ComputerName $VMHost).Caption
            
            If ($OSCaption -like '*2008*')    { $Namespace = 'root\virtualization' }
            ElseIf ($OSCaption -like '*201*') { $Namespace = 'root\virtualization\v2' }
            Else                              { $Namespace = 'root\virtualization' }
    
            $VMs = Get-WmiObject -Query "Select * from MSVM_ComputerSystem Where Caption = 'Virtual Machine'" -Namespace $Namespace
            ForEach ($VM in $VMS) {
                $Query     = ("Select * From Msvm_ComputerSystem Where ElementName='" + $VM.ElementName + "'")
                $SourceVm  = Get-WmiObject -Namespace $Namespace -Query $Query
                $Snapshots = Get-WmiObject -Namespace $Namespace -Query "Associators Of {$SourceVm} Where AssocClass=Msvm_ElementSettingData ResultClass=Msvm_VirtualSystemSettingData"
                If ($Snapshots -ne $null) {
                    $SnapshotCreationTime = [Management.ManagementDateTimeConverter]::ToDateTime($Snapshots.CreationTime)
                    If (((Get-Date) - $SnapshotCreationTime).Days -gt 7) {
                        $SnapshotsOldAgeCounter += 1
                        $SnapshotHealthIcon = "[CriticalImage]"
                    }
                    Else {
                        $SnapshotHealthIcon = "[WarningImage]"
                    }
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
            $Snapshots = Get-VM | Get-Snapshot | Select-Object VM, Name, Created
            ForEach ($Snapshot in $Snapshots) {
                If (((Get-Date) - $Snapshot.Created).Days -gt 7) {
                    $SnapshotsOldAgeCounter += 1
                    $SnapshotHealthIcon      = "[CriticalImage]"
                }
                Else {
                    $SnapshotHealthIcon      = "[WarningImage]"
                }

                $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                    'VM'            = $Snapshot.VM
                    'Name'          = $Snapshot.Name
                    'Creation Time' = $Snapshot.Created
                    'Age'           = ((Get-Date) - $Snapshot.Created).Days
                    'Health'        = $SnapshotHealthIcon
                })
            }
        }
        'Dummy' {
            $SnapshotsOldAgeCounter = 1
            $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                'VM'            = 'Test VM 1'
                'Name'          = 'Test Snapshot 1'
                'Creation Time' = (Get-Date -f "dd/MM/yyyy HH:mm:ss")
                'Age'           = ((Get-Date) - (Get-Date)).Days
                'Health'        = '[NonCriticalImage]'
            }) # Non Critical
            $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                'VM'            = 'Test VM 2'
                'Name'          = 'Test Snapshot 2'
                'Creation Time' = ((Get-Date).AddDays(-3) -f "dd/MM/yyyy HH:mm:ss")
                'Age'           = ((Get-Date) - (Get-Date).AddDays(-3)).Days
                'Health'        = '[WarningImage]'
            }) # Warning
            $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                'VM'            = 'Test VM 3'
                'Name'          = 'Test Snapshot 3'
                'Creation Time' = ((Get-Date).AddDays(-8) -f "dd/MM/yyyy HH:mm:ss")
                'Age'           = ((Get-Date) - (Get-Date).AddDays(-8)).Days
                'Health'        = '[CriticalImage]'
            }) # Critical
        }
    }
    If ($ReportSnapshots.Count -eq 0) {
        $Global:SnapshotImage = $NonCriticalImage48
        $Global:SnapshotIcon = "[NonCriticalImage]"
    }
    ElseIf ($ReportSnapshots.Count -gt 0) {
        $Global:SnapshotImage = $WarningImage48
        $Global:SnapshotIcon = "[WarningImage]"
    }
    If ($SnapshotsOldAgeCounter -gt 0) {
        $Global:SnapshotImage = $CriticalImage48
        $Global:SnapshotIcon = "[CriticalImage]"
    }
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

        If ($Size -le 1024) { $FormattedSize = ($Size.ToString() + " B") }
        ElseIf ($Size -ge 1025 -and $Size -le 1048576) { $FormattedSize = [Math]::Round($Size / 1024, 2).ToString() + " KB" }
        ElseIf ($Size -ge 1048577 -and $Size -le 1073741824) { $FormattedSize = [Math]::Round($Size / 1024 / 1024, 2).ToString() + " MB" }
        ElseIf ($Size -ge 1073741825 -and $Size -le 1099511627776) { $FormattedSize = [Math]::Round($Size / 1024 / 1024 / 1024, 2).ToString() + " GB" }
        ElseIf ($Size -ge 1099511627777 -and $Size -le 1125899906842624) { $FormattedSize = [Math]::Round($Size / 1024 / 1024 / 1024 / 1024, 2).ToString() + " TB" }

        Return $FormattedSize
    }
   
    $WarningStores     = $False
    $CriticalStores    = $False
    $ReportDatastores  = @()

    Switch ($Platform) {
        'HyperVStandalone' {
            $Datastores = Get-WmiObject -Query "Select DeviceID, Size, FreeSpace from Win32_LogicalDisk where DriveType = 3" -ComputerName $VMHost

            ForEach ($Datastore in $Datastores) {
                If ([Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0) -ge ($CriticalRange + 1) -and [Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0) -le $WarningRange) {
                    $WarningStores   = $True
                    $DatastoreHealth = "[WarningImage]"
                }
                ElseIf ([Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0) -le $CriticalRange) {
                    $CriticalStores   = $True
                    $DatastoreHealth = "[CriticalImage]"
                }
                Else {
                    $DatastoreHealth = "[NonCriticalImage]"
                }

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
            $Datastores       = Get-ClusterSharedVolume -Cluster $Cluster
            ForEach ($Datastore in $Datastores) {
                If ([Math]::Round(($Datastore.SharedVolumeInfo.Partition.FreeSpace / $Datastore.SharedVolumeInfo.Partition.Size * 100), 0) -ge ($CriticalRange + 1) -and [Math]::Round(($Datastore.SharedVolumeInfo.Partition.FreeSpace / $Datastore.SharedVolumeInfo.Partition.Size * 100), 0) -le $WarningRange) {
                    $WarningStores = $True
                    $DatastoreHealth = "[WarningImage]"
                }
                ElseIf ([Math]::Round(($Datastore.SharedVolumeInfo.Partition.FreeSpace / $Datastore.SharedVolumeInfo.Partition.Size * 100), 0) -le $CriticalRange) {
                    $CriticalStores = $True
                    $DatastoreHealth = "[CriticalImage]"
                }
                Else {
                    $DatastoreHealth = "[NonCriticalImage]"
                }
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
            $Datastores = Get-Datastore
            ForEach ($Datastore in $Datastores) {
                If ([Math]::Round(($Datastore.FreeSpaceMB / $Datastore.CapacityMB * 100), 0) -ge ($CriticalRange + 1) -and [Math]::Round(($Datastore.FreeSpaceMB / $Datastore.CapacityMB * 100), 2) -le $WarningRange) {
                    $WarningStores = $True
                    $DatastoreHealth = "[WarningImage]"
                }
                ElseIf ([Math]::Round(($Datastore.FreeSpaceMB / $Datastore.CapacityMB * 100), 0) -le $CriticalRange) {
                    $CriticalStores = $True
                    $DatastoreHealth = "[CriticalImage]"
                }
                Else {
                    $DatastoreHealth = "[NonCriticalImage]"
                }
                $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                    'Name'       = $Datastore.Name
                    'Free Space' = (Format-Size -Size ($Datastore.FreeSpaceMB * 1024 * 1024))
                    'Capacity'   = (Format-Size -Size ($Datastore.CapacityMB * 1024 * 1024))
                    'Free %'     = [Math]::Round(($Datastore.FreeSpaceMB / $Datastore.CapacityMB * 100), 0)
                    'Health'     = $DatastoreHealth
                })
            }
        }
        'Dummy' {
            $WarningStores     = $True
            $CriticalStores    = $True
            $ReportDatastores  = @()
            $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                'Name'       = 'Test Data Store 1'
                'Free Space' = '1024'
                'Capacity'   = '1024'
                'Free %'     = '100'
                'Health'     = '[NonCriticalImage]'
            })
            $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                'Name'       = 'Test Data Store 1'
                'Free Space' = '204'
                'Capacity'   = '1024'
                'Free %'     = '20'
                'Health'     = '[WarningImage]'
            })
            $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                'Name'       = 'Test Data Store 1'
                'Free Space' = '102'
                'Capacity'   = '1024'
                'Free %'     = '10'
                'Health'     = '[CriticalImage]'
            })
        }
    }
    If ($CriticalStores -eq $True) {
        $Global:DatastoreImage = $CriticalImage48
        $Global:DatastoreIcon = "[CriticalImage]"
    }
    ElseIf ($WarningStores -eq $True) {
        $Global:DatastoreImage = $WarningImage48
        $Global:DatastoreIcon = "[WarningImage]"
    }
    Else {
        $Global:DatastoreImage = $NonCriticalImage48
        $Global:DatastoreIcon = "[NonCriticalImage]"
    }
    
    Return $ReportDatastores | Select-Object 'Name', 'Free Space', 'Capacity', 'Free %', 'Health'
}
#endregion
#region Processing Functions
Function Embed-Images {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [XML] $Fragment, `
        [Parameter(Mandatory=$True, Position=2)]
        [Int] $ImageSize)

    Switch ($ImageSize) {
        96 {
            $NonCriticalImage = $NonCriticalImage96
            $WarningImage     = $WarningImage96
            $CriticalImage    = $CriticalImage96
        }
        24 {
            $NonCriticalImage = $NonCriticalImage24
            $WarningImage     = $WarningImage24
            $CriticalImage    = $CriticalImage24
        }
    }
    If ($Fragment.InnerXml.Contains("[WarningImage]") -or $Fragment.InnerXml.Contains("[NonCriticalImage]") -or $Fragment.InnerXml.Contains("[CriticalImage]")) {
        $ReplacementFragment = $Fragment.InnerXml.Replace("[WarningImage]",$WarningImage).Replace("[NonCriticalImage]",$NonCriticalImage).Replace("[CriticalImage]",$CriticalImage)
    }
    Else {
        $ReplacementFragment = $Fragment.InnerXml
    }
    Return $ReplacementFragment
}
Function Process-OverallHealth {
    $ReturnFragment = @()
    $ReturnFragment+= "<H2 align='center'>Overall Health</H2>"
    $GlobalHealth = New-Object -TypeName PSObject -Property @{
        Alarms     = $Global:AlarmIcon
        Hosts      = $Global:HostIcon
        Datastores = $Global:DatastoreIcon
        VMs        = $Global:VMIcon
        Snapshots  = $Global:SnapshotIcon
    } | Select Alarms, Hosts, Datastores, VMs, Snapshots

    [XML] $GlobalHealthHTML = $GlobalHealth | ConvertTo-Html -Fragment
    $ReturnFragment += Embed-Images -Fragment $GlobalHealthHTML -ImageSize 96
    Return $ReturnFragment
}
Function Process-vCenterAlarms {
    Param (
        [Parameter(Mandatory=$False, Position=1)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()]
        [Object[]] $ReportAlarms)

    $ReturnFragment = @()
    $ReturnFragment += $Global:AlarmImage
    $ReturnFragment+= "<H2>Alarms</H2>"
    If ($ReportAlarms.Count -gt 0) {
        [XML] $AlarmsHTML = $ReportAlarms | ConvertTo-Html -Fragment
        For ($AlarmsHTMLIndex = 1; $AlarmsHTMLIndex -le $AlarmsHTML.table.tr.count - 1; $AlarmsHTMLIndex++) {
            $class = $AlarmsHTML.CreateAttribute("class")
            If ($AlarmsHTML.table.tr[$AlarmsHTMLIndex].td[4] -eq "[CriticalImage]") { $class.value = 'alert' }
            If ($AlarmsHTML.table.tr[$AlarmsHTMLIndex].td[4] -eq "[WarningImage]")  { $class.value = 'warning' }
            $AlarmsHTML.table.tr[$AlarmsHTMLIndex].attributes.append($class) | out-null
        }
    }
    Else {
        $ReportAlarms = New-Object -TypeName PSObject -Property @{
            Source   = $null
            Event    = $null
            Category = $null
            Time     = $null
            Health   = $null
        }
    }
    [XML] $AlarmsHTML = $ReportAlarms | ConvertTo-Html -Fragment
    $ReturnFragment+= Embed-Images -Fragment $AlarmsHTML -ImageSize 24
    Return $ReturnFragment
}
Function Process-vCenterHosts {
    Param (
        [Parameter(Mandatory=$False, Position=1)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()]
        [Object[]] $ReportHosts)

    $ReturnFragment = @()
    $ReturnFragment += $Global:HostImage
    $ReturnFragment += "<H2>Hosts</H2>"
    If ($ReportHosts.Count -gt 0) {
        [XML] $ReportHostsHTML = $ReportHosts | ConvertTo-Html -Fragment
        For ($ReportHostsHTMLIndex = 1; $ReportHostsHTMLIndex -le $ReportHostsHTML.table.tr.count - 1; $ReportHostsHTMLIndex++) {
            If ($ReportHostsHTML.table.tr[$ReportHostsHTMLIndex].td[2] -ne 'PoweredOn') {
                $class = $ReportHostsHTML.CreateAttribute("class")
                $class.value = 'alert'
                $ReportHostsHTML.table.tr[$ReportHostsHTMLIndex].attributes.append($class) | out-null
            }
        }
    }
    Else {
        $ReportHosts = New-Object -TypeName PSObject -Property @{
            'Name'        = $null
            'State'       = $null
            'Power State' = $null
            'Health'      = $null
        }
        [XML] $ReportHostsHTML = $ReportHosts | ConvertTo-Html -Fragment
    }
    $ReturnFragment += Embed-Images -Fragment $ReportHostsHTML -ImageSize 24
    Return $ReturnFragment
}
Function Process-vCenterDatastores {
    Param (
        [Parameter(Mandatory=$False, Position=1)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()]
        [Object[]] $ReportDatastores)

    $ReturnFragment = @()
    $ReturnFragment += $Global:DatastoreImage
    $ReturnFragment += "<H2>Datastores</H2>"
    If ($ReportDatastores.Count -gt 0) {
        [XML] $DatastoresHTML = $ReportDatastores | ConvertTo-Html -Fragment
        For ($DatastoresHTMLIndex = 1; $DatastoresHTMLIndex -le $DatastoresHTML.table.tr.count - 1; $DatastoresHTMLIndex++) {
            If ([int] $DatastoresHTML.table.tr[$DatastoresHTMLIndex].td[3] -le $CriticalRange) {
                $class = $DatastoresHTML.CreateAttribute("class")
                $class.value = 'alert'
                $DatastoresHTML.table.tr[$DatastoresHTMLIndex].attributes.append($class) | out-null
            }
            ElseIf ([int] $DatastoresHTML.table.tr[$DatastoresHTMLIndex].td[3] -ge ($CriticalRange + 1) -and [int] $DatastoresHTML.table.tr[$DatastoresHTMLIndex].td[3] -le $WarningRange ) {
                $class = $DatastoresHTML.CreateAttribute("class")
                $class.value = 'warning'
                $DatastoresHTML.table.tr[$DatastoresHTMLIndex].attributes.append($class) | out-null
            }
        }
    }
    Else {
        $ReportDatastores = New-Object -TypeName PSOBject -Property @{
            'Name'       = $null
            'Free Space' = $null
            'Capacity'   = $null
            'Free %'     = $null
            'Health'     = $null
        }
        [XML] $DatastoresHTML = $ReportDatastores | ConvertTo-Html -Fragment
    }
    $ReturnFragment += Embed-Images -Fragment $DatastoresHTML -ImageSize 24
    Return $ReturnFragment
}
Function Process-vCenterVMs {
    Param (
        [Parameter(Mandatory=$False, Position=1)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()]
        [Object[]] $ReportVMs)

    $ReturnFragment = @()
    $ReturnFragment += $Global:VMImage
    $ReturnFragment += "<H2>VMs</H2>"
    If ($ReportVMs.count -gt 0) {
        [XML] $VMsHTML = $ReportVMs | ConvertTo-Html -Fragment
        For ($VMsHTMLIndex = 1; $VMsHTMLIndex -le $VMsHTML.table.tr.count - 1; $VMsHTMLIndex++) {
            If ($VMsHTML.table.tr[$VMsHTMLIndex].td[2] -ne 'PoweredOn') {
                $State = 'Critical'
                ForEach ($Exclusion in $VMCriticalExclusionList) {
                    If ($VMsHTML.table.tr[$VMsHTMLIndex].td[0].ToLower() -like $Exclusion.ToLower()) {
                        $State = 'Warning'
                    }
                }
                $class = $VMsHTML.CreateAttribute("class")
                If ($State -eq 'Warning') {
                    $class.value = 'warning'
                }
                Else {
                    $class.value = 'alert'
                }
                $VMsHTML.table.tr[$VMsHTMLIndex].attributes.append($class) | out-null
            }
            ElseIf ($VMsHTML.table.tr[$VMsHTMLIndex].td[3] -eq 'toolsNotRunning' -and $VMsHTML.table.tr[$VMsHTMLIndex].td[2] -eq 'PoweredOn') {
                $State = 'Critical'
                $class = $VMsHTML.CreateAttribute("class")
                If ($State -eq 'Warning') {
                    $class.value = 'warning'
                }
                Else {
                    $class.value = 'alert'
                }
                $VMsHTML.table.tr[$VMsHTMLIndex].attributes.append($class) | out-null
            }
        }
    }
    Else {
        $ReportVMs = New-Object -TypeName PSObject -Property @{
            'Name'       = $null
            'IP Address' = $null
            'State'      = $null
            'Tools State' = $null
            'Health'     = $null
        }
        [XML] $VMsHTML = $ReportVMs | ConvertTo-Html -Fragment
    }
    $ReturnFragment += Embed-Images -Fragment $VMsHTML -ImageSize 24
    Return $ReturnFragment
}
Function Process-vCenterSnapshots {
    Param (
        [Parameter(Mandatory=$False, Position=1)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()]
        [Object[]] $ReportSnapshots)

    $ReturnFragment = @()
    $ReturnFragment += $Global:SnapshotImage
    $ReturnFragment += "<H2>VM Snapshots</H2>"
    If ($ReportSnapshots.Count -gt 0) {
        [XML] $VMSnapshotsHTML = $ReportSnapshots | ConvertTo-Html -Fragment
        For ($VMSnapshotsHTMLIndex = 1; $VMSnapshotsHTMLIndex -le $VMSnapshotsHTML.table.tr.count - 1; $VMSnapshotsHTMLIndex++) {
            if ($VMSnapshotsHTML.table.tr[$VMSnapshotsHTMLIndex].td[3] -ge $AllowedSnapshotAge) {
                $class = $VMSnapshotsHTML.CreateAttribute("class")
                $class.value = 'alert'
                $VMSnapshotsHTML.table.tr[$VMSnapshotsHTMLIndex].attributes.append($class) | out-null
            }
        }
    }
    Else {
        $ReportSnapshots = New-Object -TypeName PSObject -Property @{
            'VM'            = $null
            'Name'          = $null
            'Creation Time' = $null
            'Age'           = $null
            'Health'        = $null
        }
        [XML] $VMSnapshotsHTML = $ReportSnapshots | ConvertTo-Html -Fragment
    }
    $ReturnFragment += Embed-Images -Fragment $VMSnapshotsHTML -ImageSize 24
    Return $ReturnFragment
}
Function Process-ScriptExecution {
    $ReturnFragment = @()
    $ReturnFragment += "<H3>Script Execution Details</H3>"
    
    $ScriptHostDetails = New-Object -TypeName PSObject -Property @{
        'Execution Host' = $env:COMPUTERNAME
        'Version'        = $Global:ScriptVersion.ToString()
    } | Select-Object 'Execution Host', 'Version'
    
    $ReturnFragment += "<H4 align='center'>Source System</H4>"
    [XML] $ScriptHostDetailsHTML = $ScriptHostDetails | ConvertTo-Html -Fragment
    [XML] $ReportingEnvironmentHTML = $ReportingEnvironment | Select-Object 'System Name', 'IP Address', 'Common Name', 'Platform' | ConvertTo-HTML
    $ReturnFragment += $ScriptHostDetailsHTML.InnerXml
    $ReturnFragment += "<H4 align='center'>Target System</H4>"
    $ReturnFragment += $ReportingEnvironmentHTML.InnerXml

    Return $ReturnFragment
}
#endregion
#region Post Processing
Function Move-OldReports {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Int] $Days)
    $Files = Get-ChildItem C:\EOH_RT -File
    ForEach ($File in $Files) {
        If (((Get-Date) - $File.CreationTime).Days -gt $Days ) {
            Move-Item -Path $File.FullName -Destination 'C:\EOH_RT\Old Reports' -Force | Out-Null
        }
    }
}
#endregion

#Module Loading
Write-Host ("Loading Modules - ") -ForegroundColor White -NoNewLine
    Switch ($ReportingEnvironment.'Platform') {
        "Vmware"           {
            $Credentials = New-Object -TypeName System.Management.Automation.PSCredential($ReportingEnvironment.'Username', (ConvertTo-SecureString -String $ReportingEnvironment.'Password' -AsPlainText -Force))
            Load-Modules -HyperVisor VMware
        }
        "HyperVStandalone" { Load-Modules -HyperVisor HyperV }
        "HyperVCluster"    { Load-Modules -HyperVisor HyperVCluster }
    }
Write-Host "Complete"
#Collecting Data
Write-Host ("Collecting data for " + $ReportingEnvironment.'Common Name' + " - ") -ForegroundColor Yellow -NoNewLine
$ServerConnect = $False
Try {
    If ($ReportingEnvironment.Platform -eq 'VMWare') {
        Connect-VIServer -Server $ReportingEnvironment.'IP Address' -Credential $Credentials -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
        $ServerConnect = $True
    }
    Else {
        $ServerConnect = Test-Connection -ComputerName $ReportingEnvironment.'IP Address' -Count 1 -Quiet
    }
}
Catch { $ServerConnect = $False }

If ($ServerConnect -ne $False) {
    If ($ReportingEnvironment.Platform -eq 'HyperVCluster') {
        $ReportAlarms     = @()
        $ReportHosts      = @()
        $ReportVMs        = @()
        $ReportSnapshots  = @()
        ForEach ($ClusterHost in (Get-ClusterNode -Cluster $ReportingEnvironment.'IP Address')) {
            ForEach ($ReturnAlarm in (Get-Alarms -Platform $ReportingEnvironment.Platform -VMHost $ClusterHost.Name))       { $ReportAlarms += $ReturnAlarm }
            ForEach ($ReturnHost in (Get-Hosts -Platform $ReportingEnvironment.Platform -VMHost $ClusterHost.Name))         { $ReportHosts += $ReturnHost }
            ForEach ($ReturnVM in (Get-VMSRunning -Platform $ReportingEnvironment.Platform -VMHost $ClusterHost.Name))             { $ReportVMs += $ReturnVM }
            ForEach ($ReturnSnapshot in (Get-SnapShots -Platform $ReportingEnvironment.Platform -VMHost $ClusterHost.Name)) { $ReportSnapshots += $ReturnSnapshot }
        }
        $ReportDatastores = Get-Datastores -Platform $ReportingEnvironment.Platform -Cluster $ReportingEnvironment.'IP Address'
    }
    Else {
        $ReportAlarms     = Get-Alarms -Platform $ReportingEnvironment.Platform
        $ReportHosts      = Get-Hosts -Platform $ReportingEnvironment.Platform
        $ReportVMs        = Get-VMsRunning -Platform $ReportingEnvironment.Platform
        $ReportSnapshots  = Get-SnapShots -Platform $ReportingEnvironment.Platform
        $ReportDatastores = Get-Datastores -Platform $ReportingEnvironment.Platform
    }
    
    If ($ReportingEnvironment.Platform -eq 'VMWare') {
        Disconnect-VIServer * -Confirm:$false
    }
    #region Generated Web Images
    #96x96x32
    $NonCriticalImage96 = Generate-HTMLImage -ImagePath 'C:\EOH_RT\Images\Non-Critical (96x96x32).png' -SquareSize 96
    $WarningImage96     = Generate-HTMLImage -ImagePath 'C:\EOH_RT\Images\Warning (96x96x32).png'      -SquareSize 96
    $CriticalImage96    = Generate-HTMLImage -ImagePath 'C:\EOH_RT\Images\Critical (96x96x32).png'     -SquareSize 96
    #48x48x32
    $NonCriticalImage48 = Generate-HTMLImage -ImagePath 'C:\EOH_RT\Images\Non-Critical (48x48x32).png' -SquareSize 48
    $WarningImage48     = Generate-HTMLImage -ImagePath 'C:\EOH_RT\Images\Warning (48x48x32).png'      -SquareSize 48
    $CriticalImage48    = Generate-HTMLImage -ImagePath 'C:\EOH_RT\Images\Critical (48x48x32).png'     -SquareSize 48
    #24x24x32
    $NonCriticalImage24 = Generate-HTMLImage -ImagePath 'C:\EOH_RT\Images\Non-Critical (24x24x32).png' -SquareSize 24
    $WarningImage24     = Generate-HTMLImage -ImagePath 'C:\EOH_RT\Images\Warning (24x24x32).png'      -SquareSize 24
    $CriticalImage24    = Generate-HTMLImage -ImagePath 'C:\EOH_RT\Images\Critical (24x24x32).png'     -SquareSize 24
    #endregion
    $ReportFile = Generate-HTMLReport -ReportingEnvironment $ReportingEnvironment -ReportAlarms $ReportAlarms -ReportHosts $ReportHosts -ReportDatastores $ReportDatastores -ReportVMS $ReportVMs -ReportSnapshots $ReportSnapshots
    Send-Report -Client $ReportingEnvironment.'Common Name' -File $ReportFile
    Move-OldReports -Days $OldReportDays
    Write-Host "Complete"
}
Else {
    Write-Host "Report Failed" -ForegroundColor Red
}