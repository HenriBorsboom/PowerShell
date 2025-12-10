# Notes
# version 2.2
# Updates:
# Added the target details and the servicing host details to the footer
# Optimized the Hyper-V Get VMs Function

Param (
    [Parameter(Mandatory=$False, Position=1)]
    [String] $SystemName, `
    [Parameter(Mandatory=$False, Position=2)]
    [String] $IPAddress, `
    [Parameter(Mandatory=$False, Position=3)]
    [String] $CommonName, `
    [Parameter(Mandatory=$False, Position=4)]
    [String] $Platform, `
    [Parameter(Mandatory=$False, Position=5)]
    [String] $Username, `
    [Parameter(Mandatory=$False, Position=6)]
    [String] $Password)
$Global:ScriptVersion = 2.2


#region Connection
If ($SystemName -eq '' -and $IPAddress -eq '' -and $CommonName -eq '' -and $Platform -eq '' -and $Username -eq '' -and $Password -eq '') {
    $ReportingEnvironment = New-Object -TypeName PSObject -Property @{
        SystemName = 'Dummy';
        IPAddress  = '127.0.0.1';
        CommonName = 'Dummy';
        Platform   = 'Dummy'; # Valid Options are HyperVCluster, HyperVStandalone, VMWare, Dummy
        Username   = '';
        Password   = '';
    }
}
Else {
    $ReportingEnvironment = New-Object -TypeName PSObject -Property @{
        SystemName = $SystemName;
        IPAddress  = $IPAddress;
        CommonName = $CommonName;
        Platform   = $Platform; # Valid Options are HyperVCluster, HyperVStandalone, VMWare
        Username   = $Username;
        Password   = $Password;
    }
}
#endregion
#region Global Variables
$Global:AlarmImage     = $null
$Global:HostImage      = $null
$Global:VMImage        = $null
$Global:SnapshotImage  = $null
$Global:DatastoreImage = $null
$Global:AlarmIcon      = $null
$Global:HostIcon       = $null
$Global:VMIcon         = $null
$Global:SnapshotIcon   = $null
$Global:DatastoreIcon  = $null
#endregion
#region Primary Functions
Function Setup-Credentials {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Username, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $Password)

    $LoadedPassword = New-Object -TypeName System.Management.Automation.PSCredential($Username, (ConvertTo-SecureString -String $Password -AsPlainText -Force))
    Return $LoadedPassword
}
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

    $LoadedModules = Get-Module -Name $Modules -ErrorAction Ignore | ForEach-Object {$_.Name}
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
        [Parameter(Mandatory=$False, Position=3)]
        [Int16] $Port, `
        [Parameter(Mandatory=$False, Position=4)]
        [String] $Address)

    $SMTPServer = 'za-smtp-outbound-1.mimecast.co.za'
    If ($Port -ne 0) { $SMTPPort = $Port }
    Else { $SMTPPort   = 587 }
    If ($Address -eq '') {
        $To         = 'mscloud@eoh.com'
    }
    Else {
        $To = $Address
    }
    $From       = 'eohrt_vm_storage@eoh.com'
    $Subject    = ('Daily RT - ' + $Client + ' - ' + '{0:yyyy-MM-dd}' -f (Get-Date))
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential('eohrt_vm_storage@eoh.com',(ConvertTo-SecureString -String 'v3Rystr0nGP@ssword2019' -AsPlainText -Force))
    [String] $Body = Get-Content $File

    Send-MailMessage -From $From -BodyAsHtml -Body $Body -SmtpServer $SMTPServer -Subject $Subject -To $To -Port $SMTPPort -Attachments $File -Credential $Credential
}
#endregion
#region HTML Functions
Function Generate-HTMLImage {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $ImagePath, `
        [Parameter(Mandatory=$True, Position=2)]
        [Int] $SquareSize)

    $ImageBits =  [Convert]::ToBase64String((Get-Content $ImagePath -Encoding Byte))
    $ImageFile = Get-Item $ImagePath
    $ImageType = $ImageFile.Extension.Substring(1) #strip off the leading .
    If ($SquareSize -gt 0) {
        $ImageTag = "<Img src='data:image/$ImageType;base64,$($ImageBits)' Alt='$($ImageFile.Name)' style='float:left' width='$($SquareSize)' height='$($SquareSize)' hspace=10>"
    }
    Else {
        $ImageTag = "<Img src='data:image/$ImageType;base64,$($ImageBits)' Alt='$($ImageFile.Name)' style='float:left' width='24' height='24' hspace=10>"
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

    $ReportDate = (Get-Date -Format 'dd-MM-yyyy')
    $OutFile = ("C:\EOH_RT\" + $ReportingEnvironment.CommonName + " - " + $ReportDate + ".html")
    Write-Host ("Generating HTML to " + $OutFile + " - ") -ForegroundColor Yellow -NoNewLine
    $Fragments = @()
    $Fragments += "<h1 align='center'>$($ReportingEnvironment.CommonName)</h1>"
    $Fragments += "<h1 align='center'>$(Get-Date)</h1>"
    $Fragments += (Process-OverallHealth)
    $Fragments += (Process-vCenterAlarms -ReportAlarms $ReportAlarms)
    $Fragments += (Process-vCenterHosts -ReportHosts $ReportHosts)
    $Fragments += (Process-vCenterDatastores -ReportDatastores $ReportDatastores)
    $Fragments += (Process-vCenterVMs -ReportVMs $ReportVMs)
    $Fragments += (Process-vCenterSnapshots -ReportSnapshots $ReportSnapshots)

    $Fragments += "<p class='footer'>Script Execution Host: $($env:COMPUTERNAME)"
    $Fragments += "Script Version:        $($Global:ScriptVersion)</p>"
    $Fragments += "<p class='footer'>Target System Name:    $($ReportingEnvironment.SystemName)</p>"
    $Fragments += "<p class='footer'>Target IP Address:     $($ReportingEnvironment.IPAddress)</p>"
    $Fragments += "<p class='footer'>Target Common Name:    $($ReportingEnvironment.CommonName)</p>"
    $Fragments += "<p class='footer'>Target Platform:       $($ReportingEnvironment.Platform)</p>"
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
#region Hyper-V Clusters
Function Get-HyperVAlarms {
        Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $VMHost = $env:COMPUTERNAME)

    $AllAlarms = Get-WinEvent -FilterHashtable @{LogName='System';StartTime=(Get-Date).AddDays(-1);} -ComputerName $VMHost
    $ActiveAlarms = $AllAlarms | Where-Object {$_.Message -like "*hyper*" -or $_.Message -like "*cluster*" -and $_.LevelDisplayName -ne 'Information'}
    $ReportAlarms = @()
    ForEach ($ActiveAlarm in $ActiveAlarms) {
        If ($ActiveAlarm.LevelDisplayName -eq 'Error') { $AlarmHealthIcon = "[CriticalImage]" }
        ElseIf ($ActiveAlarm.LevelDisplayName -eq 'Warning') { $AlarmHealthIcon = "[WarningImage]" }
        ElseIf ($ActiveAlarm.LevelDisplayName -eq 'Information') { Continue }
        $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
            AlarmSource   =  $ActiveAlarms.ProviderName
            AlarmName   = $ActiveAlarm.Message
            OverallStatus =  $ActiveAlarm.LevelDisplayName
            Time = $ActiveAlarm.TimeCreated
            HealthIcon = $AlarmHealthIcon
        }) | Select AlarmSource, AlarmName, OverallStatus, Time, HealthIcon
    }
    If ($ReportAlarms.Count -gt 0) { $Global:AlarmImage = $CriticalImage48; $Global:AlarmIcon = "[CriticalImage]" }
    Else { $Global:AlarmImage = $NonCriticalImage48; $Global:AlarmIcon = "[NonCriticalImage]" }
    Return $ReportAlarms
}
Function Get-HyperVHosts {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $VMHost = $env:COMPUTERNAME)

    If ($VMHost -ne $env:COMPUTERNAME) { $HyperVHost = (Get-VMHost -ComputerName $VMHost).Name }
    Else { $HyperVHost = $env:COMPUTERNAME }

    $ReportHosts = @()
    $HostUnhealthyCounter = 0

    Try {
        Test-Connection $HyperVHost -Quiet -ErrorAction Stop
        $Health = "OK"
        $HealthIcon = "[NonCriticalImage]"
    }
    Catch {
        $Health = "Fail"
        $HostUnhealthyCounter += 1
        $HealthIcon = "[CriticalImage]"
        }
    Finally {
        $ReportHosts = (New-Object -TypeName PSObject -Property @{
            Name            = $HyperVHost
            ConnectionState = 'Connected'
            PowerState      = 'Online'
            Health          = $Health
            HealthIcon      = $HealthIcon
        }) | Select-Object Name, ConnectionState, PowerState, Health, HealthIcon
    }

    If ($HostUnhealthyCounter -eq 0) {
        $Global:HostImage = $NonCriticalImage48
        $Global:HostIcon = "[NonCriticalImage]"
    }
    ElseIf ($HostUnhealthyCounter -lt ($ReportHosts.Count / 2)) {
        $Global:HostImage = $WarningImage48
        $Global:HostIcon = "[WarningImage]"
    }
    Else {
        $Global:HostImage = $CriticalImage48
        $Global:HostIcon = "[CriticalImage]"
    }
    Return $ReportHosts
}
Function Get-HyperVVMS {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $VMHost)

    $VMUnhealthyCounter = 0
    $ReportVMs = @()
    If ($VMHost -ne '') {
        $OSCaption = (Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption' -ComputerName $VMHost).Caption
        If ($OSCaption -like '*2008*') {
            $Namespace = 'root\virtualization'
        }
        ElseIf ($OSCaption -like '*201*') {
            $Namespace = 'root\virtualization\v2'
        }
        Else {
            $Namespace = 'root\virtualization'
        }
        $VMs = Get-WmiObject -Query "Select * from MSVM_ComputerSystem Where Caption = 'Virtual Machine'" -Namespace $Namespace  -ComputerName $VMHost
    }
    Else {
        If ((Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption').Caption -like '*2008*') {
            $Namespace = 'root\virtualization'
        }
        ElseIf ((Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption').Caption -like '*201*') {
            $Namespace = 'root\virtualization\v2'
        }
        Else {
            $Namespace = 'root\virtualization'
        }
        $VMs = Get-WmiObject -Query "Select * from MSVM_ComputerSystem Where Caption = 'Virtual Machine'" -Namespace $Namespace
    }
    ForEach ($VM in $VMs) {
        If ($VM.EnabledState -eq 3) {
            $VMUnhealthyCounter += 1
            $VMHealthIcon = "[CriticalImage]"
            $VMState = 'PoweredOff'
        }
        Else {
            $VMHealthIcon = "[NonCriticalImage]"
            $VMState = 'PoweredOn'
        }
        #Get IP Address
        If ($Namespace -eq 'root\virtualization') {
            $VMIPaddress = 'Not available on this host'
        }
        Else {
            $VMIpaddress = $vm.GetRelated("Msvm_KvpExchangeComponent").GuestIntrinsicExchangeItems | `
                ForEach-Object {
                    $GuestExchangeItemXml = ([XML]$_).SelectSingleNode("/INSTANCE/PROPERTY[@NAME='Name']/VALUE[child::text()='NetworkAddressIPv4']")
                    If ($GuestExchangeItemXml -ne $null) { 
                        $GuestExchangeItemXml.SelectSingleNode("/INSTANCE/PROPERTY[@NAME='Data']/VALUE/child::text()").Value
                    }    
                }
        }
        $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
            Name       = $VM.ElementName
            IPAddress  = $VMIpaddress
            Powerstate = $VMState
            HealthIcon = $VMHealthIcon
        })
    }
    If ($VMUnhealthyCounter -eq 0) {
        $Global:VMImage = $NonCriticalImage48
        $Global:VMIcon = "[NonCriticalImage]"
    }
    ElseIf ($VMUnhealthyCounter -lt ($VMs.Count / 2)) {
        $Global:VMImage = $WarningImage48
        $Global:VMIcon = "[WarningImage]"
    }
    Else {
        $Global:VMImage = $CriticalImage48
        $Global:VMIcon = "[CriticalImage]"
    }
    Return $ReportVMs | Select-Object Name, IPAddress, Powerstate, HealthIcon
}
Function Get-HyperVSnapShots {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $VMHost)

    $ReportSnapshots = @()
    $Snapshots = @()
    $SnapshotsOldAgeCounter = 0

    If ($VMHost -ne '') {
        $Snapshots = Get-VM -ComputerName $VMHost | Get-VMSnapshot | Select-Object VMName, Name, CreationTime
        ForEach ($Snapshot in $Snapshots) {
            If (((Get-Date) - $Snapshot.CreationTime).Days -gt 7) {
                $SnapshotsOldAgeCounter += 1
                $SnapshotHealthIcon = "[CriticalImage]"
            }
            Else {
                $SnapshotHealthIcon = "[WarningImage]"
            }

            $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                VMName = $Snapshot.VMName
                Name = $Snapshot.Name
                Created = $Snapshot.CreationTime
                Age = ((Get-Date) - $Snapshot.CreationTime).Days
                HealthIcon = $SnapshotHealthIcon
            }) | Select-Object VMName, Name, CreationTime, Age, HealthIcon

        }
    }
    Else {
        If ((Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption').Caption -like '*2008*') {
            $Namespace = 'root\virtualization'
        }
        ElseIf ((Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption').Caption -like '*2012*') {
            $Namespace = 'root\virtualization\v2'
        }
        Else {
            $Namespace = 'root\virtualization'
        }
        $VMs = Get-WmiObject -Query "Select * from MSVM_ComputerSystem Where Caption = 'Virtual Machine'" -Namespace $Namespace
        ForEach ($VM in $VMS) {
            $Query = ("Select * From Msvm_ComputerSystem Where ElementName='" + $VM.ElementName + "'")
            $SourceVm = Get-WmiObject -Namespace $Namespace -Query $Query
            $Snapshots = Get-WmiObject -Namespace $Namespace -Query "Associators Of {$SourceVm} Where AssocClass=Msvm_ElementSettingData ResultClass=Msvm_VirtualSystemSettingData"
            If ($Snapshots -ne $null) {
                $SnapshotCreationTime = [Management.ManagementDateTimeConverter]::ToDateTime($Snapshots.CreationTime)
                #$SnapshotAge =
                If (((Get-Date) - $SnapshotCreationTime).Days -gt 7) {
                    $SnapshotsOldAgeCounter += 1
                    $SnapshotHealthIcon = "[CriticalImage]"
                }
                Else {
                    $SnapshotHealthIcon = "[WarningImage]"
                }
                $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                    VMName = $VM.ElementName
                    Name = $Snapshots.ElementName
                    CreationTime = '{0:yyyy/MM/dd HH:mm:ss}' -f $SnapshotCreationTime
                    Age = ((Get-Date) - $SnapshotCreationTime).Days
                    HealthIcon = $SnapshotHealthIcon
                }) | Select-Object VMName, Name, CreationTime, Age, HealthIcon
            }
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
    If ($Global:SnapshotsOldAgeCounter -gt 0) {
        $Global:SnapshotImage = $CriticalImage48
        $Global:SnapshotIcon = "[CriticalImage]"
    }
    Return $ReportSnapshots
}
Function Get-HyperVDatastores {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $VMHost)

    If ($VMHost -ne '') {
        $Datastores = Get-WmiObject -Query "Select DeviceID,Size,FreeSpace from Win32_LogicalDisk where DriveType = 3" -ComputerName $VMHost
    }
    Else {
        $Datastores = Get-WmiObject -Query "Select DeviceID,Size,FreeSpace from Win32_LogicalDisk where DriveType = 3"
    }
    $ReportDatastores = @()
    $WarningStores = $False
    $CriticalStores = $False
    ForEach ($Datastore in $Datastores) {
        If ([Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0) -ge 11 -and [Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0) -le 20) {
            $WarningStores = $True
            $DatastoreHealth = "[WarningImage]"
        }
        ElseIf ([Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0) -le 10) {
            $CriticalStores = $True
            $DatastoreHealth = "[CriticalImage]"
        }
        Else {
            $DatastoreHealth = "[NonCriticalImage]"
        }
        $ReportDatastores += (New-Object -TypeName PSObject -Property @{
            Name = $Datastore.DeviceID
            FreeSpaceMB = $Datastore.FreeSpace
            CapacityMB = $Datastore.Size
            FreePerc = [Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0)
            HealthIcon = $DatastoreHealth
        }) | Select-Object Name, FreeSpaceMB, CapacityMB, FreePerc, HealthIcon
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
    Return $ReportDatastores
}
Function Get-HyperVClusterDatastores {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Cluster)

    $Datastores = Get-ClusterSharedVolume -Cluster $Cluster
    $ReportDatastores = @()
    $WarningStores = $False
    $CriticalStores = $False
    ForEach ($Datastore in $Datastores) {
        If ([Math]::Round(($Datastore.SharedVolumeInfo.Partition.FreeSpace / $Datastore.SharedVolumeInfo.Partition.Size * 100), 0) -gt 10 -and [Math]::Round(($Datastore.SharedVolumeInfo.Partition.FreeSpace / $Datastore.SharedVolumeInfo.Partition.Size * 100), 0) -lt 25) {
            $WarningStores = $True
            $DatastoreHealth = "[WarningImage]"
        }
        ElseIf ([Math]::Round(($Datastore.SharedVolumeInfo.Partition.FreeSpace / $Datastore.SharedVolumeInfo.Partition.Size * 100), 0) -le 10) {
            $CriticalStores = $True
            $DatastoreHealth = "[CriticalImage]"
        }
        Else {
            $DatastoreHealth = "[NonCriticalImage]"
        }
        $ReportDatastores += (New-Object -TypeName PSObject -Property @{
            Name = $Datastore.SharedVolumeInfo.FriendlyVolumeName
            FreeSpaceMB = $Datastore.SharedVolumeInfo.Partition.FreeSpace
            CapacityMB = $Datastore.SharedVolumeInfo.Partition.Size
            FreePerc = [Math]::Round(($Datastore.SharedVolumeInfo.Partition.FreeSpace / $Datastore.SharedVolumeInfo.Partition.Size * 100), 0)
            HealthIcon = $DatastoreHealth
        }) | Select-Object Name, FreeSpaceMB, CapacityMB, FreePerc, HealthIcon
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
    Return $ReportDatastores
}
#endregion
#region VMWare
Function Get-vCenterAlarms {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [Switch] $Dummy)

    Switch ($Dummy) {
        $True {
            $ReportAlarms = @()
            #VMs
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                AlarmSource   = "VM"
                AlarmName     = "Test VM Alarm Name"
                OverallStatus = "Red"
                Time          = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                HealthIcon    = "[CriticalImage]"
            })
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                AlarmSource   = "VM"
                AlarmName     = "Test VM Alarm Name"
                OverallStatus = "Yellow"
                Time          = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                HealthIcon    = "[WarningImage]"
            })
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                AlarmSource   = "VM"
                AlarmName     = "Test VM Alarm Name"
                OverallStatus = "Green"
                Time          = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                HealthIcon    = "[NonCriticalImage]"
            })
            #Hosts
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                AlarmSource   = "Host"
                AlarmName     = "Test Host Alarm Name"
                OverallStatus = "Red"
                Time          = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                HealthIcon    = "[CriticalImage]"
            })
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                AlarmSource   = "Host"
                AlarmName     = "Test Host Alarm Name"
                OverallStatus = "Yellow"
                Time          = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                HealthIcon    = "[WarningImage]"
            })
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                AlarmSource   = "Host"
                AlarmName     = "Test Host Alarm Name"
                OverallStatus = "Green"
                Time          = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                HealthIcon    = "[NonCriticalImage]"
            })
            #Datastores
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                AlarmSource   = "Datastore"
                AlarmName     = "Test Datastore Alarm Name"
                OverallStatus = "Red"
                Time          = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                HealthIcon    = "[CriticalImage]"
            })
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                AlarmSource   = "Datastore"
                AlarmName     = "Test Datastore Alarm Name"
                OverallStatus = "Yellow"
                Time          = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                HealthIcon    = "[WarningImage]"
            })
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                AlarmSource   = "Datastore"
                AlarmName     = "Test Datastore Alarm Name"
                OverallStatus = "Green"
                Time          = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                HealthIcon    = "[NonCriticalImage]"
            })
        }
        $False {
            $ActiveAlarms = (Get-Datacenter).ExtensionData.TriggeredAlarmState
            $ReportAlarms = @()
            ForEach ($ActiveAlarm in $ActiveAlarms) {
                If ($ActiveAlarm.OverallStatus -eq 'red') { $AlarmHealthIcon = "[CriticalImage]" }
                ElseIf ($ActiveAlarm.OverallStatus -eq 'yellow') { $AlarmHealthIcon = "[WarningImage]" }
                If ($ActiveAlarm.Entity.Value -like "*host*") {
                    $AlarmSource = (Get-VMHost -Id $ActiveAlarm.Entity).Name
                }
                ElseIf ($ActiveAlarm.Entity.Type -like "*VirtualMachine*") {
                    $AlarmSource = (Get-VM -Id $ActiveAlarm.Entity).Name
                }
                ElseIf ($ActiveAlarm.Entity.Type -like "*Datastore*") {
                    $AlarmSource = (Get-Datastore -Id $ActiveAlarm.Entity).Name
                }
                Else {
                    $AlarmSource = "Unknown"
                }
                $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                    AlarmSource   = $AlarmSource
                    AlarmName   = (Get-AlarmDefinition -Id $ActiveAlarm.Alarm).Name
                    OverallStatus = $ActiveAlarm.OverallStatus
                    Time = $ActiveAlarm.Time
                    HealthIcon = $AlarmHealthIcon
                })
            }
        }
    }
    If ($ReportAlarms.Count -gt 0) { $Global:AlarmImage = $CriticalImage48; $Global:AlarmIcon = "[CriticalImage]" }
    Else { $Global:AlarmImage = $NonCriticalImage48; $Global:AlarmIcon = "[NonCriticalImage]" }
    Return $ReportAlarms | Select-Object AlarmSource, AlarmName, OverallStatus, Time, HealthIcon
}
Function Get-vCenterHosts {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [Switch] $Dummy)

    Switch ($Dummy) {
        $True {
            $HostUnhealthyCounter = 2
            $ReportHosts = @()
            $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                Name            = "Test Host 1"
                ConnectionState = 'Connected'
                PowerState      = 'PoweredOn'
                Health          = "OK"
                HealthIcon      = "[NonCriticalImage]"
            })
            $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                Name            = "Test Host 2"
                ConnectionState = 'Not Connected'
                PowerState      = 'PoweredOff'
                Health          = "Fail"
                HealthIcon      = "[CriticalImage]"
            })
            $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                Name            = "Test Host 3"
                ConnectionState = 'Connected'
                PowerState      = 'PoweredOff'
                Health          = "Fail"
                HealthIcon      = "[WarningImage]"
            })
        }
        $False {
            $ESXHosts = Get-VMHost | Select-Object Name, ConnectionState, PowerState
            $ReportHosts = @()
            $HostUnhealthyCounter = 0
            ForEach ($ESXHost in $ESXHosts) {
                If ($ESXHost.ConnectionState -eq 'Connected' -and $ESXHost.PowerState -eq 'PoweredOn') {
                    $Health = "OK"
                    $HealthIcon = "[NonCriticalImage]"
                }
                Else {
                    $Health = "Fail"
                    $HostUnhealthyCounter += 1
                    $HealthIcon = "[CriticalImage]"
                }
                $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                    Name            = $ESXHost.Name
                    ConnectionState = $ESXHost.ConnectionState
                    PowerState      = $ESXHost.PowerState
                    Health          = $Health
                    HealthIcon      = $HealthIcon
                })
            }
        }
    }
    If ($HostUnhealthyCounter -eq 0) {
        $Global:HostImage = $NonCriticalImage48
        $Global:HostIcon = "[NonCriticalImage]"
    }
    ElseIf ($HostUnhealthyCounter -lt ($ReportHosts.Count / 2)) {
        $Global:HostImage = $WarningImage48
        $Global:HostIcon = "[WarningImage]"
    }
    Else {
        $Global:HostImage = $CriticalImage48
        $Global:HostIcon = "[CriticalImage]"
    }
    Return $ReportHosts | Select-Object Name, ConnectionState, PowerState, Health, HealthIcon
}
Function Get-vCenterVMS {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [Switch] $Dummy)

    Switch ($Dummy) {
        $True {
            $VMUnhealthyCounter = 2
            $ReportVMs = @()
            $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                Name       = 'Test VM 1'
                IPAddress  = '1.1.1.1'
                Powerstate = 'PoweredOn'
                HealthIcon = '[NonCriticalImage]'
            })
            $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                Name       = 'Test VM 2'
                IPAddress  = '2.2.2.2'
                Powerstate = 'PoweredOff'
                HealthIcon = '[CriticalImage]'
            })
            $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                Name       = 'Test VM 3'
                IPAddress  = '3.3.3.3'
                Powerstate = 'PoweredMissing'
                HealthIcon = '[WarningImage]'
            })
        }
        $False {
            $VMUnhealthyCounter = 0
            $ReportVMs = @()
            ForEach ($VM in (Get-VM | Select Name, PowerState, @{N="IPAddress";E={@($_.guest.IPAddress[0])}})) {
                If ($VM.PowerState -ne 'PoweredOn') {
                    $VMUnhealthyCounter += 1 
                    $VMHealthIcon = "[CriticalImage]" 
                }
                Else {
                    $VMHealthIcon = "[NonCriticalImage]"
                }
                $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                    Name       = $VM.Name
                    IPAddress  = $VM.IPAddress
                    Powerstate = $VM.PowerState
                    HealthIcon = $VMHealthIcon
                })
            }
        }
    }
    If ($VMUnhealthyCounter -eq 0) {
        $Global:VMImage = $NonCriticalImage48
        $Global:VMIcon = "[NonCriticalImage]" 
    }
    ElseIf ($VMUnhealthyCounter -lt ($VMs.Count / 2)) {
        $Global:VMImage = $WarningImage48
        $Global:VMIcon = "[WarningImage]" 
    }
    Else {
        $Global:VMImage = $CriticalImage48
        $Global:VMIcon = "[CriticalImage]" 
    }
    Return $ReportVMs | Select Name, IPAddress, PowerState, HealthIcon
}
Function Get-vCenterSnapShots {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [Switch] $Dummy)

    Switch ($Dummy) {
        $True {
            $SnapshotsOldAgeCounter = 1
            $ReportSnapshots = @()
            $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                VMName     = 'Test VM 1'
                Name       = 'Test Snapshot 1'
                Created    = (Get-Date -f "dd/MM/yyyy HH:mm:ss")
                Age        = ((Get-Date) - (Get-Date)).Days
                HealthIcon = '[NonCriticalImage]'
            })
            $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                VMName     = 'Test VM 2'
                Name       = 'Test Snapshot 2'
                Created    = ((Get-Date).AddDays(-3) -f "dd/MM/yyyy HH:mm:ss")
                Age        = ((Get-Date) - (Get-Date).AddDays(-3)).Days
                HealthIcon = '[WarningImage]'
            })
            $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                VMName     = 'Test VM 3'
                Name       = 'Test Snapshot 3'
                Created    = ((Get-Date).AddDays(-8) -f "dd/MM/yyyy HH:mm:ss")
                Age        = ((Get-Date) - (Get-Date).AddDays(-8)).Days
                HealthIcon = '[CriticalImage]'
            })
        }
        $False {
            $Snapshots = Get-VM | Get-Snapshot | Select-Object VM, Name, Created
            $ReportSnapshots = @()
            $SnapshotsOldAgeCounter = 0
            ForEach ($Snapshot in $Snapshots) {
                If (((Get-Date) - $Snapshot.Created).Days -gt 7) {
                    $SnapshotsOldAgeCounter += 1
                    $SnapshotHealthIcon = "[CriticalImage]"
                }
                Else {
                    $SnapshotHealthIcon = "[WarningImage]"
                }

                $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                    VMName = $Snapshot.VM
                    Name = $Snapshot.Name
                    Created = $Snapshot.Created
                    Age = ((Get-Date) - $Snapshot.Created).Days
                    HealthIcon = $SnapshotHealthIcon
                })

            }
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
    Return $ReportSnapshots | Select-Object VMName, Name, Created, Age, HealthIcon
}
Function Get-vCenterDatastores {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [Switch] $Dummy)
    
    Switch ($Dummy) {
        $True {
            $WarningStores     = $True
            $CriticalStores    = $True
            $ReportDatastores  = @()
            $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                Name        = 'Test Data Store 1'
                FreeSpaceMB = '1024'
                CapacityMB  = '1024'
                FreePerc    = '100'
                HealthIcon  = '[NonCriticalImage]'
            })
            $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                Name        = 'Test Data Store 1'
                FreeSpaceMB = '204'
                CapacityMB  = '1024'
                FreePerc    = '20'
                HealthIcon  = '[WarningImage]'
            })
            $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                Name        = 'Test Data Store 1'
                FreeSpaceMB = '102'
                CapacityMB  = '1024'
                FreePerc    = '10'
                HealthIcon  = '[CriticalImage]'
            })
        }
        $False {
            $Datastores = Get-Datastore
            $ReportDatastores = @()
            $WarningStores = $False
            $CriticalStores = $False
            ForEach ($Datastore in $Datastores) {
                If ([Math]::Round(($Datastore.FreeSpaceMB / $Datastore.CapacityMB * 100), 0) -ge 11 -and [Math]::Round(($Datastore.FreeSpaceMB / $Datastore.CapacityMB * 100), 2) -le 20) {
                    $WarningStores = $True
                    $DatastoreHealth = "[WarningImage]"
                }
                ElseIf ([Math]::Round(($Datastore.FreeSpaceMB / $Datastore.CapacityMB * 100), 0) -le 10) {
                    $CriticalStores = $True
                    $DatastoreHealth = "[CriticalImage]"
                }
                Else {
                    $DatastoreHealth = "[NonCriticalImage]"
                }
                $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                    Name = $Datastore.Name
                    FreeSpaceMB = $Datastore.FreeSpaceMB
                    CapacityMB = $Datastore.CapacityMB
                    FreePerc = [Math]::Round(($Datastore.FreeSpaceMB / $Datastore.CapacityMB * 100), 0)
                    HealthIcon = $DatastoreHealth
                })
            }
            
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
    
    Return $ReportDatastores | Select-Object Name, FreeSpaceMB, CapacityMB, FreePerc, HealthIcon
}
#endregion
#region Processing Functions
Function Process-vCenterAlarms {
    Param (
        [Parameter(Mandatory=$False, Position=1)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()]
        [Object[]] $ReportAlarms)

    $ReturnFragment = @()
    $ReturnFragment += $Global:AlarmImage
    $ReturnFragment+= "<H2>Alarms</H2>"
    If ($ReportAlarms.Count -gt 0) {
        [xml] $AlarmsHTML = $ReportAlarms | ConvertTo-Html -Fragment
        for ($AlarmsHTMLIndex = 1; $AlarmsHTMLIndex -le $AlarmsHTML.table.tr.count - 1; $AlarmsHTMLIndex++) {
            if ($AlarmsHTML.table.tr[$AlarmsHTMLIndex].td[4] -eq "[CriticalImage]") {
                $class = $AlarmsHTML.CreateAttribute("class")
                $class.value = 'alert'
                $AlarmsHTML.table.tr[$AlarmsHTMLIndex].attributes.append($class) | out-null
            }
            if ($AlarmsHTML.table.tr[$AlarmsHTMLIndex].td[4] -eq "[WarningImage]") {
                $class = $AlarmsHTML.CreateAttribute("class")
                $class.value = 'warning'
                $AlarmsHTML.table.tr[$AlarmsHTMLIndex].attributes.append($class) | out-null
            }
        }
        If ($AlarmsHTML.InnerXml.Contains("[WarningImage]") -or $AlarmsHTML.InnerXml.Contains("[NonCriticalImage]") -or $AlarmsHTML.InnerXml.Contains("[CriticalImage]")) {
            $replacementFragment = $AlarmsHTML.InnerXml.Replace("[WarningImage]",$WarningImage24).Replace("[NonCriticalImage]",$NonCriticalImage24).Replace("[CriticalImage]",$CriticalImage24)
        }
        Else {
            $replacementFragment = $ReportAlarms.InnerXml
        }
        $ReturnFragment+= $replacementFragment
    }
    Else { $ReturnFragment += $ReportAlarms | ConvertTo-Html -Fragment }
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
        $HostUnhealthyCounter = 0
        [xml] $ReportHostsHTML = $ReportHosts | ConvertTo-Html -Fragment
        for ($ReportHostsHTMLIndex = 1; $ReportHostsHTMLIndex -le $ReportHostsHTML.table.tr.count - 1; $ReportHostsHTMLIndex++) {
            if ($ReportHostsHTML.table.tr[$ReportHostsHTMLIndex].td[3] -ne 'OK') {
                $class = $ReportHostsHTML.CreateAttribute("class")
                $class.value = 'alert'
                $ReportHostsHTML.table.tr[$ReportHostsHTMLIndex].attributes.append($class) | out-null
                $HostUnhealthyCounter += 1
            }
        }
        If ($ReportHostsHTML.InnerXml.Contains("[WarningImage]") -or $ReportHostsHTML.InnerXml.Contains("[NonCriticalImage]") -or $ReportHostsHTML.InnerXml.Contains("[CriticalImage]")) {
            $replacementFragment = $ReportHostsHTML.InnerXml.Replace("[WarningImage]",$WarningImage24).Replace("[NonCriticalImage]",$NonCriticalImage24).Replace("[CriticalImage]",$CriticalImage24)
        }
        Else {
            $replacementFragment = $ReportHostsHTML.InnerXml
        }
        $ReturnFragment += $replacementFragment
    }
    Else { $ReturnFragment += $ReportHosts | ConvertTo-Html -Fragment }
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
        [xml]$DatastoresHTML = $ReportDatastores | ConvertTo-Html -Fragment
        for ($DatastoresHTMLIndex = 1; $DatastoresHTMLIndex -le $DatastoresHTML.table.tr.count - 1; $DatastoresHTMLIndex++) {
            if ([int] $DatastoresHTML.table.tr[$DatastoresHTMLIndex].td[3] -le 10) {
                $class = $DatastoresHTML.CreateAttribute("class")
                $class.value = 'alert'
                $DatastoreUnhealthyCounter += 1
                $DatastoresHTML.table.tr[$DatastoresHTMLIndex].attributes.append($class) | out-null
            }
            ElseIf ([int] $DatastoresHTML.table.tr[$DatastoresHTMLIndex].td[3] -ge 11 -and [int] $DatastoresHTML.table.tr[$DatastoresHTMLIndex].td[3] -le 20 ) {
                $class = $DatastoresHTML.CreateAttribute("class")
                $class.value = 'warning'
                $DatastoreUnhealthyCounter += 1
                $DatastoresHTML.table.tr[$DatastoresHTMLIndex].attributes.append($class) | out-null
            }
        }

        If ($DatastoresHTML.InnerXml.Contains("[WarningImage]") -or $DatastoresHTML.InnerXml.Contains("[NonCriticalImage]") -or $DatastoresHTML.InnerXml.Contains("[CriticalImage]")) {
            $replacementFragment = $DatastoresHTML.InnerXml.Replace("[WarningImage]",$WarningImage24).Replace("[NonCriticalImage]",$NonCriticalImage24).Replace("[CriticalImage]",$CriticalImage24)
        }
        Else {
            $replacementFragment = $DatastoresHTML.InnerXml
        }
        $ReturnFragment += $replacementFragment
    }
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
        [xml]$VMsHTML = $ReportVMs | ConvertTo-Html -Fragment
        for ($VMsHTMLIndex = 1; $VMsHTMLIndex -le $VMsHTML.table.tr.count - 1; $VMsHTMLIndex++) {
            if ($VMsHTML.table.tr[$VMsHTMLIndex].td[2] -ne 'PoweredOn') {
                $class = $VMsHTML.CreateAttribute("class")
                $class.value = 'alert'
                $VMsHTML.table.tr[$VMsHTMLIndex].attributes.append($class) | out-null
            }
        }
        If ($VMsHTML.InnerXml.Contains("[WarningImage]") -or $VMsHTML.InnerXml.Contains("[NonCriticalImage]") -or $VMsHTML.InnerXml.Contains("[CriticalImage]")) {
            $replacementFragment = $VMsHTML.InnerXml.Replace("[WarningImage]",$WarningImage24).Replace("[NonCriticalImage]",$NonCriticalImage24).Replace("[CriticalImage]",$CriticalImage24)
        }
        Else {
            $replacementFragment = $VMsHTML.InnerXml
        }
        $ReturnFragment += $replacementFragment
    }
    Return $ReturnFragment
}
Function Process-vCenterSnapshots {
    Param (
        [Parameter(Mandatory=$False, Position=1)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()]
        [Object[]] $ReportSnapshots)

    #Read-Host "------------------------Paused----------------------------"
    $ReturnFragment = @()
    $ReturnFragment += $Global:SnapshotImage
    $ReturnFragment += "<H2>VM Snapshots</H2>"
    #Write-host $ReportSnapshots
    #Read-Host "------------------------Paused----------------------------"
    If ($ReportSnapshots.Count -gt 0) {
        [xml]$VMSnapshotsHTML = $ReportSnapshots | ConvertTo-Html -Fragment
        for ($VMSnapshotsHTMLIndex = 1; $VMSnapshotsHTMLIndex -le $VMSnapshotsHTML.table.tr.count - 1; $VMSnapshotsHTMLIndex++) {
            if ($VMSnapshotsHTML.table.tr[$VMSnapshotsHTMLIndex].td[3] -ge 7) {
                $class = $VMSnapshotsHTML.CreateAttribute("class")
                $class.value = 'alert'
                $VMSnapshotsHTML.table.tr[$VMSnapshotsHTMLIndex].attributes.append($class) | out-null
            }
        }
        If ($VMSnapshotsHTML.InnerXml.Contains("[WarningImage]") -or $VMSnapshotsHTML.InnerXml.Contains("[NonCriticalImage]") -or $VMSnapshotsHTML.InnerXml.Contains("[CriticalImage]")) {
            $replacementFragment = $VMSnapshotsHTML.InnerXml.Replace("[WarningImage]",$WarningImage24).Replace("[NonCriticalImage]",$NonCriticalImage24).Replace("[CriticalImage]",$CriticalImage24)
        }
        Else {
            $replacementFragment = $VMSnapshotsHTML.InnerXml
        }
    }
    $ReturnFragment += $replacementFragment
    Return $ReturnFragment
}
Function Process-OverallHealth {
    $ReturnFragment = @()
    $ReturnFragment+= "<H2>Overall Health</H2>"
    $GlobalHealth = New-Object -TypeName PSObject -Property @{
        Alarms = $Global:AlarmIcon
        Hosts = $Global:HostIcon
        Datastores = $Global:DatastoreIcon
        VMs = $Global:VMIcon
        Snapshots = $Global:SnapshotIcon
    } | Select Alarms, Hosts, Datastores, VMs, Snapshots

    [xml] $GlobalHealthHTML = $GlobalHealth | ConvertTo-Html -Fragment
    If ($GlobalHealthHTML.InnerXml.Contains("[WarningImage]") -or $GlobalHealthHTML.InnerXml.Contains("[NonCriticalImage]") -or $GlobalHealthHTML.InnerXml.Contains("[CriticalImage]")) {
        $ReturnFragment += ,($GlobalHealthHTML.InnerXml.Replace("[WarningImage]",$WarningImage96).Replace("[NonCriticalImage]",$NonCriticalImage96).Replace("[CriticalImage]",$CriticalImage96))
    }
    Else {
        $ReturnFragment += ,($GlobalHealthHTML.InnerXml)
    }
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
#Module Loading
Write-Host ("Loading Modules - ") -ForegroundColor White -NoNewLine
    Switch ($ReportingEnvironment.Platform) {
        "Vmware"           {
            $Credentials = Setup-Credentials -Username $ReportingEnvironment.Username -Password $ReportingEnvironment.Password
            Load-Modules -HyperVisor VMware
        }
        "HyperVStandalone" { Load-Modules -HyperVisor HyperV }
        "HyperVCluster"    { Load-Modules -HyperVisor HyperVCluster }
    }
Write-Host "Complete"
#Collecting Data
Write-Host ("Collecting data for " + $ReportingEnvironment.CommonName + " - ") -ForegroundColor Yellow -NoNewLine
#region Collect Data
$ServerConnect = $False
Try {
    If ($ReportingEnvironment.Platform -eq 'VMWare') {
        Connect-VIServer -Server $ReportingEnvironment.IPAddress -Credential $Credentials -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
        $ServerConnect = $True
    }
    Else {
        $ServerConnect = Test-Connection -ComputerName $ReportingEnvironment.IPAddress -Count 1 -Quiet
    }
}
Catch { $ServerConnect = $False }

If ($ServerConnect -ne $False) {
    If ($ReportingEnvironment.Platform -eq 'VMWare') {
        $ReportAlarms     = Get-vCenterAlarms
        $ReportHosts      = Get-vCenterHosts
        $ReportVMs        = Get-vCenterVMs
        $ReportSnapshots  = Get-vCenterSnapshots
        $ReportDatastores = Get-vCenterDataStores
        Disconnect-VIServer * -Confirm:$false
    }
    ElseIf ($ReportingEnvironment.Platform -eq 'HyperVStandalone') {
        $ReportAlarms     = Get-HyperVAlarms
        $ReportHosts      = Get-HyperVHosts
        $ReportVMs        = Get-HyperVVMS
        $ReportSnapshots  = Get-HyperVSnapShots
        $ReportDatastores = Get-HyperVDatastores
    }
    ElseIf ($ReportingEnvironment.Platform -eq 'HyperVCluster') {
        $ReportAlarms     = @()
        $ReportHosts      = @()
        $ReportVMs        = @()
        $ReportSnapshots  = @()
        ForEach ($ClusterHost in (Get-ClusterNode -Cluster $ReportingEnvironment.IPAddress)) {
            ForEach ($ReturnAlarm in (Get-HyperVAlarms -VMHost $ClusterHost.Name))       { $ReportAlarms += $ReturnAlarm }
            ForEach ($ReturnHost in (Get-HyperVHosts -VMHost $ClusterHost.Name))         { $ReportHosts += $ReturnHost }
            ForEach ($ReturnVM in (Get-HyperVVMs -VMHost $ClusterHost.Name))             { $ReportVMs += $ReturnVM }
            ForEach ($ReturnSnapshot in (Get-HyperVSnapShots -VMHost $ClusterHost.Name)) { $ReportSnapshots += $ReturnSnapshot }
        }
        $ReportDatastores = Get-HyperVClusterDatastores -Cluster $ReportingEnvironment.IPAddress
    }
    ElseIf ($ReportingEnvironment.Platform -eq 'Dummy') {
        $ReportAlarms     = Get-vCenterAlarms -Dummy
        $ReportHosts      = Get-vCenterHosts -Dummy
        $ReportVMs        = Get-vCenterVMs -Dummy
        $ReportSnapshots  = Get-vCenterSnapshots -Dummy
        $ReportDatastores = Get-vCenterDataStores -Dummy
    }
    $ReportFile = Generate-HTMLReport -ReportingEnvironment $ReportingEnvironment -ReportAlarms $ReportAlarms -ReportHosts $ReportHosts -ReportDatastores $ReportDatastores -ReportVMS $ReportVMs -ReportSnapshots $ReportSnapshots
    Send-Report -Client $ReportingEnvironment.CommonName -File $ReportFile
    Move-OldReports -Days 8
    Write-Host "Complete"
}
Else {
    Write-Host "Report Failed" -ForegroundColor Red
}
#endregion
