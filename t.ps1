$Server = 'CN3814281EF33E'
$User = 'a'
[XML] $GlobalConfig = Get-Content 'C:\HealthCheck\Scripts\Config.xml'

Write-host $Server -ForegroundColor Red
        Write-Host $User -ForegroundColor red
    
        If (!(Test-Path ($GlobalConfig.Settings.Sources.ReportFolder + $User + '\' + $Server))) {
                New-Item ($GlobalConfig.Settings.Sources.ReportFolder + $User + '\' + $Server) -Type Directory | Out-Null
        }

        $a = "<style>" 
        $a = $a + "BODY{background-color:#999999;}" 
        $a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}" 
        $a = $a + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:thistle;}" 
        $a = $a + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:#e6e6e6;}" 
        $a = $a + "a{ color: black; }"
        $a = $a + "a:hover { color: yellow; }"
        $a = $a + "</style>"
        Function Get-DiskInfo {
                Param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $Server
                )

                $Volumes = Get-WmiObject win32_volume -ComputerName $Server | `
                        Where-Object {$_.caption -notlike 'S:\' -and $_.drivetype -ne 5 -and $_.label -ne 'System Reserved' -and $_.capacity -gt 1} | `
                                Select-Object caption, `
                                        @{n='FreeSpace';e={[int]($_.freespace/1GB)}},
                                        @{n='Capacity';e={[int]($_.Capacity/1GB)}},
                                        @{n='Free%';e={[int](($_.freespace/$_.capacity)*100)}},label,driveletter | `
                                                ConvertTo-Html -Head a$
                $ErrorAmount = 0
                $HTMLVolumes = @()
                foreach($Line in $Volumes)
                {
                        $Test = $Line
                        Try {
                        if([int]$Line.Split('<')[8].substring(3) -lt 10)
                        {
                                $ErrorAmount ++
                                $HTMLVolumes += $Line.substring(0,8) + '<span style="background-color: red;">' + $Line.Substring(8)
                        }
                        Else {
                                $HTMLVolumes += $Test
                        }
                        }
                        Catch {
                        $HTMLVolumes += $Test
                        }
                }

                Return ((Add-BackButtons -HTML $HTMLVolumes),$ErrorAmount)
        }
        Function Get-EventLogs {
                param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $Server,
                        [Parameter(Mandatory=$True, Position=2)]
                        [String] $Logname, `
                        [Parameter(Mandatory=$False, Position=3)]
                        [Int] $Level, `
                        [Parameter(Mandatory=$False, Position=4)]
                        [Int[]] $ID                
                )
                $StartTime = (Get-Date).AddDays(-$GlobalConfig.Settings.Alarms.AlarmDateRangeInDays)

                If ($Level -gt 0) {
                        $Events = Get-WinEvent -FilterHashtable @{Logname= $Logname; StartTime=$StartTime; Level=$Level} -ErrorAction SilentlyContinue -Force -ComputerName $Server | `
                                Select-Object ID, ProviderName, Message
                        
                        If ($Events.Message.Count -gt 0) {
                                $ErrorAmount = $Events.Message.Count
                        }
                        
                        $ReturnEvents = $Events | Group-Object MESSAGE | ForEach-Object{ 
                                $temp = " " | Select-Object COUNT,ID,ProviderName,MESSAGE
                                $temp.count = $_.count
                                $temp.ID = $_.group | Select-Object -ExpandProperty ID -unique
                                $temp.ProviderName = $_.group | Select-Object -ExpandProperty ProviderName -unique
                                $temp.MESSAGE = $_.group | Select-Object -ExpandProperty message -unique
                                $temp} | Sort-Object count -descending | ConvertTo-Html -head $a
                }
                ElseIf ($ID.Count -gt 0) {
                        $Events = Get-WinEvent -FilterHashtable @{Logname=$Logname; StartTime=$StartTime; ID=$ID} -ErrorAction SilentlyContinue -Force -ComputerName $Server | `
                                Select-Object ID, ProviderName, Message

                        If ($Events.Message.Count -gt 0) {
                                $ErrorAmount = $Events.Message.Count
                        }
                        $ReturnEvents = $Events | Group-Object MESSAGE | ForEach-Object{ 
                                $temp = " " | Select-Object COUNT,ID,ProviderName,MESSAGE
                                $temp.count = $_.count
                                $temp.ID = $_.group | Select-Object -ExpandProperty ID -unique
                                $temp.ProviderName = $_.group | Select-Object -ExpandProperty ProviderName -unique
                                $temp.MESSAGE = $_.group | Select-Object -ExpandProperty message -unique
                                $temp} | Sort-Object count -descending | ConvertTo-Html -head $a
                }
                Return ((Add-BackButtons -HTML $ReturnEvents), $ErrorAmount)
        } # Returns [0] HTML Events [1] ErrorAmount
        Function Get-ShadowCopies {
                Param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $Server
                )
                Function Get-RemoteShadowCopyInformation {
                        Param ($ComputerName)
                        Filter ConvertTo-KMG  {
                                $bytecount = $_
                                switch ([math]::truncate([math]::log($bytecount,1024)))  {
                                0 {"$bytecount Bytes"}
                                1 {"{0:n2} KB" -f ($bytecount / 1kb)}
                                2 {"{0:n2} MB" -f ($bytecount / 1mb)}
                                3 {"{0:n2} GB" -f ($bytecount / 1gb)}
                                4 {"{0:n2} TB" -f ($bytecount / 1tb)}
                                default {"{0:n2} PB" -f ($bytecount / 1pb)}
                                }
                        }
                        Try {
                                Write-Verbose -Message ("Get-RemoteShadowCopyInformation: Runspace {0}: Start" -f $ComputerName)
                                $WMIHast = @{
                                ComputerName = $ComputerName
                                ErrorAction = "Stop"
                                }
                                if (($LocalHost -notcontains $ComputerName) -and ($null -ne $Credential)) {
                                $WMIHast.Credential = $Credential
                                }

                                # General variables
                                $PSDateTime = Get-Date

                                #region Data Collection
                                Write-Verbose -Message ("Get-RemoteShadowCopyInformation: Runspace {0}: Share session information" -f $ComputerName)

                                # Modify this variable to change your default set of display properties
                                $defaultProperties    = @("ComputerName","ShadowCopyVolumes","ShadowCopySettings", "ShadowCopyProviders","ShadowCopies")

                                $wmi_shadowcopyareas = Get-WmiObject @WMIHast -Class win32_shadowstorage
                                $wmi_volumeinfo =  Get-WmiObject @WMIHast -Class win32_volume
                                $wmi_shadowcopyproviders = Get-WmiObject @WMIHast -Class Win32_ShadowProvider
                                $wmi_shadowcopysettings = Get-WmiObject @WMIHast -Class Win32_ShadowContext
                                $wmi_shadowcopies = Get-WmiObject @WMIHast -Class Win32_ShadowCopy
                                $ShadowCopyVolumes = @()
                                $ShadowCopyProviders = @()
                                $ShadowCopySettings = @()
                                $ShadowCopies = @()
                                foreach ($shadow in $wmi_shadowcopyareas) {
                                foreach ($volume in $wmi_volumeinfo) {
                                        if ($shadow.Volume -like "*$($volume.DeviceId.trimstart("\\?\Volume").trimend("\"))*") {
                                        $ShadowCopyVolumeProperty =  @{
                                                "Drive" = $volume.Name
                                                "DriveCapacity" = $volume.Capacity | ConvertTo-KMG
                                                "ShadowSizeMax" = $shadow.MaxSpace  | ConvertTo-KMG
                                                "ShadowSizeUsed" = $shadow.UsedSpace  | ConvertTo-KMG
                                                "ShadowCapacityUsed" = [math]::round((($shadow.UsedSpace/$shadow.MaxSpace) * 100),2)
                                                "VolumeCapacityUsed" = [math]::round((($shadow.UsedSpace/$volume.Capacity) * 100),2)
                                        }
                                        $ShadowCopyVolumes += New-Object -TypeName PSObject -Property $ShadowCopyVolumeProperty
                                        }
                                }
                                }
                                foreach ($scprovider in $wmi_shadowcopyproviders) {
                                $SCCopyProviderProp = @{
                                        "Name" = $scprovider.Name
                                        "CLSID" = $scprovider.CLSID
                                        "ID" = $scprovider.ID
                                        "Type" = $scprovider.Type
                                        "Version" = $scprovider.Version
                                        "VersionID" = $scprovider.VersionID
                                }
                                $ShadowCopyProviders += New-Object -TypeName PSObject -Property $SCCopyProviderProp
                                }
                                foreach ($scsetting in $wmi_shadowcopysettings) {
                                $SCSettingProperty = @{
                                        "Name" = $scsetting.Name
                                        "ClientAccessible" = $scsetting.ClientAccessible
                                        "Differential" = $scsetting.Differential
                                        "ExposedLocally" = $scsetting.ExposedLocally
                                        "ExposedRemotely" = $scsetting.ExposedRemotely
                                        "HardwareAssisted" = $scsetting.HardwareAssisted
                                        "Imported" = $scsetting.Imported
                                        "NoAutoRelease" = $scsetting.NoAutoRelease
                                        "NotSurfaced" = $scsetting.NotSurfaced
                                        "NoWriters" = $scsetting.NoWriter
                                        "Persistent" = $scsetting.Persistent
                                        "Plex" = $scsetting.Plex
                                        "Transportable" = $scsetting.Transportable
                                }
                                $ShadowCopySettings += New-Object -TypeName PSObject -Property $SCSettingProperty

                                }
                                if ($ShadowCopiesAsBaseObject) {
                                $ShadowCopies = @($wmi_shadowcopies)
                                }
                                else {
                                foreach ($shadowcopy in $wmi_shadowcopies) {
                                        $SCProperty = @{
                                        "ID" = $shadowcopy.ID
                                        "ClientAccessible" = $shadowcopy.ClientAccessible
                                        "Count" = $shadowcopy.Count
                                        "DeviceObject" = $shadowcopy.DeviceObject
                                        "Differential" = $shadowcopy.Differential
                                        "ExposedLocally" = $shadowcopy.ExposedLocally
                                        "ExposedName" = $shadowcopy.ExposedName
                                        "ExposedRemotely" = $shadowcopy.ExposedRemotely
                                        "HardwareAssisted" = $shadowcopy.HardwareAssisted
                                        "Imported" = $shadowcopy.Imported
                                        "NoAutoRelease" = $shadowcopy.NoAutoRelease
                                        "NotSurfaced" = $shadowcopy.NotSurfaced
                                        "NoWriters" = $shadowcopy.NoWriters
                                        "Persistent" = $shadowcopy.Persistent
                                        "Plex" = $shadowcopy.Plex
                                        "ProviderID" = $shadowcopy.ProviderID
                                        "ServiceMachine" = $shadowcopy.ServiceMachine
                                        "SetID" = $shadowcopy.SetID
                                        "State" = $shadowcopy.State
                                        "Transportable" = $shadowcopy.Transportable
                                        "VolumeName" = $shadowcopy.VolumeName
                                        }
                                        $ShadowCopies += New-Object -TypeName PSObject -Property $SCProperty
                                }
                                }
                                $ResultProperty = @{
                                "PSComputerName" = $ComputerName
                                "PSDateTime" = $PSDateTime
                                "ComputerName" = $ComputerName
                                "ShadowCopyVolumes" = $ShadowCopyVolumes
                                "ShadowCopySettings" = $ShadowCopySettings
                                "ShadowCopies" = $ShadowCopies
                                "ShadowCopyProviders" = $ShadowCopyProviders
                                }

                                $ResultObject += New-Object -TypeName PSObject -Property $ResultProperty

                                # Setup the default properties for output
                                $ResultObject.PSObject.TypeNames.Insert(0,"My.ShadowCopy.Info")
                                $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet("DefaultDisplayPropertySet",[string[]]$defaultProperties)
                                $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
                                $ResultObject | Add-Member MemberSet PSStandardMembers $PSStandardMembers

                                Write-Output -InputObject $ResultObject
                                #endregion Data Collection
                        }
                        catch {
                                Write-Warning -Message ("Get-RemoteShadowCopyInformation: {0}: {1}" -f $ComputerName, $_.Exception.Message)
                        }
                        Write-Verbose -Message ("Get-RemoteShadowCopyInformation: Runspace {0}: End" -f $ComputerName)
                }

                $shawdowcopyarray =@()
                $shawdowcopyinfo = (Get-RemoteShadowCopyInformation -ComputerName $Server).ShadowCopyVolumes -replace "[@{}]",""
                $shawdowcopysplit = $shawdowcopyinfo -split ";"

                foreach ($line in $shawdowcopysplit)
                {
                        $linearray = $line + "<br>"
                        $shawdowcopyarray += $linearray
                }

                $shawdowfound = "<tr><td><h1><center>Shadow Copies found: <br> $shawdowcopyarray</center></h1>"
                $shawdownotfound = "<tr><td><h1><center>No Shadow Copies Found on $Server</center></h1>"
                if ($shawdowcopyinfo -like "*ShadowSizeMax*")
                {
                        $DiskShadowsinHTML = $shawdowfound
                }
                Else
                {
                        $DiskShadowsinHTML = $shawdownotfound
                }  
                Return (Add-BackButtons -HTML $DiskShadowsinHTML)
        }
        Function Get-Services {
                Param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $Server
                )
                $Services = Get-WmiObject win32_service -computername $Server | Sort-Object displayname | Select-Object displayname,startmode,state,startname | ConvertTo-Html -Head $a

                Return (Add-BackButtons -HTML $Services)
        }
        Function Get-Shares {
                Param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $Server
                )
                
                $Shares = Get-WmiObject Win32_Share -ComputerName $Server | Select-Object Name | Sort-Object Name
                $ShareDataArray =@()
                ForEach ($Share in $Shares) {
                        $ShareDataArray += "\\$Server\" + $Share.Name
                }
                
                $FinalShareArray =@()
                ForEach ($Share in $ShareDataArray ) {
                        If ($Share -notlike '*\IPC$') {
                                $ACL = Get-ACL $Share
                                
                                $FileArray =@()

                                ForEach ($AccessRule in $ACL.Access)
                                {
                                        $FileArray += [String] $AccessRule.IdentityReference + '(' + $AccessRule.FileSystemRights + ')'
                                }
                        }
                        $SMBArray =@()
                        $ShareSecurity = Get-WmiObject -Query ("Select * from win32_LogicalShareSecuritySetting Where Name='" + $Share.Split("\")[3] + "'") -ComputerName $Server
                        If ($null -ne $ShareSecurity) {
                                $ACLS = $ShareSecurity.GetSecurityDescriptor().Descriptor.DACL
                                ForEach ($ACL in $ACLS) {
                                        $User = $ACL.Trustee.Name
                                        If ($null -ne $user) {
                                                $user = $ACL.Trustee.SID
                                        }
                                        $Domain = $ACL.Trustee.Domain
                                        Switch($ACL.AccessMask) {
                                                2032127 {$Perm = "Full Control"}
                                                1245631 {$Perm = "Change"}
                                                1179817 {$Perm = "Read"}
                                        }
                                        $SMBArray += "$Domain\$user" + ' ' + $Perm
                                }
                        }
                        $FinalShareArray += ,(New-Object -TypeName PSObject -Property @{
                                ShareName = $Share
                                SMB = [String] $SMBArray
                                NTFS = [string] $FileArray
                        })
                }
                
                $ReturnShare = $FinalShareArray | ConvertTo-Html -Head $a
                Return (Add-BackButtons -HTML $ReturnShare)
        }
        Function Get-Groups {
                Param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $Server
                )
                
                $Array = @()
                $computer = [ADSI]"WinNT://$Server,computer"
                $computer.psbase.children | Where-Object { $_.psbase.schemaClassName -eq 'group' } | ForEach-Object{
                        $info = " " | Select-Object GroupName,Users
                        $info.GroupName = [string]($_ | Select-Object name).name
                        $group =[ADSI]$_.psbase.Path
                        $group.psbase.Invoke("Members") | ForEach-Object{
                        $info.Users = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
                        $array += $info
                        $info = " " | Select-Object GroupName,Users}
                }
                $ReturnArray = $array | ConvertTo-Html -Head $a
                Return (Add-BackButtons -HTML $ReturnArray)
        }
        Function Get-Perfmons {
                Param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $Server
                )
                # This has been left out on purpose for now
                $ReturnPerfMons = $null | ConvertTo-Html -Head $a
                Return (Add-BackButtons -HTML $ReturnPerfMons)
        }
        Function Add-BackButtons {
                param(
                        [Parameter(Mandatory=$True, Position=1)]
                        [String[]] $HTML
                )

                Return ($HTML + '<FORM><INPUT TYPE="button" VALUE="Back" onClick="history.back()"></FORM>')
        }

        $VolumesInHTML = Get-DiskInfo -Server $Server
        $ApplicationErrorsInHTML = Get-EventLogs -Server $Server -Logname 'Application' -Level 2
        $ApplicationWarningsInHTML = Get-EventLogs -Server $Server -Logname 'Application' -Level 3
        $SystemErrorsInHTML = Get-EventLogs -Server $Server -Logname 'System' -Level 2
        $SystemWarningsInHTML = Get-EventLogs -Server $Server -Logname 'System' -Level 3
        $SecurityWarningInHTML = Get-EventLogs -Server $Server -Logname 'Security' -ID (4776,4625,5378)
        $ShadowCopiesInHTML = Get-ShadowCopies -Server $Server
        $ServicesInHTML  = Get-Services -Server $Server
        $SharesInHTML = Get-Shares -Server $Server
        $GroupsInHTML = Get-Groups -Server $Server
        $PerfmonsInHTML = Get-Perfmons -Server $server

        $VolumesInHTML | Out-File ($GlobalConfig.Settings.Sources.ReportFolder + $User + '\' + $Server + '\Volumes.html')
        $ApplicationErrorsInHTML | Out-File ($GlobalConfig.Settings.Sources.ReportFolder + $User + '\' + $Server + '\ApplicationErrors.html')
        $ApplicationWarningsInHTML | Out-File ($GlobalConfig.Settings.Sources.ReportFolder + $User + '\' + $Server + '\ApplicationWarnings.html')
        $SystemErrorsInHTML | Out-File ($GlobalConfig.Settings.Sources.ReportFolder + $User + '\' + $Server + '\SystemErrors.html')
        $SystemWarningsInHTML | Out-File ($GlobalConfig.Settings.Sources.ReportFolder + $User + '\' + $Server + '\SystemWarnings.html')
        $SecurityWarningInHTML | Out-File ($GlobalConfig.Settings.Sources.ReportFolder + $User + '\' + $Server + '\SecurityWarnings.html')
        $ShadowCopiesInHTML | Out-File ($GlobalConfig.Settings.Sources.ReportFolder + $User + '\' + $Server + '\ShadowCopies.html')
        $ServicesInHTML  | Out-File ($GlobalConfig.Settings.Sources.ReportFolder + $User + '\' + $Server + '\Services.html')
        $SharesInHTML | Out-File ($GlobalConfig.Settings.Sources.ReportFolder + $User + '\' + $Server + '\Shares.html')
        $GroupsInHTML | Out-File ($GlobalConfig.Settings.Sources.ReportFolder + $User + '\' + $Server + '\Groups.html')
        $PerfmonsInHTML | Out-File ($GlobalConfig.Settings.Sources.ReportFolder + $User + '\' + $Server + '\PerfMons.html')