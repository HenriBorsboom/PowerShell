$ServerList = Import-CSV ($GlobalConfig.Settings.Sources.ServerListFolder + $GlobalConfig.Settings.Lists.DebugServerList) -Delimiter ";"
$ServerItem = $ServerList[0]
$GlobalConfig = Get-Content 'C:\HealthCheck\Scripts\Config.xml'
$ReportFolder = 'C:\HealthCheck\DebugReports\'

        #region Functions
        Function Write-log {
                [CmdletBinding()]
                Param(
                        [parameter(Mandatory=$true, Position=1)][AllowEmptyString()]
                        [String]$Logfile,
                        [parameter(Mandatory=$true, Position=2)][AllowEmptyString()]
                        [String]$Message,
                        [parameter(Mandatory=$true, Position=3)][AllowEmptyString()]
                        [String]$Component,
                        [Parameter(Mandatory=$true,Position=4)][ValidateSet("Info", "Warning", "Error")]
                        [String]$Level
                )
                
                If ($null -eq $Component) { $Level = "Error"}
                Try {    
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
                    Start-Sleep -Milliseconds 50
                }
                Catch {
                    switch ($Level) {
                        "Info" { [int]$Level = 1 }
                        "Warning" { [int]$Level = 2 }
                        "Error" { [int]$Level = 3 }
                    }
                    $Component = 'Error'
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
                    
                    Add-Content -Path ($Logfile + '_Loggingerror.log') -Value $Content
                    $Content = "<![LOG[$_]LOG]!>" +`
                        "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
                        "date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
                        "component=`"$Component`" " +`
                        "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
                        "type=`"3`" " +`
                        "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
                        "file=`"`">"
                    Add-Content -Path ($Logfile + '_Loggingerror.log') -Value $Content
                }
        }
        Function Test-Port {
                Param (
                    [Parameter(Mandatory=$True, Position=1)]
                    [String] $Server,
                    [Parameter(Mandatory=$True, Position=2)]
                    [Int] $Port, `
                    [Parameter(Mandatory=$False, Position=3)]
                    [Int] $Timeout = 50)
                   
                $Domains = @()
                $Domains += 'mercantile.co.za'
                $Domains += 'mblcard.co.za'
                $Domains += 'MBLWEBDC.co.za'
            
                ForEach ($Domain in $Domains) {
                    Try {
                        $IP = [System.Net.Dns]::GetHostAddresses($Server + '.' + $Domain)| Where-Object AddressFamily -eq 'Internetwork' | Select-Object IPAddressToString -Expandproperty IPAddressToString
                        If ($IP.GetType().Name -eq 'Object[]') {
                            $IP = $IP[0]
                        }
                        break
                    } 
                    Catch {
                        Try {
                            $IP = [System.Net.Dns]::GetHostAddresses($Server) | Where-Object AddressFamily -eq 'Internetwork'| Select-Object IPAddressToString -Expandproperty IPAddressToString
                            If ($IP.GetType().Name -eq 'Object[]') {
                                $IP = $IP[0]
                            }
                            break
                        }
                        Catch {
        
                        }
                    }
                }
                Try {        
                    $requestCallback = $state = $null
                    $client = New-Object System.Net.Sockets.TcpClient
                    $null = $client.BeginConnect($IP,$Port,$requestCallback,$state)
                    Start-Sleep -Milliseconds $Timeout
                    if ($client.Connected) { $State = $true } else { $State = $false }
                    $client.Close()
                    $ReturnValue = New-Object -TypeName PSObject -Property @{
                        Server = $Server
                        IP = $IP
                        Domain = $Domain
                        Open = $State
                        Port = $Port
                    }
                    $IP = $null
                    Return $ReturnValue
                }
                Catch {
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ($_)
                }
        }
        Function Get-DiskInfo {
                Param (
                    [Parameter(Mandatory=$True, Position=1)]
                    [String] $Server
                )

                Try {
                        $Volumes = Get-WmiObject win32_volume -ComputerName $Server -Authentication PacketIntegrity | `
                                        Where-Object {$_.caption -notlike 'S:\' -and $_.drivetype -ne 5 -and $_.label -ne 'System Reserved' -and $_.capacity -gt 1} | `
                                                Select-Object caption, `
                                                        @{n='FreeSpace';e={[int]($_.freespace/1GB)}},
                                                        @{n='Capacity';e={[int]($_.Capacity/1GB)}},
                                                        @{n='Free%';e={[int](($_.freespace/$_.capacity)*100)}},label,driveletter
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Volumes found: ' + $Volumes.Count.ToString())
                        $Volumes = $Volumes | ConvertTo-Html -Head $a
                        $ErrorAmount = 0
                        $HTMLVolumes = @()
                        foreach($Line in $Volumes)
                        {
                                $Test = $Line
                                Try {
                                        if([int]$Line.Split('<')[8].substring(3) -lt 10)
                                        {
                                                Write-Log -LogFile $ServerLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Volume found below threshold. Verbose: ' + $Line)
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
                }
                Catch {
                        Write-Log -LogFile $ServerLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ($_)
                        $HTMLVolumes = $null | ConvertTo-Html -Head $a
                }

                Switch ($DebugState) {
                    $True {
                        Return ($HTMLVolumes.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + '/index.html">Home</a></h2>' + "`n"),$ErrorAmount)
                    }
                    $False {
                        Return ($HTMLVolumes.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/index.html">Home</a></h2>' + "`n"),$ErrorAmount)
                    }
                }
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
                Try {
                    $StartTime = (Get-Date).AddDays(-$GlobalConfig.Settings.Alarms.AlarmDateRangeInDays)

                    If ($Level -gt 0) {
                            Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting logs from ' + $LogName + '. StartTime: ' + $StartTime + '. LogLevel: ' + $Level)
                            $Events = Get-WinEvent -FilterHashtable @{Logname= $Logname; StartTime=$StartTime; Level=$Level} -ErrorAction SilentlyContinue -Force -ComputerName $Server | `
                                    Select-Object ID, ProviderName, Message

                            If ($Events.Message.Count -gt 0) {
                                    Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Events found:'  + $Events.Message.Count.ToString())
                                    $ErrorAmount = $Events.Message.Count
                                    $ReturnEvents = $Events | Group-Object MESSAGE | ForEach-Object{ 
                                    $temp = " " | Select-Object COUNT,ID,ProviderName,MESSAGE
                                    $temp.count = $_.count
                                    $temp.ID = $_.group | Select-Object -ExpandProperty ID -unique
                                    $temp.ProviderName = $_.group | Select-Object -ExpandProperty ProviderName -unique
                                    $temp.MESSAGE = $_.group | Select-Object -ExpandProperty message -unique
                                    $temp} | Sort-Object count -descending | ConvertTo-Html -head $a
                            }
                            Else {
                                    Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('No events found')
                                    $ErrorAmount = 0
                                    $ReturnEvents = ($null | ConvertTo-Html -head $a).Replace('<body>',"`n" + "`t" + '<body>' + "`n" + "`t" + "`t" + '<h2>No events found for the past 24 hours</h2>')
                            }
                    }
                    ElseIf ($ID.Count -gt 0) {
                            Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Gettings events from ' + $Logname + '. Start Time: ' + $StartTime + '. ID: ' + $ID)
                            $Events = Get-WinEvent -FilterHashtable @{Logname=$Logname; StartTime=$StartTime; ID=$ID} -ErrorAction SilentlyContinue -Force -ComputerName $Server | `
                                    Select-Object ID, ProviderName, Message

                            If ($Events.Message.Count -gt 0) {
                                    Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Events found: ' + $Events.Message.Count.ToString())
                                    $ErrorAmount = $Events.Message.Count
                                    $ReturnEvents = $Events | Group-Object MESSAGE | ForEach-Object{ 
                                    $temp = " " | Select-Object COUNT,ID,ProviderName,MESSAGE
                                    $temp.count = $_.count
                                    $temp.ID = $_.group | Select-Object -ExpandProperty ID -unique
                                    $temp.ProviderName = $_.group | Select-Object -ExpandProperty ProviderName -unique
                                    $temp.MESSAGE = $_.group | Select-Object -ExpandProperty message -unique
                                    $temp} | Sort-Object count -descending | ConvertTo-Html -head $a
                            }
                            Else {
                                    Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('No events found')
                                    $ErrorAmount = 0
                                    $ReturnEvents = ($null | ConvertTo-Html -head $a).Replace('<body>',"`n" + "`t" + '<body>' + "`n" + "`t" + "`t" + '<h2>No events found for the past 24 hours</h2>')
                            }
                            
                    }
                }
                Catch {
                    Write-Log -LogFile $ServerLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ($_)
                    $ReturnEvents = ($null | ConvertTo-Html -head $a).Replace('<body>',"`n" + "`t" + '<body>' + "`n" + "`t" + "`t" + '<h2>' + $_ + '</h2>')
                }
                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Returning events count: ' + $ErrorAmount.ToString())
                
                Switch ($DebugState) {
	                $True {
	                    Return (($ReturnEvents.Replace('<table>','<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">' + "`n" + '<table id="SearchTable">').Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + '/index.html">Home</a></h2>' + "`n")), $ErrorAmount)
	                }
	                $False {
                        Return (($ReturnEvents.Replace('<table>','<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">' + "`n" + '<table id="SearchTable">').Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/index.html">Home</a></h2>' + "`n")), $ErrorAmount)
	                }
                }
        }
        Function Get-ShadowCopies {
                Param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $Server
                )
                Function Get-RemoteShadowCopyInformation {
                        Param (
                                [Parameter(Mandatory=$True, Position=1)]
                                [String] $ComputerName
                        )
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
                                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ("Get-RemoteShadowCopyInformation: Runspace {0}: Start" -f $ComputerName)
                                
                                $PSDateTime = Get-Date

                                #region Data Collection
                                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ("Get-RemoteShadowCopyInformation: Runspace {0}: Share session information" -f $ComputerName)

                                $defaultProperties    = @("ComputerName","ShadowCopyVolumes","ShadowCopySettings", "ShadowCopyProviders","ShadowCopies")

                                $wmi_shadowcopyareas = Get-WmiObject -Class win32_shadowstorage -ComputerName $ComputerName -Authentication PacketIntegrity -ErrorAction Stop
                                $wmi_volumeinfo =  Get-WmiObject -Class win32_volume -ComputerName $ComputerName -Authentication PacketIntegrity -ErrorAction Stop
                                $wmi_shadowcopyproviders = Get-WmiObject -Class Win32_ShadowProvider -ComputerName $ComputerName -Authentication PacketIntegrity -ErrorAction Stop
                                $wmi_shadowcopysettings = Get-WmiObject -Class Win32_ShadowContext -ComputerName $ComputerName -Authentication PacketIntegrity -ErrorAction Stop
                                $wmi_shadowcopies = Get-WmiObject -Class Win32_ShadowCopy -ComputerName $ComputerName -Authentication PacketIntegrity -ErrorAction Stop
                                
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
                                
                                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ($ResultObject)
                                #endregion Data Collection
                        }
                        catch {
                                Write-Log -LogFile $ServerLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ("Get-RemoteShadowCopyInformation: {0}: {1}" -f $ComputerName, $_.Exception.Message)
                        }
                       Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ("Get-RemoteShadowCopyInformation: Runspace {0}: End" -f $ComputerName)
                }

                $shawdowcopyarray =@()
                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting information of Remote ShadowCopy')
                $shawdowcopyinfo = (Get-RemoteShadowCopyInformation -ComputerName $Server).ShadowCopyVolumes -replace "[@{}]",""
                $shawdowcopysplit = $shawdowcopyinfo -split ";"

                foreach ($line in $shawdowcopysplit)
                {
                        $linearray = $line + "<br>"
                        $shawdowcopyarray += $linearray
                }
                $ErrorAmmount = 0
                if ($shawdowcopyinfo -like "*ShadowSizeMax*")
                {
                        Write-Log -LogFile $ServerLogFile -Level Warning -Component $MyInvocation.MyCommand.Name -Message ('Shadow Copies found.')
                        [String[]] $DiskShadowsinHTML = Get-HTMLCode -Style Head
                        $DiskShadowsinHTML += "`t" + "`t" + '<table>'
                        $DiskShadowsinHTML += "`t" + "`t" + "<tr><th><h1><center>Shadow Copies found: <br> $shawdowcopyarray</center></h1></th></tr>"
                        $DiskShadowsinHTML += "`t" + "`t" + '</table>'
                        $DiskShadowsinHTML += "`t" + '</BODY>'
                        $DiskShadowsinHTML += '</HTML>'
                        $ErrorAmmount ++ 
                }
                Else
                {
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('No Shadow copies found')
                        [String[]] $DiskShadowsinHTML = Get-HTMLCode -Style Head
                        $DiskShadowsinHTML += "`t" + "`t" + '<table>'
                        $DiskShadowsinHTML += "`t" + "`t" + '<tr><th><h1><center>No Shadow Copies Found on ' + $Server + '</center></h1></th></tr>'
                        $DiskShadowsinHTML += "`t" + "`t" + '</table>'
                        $DiskShadowsinHTML += "`t" + '</BODY>'
                        $DiskShadowsinHTML += '</HTML>'
                }  
                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Shadow copies found: ' + $ErrorAmmount.ToString())
                
               Switch ($DebugState) {
	                $True {
	                    Return (($DiskShadowsinHTML.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + '/index.html">Home</a></h2>' + "`n")), $ErrorAmmount)
	                }
	                $False {
                        Return (($DiskShadowsinHTML.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/index.html">Home</a></h2>' + "`n")), $ErrorAmmount)
	                }
                }
        }
        Function Get-Services {
                Param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $Server
                )
                Try {
                        $Services = Get-WmiObject win32_service -computername $Server -Authentication PacketIntegrity | Sort-Object displayname | Select-Object DisplayName, StartMode, State, StartName
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Services found: ' + $Services.Count)
                        $Services = $Services | ConvertTo-Html -Head $a
                        [String[]] $Reformat = @()
                        ForEach ($line in $Services) {
                                Write-Host $Line
                                If ($Line -like '*>Auto<*' -and $Line -like '*>Stopped<*') {
                                        $Reformat += $Line.Replace('<td>','<td><span style="background-color: red;">').Replace('</td>','</td></span>')
                                }
                                Else {
                                        $Reformat += $Line
                                }
                        }
                }
                Catch {
                        Write-Log -LogFile $ServerLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ($_)
                        $Reformat = $null | ConvertTo-Html -Head $a
                }
                Switch ($DebugState) {
	                $True {
	                    Return ($Reformat.Replace('<table>','<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">' + "`n" + '<table id="SearchTable">').Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + '/index.html">Home</a></h2>' + "`n"))
	                }
	                $False {
                        Return ($Reformat.Replace('<table>','<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">' + "`n" + '<table id="SearchTable">').Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/index.html">Home</a></h2>' + "`n"))
	                }
                }
         }
        Function Get-Shares {
                Param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $Server
                )
                Try {
                        $Shares = Get-WmiObject Win32_Share -ComputerName $Server -Authentication PacketIntegrity | Select-Object Name | Sort-Object Name
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Shares Found: ' + $Shares.Count.ToString())
                        $ShareDataArray =@()
                        ForEach ($Share in $Shares) {
                                If ($Share.Name.Contains("\\")) {
                                        $ShareDataArray += $Share.Name
                                }
                                Else {
                                        $ShareDataArray += "\\$Server\" + $Share.Name
                                }
                        }
                        
                        $FinalShareArray =@()
                        ForEach ($Share in $ShareDataArray ) {
                                If ($Share -notlike '*\IPC$') {
                                        Try 
                                        {
                                                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting ACL of ' + $Share)
                                                $ACL = Get-ACL $Share -ErrorAction Stop
                                                
                                                $FileArray =@()

                                                ForEach ($AccessRule in $ACL.Access)
                                                {
                                                        $FileArray += [String] $AccessRule.IdentityReference + '(' + $AccessRule.FileSystemRights + ')'
                                                }
                                        }
                                        Catch {
                                                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ($_)
                                                $FileArray =@()
                                        }
                                }
                                $SMBArray =@()
                                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Share Security')
                                $ShareSecurity = Get-WmiObject -Query ("Select * from win32_LogicalShareSecuritySetting Where Name='" + $Share.Split("\")[3] + "'") -ComputerName $Server -Authentication PacketIntegrity 
                                If ($null -ne $ShareSecurity) {
                                        $ACLS = $ShareSecurity.GetSecurityDescriptor().Descriptor.DACL
                                        ForEach ($ACL in $ACLS) {
                                                Switch($ACL.AccessMask) {
                                                        2032127 {$Perm = "Full Control"}
                                                        1245631 {$Perm = "Change"}
                                                        1179817 {$Perm = "Read"}
                                                }
                                                $SMBArray += $ACL.Trustee.Domain + '\' + $ACL.Trustee.Name + ' ' + $Perm
                                        }
                                }
                                $FinalShareArray += ,(New-Object -TypeName PSObject -Property @{
                                        ShareName = $Share
                                        SMB = [String] $SMBArray
                                        NTFS = [string] $FileArray
                                })
                        }
                }
                Catch {
                        Write-Log -LogFile $ServerLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ($_)
                        $ReturnShare = $null | ConvertTo-Html -head $a
                }
                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Shares found: ' + $FinalShareArray.Count.ToString())
                $ReturnShare = $FinalShareArray | ConvertTo-Html -Head $a
                
                Switch ($DebugState) {
	                $True {
                                Return ($ReturnShare.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + '/index.html">Home</a></h2>' + "`n"))
	                }
	                $False {
                                Return ($ReturnShare.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/index.html">Home</a></h2>' + "`n"))
	                }
                }
                
        }
        Function Get-Groups {
                Param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $Server
                )
                Try {
                    Write-Log -LogFile $ServerLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Getting Group Information')
                    $computer = [ADSI]"WinNT://$Server"
                    $result = @()
                    foreach($adsiObj in $computer.psbase.children)
                    {
                            switch -regex($adsiObj.psbase.SchemaClassName)
                            {
                                    "group"
                                    {
                                            $group = $adsiObj.name
                                            $LocalGroup = [ADSI]"WinNT://$Server/$group,group"
                                            $Members = @($LocalGroup.psbase.Invoke("Members"))

                                            $GName = $group.tostring()

                                            ForEach ($Member In $Members) {
                                                    $Name = $Member.GetType().InvokeMember("Name", "GetProperty", $Null, $Member, $Null)
                                                    $result += New-Object PSObject -Property @{
                                                            Group = $GName
                                                            Member = $Name
                                                    }
                                            }
                                    }
                            } 
                    } 
                    Write-Log -LogFile $ServerLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Groups members found: ' + $result.Count.ToString())
                    Write-Log -LogFile $ServerLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Flagging SIDs')
                    $HTMLResult = $result | ConvertTo-Html -Head $a
                    [String[]] $Reformat = @()
                    ForEach ($Line in $HTMLResult) {
                        Write-Host $Line
                        If ($Line -like '*S-1-5-21*') {
                            $Reformat += $Line.Replace('<td>','<td><span style="background-color: red;">').Replace('</td>','</td></span>')
                        }
                        Else {
                            $Reformat += $Line
                        }
                    }
                }
                Catch {
                    Write-Log -LogFile $ServerLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ($_)
                }
                
                Switch ($DebugState) {
	                $True {
	                    Return ($Reformat.Replace('<table>','<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">' + "`n" + '<table id="SearchTable">').Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + '/index.html">Home</a></h2>' + "`n"))
	                }
	                $False {
                        Return ($Reformat.Replace('<table>','<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">' + "`n" + '<table id="SearchTable">').Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/index.html">Home</a></h2>' + "`n"))
	                }
                }
        }
        Function Get-Perfmons {
                Param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $Server
                )
                # This has been left out on purpose for now
                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting PerfMons')
                [String[]] $ReturnPerfMons = Get-HTMLCode -Style Head
                $ReturnPerfMons += "`t" + "`t" + '<table>'
                $ReturnPerfMons += "`t" + "`t" + '<tr><th><h1><center>No Performance Monitors configured on ' + $Server + '</center></h1></th></tr>'
                $ReturnPerfMons += "`t" + "`t" + '</table>'
                $ReturnPerfMons += "`t" + '</BODY>'
                $ReturnPerfMons += '</HTML>'

                Switch ($DebugState) {
	                $True {
                                Return ($ReturnPerfMons.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + '/index.html">Home</a></h2>' + "`n"))
	                }
	                $False {
                                Return ($ReturnPerfMons.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/index.html">Home</a></h2>' + "`n"))
	                }
                }
                
        }
        Function Get-NICDetails {
            Param (
                    [Parameter(Mandatory=$True, Position=1)]
                    [String] $Server
            )

            Function Get-ConnectedNICs {
                Param (
                    [Parameter(Mandatory=$true, Position=1)]
                    [String] $Server)
        
                $WMIQuery = "Select NetConnectionID,MACAddress,InterfaceIndex from Win32_NetworkAdapter Where NetConnectionStatus = ""2"""
                Try { 
                    If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery -Authentication PacketIntegrity }
                    Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server -Authentication PacketIntegrity  }
                    Return $WMIResults
                }
                Catch { Return $false }
            }
            Function Get-IPDetails {
                Param (
                    [Parameter(Mandatory=$true, Position=1)]
                    [String] $Server, `
                    [Parameter(Mandatory=$true, Position=2)]
                    [String] $InterfaceIndex)

                $WMIQuery = "Select IPAddress,IPSubnet,DefaultIPGateway,DNSServerSearchOrder from Win32_NetworkAdapterConfiguration Where InterfaceIndex = ""$InterfaceIndex"""
                Try { 
                    If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery -Authentication PacketIntegrity }
                    Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server -Authentication PacketIntegrity  }
                    Return $WMIResults
                }
                Catch { Return $false }
            }
            Try {
                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting NIC Details')
                [Object[]] $ConnectedNICs = Get-ConnectedNICs -Server $Server
                [Object[]] $NICDetails = @()
                ForEach ($NIC in $ConnectedNICs) {
                    $IPDetails  = Get-IPDetails -Server $Server -InterfaceIndex $NIC.InterfaceIndex
	                For ($Index = 0; $Index -lt $IPDetails.IPAddress.Count; $Index ++) {
                        If ([IPAddress]::TryParse([IPAddress] $IPDetails.IPAddress[$Index], [Ref] "0.0.0.0") -and (([IPAddress] $IPDetails.IPAddress[$Index]).IsIPv6LinkLocal) -eq $false) {
                            #region Set Results to Variables
                            $AdapterName          = $NIC.NetConnectionID
                            $MACAddress           = $NIC.MACAddress
                            $InterfaceIndex       = $NIC.InterfaceIndex
                            $IPAddress            = $IPDetails.IPAddress[$Index]
                            $IPSubnet             = $IPDetails.IPSubnet[$Index]
                            Try {$DefaultIPGateway     = $IPDetails.DefaultIPGateway[$Index]} Catch {$DefaultIPGateway = ""}
                            $DNSServerSearchOrder = $IPDetails.DNSServerSearchOrder -join ";"
                            #endregion
                            #region Verify Variables are not empty
                            If ($null -eq $AdapterName)      {$AdapterName = ""}
                            If ($null -eq $MACAddress)       {$MACAddress = ""}
                            If ($null -eq $InterfaceIndex)   {$InterfaceIndex = ""}
                            If ($null -eq $IPAddress)        {$IPAddress = ""}
                            If ($null -eq $IPSubnet)         {$IPSubnet = ""}
                            If ($null -eq $DefaultIPGateway) {$DefaultIPGateway = ""}
                            #endregion
                            #region Populate Output
                            $NICDetail = New-Object PSObject -Property @{
                                AdapterName          = $AdapterName
                                MACAddress           = $MACAddress
                                InterfaceIndex       = $InterfaceIndex
                                IPAddress            = $IPAddress
                                IPSubnet             = $IPSubnet
                                DefaultIPGateway     = $DefaultIPGateway
                                DNSServerSearchOrder = $DNSServerSearchOrder
                            }
                            #endregion
                            #region Reset Variables
                            $AdapterName          = $null
                            $MACAddress           = $null
                            $InterfaceIndex       = $null
                            $IPAddress            = $null
                            $IPSubnet             = $null
                            $DefaultIPGateway     = $null
                            $DNSServerSearchOrder = $null
                            #endregion
                            $NICDetails += $NICDetail
                        }
                    }
                }
            }
            Catch {
                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ($_)
            }
            $NICDetails = $NICDetails | Select-Object AdapterName, MACAddress, InterFaceIndex, IPAddress, IPSubnet, DefaultIPGateway, DNSServerSearchOrder 
            $NICDetails = $NICDetails | ConvertTo-Html -Head $a
            Switch ($DebugState) {
	                $True {
                                Return ($NICDetails.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + '/index.html">Home</a></h2>' + "`n"))
	                }
	                $False {
                                Return ($NICDetails.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/index.html">Home</a></h2>' + "`n"))
	                }
                }
            
        }
        Function Get-BMRInfo {
                Param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $Server
                )
                Try {
                        $ComputerSystemProperties = @('DNSHostName','Manufacturer','Model', 'NumberOfLogicalProcessors', 'TotalPhysicalMemory')
                        $ComputerSystem = Get-WmiObject Win32_ComputerSystem -Property $ComputerSystemProperties -Computername $Server -Authentication PacketIntegrity | Select-Object $ComputerSystemProperties
                        #Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Information retrieved from Win32_ComputerSystem')
                        
                        $BIOSProperties = @('SerialNumber','ReleaseDate')
                        $BIOS = Get-WmiObject Win32_BIOS -Property $BIOSProperties -Computername $Server -Authentication PacketIntegrity | Select-Object $BIOSProperties
                        #Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Information retrieved from Win32_BIOS')
            
                        $ProcessorProperties = @('Name')
                        [Object[]] $Processor = Get-WmiObject Win32_Processor -Property $ProcessorProperties -Computername $Server -Authentication PacketIntegrity | Select-Object $ProcessorProperties
                        #Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Information retrieved from Win32_Processor')
            
                        $OperatingSystemProperties = @('Caption','LastBootUpTime','InstallDate')
                        $OperatingSystem = Get-WmiObject Win32_OperatingSystem -Property $OperatingSystemProperties -Computername $Server -Authentication PacketIntegrity | Select-Object $OperatingSystemProperties
                        #Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Information retrieved from Win32_OperatingSystem')
            
                        $CompiledProperties = @('DNS Name', 'Manufacturer', 'Model', 'Serial', 'BIOS Release Date', 'CPU Name', 'Logical Cores', 'Operating System', 'Last Boot Up Time', 'Up Time', 'Install Date')
                        $CompiledObject = New-Object -TypeName PSObject -Property @{
                            'DNS Name' = $ComputerSystem.DNSHostName
                            'Manufacturer' = $ComputerSystem.Manufacturer
                            'Model' = $ComputerSystem.Model
                            'Serial' = $BIOS.SerialNumber
                            'BIOS Release Date' = [Management.ManagementDateTimeConverter]::ToDateTime($BIOS.ReleaseDate)
                            'CPU Name' = $Processor[0].Name
                            'Logical Cores' = $ComputerSystem.NumberofLogicalProcessors
                            'Operating System' = $OperatingSystem.Caption
                            'Last Boot Up Time' = [Management.ManagementDateTimeConverter]::ToDateTime($OperatingSystem.LastBootUpTime)
                            'Up Time' = (((Get-Date) - [Management.ManagementDateTimeConverter]::ToDateTime($OperatingSystem.LastBootUpTime)).Tostring())
                            'Install Date' = [Management.ManagementDateTimeConverter]::ToDateTime($OperatingSystem.InstallDate)
                        } | Select-Object $CompiledProperties
                        $CompiledObject = $CompiledObject | ConvertTo-Html -Head $a
                }
                Catch {
                        #Write-Log -LogFile $ServerLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ($_)
                        $CompiledObject = $null | ConvertTo-Html -head $a
                }
                Switch ($DebugState) {
	                $True {
                                Return ($CompiledObject.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + '/index.html">Home</a></h2>' + "`n"))
	                }
	                $False {
                                Return ($CompiledObject.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/index.html">Home</a></h2>' + "`n"))
	                }
                }
                
        }
        Function Get-Products {
                Param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $Server
                )
                Try {
                        $ProductProperties = @('Name', 'Vendor', 'Version', 'InstallDate')
                        $Products = Get-WmiObject Win32_Product -Property $ProductProperties -Computername $Server -Authentication PacketIntegrity | Sort-Object Name | Select-Object Name, Vendor, Version, @{Name='InstallDate';Expression={[String]::Format("{0}/{1}/{2}", $_.InstallDate.Substring(0,4), $_.InstallDate.Substring(4,2), $_.InstallDate.Substring(6,2))}}
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Products found: ' + $Products.Count.ToString())
                        $Products = $Products | Select-Object $ProductProperties | ConvertTo-Html -Head $a
                }
                Catch {
                        Write-Log -LogFile $ServerLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ($_)
                        $Products = $null | ConvertTo-Html -Head $a
                }
                Switch ($DebugState) {
                        $True {
                                Return ($Products.Replace('<table>','<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">' + "`n" + '<table id="SearchTable">').Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + '/index.html">Home</a></h2>' + "`n"))
                        }
                        $False {
                                Return ($Products.Replace('<table>','<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">' + "`n" + '<table id="SearchTable">').Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/index.html">Home</a></h2>' + "`n"))
                        }
                }
        }
        Function Get-Updates {
                Param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $Server
                )
                Function New-Links {
                        Param (
                                [Parameter(Mandatory=$True, Position=1)]
                                [Object[]] $Links
                        )

                        [String[]] $FixedLinks = Get-HTMLCode -Style Head
                        $FixedLinks += "`t" + "`t" + '<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">'
                        $FixedLinks += "`t" + "`t" + '<table id="SearchTable">'
                        $FixedLinks += "`t" + "`t" + "`t" + '<colgroup><col/><col/><col/><col/><col/></colgroup>'
                        $FixedLinks += "`t" + "`t" + "`t" + '<tr><th>Hot Fix ID</th><th>Installed By</th><th>Installed On</th><th>Description</th><th>MS Link</th></tr>'
                        ForEach ($Link in $Links) {
                                $FixedLinks += "`t" + "`t" + "`t" + '<tr><td>' + $Link.HotFixID + '</td><td>' + $Link.InstalledBy + '</td><td>' + $Link.InstalledOn + '</td><td>' + $Link.Description + '</td><td><a href="' + $Link.Caption + '" target="_blank">' + $Link.Caption + '</td></tr>'
                        }
                        $FixedLinks += "`t" + "`t" + '</table>'
                        Switch ($DebugState) {
                                $True {
                                        $FixedLinks += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + '/index.html">Home</a></h2>'
                                }
                                $False {
                                        $FixedLinks += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/index.html">Home</a></h2>'
                                }
                        }
                        
                        $FixedLinks += "`t" + '</BODY>'
                        $FixedLinks += '</HTML>'
                        Return $FixedLinks
                }
                Try {
                        $UpdateProperties = @('HotFixID', 'InstalledBy', 'InstalledOn', 'Description', 'Caption')
                        $Updates = Get-WmiObject Win32_QuickFixEngineering -Property $UpdateProperties -Computername $Server -Authentication PacketIntegrity | Select-Object $UpdateProperties | Sort-Object InstalledOn -Descending
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Updates installed: ' + $Updates.Count.ToString())
                        $Updates = New-Links -Links $Updates
                }
                Catch {
                        Write-Log -LogFile $ServerLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ($_)
                        $Updates = $null | ConvertTo-Html -Head $a
                }
                Return $Updates
        }
        Function Get-Routes {
                Param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $Server
                )
                Try {
                        $RouteProperties = @('Destination', 'Mask', 'NextHop', 'Metric1', 'InterfaceIndex', 'Description')
                        $Routes = Get-WmiObject Win32_IP4RouteTable -Property $RouteProperties -Computername $Server -Authentication PacketIntegrity | Select-Object $RouteProperties | Sort-Object Metric1
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Routes found: ' + $Routes.Count.ToString())
                        $Routes = $Routes | ConvertTo-Html -Head $a
                }
                Catch {
                        Write-Log -LogFile $ServerLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ($_)
                        $Routes = $null | ConvertTo-Html -Head $a
                }
                Return $Routes

        }
        Function New-HTMLSummary {
                Param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $User, `
                        [Parameter(Mandatory=$True, Position=2)]
                        [String] $Server
                )
                
                If (!(Test-Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\Unavailable'))) {
                        New-Item ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\Unavailable') -Type Directory | Out-Null
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('New directory created: '+ ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\Unavailable'))
                }
                
                If (!(Test-Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\AllDiskSummary'))) {
                    New-Item ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\AllDiskSummary') -Type Directory | Out-Null
                    Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('New directory created: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\AllDiskSummary'))
                }
                
                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Disk Space Files')
                $SpaceFiles = Get-ChildItem -recurse ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\') | Where-Object{$_.fullname -like '*Space*.html' -and $_.fullname -notlike '*Space (0 errors)*.html'}
                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Disk Space Files found: ' + $SpaceFiles.Count.ToString())
                If ($Null -ne $SpaceFiles) {                
                        ForEach ($File in $SpaceFiles) {
                                If (!(Test-Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\AllDiskSummary\' + $File.Name))) {
                                Copy-Item $File.Fullname -Destination ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\AllDiskSummary\' + $File.Name)
                                }
                        }
                } 
        
                If (!(Test-Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\PerfmonSummary'))) {
                        New-Item ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\PerfmonSummary') -Type Directory | Out-Null
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('New Directory Created: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\PerfmonSummary'))
                    }

                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting PerfMon Files')
                $PerfMonFiles = Get-ChildItem -recurse ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\') | Where-Object{$_.fullname -like '*Perfmon*.html' -and $_.fullname -notlike '*PerfMon (0 errors)*.html'}
                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('PerfMon Files found: ' + $PerfMonFiles.Count.ToString())
                If ($Null -ne $PerfMonFiles) {
                        ForEach ($File in $PerfMonFiles) {
                                If (!(Test-Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\PerfmonSummary\' + $File.Name))) {
                                Copy-Item $File.Fullname -Destination ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\PerfmonSummary\' + $File.Name)
                                }
                        } 
                }
                
                If (!(Test-Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\ShadowCopySummary'))) {
                    New-Item ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\ShadowCopySummary') -Type Directory | Out-Null
                    Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('New Directory Created: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\ShadowCopySummary'))
                }
                
                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Shadow Copy Files')
                $ShadowFiles = Get-ChildItem -recurse ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\') | Where-Object{$_.fullname -like '*ShadowCopies*.html' -and $_.fullname -notlike '*ShadowCopies (0 errors)*.html'}
                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Shadow Copy Files found: ' + $ShadowFiles.Count.ToString())
                If ($Null -ne $ShadowFiles) {
                        ForEach ($File in $ShadowFiles) {
                                If (!(Test-Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\ShadowCopySummary\' + $File.Name))) {
                                Copy-Item $File.Fullname -Destination ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\ShadowCopySummary\' + $File.Name)
                                }
                        } 
                }

        }
        Function Get-HTMLCode {
                Param (
                        [Parameter(Mandatory=$True, Position=1)][ValidateSet("Head", "Style")]
                        [String] $Style
                )
        
                If ($Style -eq 'Head') {
                        [String[]] $a = '<HTML>'
                                $a += "`t" + '<HEAD>'
                                $a += "`t" + "`t" +'<TITLE>Daily Health Report</TITLE>'
                                $a += "`t" + '</HEAD>'
                                $a += "`t" + '<BODY>' 
                                $a += "`t" + "`t" + "<style>"
                }
                Else {
                        [string[]] $a = "`t" + "`t" + "<style>" 
                }
        
                $a += "`t" + "`t" + "`t" + "BODY{background-color:#999999;}" 
                $a += "`t" + "`t" + "`t" + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}" 
                $a += "`t" + "`t" + "`t" + "TH{border-width: 1px;padding: 2px;border-style: solid;border-color: black;background-color:thistle;}" 
                $a += "`t" + "`t" + "`t" + "TD{border-width: 1px;padding: 2px;border-style: solid;border-color: black;background-color:#e6e6e6;}" 
                $a += "`t" + "`t" + "`t" + "a{ color: black; }"
                $a += "`t" + "`t" + "`t" + "a:hover { color: yellow; }"
                $a += "`t" + "`t" + "`t" + '#SearchInput {'
                $a += "`t" + "`t" + "`t" + "`t" + 'background-position: 10px 10px;'
                $a += "`t" + "`t" + "`t" + "`t" + 'background-repeat: no-repeat;'
                $a += "`t" + "`t" + "`t" + "`t" + 'width: 100%;'
                $a += "`t" + "`t" + "`t" + "`t" + 'font-size: 16px;'
                $a += "`t" + "`t" + "`t" + "`t" + 'padding: 12px 20px 12px 40px;'
                $a += "`t" + "`t" + "`t" + "`t" + 'border: 1px solid #ddd;'
                $a += "`t" + "`t" + "`t" + "`t" + 'margin-bottom: 12px;'
                $a += "`t" + "`t" + "`t" + '}'
                $a += "`t" + "`t" + "`t" + '#SearchTable {border-collapse: collapse;}'
                $a += "`t" + "`t" + "</style>"
        
                $a += "`t" + "`t" + '<script>'
                $a += "`t" + "`t" + "`t" + 'function SearchFunction() {'
                $a += "`t" + "`t" + "`t" + "`t" + 'var input, filter, table, tr, td, i, txtValue;'
                $a += "`t" + "`t" + "`t" + "`t" + 'input = document.getElementById("SearchInput");'
                $a += "`t" + "`t" + "`t" + "`t" + 'filter = input.value.toUpperCase();'
                $a += "`t" + "`t" + "`t" + "`t" + 'table = document.getElementById("SearchTable");'
                $a += "`t" + "`t" + "`t" + "`t" + 'tr = table.getElementsByTagName("tr");'
                $a += "`t" + "`t" + "`t" + "`t" + 'for (i = 1; i < tr.length; i++) {'
                $a += "`t" + "`t" + "`t" + "`t" + "`t" + 'td = tr[i];'
                $a += "`t" + "`t" + "`t" + "`t" + "`t" + 'if (td) {'
                $a += "`t" + "`t" + "`t" + "`t" + "`t" + "`t" + 'txtValue = td.textContent || td.innerText;'
                $a += "`t" + "`t" + "`t" + "`t" + "`t" + "`t" + 'if (txtValue.toUpperCase().indexOf(filter) > -1) {'
                $a += "`t" + "`t" + "`t" + "`t" + "`t" + "`t" + "`t" + 'tr[i].style.display = "";'
                $a += "`t" + "`t" + "`t" + "`t" + "`t" + "`t" + '} else {'
                $a += "`t" + "`t" + "`t" + "`t" + "`t" + "`t" + "`t" + 'tr[i].style.display = "none";'
                $a += "`t" + "`t" + "`t" + "`t" + "`t" + "`t" + '}'
                $a += "`t" + "`t" + "`t" + "`t" + "`t" + '}'
                $a += "`t" + "`t" + "`t" + "`t" + '}'
                $a += "`t" + "`t" + "`t" + '}'
                $a += "`t" + "`t" + '</script>'
                Return $a
        }
        #endregion
        $StartTime = Get-Date
        $Server = $ServerItem.ServerName
        $User = $ServerItem.Username
        
        Switch ($DebugState) {
            $True {
                    $ServerLogFile = ($GlobalConfig.Settings.Sources.LogFolder +'Debug\' + $StartTime.Tostring("yyyy-MM-dd") + '\'+ $Server + '_' + $User + '_' + $StartTime.Tostring("yyyy-MM-dd") + '.log')
            }
            $False {
                    $ServerLogFile = ($GlobalConfig.Settings.Sources.LogFolder +'Active\' + $StartTime.Tostring("yyyy-MM-dd") + '\'+ $Server + '_' + $User + '_' + $StartTime.Tostring("yyyy-MM-dd") + '.log')
            }
        }

        $a = Get-HTMLCode -Style Style
        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Testing TCP Port ' + $GlobalConfig.Settings.Communication.CommPort.ToString())
        $TestPortResults = Test-Port $Server -Port $GlobalConfig.Settings.Communication.CommPort
        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Test Port Result: ' + $TestPortResults)
        If (($TestPortResults.Open) -eq $True -and ($TestPortResults.Domain -like $env:USERDNSDOMAIN)) {
                If (!($Server -eq 'DCPRD01' -or $Server -eq 'DCPRD02' -or $Server -eq 'DCPRD03' -or $Server -eq 'DCPRD04' -or $Server -eq 'DHCPPRD01' -or $Server -eq 'DCDRS01')) {
                        If (!(Test-Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server))) {
                                New-Item ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server) -Type Directory | Out-Null
                                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Directory created: ' + $ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server)
                        }
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Bare Metal info')
                        $BMRInHTML = Get-BMRInfo -Server ($Server + '.' + $TestPortResults.Domain)
                        $BMRInHTML | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Bare Metal info.html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Bare Metal saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Bare Metal info.html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Disk info')
                        $VolumesInHTML = Get-DiskInfo -Server ($Server + '.' + $TestPortResults.Domain)
                        $VolumesInHTML[0] | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Space (' + $VolumesInHTML[1].ToString() + ' errors).html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Volume Information saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Space (' + $VolumesInHTML[1] + ' errors).html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Services')
                        $ServicesInHTML  = Get-Services -Server ($Server + '.' + $TestPortResults.Domain)
                        $ServicesInHTML  | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Services.html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Services Information saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Services.html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Shares')
                        $SharesInHTML = Get-Shares -Server ($Server + '.' + $TestPortResults.Domain)
                        $SharesInHTML | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Shares.html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Shares Information saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Shares.html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Groups')
                        $GroupsInHTML = Get-Groups -Server ($Server + '.' + $TestPortResults.Domain)
                        $GroupsInHTML | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Groups.html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Group information saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Groups.html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Shadow Copies')
                        $ShadowCopiesInHTML = Get-ShadowCopies -Server ($Server + '.' + $TestPortResults.Domain)
                        $ShadowCopiesInHTML[0] | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' ShadowCopies (' + $ShadowCopiesInHTML[1].ToString() + ' errors).html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Shadow Copies saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Shadow Copies (' + $ShadowCopiesInHTML[1] + ' errors).html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Network Details')
                        $NICDetailsInHTML = Get-NICDetails -Server ($Server + '.' + $TestPortResults.Domain)
                        $NICDetailsInHTML | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Network Details.html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Network Details saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Network Details.html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Network Routing Details')
                        $RouteDetailsInHTML = Get-Routes -Server ($Server + '.' + $TestPortResults.Domain)
                        $RouteDetailsInHTML | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Network Routes.html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Network Routes saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Network Routes.html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Applications Installed')
                        $ApplicationsInHTML = Get-Products -Server ($Server + '.' + $TestPortResults.Domain)
                        $ApplicationsInHTML | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Applications.html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Application information saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Applications.html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting installed Updates')
                        $UpdatesInHTML = Get-Updates -Server ($Server + '.' + $TestPortResults.Domain)
                        $UpdatesInHTML | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Updates.html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Update information saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Updates.html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Application Errors')
                        $ApplicationErrorsInHTML = Get-EventLogs -Server ($Server + '.' + $TestPortResults.Domain) -Logname 'Application' -Level 2
                        $ApplicationErrorsInHTML[0] | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Application Errors (' + $ApplicationErrorsInHTML[1].ToString() + ' errors).html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Application Errors saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Application Errors (' + $ApplicationErrorsInHTML[1] + ' errors).html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Application Warnings')
                        $ApplicationWarningsInHTML = Get-EventLogs -Server ($Server + '.' + $TestPortResults.Domain) -Logname 'Application' -Level 3
                        $ApplicationWarningsInHTML[0] | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Application Warnings (' + $ApplicationWarningsInHTML[1].ToString() + ' errors).html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Application Warnings saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Application Warnings (' + $ApplicationWarningsInHTML[1] + ' errors).html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting System Errors')
                        $SystemErrorsInHTML = Get-EventLogs -Server ($Server + '.' + $TestPortResults.Domain) -Logname 'System' -Level 2
                        $SystemErrorsInHTML[0] | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' System Errors (' + $SystemErrorsInHTML[1].ToString() + ' errors).html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('System Errors saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' System Errors (' + $SystemErrorsInHTML[1] + ' errors).html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting System Warnings')
                        $SystemWarningsInHTML = Get-EventLogs -Server ($Server + '.' + $TestPortResults.Domain) -Logname 'System' -Level 3
                        $SystemWarningsInHTML[0] | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' System Warnings (' + $SystemWarningsInHTML[1].ToString() + ' errors).html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('System Warnings saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' System Warnings (' + $SystemWarningsInHTML[1] + ' errors).html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Security Warnings')
                        $SecurityWarningInHTML = Get-EventLogs -Server ($Server + '.' + $TestPortResults.Domain) -Logname 'Security' -ID (4776,4625,5378)
                        $SecurityWarningInHTML[0] | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Security Warnings (' + $SecurityWarningInHTML[1].ToString() + ' errors).html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Security Warnings saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Security Warnings (' + $SecurityWarningInHTML[1] + ' errors).html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Performance Monitors')
                        $PerfmonsInHTML = Get-Perfmons -Server ($Server + '.' + $TestPortResults.Domain)
                        $PerfmonsInHTML | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Performance Monitors.html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('PerfMons saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Performance Monitors.html'))

                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Creating New HTML Summary')
                        New-HTMLSummary -User $User -Server $Server
                        
                        }
                Else {
                        Write-Log -LogFile $ServerLogFile -Level Warning -Component $MyInvocation.MyCommand.Name -Message ('Server listed as Domain Controller Exclusion')
                        If (!(Test-Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server))) {
                                New-Item ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server) -Type Directory | Out-Null
                                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Directory created: ' + $ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server)
                        }
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Bare Metal info')
                        $BMRInHTML = Get-BMRInfo -Server ($Server + '.' + $TestPortResults.Domain)
                        $BMRInHTML | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Bare Metal info.html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Bare Metal saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Bare Metal info.html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Disk info')
                        $VolumesInHTML = Get-DiskInfo -Server ($Server + '.' + $TestPortResults.Domain)
                        $VolumesInHTML[0] | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Space (' + $VolumesInHTML[1].ToString() + ' errors).html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Volume Information saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Space (' + $VolumesInHTML[1] + ' errors).html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Services')
                        $ServicesInHTML  = Get-Services -Server ($Server + '.' + $TestPortResults.Domain)
                        $ServicesInHTML  | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Services.html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Services Information saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Services.html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Shares')
                        $SharesInHTML = Get-Shares -Server ($Server + '.' + $TestPortResults.Domain)
                        $SharesInHTML | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Shares.html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Shares Information saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Shares.html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Warning -Component $MyInvocation.MyCommand.Name -Message ('Skipping Groups')
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Shadow Copies')
                        $ShadowCopiesInHTML = Get-ShadowCopies -Server ($Server + '.' + $TestPortResults.Domain)
                        $ShadowCopiesInHTML[0] | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' ShadowCopies (' + $ShadowCopiesInHTML[1].ToString() + ' errors).html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Shadow Copies saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' ShadowCopies (' + $ShadowCopiesInHTML[1] + ' errors).html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting NIC Details')
                        $NICDetailsInHTML = Get-NICDetails -Server ($Server + '.' + $TestPortResults.Domain)
                        $NICDetailsInHTML | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' NICDetails.html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('NIC Details saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' NICDetails.html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Network Routing Details')
                        $RouteDetailsInHTML = Get-Routes -Server ($Server + '.' + $TestPortResults.Domain)
                        $RouteDetailsInHTML | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Network Routes.html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Network Routes saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Network Routes.html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Applications Installed')
                        $ApplicationsInHTML = Get-Products -Server ($Server + '.' + $TestPortResults.Domain)
                        $ApplicationsInHTML | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Applications.html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Application information saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Applications.html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting installed Updates')
                        $UpdatesInHTML = Get-Updates -Server ($Server + '.' + $TestPortResults.Domain)
                        $UpdatesInHTML | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Updates.html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Update information saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Updates.html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Application Errors')
                        $ApplicationErrorsInHTML = Get-EventLogs -Server ($Server + '.' + $TestPortResults.Domain) -Logname 'Application' -Level 2
                        $ApplicationErrorsInHTML[0] | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' ApplicationErrors (' + $ApplicationErrorsInHTML[1].ToString() + ' errors).html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Application Errors saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' ApplicationErrors (' + $ApplicationErrorsInHTML[1] + ' errors).html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Application Warnings')
                        $ApplicationWarningsInHTML = Get-EventLogs -Server ($Server + '.' + $TestPortResults.Domain) -Logname 'Application' -Level 3
                        $ApplicationWarningsInHTML[0] | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' ApplicationWarnings (' + $ApplicationWarningsInHTML[1].ToString() + ' errors).html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Application Warnings saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' ApplicationWarnings (' + $ApplicationWarningsInHTML[1] + ' errors).html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting System Errors')
                        $SystemErrorsInHTML = Get-EventLogs -Server ($Server + '.' + $TestPortResults.Domain) -Logname 'System' -Level 2
                        $SystemErrorsInHTML[0] | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' SystemErrors (' + $SystemErrorsInHTML[1].ToString() + ' errors).html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('System Errors saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' SystemErrors (' + $SystemErrorsInHTML[1] + ' errors).html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting System Warnings')
                        $SystemWarningsInHTML = Get-EventLogs -Server ($Server + '.' + $TestPortResults.Domain) -Logname 'System' -Level 3
                        $SystemWarningsInHTML[0] | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' SystemWarnings (' + $SystemWarningsInHTML[1].ToString() + ' errors).html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('System Warnings saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' SystemWarnings (' + $SystemWarningsInHTML[1] + ' errors).html'))
                        
                        Write-Log -LogFile $ServerLogFile -Level Warning -Component $MyInvocation.MyCommand.Name -Message ('Skipping Security Warnings')
                        
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Perfmons')
                        $PerfmonsInHTML = Get-Perfmons -Server ($Server + '.' + $TestPortResults.Domain)
                        $PerfmonsInHTML | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' PerfMon.html')
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('PerfMons saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' PerfMon.html'))

                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Creating New HTML Summary')
                        New-HTMLSummary -User $User -Server $Server
                }
        }
        Else {
                Write-Log -LogFile $ServerLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Server unavailable or not in ' + $env:USERDNSDOMAIN)
                $LogFile = ($Server + '_' + $User + '_' + $StartTime.Tostring("yyyy-MM-dd") + '.log')
                [String[]] $UnavailableBody = Get-HTMLCode -Style Head
                $UnavailableBody += "`t" + "`t" + '<TABLE>'
                $UnavailableBody += "`t" + "`t" + "`t" + '<tr><th>Index</tr></th>'
                $UnavailableBody += "`t" + "`t" + "`t" + '<tr><td>' + $Server + '</tr></td>'
                Switch ($DebugState) {
	                $True {
                                $UnavailableBody += "`t" + "`t" + "`t" + '<tr><td><a href="http://' + $GlobalConfig.Settings.Hosting.LoggingServer + ':' + $GlobalConfig.Settings.Hosting.LoggingPort + '/Debug/' + ($StartTime.ToString("yyyy-MM-dd")) +'/' + $LogFile + '" download>' + 'Log File: ' + $LogFile + '</a></tr></td>'
                                $UnavailableBody += "`t" + "`t" + '</TABLE>'
                                $UnavailableBody += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + '/index.html">Home</a></h2>'
	                }
	                $False {
                                $UnavailableBody += "`t" + "`t" + "`t" + '<tr><td><a href="http://' + $GlobalConfig.Settings.Hosting.LoggingServer + ':' + $GlobalConfig.Settings.Hosting.LoggingPort + '/Active/' + ($StartTime.ToString("yyyy-MM-dd")) +'/' + $LogFile + '" download>' + 'Log File: ' + $LogFile + '</a></tr></td>'
                                $UnavailableBody += "`t" + "`t" + '</TABLE>'
                                $UnavailableBody += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/index.html">Home</a></h2>'
	                }
                }
                $UnavailableBody += "`t" + '</BODY>'
                $UnavailableBody += '</HTML>'
                
                If (!(Test-Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\Unavailable'))) {
                        New-Item ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\Unavailable') -Type Directory | Out-Null
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Created Unavailable directory: '+ ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\Unavailable'))
                }

                $UnavailableBody | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\Unavailable\' + $Server + ' Unavailable.html')
                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Unavailable file saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\Unavailable\' + $Server + ' Unavailable.html'))
        }
        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Report Completed')