$Global:AlarmImage = $null
$Global:HostImage = $null
$Global:VMImage = $null
$Global:SnapshotImage = $null
$Global:DatastoreImage = $null

Function Load-Modules(){
    $Modules = @()
    $Modules += ,("Hyper-V")
    $LoadedModules = Get-Module -Name $Modules -ErrorAction Ignore | % {$_.Name}
    $RegisteredModules = Get-Module -Name $Modules -ListAvailable -ErrorAction Ignore | % {$_.Name}
    $NotLoaded = $RegisteredModules | ? {$LoadedModules -notcontains $_}
   
    ForEach ($Module in $RegisteredModules) {
        If ($LoadedModules -notcontains $Module) {
            Import-Module $Module -ErrorAction SilentlyContinue
        }
   }
}
Function Write-Color {
    [CmdletBinding(DefaultParameterSetName='Normal')]
    Param(
        [Parameter(Mandatory=$True, Position=1,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$True, Position=1,ParameterSetName='Tab')]
        [String[]] $Text, `
        [Parameter(Mandatory=$False, Position=2,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=2,ParameterSetName='Tab')]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory=$False, Position=3,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=3,ParameterSetName='Tab')]
        [ConsoleColor[]] $BackgroundColor, `
        [Parameter(Mandatory=$False, Position=1,ParameterSetName='Complete')]
        [Switch] $Complete, `
	    [Parameter(Mandatory=$False, Position=4,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=4,ParameterSetName='Tab')]
	    [Parameter(Mandatory=$False, Position=2,ParameterSetName='Complete')]
        [Switch] $NoNewLine, `
        [Parameter(Mandatory=$False, Position=5,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=8,ParameterSetName='Tab')]
	    [Parameter(Mandatory=$False, Position=3,ParameterSetName='Complete')]
        [String] $LogFile = "", `
	    [Parameter(Mandatory=$False, Position=5,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=4,ParameterSetName='Complete')]
        [Int16] $StartTab = 0, `
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=5,ParameterSetName='Complete')]
        [Int16] $LinesBefore = 0, `
        [Parameter(Mandatory=$False, Position=7,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Complete')]
        [Int16] $LinesAfter = 0, `
        [Parameter(Mandatory=$False, Position=9,ParameterSetName='Tab')]
        [String] $TimeFormat = "yyyy-MM-dd HH:mm:ss", `
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Normal')]
        [Parameter(Mandatory=$False, Position=10,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=1,ParameterSetName='Counter')]
        [Int64] $IndexCounter, `
        [Parameter(Mandatory=$False, Position=7,ParameterSetName='Normal')]
        [Parameter(Mandatory=$False, Position=11,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=2,ParameterSetName='Counter')]
        [Int64] $TotalCounter)

    Begin {
        $CurrentActionPreference = $ErrorActionPreference;
        $ErrorActionPreference = 'Stop'

        If ($Text.Count -gt 0) {
            If ($BackgroundColor.Count -eq 0 -and $ForegroundColor.Count -eq 0) { $OperationMode = 'WriteHost' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -eq 0) { $OperationMode = 'SingleBackground' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -eq 0) { $OperationMode = 'SingleForeground' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count) { $OperationMode = 'SingleForegroundBackground' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count) { $OperationMode = 'SingleBackgroundForeground' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -ge $Text.Count -or $ForegroundColor.Count -eq 0) { $OperationMode = 'Background' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -ge $Text.Count -or $BackgroundColor.Count -eq 0) { $OperationMode = 'Foreground' }
            ElseIf ($BackgroundColor.Count -eq $Text.Count -and $ForegroundColor.Count -eq $Text.Count) { $OperationMode = 'Normal' }
            Else { Throw }
        }
        If ($Complete -eq $True) { $OperationMode = 'Complete' }
    }
    Process {
        If ($LinesBefore -ne 0) { For ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline } }
        If ($StartTab -ne 0) { For ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewLine } }
        If ($TotalCounter -gt 0 -and $IndexCounter -ge 0) {
            $CounterLength = $TotalCounter.ToString().Length
            Write-Host ("[" + ("{0:D$CounterLength}" -f ($IndexCounter + 1) + "/" + $TotalCounter) + "] ") -ForegroundColor DarkCyan -NoNewline
        }
        If ($OperationMode -eq 'WriteHost') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Foreground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Background') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'SingleBackground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -BackgroundColor $BackgroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'SingleForeground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'SingleForegroundBackground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[0] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'SingleBackgroundForeground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -BackgroundColor $BackgroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'Normal') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Complete') { Write-Host 'Complete' -ForegroundColor Green -NoNewLine }
        If ($LinesAfter -ne 0) { For ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host "`n" } }
    }
    End {
        If ($NoNewLine -eq $False) { Write-Host } Else { }
        If ($LogFile -ne "") {
            $TextToFile = ""
            For ($i = 0; $i -lt $Text.Length; $i++) {
                $TextToFile += $Text[$i]
            }
            Write-Output "[$([datetime]::Now.ToString($TimeFormat))] $TextToFile" | Out-File $LogFile -Encoding unicode -Append
        }
        $ErrorActionPreference = $CurrentActionPreference
    }
}
Function SendMail {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Client, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $File)

    Write-Color -Text 'Sending email - ' -NoNewLine
    $SMTPServer = 'za-smtp-outbound-1.mimecast.co.za'
    $SMTPPort   = 587
    $To         = 'mscloud@eoh.com'
    $From       = 'eohrt_vm_storage@eoh.com'
    $Subject    = ('Daily RT - ' + $Client + ' - ' + '{0:yyyy-MM-dd}' -f (Get-Date))
    $Credential = New-Object -TypeName PSCredential('eohrt_vm_storage@eoh.com',(ConvertTo-SecureString -String 'v3Rystr0nGP@ssword2019' -AsPlainText -Force))
    [String] $Body = Get-Content $File
    
    Send-MailMessage -From $From -BodyAsHtml -Body $Body -SmtpServer $SMTPServer -Subject $Subject -To $To -Port $SMTPPort -Attachments $File -Credential $Credential
}
Function Load-HyperVHosts {
    $HyperVHosts = @()
    $HyperVHosts += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '172.20.10.3'  ; CommonName = 'Eskort East Rand Mall'})
    #$HyperVHosts += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '172.20.16.2'  ; CommonName = 'Eskort Heidelberg 1'})
    #$HyperVHosts += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '172.20.16.7'  ; CommonName = 'Eskort Heidelberg 2'})
    #$HyperVHosts += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '172.20.13.6'  ; CommonName = 'Eskort Nelspruit'})
    #$HyperVHosts += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '172.20.11.61' ; CommonName = 'Eskort Rooihuiskraal'})
    #$HyperVHosts += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '172.20.20.52' ; CommonName = 'Eskort Silverton'})
    #$HyperVHosts += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '172.20.9.3'   ; CommonName = 'Eskort Xavier'})
    #$HyperVHosts += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '1720.2.36.32' ; CommonName = 'Eskort Eskort'})
    #$Properties = @('IPAddress', 'CommonName')
    Return ($HyperVHosts | Select $Properties)
}

