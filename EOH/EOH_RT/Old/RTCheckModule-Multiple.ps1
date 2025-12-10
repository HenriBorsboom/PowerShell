$Global:AlarmImage = $null
$Global:HostImage = $null
$Global:VMImage = $null
$Global:SnapshotImage = $null
$Global:DatastoreImage = $null

Function Load-Modules(){
    $Modules = @()
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
Function Load-vCenters {
    $vCenters = @()
    $vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.5.254'   ; CommonName = 'EOH Midrand Waterfall'; Username = 'root'  ; Password = 'Passw00rd' ; Parameter = ''})
    $vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.33.8'    ; CommonName = 'EOH PE'               ; Username = 'root'  ; Password = 'P@ssw0rd'  ; Parameter = ''})
    $vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.144.27'  ; CommonName = 'EOH Pinmill'          ; Username = 'root'  ; Password = 'con42esx05'; Parameter = ''})
    $vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.172.11'  ; CommonName = 'PTA R21'              ; Username = 'root'  ; Password = 'Passw00rd' ; Parameter = ''})
    $vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.238.11'  ; CommonName = 'Autospec'             ; Username = 'root'  ; Password = 'Fro0ple.'  ; Parameter = 'RT'})
    $vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.2.9.2'     ; CommonName = 'EOH KZN'              ; Username = 'root'  ; Password = 'Passw00rd' ; Parameter = ''})
    $vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.2.17.11'   ; CommonName = 'KZN Gridey'           ; Username = 'root'  ; Password = 'Fro0ple.'  ; Parameter = ''})
    $vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.2.20.11'   ; CommonName = 'Armstrong'            ; Username = 'root'  ; Password = 'Fro0ple'   ; Parameter = ''})
    $vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.3.0.11'    ; CommonName = 'EOH BT Cape Town'     ; Username = 'root'  ; Password = 'password'  ; Parameter = ''})
    $vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.3.0.12'    ; CommonName = 'EOH Cape Town'        ; Username = 'root'  ; Password = 'password'  ; Parameter = ''})
    $vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.3.4.15'    ; CommonName = 'More SBT'             ; Username = 'root'  ; Password = 'Passw00rd' ; Parameter = ''})
    $vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.3.17.11'   ; CommonName = 'EOH-CLEARCPT-VHS1'    ; Username = 'root'  ; Password = 'Fro0ple'   ; Parameter = ''})
    $vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.10.4.100'  ; CommonName = 'Gilloolys'            ; Username = 'eohcorp\hboadm'; Password = 'Trustnoone8521^'          ; Parameter = 'RT'})
    $vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.10.6.16'   ; CommonName = 'EOH FIN'              ; Username = 'root'  ; Password = 'Passw00rd' ; Parameter = ''})
    $vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.10.180.35' ; CommonName = 'Amethyst'             ; Username = 'eohcorp\hboadm'; Password = 'Trustnoone8521^'          ; Parameter = 'RT'})
    $vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.12.5.230'  ; CommonName = 'Teraco'               ; Username = 'root'  ; Password = 'P@ssw0rd1' ; Parameter = 'RT'})
    $vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.12.255.110'; CommonName = 'IMSSD'                ; Username = 'eohcorp\hboadm'; Password = 'Trustnoone8521^'          ; Parameter = 'RT'})
    $Properties = @('IPAddress', 'CommonName', 'Username', 'Password')
    Return ($vCenters | Select $Properties)
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
Function Get-vCenterAlarms {
    $ActiveAlarms = (Get-Datacenter).ExtensionData.TriggeredAlarmState
    $ReportAlarms = @()
    ForEach ($ActiveAlarm in $ActiveAlarms) {
        If ($ActiveAlarm.OverallStatus -eq 'red') { $AlarmHealthIcon = "[CriticalImage]" }
        ElseIf ($ActiveAlarm.OverallStatus -eq 'yellow') { $AlarmHealthIcon = "[WarningImage]" }
        If ($ActiveAlarm.Entity.Value -like "*host*") {
            $AlarmSource = (Get-VMHost -Id $ActiveAlarm.Entity).Name
        }
        ElseIf ($ActiveAlarm.Entity.Value -like "*VirtualMachine*") {
            $AlarmSource = (Get-VM -Id $ActiveAlarm.Entity).Name
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
        }) | Select AlarmHost, AlarmName, OverallStatus, Time, HealthIcon
    }
    If ($ReportAlarms.Count -gt 0) { $Global:AlarmImage = $CriticalImage }
    Else { $Global:AlarmImage = $NonCriticalImage }
    Return $ReportAlarms
}
Function Get-vCenterHosts {
    $ESXHosts = Get-VMHost | Select Name, ConnectionState, PowerState
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
        }) | Select Name, ConnectionState, PowerState, Health, HealthIcon
    }
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
Function Get-vCenterVMS {
    $VMUnhealthyCounter = 0
    $ReportVMs = @()
    ForEach ($VM in (Get-VM | Select Name, PowerState)) {
        If ($VM.PowerState -ne 'PoweredOn') {
            $VMUnhealthyCounter += 1 
            $VMHealthIcon = "[CriticalImage]" 
        }
        Else {
            $VMHealthIcon = "[NonCriticalImage]"
        }
        $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
            Name       = $VM.Name
            Powerstate = $VM.PowerState
            HealthIcon = $VMHealthIcon
        }) | Select Name, PowerState, HealthIcon
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
Function Get-vCenterSnapShots {
    $Snapshots = Get-VM | Get-Snapshot | Select VM, Name, Created
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
        }) | Select VMName, Name, Created, Age, HealthIcon
        
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
Function Get-vCenterDatastores {
    $Datastores = Get-Datastore
    $ReportDatastores = @()
    $WarningStores = $False
    $CriticalStores = $False
    ForEach ($Datastore in $Datastores) {
        If ([Math]::Round(($Datastore.FreeSpaceMB / $Datastore.CapacityMB * 100), 0) -gt 10 -and [Math]::Round(($Datastore.FreeSpaceMB / $Datastore.CapacityMB * 100), 2) -lt 25) { 
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
    $ReturnFragment+= "<H2>VMWare Alarms</H2>"
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
            if ($VMsHTML.table.tr[$VMsHTMLIndex].td[1] -ne 'PoweredOn') {
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

Write-Color -Text "Loading PowerCLI Modules - " -ForegroundColor White -NoNewLine
    Load-Modules
    Write-Color -Complete

$vCenters = Load-vCenters
ForEach ($vCenter in $vCenters) {
Write-Color  -Text "Collecting data for ", $vCenter.CommonName, " - " -ForegroundColor White, Yellow, White -NoNewLine
#region Collect Data
Try {
    Connect-VIServer -Server $vCenter.IPAddress -User $vCenter.Username -Password $vCenter.Password -ErrorAction Stop | Out-Null
    $ServerConnect = $True
}
Catch {
    $ServerConnect = $False
}
If ($ServerConnect -ne $False) {
    $ReportAlarms     = Get-vCenterAlarms
    $ReportHosts      = Get-vCenterHosts
    $ReportVMs        = Get-vCenterVMs
    $ReportSnapshots  = Get-vCenterSnapshots
    $ReportDatastores = Get-vCenterDataStores

    Disconnect-VIServer -Confirm:$false
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
$OutFile = ("C:\EOH_RT\" + $vCenter.CommonName + " - " + $ReportDate + ".html")
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
<h1 align="center">$($vCenter.CommonName)</h1>
<h1 align="center">$(Get-Date)</h1>
</body>
"@
$convertParams = @{
    head = $Head
    body = $fragments
}

ConvertTo-Html @convertParams | out-file $OutFile -Force
SendMail -Client $vCenter.CommonName -File $OutFile
Write-Color -Complete
#endregion
}