#region HTML Images
Function Generate-HTMLImage {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $ImagePath)

    $ImageBits =  [Convert]::ToBase64String((Get-Content $ImagePath -Encoding Byte))
    $ImageFile = Get-Item $ImagePath
    $ImageType = $ImageFile.Extension.Substring(1) #strip off the leading .
    $ImageTag = "<Img src='data:image/$ImageType;base64,$($ImageBits)' Alt='$($ImageFile.Name)' style='float:left' width='24' height='24' hspace=10>"

    Return $ImageTag
}
$NonCriticalImage = Generate-HTMLImage -ImagePath 'C:\EOH_RT\Scripts\Non-Critical.png'
$WarningImage     = Generate-HTMLImage -ImagePath 'C:\EOH_RT\Scripts\Warning.png'
$CriticalImage    = Generate-HTMLImage -ImagePath 'C:\EOH_RT\Scripts\Critical.png'
#endregion
#region Gathering Data
Function Get-HyperVAlarms {
        Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $VMHost)
        
    $AllAlarms = Get-WinEvent -FilterHashtable @{LogName='System';StartTime=(Get-Date).AddDays(-1)} -ComputerName $VMHost
    $ActiveAlarms = $AllAlarms | Where-Object {$_.Message -like "*hyper*"}
    $ReportAlarms = @()
    ForEach ($ActiveAlarm in $ActiveAlarms) {
        If ($ActiveAlarm.EntryType -eq 'Error') { $AlarmHealthIcon = "[CriticalImage]" }
        ElseIf ($ActiveAlarm.EntryType -eq 'Warning') { $AlarmHealthIcon = "[WarningImage]" }
        $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
            AlarmSource   =  $ActiveAlarm.Source
            AlarmName   = $ActiveAlarm.Message
            OverallStatus =  $ActiveAlarm.EntryType
            Time = $ActiveAlarm.Time
            HealthIcon = $AlarmHealthIcon
        }) | Select AlarmSource, AlarmName, OverallStatus, Time, HealthIcon
    }
    If ($ReportAlarms.Count -gt 0) { $Global:AlarmImage = $CriticalImage }
    Else { $Global:AlarmImage = $NonCriticalImage }
    Return $ReportAlarms
}
Function Get-HyperVHosts {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $VMHost)

    $HyperVHost = Get-VMHost -ComputerName $VMHost | Select FullyQualifiedDomainName
    $ReportHosts = @()
    $HostUnhealthyCounter = 0
    #ForEach ($HyperVHost in $HyperVHosts) {
        If ($HyperVHost -ne $null) { 
            $Health = "OK" 
            $HealthIcon = "[NonCriticalImage]"
        } 
        Else { 
            $Health = "Fail" 
            $HostUnhealthyCounter += 1
            $HealthIcon = "[CriticalImage]"
        }
        $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
            Name            = $HyperVHost.FullyQualifiedDomainName
            ConnectionState = 'Connected'
            PowerState      = 'Online'
            Health          = $Health
            HealthIcon      = $HealthIcon
        }) | Select Name, ConnectionState, PowerState, Health, HealthIcon
    #}
    If ($HostUnhealthyCounter -eq 0) {
        $Global:HostImage = $NonCriticalImage
    }
    ElseIf ($HostUnhealthyCounter -lt ($ReportHosts.Count / 2)) {
        $Global:HostImage = $WarningImage
    }
    Else {
        $Global:HostImage = $CriticalImage
    }
    Return $ReportHosts
}
Function Get-HyperVVMS {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $VMHost)
        
    $VMUnhealthyCounter = 0
    $ReportVMs = @()
    ForEach ($VM in (Get-VM -ComputerName $VMhost | Select Name, State)) {
        If ($VM.State -ne 'Running') {
            $VMUnhealthyCounter += 1 
            $VMHealthIcon = "[CriticalImage]" 
        }
        Else {
            $VMHealthIcon = "[NonCriticalImage]"
        }
        $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
            Name       = $VM.Name
            Powerstate = $VM.State
            HealthIcon = $VMHealthIcon
        }) | Select Name, Powerstate, HealthIcon
    }
    If ($VMUnhealthyCounter -eq 0) {
        $Global:VMImage = $NonCriticalImage
    }
    ElseIf ($VMUnhealthyCounter -lt ($VMs.Count / 2)) {
        $Global:VMImage = $WarningImage
    }
    Else {
        $Global:VMImage = $CriticalImage
    }
    Return $ReportVMs
}
Function Get-HyperVSnapShots {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $VMHost)

    $Snapshots = Get-VM -ComputerName $VMHost | Get-VMSnapshot | Select VMName, Name, CreationTime 
    $ReportSnapshots = @()
    $SnapshotsOldAgeCounter = 0
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
        }) | Select VMName, Name, CreationTime, Age, HealthIcon
        
    }
    If ($ReportSnapshots.Count -eq 0) {
        $Global:SnapshotImage = $NonCriticalImage
    }
    ElseIf ($ReportSnapshots.Count -gt 0) {
        $Global:SnapshotImage = $WarningImage
    }
    If ($Global:SnapshotsOldAgeCounter -gt 0) { $Global:SnapshotImage = $CriticalImage }
    Return $ReportSnapshots
}
Function Get-HyperVDatastores {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $VMHost)
    
    $Datastores = Get-WmiObject -Query "Select DeviceID,Size,FreeSpace from Win32_LogicalDisk where DriveType = 3" -ComputerName $VMHost
    $ReportDatastores = @()
    $WarningStores = $False
    $CriticalStores = $False
    ForEach ($Datastore in $Datastores) {
        If ([Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0) -gt 10 -and [Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0) -lt 25) { 
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
        }) | Select Name, FreeSpaceMB, CapacityMB, FreePerc, HealthIcon
    }
    If ($CriticalStores -eq $True) { 
        $Global:DatastoreImage = $CriticalImage 
    }
    ElseIf ($WarningStores -eq $True) { 
        $Global:DatastoreImage = $WarningImage 
    }
    Else {
        $Global:DatastoreImage = $NonCriticalImage
    }
    Return $ReportDatastores
}
#endregion
#region HTML Processing Functions
Function Process-vCenterAlarms {
    Param (
        [Parameter(Mandatory=$True, Position=1)][AllowNull()]
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
            $replacementFragment = $AlarmsHTML.InnerXml.Replace("[WarningImage]",$WarningImage).Replace("[NonCriticalImage]",$NonCriticalImage).Replace("[CriticalImage]",$CriticalImage)
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
        [Parameter(Mandatory=$True, Position=1)][AllowNull()]
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
            $replacementFragment = $ReportHostsHTML.InnerXml.Replace("[WarningImage]",$WarningImage).Replace("[NonCriticalImage]",$NonCriticalImage).Replace("[CriticalImage]",$CriticalImage)
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
        [Parameter(Mandatory=$True, Position=1)][AllowNull()]
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
            ElseIf ([int] $DatastoresHTML.table.tr[$DatastoresHTMLIndex].td[3] -gt 10 -and [int] $DatastoresHTML.table.tr[$DatastoresHTMLIndex].td[3] -lt 25 ) {
                $class = $DatastoresHTML.CreateAttribute("class")
                $class.value = 'warning'
                $DatastoreUnhealthyCounter += 1
                $DatastoresHTML.table.tr[$DatastoresHTMLIndex].attributes.append($class) | out-null
            }
        }
                
        If ($DatastoresHTML.InnerXml.Contains("[WarningImage]") -or $DatastoresHTML.InnerXml.Contains("[NonCriticalImage]") -or $DatastoresHTML.InnerXml.Contains("[CriticalImage]")) {
            $replacementFragment = $DatastoresHTML.InnerXml.Replace("[WarningImage]",$WarningImage).Replace("[NonCriticalImage]",$NonCriticalImage).Replace("[CriticalImage]",$CriticalImage)
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
        [Parameter(Mandatory=$True, Position=1)][AllowNull()]
        [Object[]] $ReportVMs)

    $ReturnFragment = @()
    $ReturnFragment += $Global:VMImage
    $ReturnFragment += "<H2>VMs</H2>"
    If ($ReportVMs.count -gt 0) {
        [xml]$VMsHTML = $ReportVMs | ConvertTo-Html -Fragment
        for ($VMsHTMLIndex = 1; $VMsHTMLIndex -le $VMsHTML.table.tr.count - 1; $VMsHTMLIndex++) {
            if ($VMsHTML.table.tr[$VMsHTMLIndex].td[1] -ne 'Running') {
                $class = $VMsHTML.CreateAttribute("class")
                $class.value = 'alert'
                $VMsHTML.table.tr[$VMsHTMLIndex].attributes.append($class) | out-null
            }
        }
        If ($VMsHTML.InnerXml.Contains("[WarningImage]") -or $VMsHTML.InnerXml.Contains("[NonCriticalImage]") -or $VMsHTML.InnerXml.Contains("[CriticalImage]")) {
            $replacementFragment = $VMsHTML.InnerXml.Replace("[WarningImage]",$WarningImage).Replace("[NonCriticalImage]",$NonCriticalImage).Replace("[CriticalImage]",$CriticalImage)
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
        [Parameter(Mandatory=$True, Position=1)][AllowNull()]
        [Object[]] $ReportSnapshots)

    $ReturnFragment = @()
    $ReturnFragment += $Global:SnapshotImage
    $ReturnFragment += "<H2>VM Snapshots</H2>"
    [xml]$VMSnapshotsHTML = $ReportSnapshots | ConvertTo-Html -Fragment
    for ($VMSnapshotsHTMLIndex = 1; $VMSnapshotsHTMLIndex -le $VMSnapshotsHTML.table.tr.count - 1; $VMSnapshotsHTMLIndex++) {
        if ($VMSnapshotsHTML.table.tr[$VMSnapshotsHTMLIndex].td[3] -ge 7) {
            $class = $VMSnapshotsHTML.CreateAttribute("class")
            $class.value = 'alert'
            $VMSnapshotsHTML.table.tr[$VMSnapshotsHTMLIndex].attributes.append($class) | out-null
        }
    }

    If ($VMSnapshotsHTML.InnerXml.Contains("[WarningImage]") -or $VMSnapshotsHTML.InnerXml.Contains("[NonCriticalImage]") -or $VMSnapshotsHTML.InnerXml.Contains("[CriticalImage]")) {
        $replacementFragment = $VMSnapshotsHTML.InnerXml.Replace("[WarningImage]",$WarningImage).Replace("[NonCriticalImage]",$NonCriticalImage).Replace("[CriticalImage]",$CriticalImage)
    }
    Else {
        $replacementFragment = $VMSnapshotsHTML.InnerXml
    }
    $ReturnFragment += $replacementFragment
    Return $ReturnFragment
}
#endregion

Write-Color -Text "Loading Modules - " -ForegroundColor White -NoNewLine
    Load-Modules
    Write-Color -Complete

$HyperVHosts = Load-HyperVHosts
ForEach ($HyperVHost in $HyperVHosts) {
#For ($HyperVHostIndex = 0; $HyperVHostIndex -lt $HyperVHosts.Count; $HyperVHostIndex ++) {
#$HyperVHost = $HyperVHosts[$HyperVHostIndex]
Write-Color  -Text "Collecting data for ", $HyperVHost.CommonName, " - " -ForegroundColor White, Yellow, White -NoNewLine
#region Collect Data
Try {
    Test-Connection -ComputerName $HyperVHost.IPAddress -Count 1 -Quiet | Out-Null
    $ServerConnect = $True
}
Catch {
    $ServerConnect = $False
}
If ($ServerConnect -ne $False) {
    $ReportAlarms     = Get-HyperVAlarms -VMHost $HyperVHost.IPAddress
    $ReportHosts      = Get-HyperVHosts -VMHost $HyperVHost.IPAddress
    $ReportVMs        = Get-HyperVVMs -VMHost $HyperVHost.IPAddress
    $ReportSnapshots  = Get-HyperVSnapShots -VMHost $HyperVHost.IPAddress
    $ReportDatastores = Get-HyperVDataStores -VMHost $HyperVHost.IPAddress
}
Else {
    $OutFile = ("C:\Temp\" + $vCenter.CommonName + " - " + '{0:yyyy-MM-dd}' -f (Get-Date) + ".html")
    Write-Color -Text "Generating HTML to ", $OutFile, " - " -ForegroundColor White, Yellow, White -NoNewLine
    
    $Fragments = @()
    $Fragments += $CriticalImage
    $Fragments += "<H1>Unable to connect to vCenter</H2>"
    $Fragments+= "<p class='footer'>$(get-date)</p>"

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
<body>
<h1 align="center">$($vCenter.CommonName)</h1>
<h1 align="center">$(Get-Date)</h1>
</body>
"@
    $convertParams = @{
        head = $Head
        body = $fragments
    }
  
    ConvertTo-Html @convertParams | Out-File $OutFile -Force
}
#endregion
#region HTML
#region Process HTML Data
$ReportDate = '{0:yyyy-MM-dd}' -f (Get-Date)
$OutFile = ("C:\EOH_RT\" + $HyperVHost.CommonName + " - " + $ReportDate + ".html")
Write-Color -Text "Generating HTML to ", $OutFile, " - " -ForegroundColor White, Yellow, White -NoNewLine
    
$Fragments = @()
$Fragments += (Process-vCenterAlarms -ReportAlarms $ReportAlarms)
$Fragments += (Process-vCenterHosts -ReportHosts $ReportHosts)
$Fragments += (Process-vCenterDatastores -ReportDatastores $ReportDatastores)
$Fragments += (Process-vCenterVMs -ReportVMs $ReportVMs)
$Fragments += (Process-vCenterSnapshots -ReportSnapshots $ReportSnapshots)
#endregion
#region Format as HTML
$Fragments += "<p class='footer'>$(get-date)</p>"

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
<body>
<h1 align="center">$($HyperVHost.CommonName)</h1>
<h1 align="center">$(Get-Date)</h1>
</body>
"@
$convertParams = @{
    head = $Head
    body = $fragments
}

ConvertTo-Html @convertParams | out-file $OutFile -Force
SendMail -Client $HyperVHost.CommonName -File $OutFile
Write-Color -Complete
#endregion
}