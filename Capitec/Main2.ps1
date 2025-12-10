$ErrorActionPreference = 'Stop'
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
Function Stop-Jobs {
        Get-Job | Stop-Job
        Get-Job | Remove-Job
}
Function Start-Jobs {
        Param (
                [Parameter(Mandatory=$True, Position=1)][ValidateSet("TargetOnly","ArgumentsOnly","Both")]
                [String] $PassTargetToScriptBlock, `
                [Parameter(Mandatory=$True, Position=2)]
                [ScriptBlock] $ScriptBlock, `
                [Parameter(Mandatory=$False, Position=3)]
                [Object[]] $ScriptBlockArguments, `
                [Parameter(Mandatory=$True, Position=4)]
                [Object[]] $Targets, `
                [Parameter(Mandatory=$False, Position=5)]
                [Switch] $ReportImmediate=$False, `
                [Parameter(Mandatory=$False, Position=6)]
                [Int32]    $MaximumJobs=$env:NUMBER_OF_PROCESSORS, `
                [Parameter(Mandatory=$False, Position=7)]
                [Int]  $WaitTime = 0
        )

        $Jobs = @()

        Switch ($ReportImmediate) {
                $True { 
                        Write-Host ("Starting Jobs for " + $Targets.Count.ToString() + " targets. Please wait for the results.")
                }
        }
        ForEach ($Target in $Targets) {
                Switch ($ReportImmediate) {
                        $False { 
                                Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Starting Job for ' + $Target.ServerName)
                                Write-Host ("Starting Job for " + $Target.ServerName)
                        }
                }
                Switch ($PassTargetToScriptBlock) {
                        "TargetOnly" {
                                $Jobs = $Jobs + (Start-Job -Name $Target.ServerName -ScriptBlock $ScriptBlock -ArgumentList $Target)
                        }
                        "ArgumentsOnly" {
                                $Jobs = $Jobs + (Start-Job -Name $Target.ServerName -ScriptBlock $ScriptBlock -ArgumentList $ScriptBlockArguments)
                        }
                        "Both" {
                                $Arguments = @()
                                $Arguments = $Arguments + $Target
                                ForEach ($ScriptBlockArgument in $ScriptBlockArguments) {
                                        $Arguments = $Arguments + $ScriptBlockArgument
                                }
                                $Jobs = $Jobs + (Start-Job -Name $Target.ServerName -ScriptBlock $ScriptBlock -ArgumentList $Arguments)
                        }
                }
                $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})
                Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Currently Running Jobs Count: ' + $RunningJobs.Count.ToString() + "`n" + ('Currently Running Jobs:' + $RunningJobs.Name -join "`n"))
                While ($RunningJobs.Count -ge $MaximumJobs) {
                        Switch ($ReportImmediate) {
                                $True {
                                        $CompletedJobs = @($Jobs | Where-Object {$_.HasMoreData -eq "True"})
                                        ForEach ($CompleteJob in $CompletedJobs) {
                                                Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message (Receive-Job $CompleteJob)
                                        }
                                }
                        }
                        $RunningJobs  = @($Jobs | Where-Object {$_.State -eq 'Running'})
                }
        }
        If ($WaitTime -gt 0) { 
                Write-Log -LogFile $MainLogFile -Level Warning -Component $MyInvocation.MyCommand.Name -Message ('Wait Timer initiated')
                Start-Job -Name 'Timer' -ArgumentList $WaitTime -ScriptBlock {
                        Param ($WaitTime)

                        For ($i = 0; $i -lt $WaitTime; $i ++) {
                                Start-Sleep -Seconds 1
                        }
                } | Out-Null

                [DateTime] $Counter = 0
                While ((Get-Job Timer).State -eq 'Running') {
                        If ((get-job | Where-Object {$_.State -eq 'Running' -and $_.Name -ne 'Timer'}).Count -gt 0) {
                                Write-Host ($Counter.ToString("HH:mm:ss"))
                                Start-Sleep -Seconds 10
                                $Counter = $Counter.AddSeconds(10)
                                Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Currently Running Count: ' + (Get-Job | Where-Object {$_.State -eq 'Running' -and $_.Name -ne 'Timer'}).Count.ToString() + "`n" + ' Running Jobs: ' + (Get-Job | Where-Object {$_.State -eq 'Running' -and $_.Name -ne 'Timer'}).Name -join "`n")
                        }
                        Else {
                                Stop-Job Timer | Out-Null
                        }
                }
                Write-Log -LogFile $MainLogFile -Level Warning -Component $MyInvocation.MyCommand.Name -Message ('Wait Timer stopped')
                Get-Job Timer | Wait-Job | Out-Null
                Get-Job Timer | Remove-Job | Out-Null
        }
        Else {
                Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Waiting for jobs to complete')
                Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message (Wait-Job -Job $Jobs)
        }
        $FailedJobs = @($Jobs | Where-Object {$_.State -eq 'Failed'})
        If ($FailedJobs.Count -gt 0) {
                Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Failed jobs count: ' + $FailedJobs.Count.ToString())
                ForEach ($FailedJob in $FailedJobs) {
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ($FailedJob.Name + $FailedJob.ChildJobs[0].JobStateInfo.Reason.Message)
                }
        }
        $JobResults = @()
        Switch ($ReportImmediate) {
                $False {
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Compiling Job Results')
                        $ErrorActionPreference = 'SilentlyContinue'
                        ForEach ($Job in $Jobs) {
                                Stop-Job -Job $Job
                                $JobResults = $JobResults + (Receive-Job -Job $Job)
                        }
                        $ErrorActionPreference = 'Stop'
                }
        }
        Get-Job | Wait-Job | Remove-Job
        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Jobs completed')
        Return $JobResults
}
Function New-MainIndex {
        Switch ($DebugState) {
                $True {
                        [String[]] $MainBody = Get-HTMLCode -Style Head
                        $MainBody += "`t" + "`t" + '<center><h1>' + $StartTime.ToString('yyyy/MM/dd') + '</h1></center>'
                        $MainBody += "`t" + "`t" + '<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">'
                        $MainBody += "`t" + "`t" + '<TABLE id="SearchTable">'
                        $MainBody += "`t" + "`t" + "`t" + '<tr><th><h1>Users</h1></th><th><h1>Server List</h1></th></tr>'

                        $IndexFiles = Get-ChildItem ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\' ) -recurse | Where-Object {$_.FullName -notlike '*\Summary*' -and $_.Name -like '*-index*'}
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Index Files found: ' + $IndexFiles.Count.ToString())
                        ForEach ($IndexFile in $IndexFiles) {
                                $MainBody += "`t" + "`t" + "`t" + '<tr><td><a href="file:///' + $IndexFile.FullName.Replace("\", "/") + '">' + ($IndexFile.Name -Split "-index.html")[0] + '</a></td><td>' + (($Serverlist | Where-Object UserName -eq ($IndexFile.Name -Split "-index.html")[0] | Select-Object ServerName).Servername -join ', ') + '</td></tr>'
                        } 
                        $MainBody += "`t" + "`t" + '</TABLE>'
                        
                        $MainBody += "`t" + "`t" + '<h2><a href="file:///' +  $ReportFolder + '\index.html">Dates</a> <a href="file:///' + $ReportFolder + $StartTime.ToString('yyyy-MM-dd') + '/Summary/Summary.html">Summary</a></h2>'
                        $MainBody += "`t" + '</BODY>'
                        $MainBody += '</HTML>'
                        $MainBody | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd"))  + "\index.html")
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('File Saved to ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd"))  + "\index.html"))
                }
                $False {
                        [String[]] $MainBody = Get-HTMLCode -Style Head
                        $MainBody += "`t" + "`t" + '<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">'
                        $MainBody += "`t" + "`t" + '<TABLE id="SearchTable">'
                        $MainBody += "`t" + "`t" + "`t" + '<tr><th><h1>Users</h1></th><th><h1>Server List</h1></th></tr>'

                        $IndexFiles = Get-ChildItem ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\' ) -recurse | Where-Object {$_.FullName -notlike '*\Summary*' -and $_.Name -like '*-index*'}
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Index Files found: ' + $IndexFiles.Count.ToString())
                        ForEach ($IndexFile in $IndexFiles) {
                                $MainBody += "`t" + "`t" + "`t" + '<tr><td><a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + ($IndexFile.FullName.Replace($ReportFolder, "").Replace("\", "/")) + '">' + ($IndexFile.Name -Split "-index.html")[0] + '</a></td><td>' + (($Serverlist | Where-Object UserName -eq ($IndexFile.Name -Split "-index.html")[0] | Select-Object ServerName).Servername -join ', ') + '</td></tr>'
                        } 
                        $MainBody += "`t" + "`t" + '</TABLE>'
                        $MainBody += "`t" + "`t" + '<h2><a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/index.html">Dates</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/Summary/Summary.html">Summary</a></h2>'
                        $MainBody += "`t" + '</BODY>'
                        $MainBody += '</HTML>'
                        $MainBody | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd"))  + "\index.html")
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('File Saved to ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd"))  + "\index.html"))
                }
        }
}
Function New-DateIndex {
        Switch ($DebugState) {
                $True {
                        [String[]] $DateBody = Get-HTMLCode -Style Head
                        $DateBody += "`t" + "`t" + '<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">'
                        $DateBody += "`t" + "`t" + '<TABLE id="SearchTable">'
                        $DateBody += "`t" + "`t" + "`t" + '<tr><th><h1>Dates</h1></th></tr>'
                        $DateBody += "`t" + "`t" + "`t" + '<tr><td><a href="file:///' + $ReportFolder + $StartTime.ToString("yyyy-MM-dd") + '/index.html">' + $StartTime.ToString("yyyy-MM-dd") + '</a></td></tr>'
                        $DateBody += "`t" + "`t" + '</TABLE>'
                        $DateBody += "`t" + '</BODY>'
                        $DateBody += '</HTML>'
                        $DateBody | Out-File ($ReportFolder + 'index.html')
                        
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('New Date Index File: '+ ($ReportFolder + 'index.html'))
                }
                $False {
                        [String[]] $DateBody = Get-HTMLCode -Style Head
                        $DateBody += "`t" + "`t" + '<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">'
                        $DateBody += "`t" + "`t" + '<TABLE id="SearchTable">'
                        $DateBody += "`t" + "`t" + "`t" + '<tr><th><h1>Dates</h1></th></tr>'
                        
                        Try {
                                (Get-Content ($ReportFolder + 'index.html')).Replace("`t" + "`t" + '</TABLE>', ("`t" + "`t" + "`t" + '<tr><td><a href="file:///' + $ReportFolder + $StartTime.ToString("yyyy-MM-dd") + '/index.html">' + $StartTime.ToString("yyyy-MM-dd") + '</a></td></tr>' + "`n" + "`t" + "`t" + '</TABLE>')) | Out-File ($ReportFolder + 'index.html')
                        }
                        Catch {
                                Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Exception: ' + $_.Exception + "`n" + 'Message: ' + $_.Message + "`n" + 'Line Number: ' + $_.InvocationInfo.ScriptLineNumber)
                                $DateBody += "`t" + "`t" + '</TABLE>'
                                $DateBody += "`t" + '</BODY>'
                                $DateBody += '</HTML>'
                                $DateBody | Out-File ($ReportFolder + 'index.html')
                        }
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('New Date Index File: '+ ($ReportFolder + 'index.html'))
                }
        }
}
Function Update-DateIndex {
        Switch ($DebugState) {
                $True {
                        (Get-Content ($ReportFolder + 'index.html')).Replace('<tr><th><h1>Dates</h1></th></tr>', ('<tr><th><h1>Dates</h1></th></tr>' + "`n" + "`t" + "`t" + "`t" + '<tr><td><a href="file:///' + $ReportFolder + $StartTime.ToString("yyyy-MM-dd") + '/index.html">' + $StartTime.ToString("yyyy-MM-dd") + '</a></td></tr>')) | Out-File ($ReportFolder + 'index.html')
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Updated Date Index File: '+ ($ReportFolder + 'index.html'))
                }
                $False {
                        (Get-Content ($ReportFolder + 'index.html')).Replace('<tr><th><h1>Dates</h1></th></tr>', ('<tr><th><h1>Dates</h1></th></tr>' + "`n" + "`t" + "`t" + "`t" + '<tr><td><a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString("yyyy-MM-dd") + '/index.html">' + $StartTime.ToString("yyyy-MM-dd") + '</a></td></tr>')) | Out-File ($ReportFolder + 'index.html')
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Updated Date Index File: '+ ($ReportFolder + 'index.html'))
                }
        }

}
Function Set-BuildHTML {
        param(
                [Parameter(Mandatory=$True, Position=1)]
                [String] $User)

        Switch ($DebugState) {
                $True {
                        [String[]] $Body = Get-HTMLCode -Style Head
                        $Body += "`t" + "`t" + '<TABLE>'
                        $Body += "`t" + "`t" + "`t" + '<tr><th><h1><center>' + $User.ToUpper() + ' Server Checks - ' + ($StartTime.ToString('yyyy/MM/dd')) + '</center></h1></th></tr>'
                        $Body += "`t" + "`t" + "`t" + '<tr><td><span style="background-color: red;"><a href="file:///' + $ReportFolder + $StartTime.ToString("yyyy-MM-dd") + '/'  + $User + '/AllDiskSummary/index.html">Summary of Servers with Disk issues</a></span></td></tr>'
                        $Body += "`t" + "`t" + "`t" + '<tr><td><span style="background-color: red;"><a href="file:///' + $ReportFolder + $StartTime.ToString("yyyy-MM-dd") + '/'  + $User + '/ShadowCopySummary/index.html">Summary of Servers with ShadowCopy issues</a></span></td></tr>'
                        $Body += "`t" + "`t" + "`t" + '<tr><td><span style="background-color: red;"><a href="file:///' + $ReportFolder + $StartTime.ToString("yyyy-MM-dd") + '/'  + $User + '/Unavailable/index.html">Unavailable Servers</a></span></td></tr>'
                        $Body += "`t" + "`t" + "`t" + '<tr><td><a href="file:///' + $ReportFolder + $StartTime.ToString("yyyy-MM-dd") + '/'  + $User + '/PerfmonSummary/index.html">Summary of Servers with PerfMon issues</a></td></tr>'
                        
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting directories in ' + $ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User)
                        $Directories = Get-ChildItem ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User) | Where-Object {$_.PSIsContainer -eq $True}
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Directories found: ' + $Directories.Count.ToString())
                        ForEach($Dir in $Directories) {
                                If ($Dir.Name -notlike  '*AllDiskSummary*' -and  $Dir.Name -notlike  '*PerfMonSummary*' -and $Dir.Name -notlike  '*Unavailable*' -and $Dir.Name -notlike  '*ShadowCopySummary*') {
                                        $Body += "`t" + "`t" + "`t" + '<tr><td><a href="file:///' + $ReportFolder + $StartTime.ToString("yyyy-MM-dd") + '/'  + $User + '/' + $Dir.Name + '/index.html">' + $Dir.Name + '</a></td></tr>'
                                }
                        }
                        $Body += "`t" + "`t" + '</TABLE>'
                        $Body += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '/index.html">Home</a></h2>'
                        $Body += "`t" + '</BODY>'
                        $Body += '</HTML>'

                        $Body | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $User + '-index.html')
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('File saved to: ')
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Creating "No Information" pages for folders without .index.html and creating link to .index.html files')
                        ForEach ($Dir in $Directories) {
                                [String[]] $NewBody = Get-HTMLCode -Style Head
                                $NewBody += "`t" + "`t" + '<TABLE>'
                                $NewBody += "`t" + "`t" + "`t"  + '<tr><th>Index</tr></th>'
                                
                                $Files = Get-ChildItem ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $USER + '\' + $Dir.Name) | Where-Object {$_.PSIsContainer -eq $false -and $_.name -ne 'index.html' -and $_.name -notlike '*.output*'}
                                If (($Files.Count -eq 0 -or $null -eq $file.count)) {
                                        $NewBody += "`t" + "`t" + "`t"  + '<tr><td>No information available<br></tr></td>'
                                }
                                Else {
                                        ForEach ($file in $files) {	
                                                $NewBody += "`t" + "`t" + "`t"  + '<tr><td><a href="file:///' + $ReportFolder + ($StartTime.ToString('yyyy-MM-dd')) +'/' + $User + '/' + $Dir.Name + '/' + $File.Name + '">' + $File.BaseName + '</a></tr></td>'
                                        }
                                }

                                If ($Dir.Name -notlike  '*AllDiskSummary*' -and  $Dir.Name -notlike  '*PerfMonSummary*' -and $Dir.Name -notlike  '*Unavailable*' -and $Dir.Name -notlike  '*ShadowCopySummary*') {
                                        $LogFile = ($Dir.Name + '_' + $User + '_' + $StartTime.Tostring("yyyy-MM-dd") + '.log')
                                        $NewBody += "`t" + "`t" + "`t"  + '<tr><td><a href="file:///' + $GlobalConfig.Settings.Sources.LogFolder + 'Debug/' + ($StartTime.ToString("yyyy-MM-dd")) +'/' + $LogFile + '" download>' + 'Log File: ' + $LogFile + '</a></tr></td>'
                                }

                                $NewBody += "`t" + "`t" + '</TABLE>'
                                $NewBody += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>'
                                $NewBody += "`t" + '</BODY>'
                                $NewBody += '</HTML>'
                                $NewBody | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Dir.Name + '\index.html')
                                Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('File saved to: ' + $ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Dir.Name + '\index.html')
                        }
                }
                $False {
                        [String[]] $Body = Get-HTMLCode -Style Head
                        $Body += "`t" + "`t" + '<TABLE>'
                        $Body += "`t" + "`t" + "`t" + '<tr><th><h1><center>' + $User.ToUpper() + ' Server Checks - ' + ($StartTime.ToString('yyyy/MM/dd')) + '</center></h1></th></tr>'
                        $Body += "`t" + "`t" + "`t" + '<tr><td><span style="background-color: red;"><a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/'+ $StartTime.ToString("yyyy-MM-dd") + '/'  + $User + '/AllDiskSummary/index.html">Summary of Servers with Disk issues</a></span></td></tr>'
                        $Body += "`t" + "`t" + "`t" + '<tr><td><span style="background-color: red;"><a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/'+ $StartTime.ToString("yyyy-MM-dd") + '/'  + $User + '/ShadowCopySummary/index.html">Summary of Servers with ShadowCopy issues</a></span></td></tr>'
                        $Body += "`t" + "`t" + "`t" + '<tr><td><span style="background-color: red;"><a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/'+ $StartTime.ToString("yyyy-MM-dd") + '/'  + $User + '/Unavailable/index.html">Unavailable Servers</a></span></td></tr>'
                        $Body += "`t" + "`t" + "`t" + '<tr><td><a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/'+ $StartTime.ToString("yyyy-MM-dd") + '/'  + $User + '/PerfmonSummary/index.html">Summary of Servers with PerfMon issues</a></td></tr>'
                        
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting directories in ' + $ReportFolder)
                        $Directories = Get-ChildItem ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User) | Where-Object {$_.PSIsContainer -eq $True}
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Directories found: ' + $Directories.Count.ToString())
                        ForEach($Dir in $Directories) {
                                If ($Dir.Name -notlike  '*AllDiskSummary*' -and  $Dir.Name -notlike  '*PerfMonSummary*' -and $Dir.Name -notlike  '*Unavailable*' -and $Dir.Name -notlike  '*ShadowCopySummary*') {
                                        $Body += "`t" + "`t" + "`t" + '<tr><td><a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/'+ $StartTime.ToString("yyyy-MM-dd") + '/'  + $User + '/' + $Dir.Name + '/index.html">' + $Dir.Name + '</a></td></tr>'
                                }
                        }
                        $Body += "`t" + "`t" + '</TABLE>'
                        $Body += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>'
                        $Body += "`t" + '</BODY>'
                        $Body += '</HTML>'
                
                        $Body | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $User + '-index.html')
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('File saved to: ')
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Creating "No Information" pages for folders without .index.html and creating link to .index.html files')
                        ForEach ($Dir in $Directories) {
                                [String[]] $NewBody = Get-HTMLCode -Style Head
                                $NewBody += "`t" + "`t" + '<TABLE>'
                                $NewBody += "`t" + "`t" + "`t"  + '<tr><th>Index</tr></th>'
                                
                                $Files = Get-ChildItem ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $USER + '\' + $Dir.Name) | Where-Object {$_.PSIsContainer -eq $false -and $_.name -ne 'index.html' -and $_.name -notlike '*.output*'}
                                If (($Files.Count -eq 0 -or $null -eq $file.count)) {
                                        $NewBody += "`t" + "`t" + "`t"  + '<tr><td>No information available<br></tr></td>'
                                }
                                Else {
                                        ForEach ($file in $files) {	
                                                $NewBody += "`t" + "`t" + "`t"  + '<tr><td><a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + ($StartTime.ToString("yyyy-MM-dd")) +'/' + $User + '/' + $Dir.Name + '/' + $File.Name + '">' + $File.BaseName + '</a></tr></td>'
                                        }
                                }
                
                                If ($Dir.Name -notlike  '*AllDiskSummary*' -and  $Dir.Name -notlike  '*PerfMonSummary*' -and $Dir.Name -notlike  '*Unavailable*' -and $Dir.Name -notlike  '*ShadowCopySummary*') {
                                        $LogFile = ($Dir.Name + '_' + $User + '_' + $StartTime.Tostring("yyyy-MM-dd") + '.log')
                                        $NewBody += "`t" + "`t" + "`t"  + '<tr><td><a href="http://' + $GlobalConfig.Settings.Hosting.LoggingServer + ':' + $GlobalConfig.Settings.Hosting.LoggingPort + '/Active/' + ($StartTime.ToString("yyyy-MM-dd")) +'/' + $LogFile + '" download>' + 'Log File: ' + $LogFile + '</a></tr></td>'
                                }
                
                                $NewBody += "`t" + "`t" + '</TABLE>'
                                $NewBody += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>'
                                $NewBody += "`t" + '</BODY>'
                                $NewBody += '</HTML>'
                                $NewBody | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Dir.Name + '\index.html')
                
                        }  
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('File saved to: ' + $ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Dir.Name + '\index.html')
                }
        }
        
}
Function Set-Errors {
        Param (
                [Parameter(Mandatory=$True, Position=1)]
                [String] $User
        )
        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Setting errors on files')
        $IndexFiles = Get-ChildItem -Recurse ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User) | Where-Object{$_.name -like '*index*'} 
        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Matching Index files found: ' + $IndexFiles.Count.ToString())
        Try {
                ForEach ($IndexFile in $IndexFiles) {
                        [String[]] $FlagBody = ""
                        $Contents = Get-Content $IndexFile.Fullname 
                        ForEach ($Line in $Contents) {
                                If ($Line -like '*error*' -and $line -notlike '*(0 errors*')
                                {
                                        $FlagBody += $line.replace($line.Substring(0,11),$line.substring(0,11) + '<span style="background-color: red;">').Replace('</a></tr></td>', '</a></span></td></tr>')
                                }
                                else
                                {
                                        $FlagBody += $Line 
                                }
                        }
                        #Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Replacing original file: ' + $IndexFile.FullName)
                        $FlagBody | Out-File $IndexFile.FullName
                }
        }
        Catch {
                Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Exception: ' + $_.Exception + "`n" + 'Message: ' + $_.Message + "`n" + 'Line Number: ' + $_.InvocationInfo.ScriptLineNumber)
        }
} 
Function Send-Email {
        Param (
                [Parameter(Mandatory=$True, Position=1)]
                [Object[]] $GlobalConfig, `
                [Parameter(Mandatory=$True, Position=2)]
                [Int] $DiskErrors, `
                [Parameter(Mandatory=$True, Position=3)]
                [Int] $PerfMonErrors, `
                [Parameter(Mandatory=$True, Position=4)]
                [Int] $ShadowCopyErrors, `
                [Parameter(Mandatory=$True, Position=5)]
                [Int] $UnavailableServers, `
                [Parameter(Mandatory=$True, Position=6)]
                [Int] $EventsSummary
        )
        [String] $EmailBody = '<HTML>'
        $EmailBody += "`t" + '<HEAD>'
        $EmailBody += "`t" + "`t" + '<TITLE>Daily Health Report Logs</TITLE>'
        $EmailBody += "`t" + '</HEAD>'
        $EmailBody += "`t" + '<BODY>'
        $EmailBody += "`t" + "`t" + '<p>Highlights:<br></p>'
        $EmailBody += "`t" + "`t" + '<table>'
        $EmailBody += "`t" + "`t" + "`t" + '<tr><th>Summary</th><th>Problems Identified</th></tr>'
        $EmailBody += "`t" + "`t" + "`t" + '<tr><td>Disk issues</td><td>' + $DiskErrors.ToString() + '</td></tr>'
        $EmailBody += "`t" + "`t" + "`t" + '<tr><td>Perfmon issues</td><td>' + $PerfMonErrors.ToString() + '</td></tr>'
        $EmailBody += "`t" + "`t" + "`t" + '<tr><td>Shadow Copy issues</td><td>' + $ShadowCopyErrors.ToString() + '</td></tr>'
        $EmailBody += "`t" + "`t" + "`t" + '<tr><td>Unavailable Server</td><td>' + $UnavailableServers.ToString() + '</td></tr>'
        $EmailBody += "`t" + "`t" + "`t" + '<tr><td>Server with Events</td><td>' + $EventsSummary.ToString() + '</td></tr>'
        $EmailBody += "`t" + "`t" + '</table>'
        $EmailBody += "`t" + "`t" + '<p>Good day,</p>'
        $EmailBody += "`t" + "`t" + '<p>The Daily server status report has finished, and the information is available on <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd')  +'/</a></p>'
        $EmailBody += "`t" + "`t" + '<p>The following information has been made available on the report:<br></p>'
        $EmailBody += "`t" + "`t" + '<ul>'
        $EmailBody += "`t" + "`t" + "`t" + '<li>Bare Metal Information</li>'
        $EmailBody += "`t" + "`t" + "`t" + '<li>Installed Applications</li>'
        $EmailBody += "`t" + "`t" + "`t" + '<li>Installed Updates</li>'
        $EmailBody += "`t" + "`t" + "`t" + '<li>Disk usage</li>'
        $EmailBody += "`t" + "`t" + "`t" + '<li>Warnings, Errors and Security Audit Failure events for the past 24 hours</li>'
        $EmailBody += "`t" + "`t" + "`t" + '<li>Shadow Copies</li>'
        $EmailBody += "`t" + "`t" + "`t" + '<li>Services state</li>'
        $EmailBody += "`t" + "`t" + "`t" + '<li>Shares and permissions</li>'
        $EmailBody += "`t" + "`t" + "`t" + '<li>Local groups and membership</li>'
        $EmailBody += "`t" + "`t" + "`t" + '<li>Network adapters</li>'
        $EmailBody += "`t" + "`t" + "`t" + '<li>Network routes</li>'
        $EmailBody += "`t" + "`t" + "`t" + '<li>Unavailable Servers</li>'
        $EmailBody += "`t" + "`t" + "`t" + '<li>Currently Logged on Users</li>'
        $EmailBody += "`t" + "`t" + "`t" + '<li>Performance monitors*</li>'
        $EmailBody += "`t" + "`t" + '</ul>'
        $EmailBody += "`t" + "`t" + '<p>If you require IT InfOps Server & Storage support for any issues that you may pick up, please log a service request on ITSM at the following link:'
        $EmailBody += "`t" + "`t" + '<br><a href="' + $GlobalConfig.Settings.Links.ITSM + '">' + $GlobalConfig.Settings.Links.ITSM + '</a></p>'
        $EmailBody += "`t" + "`t" + '<p>For any report related queries, please contact <a href="' + $GlobalConfig.Settings.Links.ReportSupport + '">' + $GlobalConfig.Settings.Links.ReportSupport + '</a></p>'
        $EmailBody += "`t" + "`t" + '<p> * Performance monitors are not configured on any server at this stage.</p>'
        $EmailBody += "`t" + "`t" + '<p>Enjoy your day!</span></p>'

        $EmailBody += "`t" + '</BODY>'
        $EmailBody += '</HTML>'


        Send-MailMessage `
                -To $GlobalConfig.Settings.EmailSetup.To `
                -BodyAsHtml `
                -Subject 'Daily Health Report' `
                -Body $EmailBody `
                -Attachments $MainLogFile `
                -From $GlobalConfig.Settings.EmailSetup.From `
                -SmtpServer $GlobalConfig.Settings.EmailSetup.SMTPServer `
                -Port $GlobalConfig.Settings.EmailSetup.SMTPPort

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
                        $a += "`t" + "`t" + '<link href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/Web/CSS/Style.css" rel="stylesheet" />'
                        $a += "`t" + "`t" + '<script src="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/Web/JScript/Jscript.js"></script>'
                        Switch ($DebugState) {
                                $True {
                                        $a += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>'
                                }
                                $False {
                                        $a += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>'
                                }
                        }
        }
        Else {
                [string[]] $a = "`t" + "`t" + '<link href="/Web/CSS/Style.css" rel="stylesheet" />'
                $a += "`t" + "`t" + '<script src="/Web/JScript/Jscript.js"></script>'
                Switch ($DebugState) {
                        $True {
                                $a += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>'
                        }
                        $False {
                                $a += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>'
                        }
                }
        }

        Return $a
}
Function Get-ServerList {
        Try {
            Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Loaded Server List')
            $LoadedServerList = Import-CSV ($GlobalConfig.Settings.Sources.ServerListFolder + $GlobalConfig.Settings.Lists.ServerList) -Delimiter ";"
            Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Loaded Servers found: ' + $LoadedServerList.Count.ToString())
            #Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting AD Servers')
            #$ADServerList = Invoke-Command -ComputerName ($env:LOGONSERVER.Replace('\\','')) -ScriptBlock { Get-ADComputer -Filter {OperatingSystem -like '*server*' -and Enabled -eq $True} -Property Name, OperatingSystem, Description, DistinguishedName | Select-Object Name, OperatingSystem, Description, DistinguishedName}
            #Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('AD Servers found: ' + $ADServerList.Count.ToString())
            #ForEach ($Server in $ADServerList) {
            #    If (!($LoadedServerList.Servername.Contains($Server.Name))) {
            #        $LoadedServerList += ,(New-Object -TypeName psobject -Property @{`
            #            ServerName = $Server.Name
            #            Username = 'Unknown'
            #            SDLC = 'Unknown';
            #            ServerGroup = 'Unknown';
            #            Description = $Server.Description
            #            Location = $Server.DistinguishedName
            #            DMZ = 'mercantile.co.za';
            #            OS = $Server.OperatingSystem
            #        })
            #        Write-Log -LogFile $MainLogFile -Level Warning -Component $MyInvocation.MyCommand.Name -Message ('Server found in AD and not in serverlist: ' + ($Server -join ", "))
            #    }
            #}
            #Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Serverlist prepared with AD Servers: ' + $LoadedServerList.Count.ToString())

            Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Loading MBL Servers')
            $MBLServerList = Import-CSV ($GlobalConfig.Settings.Sources.ServerListFolder + $GlobalConfig.Settings.Lists.MBLServerList) -Delimiter ";"
            Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('MBL Servers loaded: ' + $MBLServerList.Count.ToString())
            $MBLRemovedList = @()
            ForEach ($Server in $LoadedServerList) {
                If ($MBLServerList.Name.Contains($Server.ServerName)) {
                    Write-Log -LogFile $MainLogFile -Level Warning -Component $MyInvocation.MyCommand.Name -Message ('Server removed from Loaded Lists: ' + $Server.ServerName)
                }
                Else {
                    $MBLRemovedList += $Server
                }
            }
            
            Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Serverlist prepared without MBL AD Servers: ' + $MBLRemovedList.Count.ToString())
            
        }
        Catch {
                Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Exception: ' + $_.Exception + "`n" + 'Message: ' + $_.Message + "`n" + 'Line Number: ' + $_.InvocationInfo.ScriptLineNumber)
        }
        Return $MBLRemovedList
}
Function New-AllSummary {
        Param (
                [Parameter(Mandatory=$true,Position=4)][ValidateSet("All Disk Summary", "Perfmon Summary", "Shadow Copy Summary", "Unavailable Servers")]
                [String]$Summary)
    
        Try {
                Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Checking if ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\Summary')  + ' exists')
                If (!(Test-Path (($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\Summary')))) {
                        New-Item ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\Summary') -Type Directory | Out-Null
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('New directory created: '+ ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\Summary'))
                }

                [String[]] $AllSummaryHTML = Get-HTMLCode -Style Head
                $AllSummaryHTML += "`t" + "`t" + "<table>"
                $AllSummaryHTML += "`t" + "`t" + "`t" + '<tr><th>Index</tr></th>'
        
                Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Summary Index Files')
                Switch ($Summary) {
                        "All Disk Summary" {                
                                $IndexFiles = Get-ChildItem -Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd"))) -Recurse | Where-Object {$_.Fullname -like "*AllDiskSummary*" -and $_.name -like '*index.html'}
                        }
                        "Perfmon Summary" {                
                                $IndexFiles = Get-ChildItem -Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd"))) -Recurse | Where-Object {$_.Fullname -like "*Perfmon*" -and $_.name -like '*index.html'}
                        }
                        "Shadow Copy Summary" {                
                                $IndexFiles = Get-ChildItem -Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd"))) -Recurse | Where-Object {$_.Fullname -like "*ShadowCopy*" -and $_.name -like '*index.html'}
                        }
                        "Unavailable Servers" {                
                                $IndexFiles = Get-ChildItem -Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd"))) -Recurse | Where-Object {$_.Fullname -like "*Unavailable*" -and $_.name -like '*index.html'}
                        }
                }
                $ErrorAmount = 0
                Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ($IndexFiles.Count.Tostring() + ' found')                        
                For ($i = 0; $i -lt $IndexFiles.Count; $i ++) {
                        [String[]] $ContentData = (Get-Content $IndexFiles[$i].FullName) | Select-string "<tr><td>"
                        ForEach ($line in $ContentData) {
                                If (!($line.ToString().Contains('No information available'))) {
                                        $AllSummaryHTML += $line
                                        $ErrorAmount ++
                                }
                        }
        
                }
                $HeadIndex = (Get-HTMLCode -Style Head).Count + 2
                If ($AllSummaryHTML[$HeadIndex] -notlike '*<tr><td>*') {
                        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('No information found')
                        $AllSummaryHTML += "`t" + "`t" +  "`t" + '<tr><td>No information available<br></tr></td>'
                }
                $AllSummaryHTML += "`t" + "`t" + "</table>"
                Switch ($DebugState) {
                        $True {
                                $AllSummaryHTML += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '/index.html">Home</a></h2>'
                        }
                        $False {
                                $AllSummaryHTML += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + ($StartTime.ToString("yyyy-MM-dd")) + '/index.html">Home</a></h2>' + "`n"
                        }
                }
                $AllSummaryHTML += "`t" + '</BODY>'
                $AllSummaryHTML += '</HTML>'
                $AllSummaryHTML | Out-file ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\Summary\' + $Summary + '-index.html') -Force
                Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Summary saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\Summary\' + $Summary + '-index.html') )
        }
        Catch {
                Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Exception: ' + $_.Exception + "`n" + 'Message: ' + $_.Message + "`n" + 'Line Number: ' + $_.InvocationInfo.ScriptLineNumber)
        }
        Return $ErrorAmount
}
Function New-AllSummaryIndex {
        Param (
            [Parameter(Mandatory=$True, Position=1)]
            [Int] $DiskErrors, `
            [Parameter(Mandatory=$True, Position=2)]
            [Int] $PerfMonErrors, `
            [Parameter(Mandatory=$True, Position=3)]
            [Int] $ShadowCopyErrors, `
            [Parameter(Mandatory=$True, Position=4)]
            [Int] $UnavailableServers, `
            [Parameter(Mandatory=$True, Position=5)]
            [Int] $EventsSummary)
        Switch ($DebugState) {
            $True {
                [String[]] $MainBody = Get-HTMLCode -Style Head
                $MainBody += "`t" + "`t" + '<TABLE id="SearchTable">'
                $MainBody += "`t" + "`t" + "`t" + '<h1><tr><th>Summary</th><th>Problem found</th></tr></h1>'
                $MainBody += "`t" + "`t" + "`t" + '<tr><td><a href="file:///' + $ReportFolder + $StartTime.ToString("yyyy-MM-dd") + '/Summary/All Disk Summary-index.html">All Disk Summary</a></td><td><center>' + $DiskErrors.ToString() + '</center></td></tr>'
                $MainBody += "`t" + "`t" + "`t" + '<tr><td><a href="file:///' + $ReportFolder + $StartTime.ToString("yyyy-MM-dd") + '/Summary/Perfmon Summary-index.html">Perfmon Summary</a></td><td><center>' + $PerfMonErrors.ToString() + '</center></td></tr>'
                $MainBody += "`t" + "`t" + "`t" + '<tr><td><a href="file:///' + $ReportFolder + $StartTime.ToString("yyyy-MM-dd") + '/Summary/Shadow Copy Summary-index.html">Shadow Copy Summary</a></td><td><center>' + $ShadowCopyErrors.ToString() + '</center></td></tr>'
                $MainBody += "`t" + "`t" + "`t" + '<tr><td><a href="file:///' + $ReportFolder + $StartTime.ToString("yyyy-MM-dd") + '/Summary/Unavailable Servers-index.html">Unavailable Servers</a></td><td><center>' + $UnavailableServers.ToString() + '</center></td></tr>'
                $MainBody += "`t" + "`t" + "`t" + '<tr><td><a href="file:///' + $ReportFolder + $StartTime.ToString("yyyy-MM-dd") + '/Summary/Events Summary-index.html">Servers with Events</a></td><td><center>' + $EventsSummary.ToString() + '</center></td></tr>'
                $MainBody += "`t" + "`t" + '</TABLE>'
                $MainBody += "`t" + "`t" + '<h2><a href="file:///' +  $ReportFolder + '\index.html">Dates</a> <a href="file:///' + $ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '/index.html">Home</a></h2>'
                $MainBody += "`t" + '</BODY>'
                $MainBody += '</HTML>'
                $MainBody | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd"))  + "\Summary\Summary.html")
                Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('File Saved to ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd"))  + '\Summary\Summary.html">Summary</a>'))
            }
            $False {
                [String[]] $MainBody = Get-HTMLCode -Style Head
                $MainBody += "`t" + "`t" + '<TABLE id="SearchTable">'
                $MainBody += "`t" + "`t" + "`t" + '<h1><tr><th>Summary</th><th>Problem found</th></tr></h1>'
                $MainBody += "`t" + "`t" + "`t" + '<tr><td><a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString("yyyy-MM-dd") + '/Summary/All Disk Summary-index.html">All Disk Summary</a></td><td><center>' + $DiskErrors.ToString() + '</center></td></tr>'
                $MainBody += "`t" + "`t" + "`t" + '<tr><td><a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString("yyyy-MM-dd") + '/Summary/Perfmon Summary-index.html">Perfmon Summary</a></td><td><center>' + $PerfMonErrors.ToString() + '</center></td></tr>'
                $MainBody += "`t" + "`t" + "`t" + '<tr><td><a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString("yyyy-MM-dd") + '/Summary/Shadow Copy Summary-index.html">Shadow Copy Summary</a></td><td><center>' + $ShadowCopyErrors.ToString() + '</center></td></tr>'
                $MainBody += "`t" + "`t" + "`t" + '<tr><td><a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString("yyyy-MM-dd") + '/Summary/Unavailable Servers-index.html">Unavailable Servers</a></td><td><center>' + $UnavailableServers.ToString() + '</center></td></tr>'
                $MainBody += "`t" + "`t" + "`t" + '<tr><td><a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString("yyyy-MM-dd") + '/Summary/Events Summary-index.html">Servers with Events</a></td><td><center>' + $EventsSummary.ToString() + '</center></td></tr>'
                $MainBody += "`t" + "`t" + '</TABLE>'
                $MainBody += "`t" + "`t" + '<h2><a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/index.html">Dates</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + ($StartTime.ToString("yyyy-MM-dd")) + '/index.html">Home</a></h2>'
                $MainBody += "`t" + '</BODY>'
                $MainBody += '</HTML>'
                $MainBody | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd"))  + "\Summary\Summary.html")
                Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('File Saved to ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd"))  + "\index.html"))
                }
            }   
}
Function New-EventSummary {
        [String[]] $EventsHTML = Get-HTMLCode -Style Head
        $EventsHTML += "`t" + "`t" + '<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">'
        $EventsHTML += "`t" + "`t" + '<TABLE id="SearchTable">'
        $EventsHTML += "`t" + "`t" + "`t" + '<tr><th><h1>Events</h1></th><tr>'

        $EventFiles = Get-ChildItem -Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd"))) -Recurse | Where-Object {$_.name -like '*Errors *'}
        $EventFiles = $EventFiles | Sort-Object BaseName
        $ErrorAmount = 0
        ForEach ($EventFile in $EventFiles) {
            If (!($EventFile.Name -like '*0 *')) {
                $ErrorAmount ++
                Switch ($DebugState) {
                    $True {
                        $EventsHTML += "`t" + "`t" + "`t" + '<tr><td><a href="file:///' + $EventFile.FullName + '">' + $EventFile.BaseName + '</a></td></tr>'
                    }
                    $False {
                        $EventsHTML += "`t" + "`t" + "`t" + '<tr><td><a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' +  $GlobalConfig.Settings.Hosting.HTTPPort + '/' + (($EventFile.FullName.Split('\\'))[3..6] -join '/') + '">' + $EventFile.BaseName + '</a></td></tr>'
                    }
                }
            }
        }
        $EventsHTML += "`t" + "`t" + '</TABLE>'
        Switch ($DebugState) {
            $True {
                $EventsHTML += "`t" + "`t" + '<h2><a href="file:///' +  $ReportFolder + '\index.html">Dates</a> <a href="file:///' + $ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '/index.html">Home</a></h2>'
            }
            $False {
                $EventsHTML += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' +  $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/' + '/index.html">Home</a></h2>'
            }
        }
        
        $EventsHTML += "`t" + '</BODY>'
        $EventsHTML += '</HTML>'
        $EventsHTML | Out-file ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\Summary\Events Summary-index.html') -Force
        Return $ErrorAmount
}
Function Clear-TodaysReports {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet("Active", "Debug")]
        [String] $State
    )

    Switch ($State) {
        'Active' {
            $LogDirectory = $GlobalConfig.Settings.Sources.LogFolder + 'Active\' + $StartTime.Tostring("yyyy-MM-dd")
            $ReportFolder = $GlobalConfig.Settings.Sources.ReportFolder + $StartTime.Tostring("yyyy-MM-dd")
            $IndexFolder = $GlobalConfig.Settings.Sources.ReportFolder
        }
        'Debug' {
            $LogDirectory = $GlobalConfig.Settings.Sources.LogFolder + 'Debug\' + $StartTime.Tostring("yyyy-MM-dd")
            $ReportFolder = $GlobalConfig.Settings.Sources.DebugFolder + $StartTime.Tostring("yyyy-MM-dd")
            $IndexFolder = $GlobalConfig.Settings.Sources.DebugFolder
        }
    }
    $LogClearConfirmation = Read-Host ('Are you sure you want to delete everything in ' + $LogDirectory + '? (y/n) [N]')
    If ($LogClearConfirmation.ToLower() -eq 'y' -or $LogClearConfirmation.ToLower() -eq 'yes') { 
        Get-Childitem $LogDirectory | Remove-Item
    }
    
    $ReportClearConfirmation = Read-Host ('Are you sure you want to delete everything in ' + $ReportFolder + '? (y/n) [N]')
    If ($ReportClearConfirmation.ToLower() -eq 'y' -or $ReportClearConfirmation.ToLower() -eq 'yes') { 
        Get-ChildItem $ReportFolder -Recurse | Remove-Item -Recurse
    }
    notepad ($IndexFolder + '\index.html')
}
#endregion
$ServerScript = {
        Param(
                [Parameter(Mandatory=$True, Position=1)]
                [Object[]] $ServerItem, `
                [Parameter(Mandatory=$True, Position=2)]
                [XML] $GlobalConfig, `
                [Parameter(Mandatory=$True, Position=3)]
                [String] $ReportFolder, `
                [Parameter(Mandatory=$True, Position=4)]
                [Switch] $DebugState
        )

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
                        Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Exception: ' + $_.Exception + "`n" + 'Message: ' + $_.Message + "`n" + 'Line Number: ' + $_.InvocationInfo.ScriptLineNumber)
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
                        Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Exception: ' + $_.Exception + "`n" + 'Message: ' + $_.Message + "`n" + 'Line Number: ' + $_.InvocationInfo.ScriptLineNumber)
                        $HTMLVolumes = $null | ConvertTo-Html -Head $a
                }

                Switch ($DebugState) {
                    $True {
                        Return ($HTMLVolumes.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"),$ErrorAmount)
                    }
                    $False {
                        Return ($HTMLVolumes.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"),$ErrorAmount)
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
                    $StartEventTime = (Get-Date).AddDays(-$GlobalConfig.Settings.Alarms.AlarmDateRangeInDays)

                    If ($Level -gt 0) {
                            Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting logs from ' + $LogName + '. StartTime: ' + $StartEventTime + '. LogLevel: ' + $Level)
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
                            Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Gettings events from ' + $Logname + '. Start Time: ' + $StartEventTime + '. ID: ' + $ID)
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
                        Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Exception: ' + $_.Exception + "`n" + 'Message: ' + $_.Message + "`n" + 'Line Number: ' + $_.InvocationInfo.ScriptLineNumber)
                        $ReturnEvents = ($null | ConvertTo-Html -head $a).Replace('<body>',"`n" + "`t" + '<body>' + "`n" + "`t" + "`t" + '<h2>' + $_ + '</h2>')
                }
                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Returning events count: ' + $ErrorAmount.ToString())
                
                Switch ($DebugState) {
	                $True {
	                    Return (($ReturnEvents.Replace('<table>','<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">' + "`n" + '<table id="SearchTable">').Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n")), $ErrorAmount)
	                }
	                $False {
                        Return (($ReturnEvents.Replace('<table>','<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">' + "`n" + '<table id="SearchTable">').Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n")), $ErrorAmount)
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
                        Catch {
                                Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Exception: ' + $_.Exception + "`n" + 'Message: ' + $_.Message + "`n" + 'Line Number: ' + $_.InvocationInfo.ScriptLineNumber)
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
	                    Return (($DiskShadowsinHTML.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n")), $ErrorAmmount)
	                }
	                $False {
                        Return (($DiskShadowsinHTML.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n")), $ErrorAmmount)
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
                                If ($Line -like '*>Auto<*' -and $Line -like '*>Stopped<*') {
                                        $Reformat += $Line.Replace('<td>','<td><span style="background-color: red;">').Replace('</td>','</td></span>')
                                }
                                Else {
                                        $Reformat += $Line
                                }
                        }
                }
                Catch {
                        Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Exception: ' + $_.Exception + "`n" + 'Message: ' + $_.Message + "`n" + 'Line Number: ' + $_.InvocationInfo.ScriptLineNumber)
                        $Reformat = $null | ConvertTo-Html -Head $a
                }
                Switch ($DebugState) {
	                $True {
	                    Return ($Reformat.Replace('<table>','<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">' + "`n" + '<table id="SearchTable">').Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"))
	                }
	                $False {
                        Return ($Reformat.Replace('<table>','<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">' + "`n" + '<table id="SearchTable">').Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"))
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
                                                Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Exception: ' + $_.Exception + "`n" + 'Message: ' + $_.Message + "`n" + 'Line Number: ' + $_.InvocationInfo.ScriptLineNumber)
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
                        Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Exception: ' + $_.Exception + "`n" + 'Message: ' + $_.Message + "`n" + 'Line Number: ' + $_.InvocationInfo.ScriptLineNumber)
                        $ReturnShare = $null | ConvertTo-Html -head $a
                }
                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Shares found: ' + $FinalShareArray.Count.ToString())
                $ReturnShare = $FinalShareArray | ConvertTo-Html -Head $a
                
                Switch ($DebugState) {
	                $True {
                                Return ($ReturnShare.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"))
	                }
	                $False {
                                Return ($ReturnShare.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"))
	                }
                }
                
        }
        Function Get-Groups {
                Param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $Server
                )
                Try {
                    Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Group Information')
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
                    Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Groups members found: ' + $result.Count.ToString())
                    Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Flagging SIDs')
                    $HTMLResult = $result | ConvertTo-Html -Head $a
                    [String[]] $Reformat = @()
                    ForEach ($Line in $HTMLResult) {
                        If ($Line -like '*S-1-5-21*') {
                            $Reformat += $Line.Replace('<td>','<td><span style="background-color: red;">').Replace('</td>','</td></span>')
                        }
                        Else {
                            $Reformat += $Line
                        }
                    }
                }
                Catch {
                        Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Exception: ' + $_.Exception + "`n" + 'Message: ' + $_.Message + "`n" + 'Line Number: ' + $_.InvocationInfo.ScriptLineNumber)
                }
                
                Switch ($DebugState) {
	                $True {
	                        Return ($Reformat.Replace('<table>','<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">' + "`n" + '<table id="SearchTable">').Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"))
	                }
	                $False {
                            Return ($Reformat.Replace('<table>','<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">' + "`n" + '<table id="SearchTable">').Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"))
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
                                Return ($ReturnPerfMons.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"))
	                }
	                $False {
                                Return ($ReturnPerfMons.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"))
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
                Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Exception: ' + $_.Exception + "`n" + 'Message: ' + $_.Message + "`n" + 'Line Number: ' + $_.InvocationInfo.ScriptLineNumber)
            }
            $NICDetails = $NICDetails | Select-Object AdapterName, MACAddress, InterFaceIndex, IPAddress, IPSubnet, DefaultIPGateway, DNSServerSearchOrder 
            $NICDetails = $NICDetails | ConvertTo-Html -Head $a
            Switch ($DebugState) {
	                $True {
                                Return ($NICDetails.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"))
	                }
	                $False {
                                Return ($NICDetails.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"))
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
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Information retrieved from Win32_ComputerSystem')
                        
                        $BIOSProperties = @('SerialNumber','ReleaseDate')
                        $BIOS = Get-WmiObject Win32_BIOS -Property $BIOSProperties -Computername $Server -Authentication PacketIntegrity | Select-Object $BIOSProperties
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Information retrieved from Win32_BIOS')
            
                        $ProcessorProperties = @('Name')
                        [Object[]] $Processor = Get-WmiObject Win32_Processor -Property $ProcessorProperties -Computername $Server -Authentication PacketIntegrity | Select-Object $ProcessorProperties
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Information retrieved from Win32_Processor')
            
                        $OperatingSystemProperties = @('Caption','LastBootUpTime','InstallDate')
                        $OperatingSystem = Get-WmiObject Win32_OperatingSystem -Property $OperatingSystemProperties -Computername $Server -Authentication PacketIntegrity | Select-Object $OperatingSystemProperties
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Information retrieved from Win32_OperatingSystem')
            
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
                        Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Exception: ' + $_.Exception + "`n" + 'Message: ' + $_.Message + "`n" + 'Line Number: ' + $_.InvocationInfo.ScriptLineNumber)
                        $CompiledObject = $null | ConvertTo-Html -head $a
                }
                Switch ($DebugState) {
	                $True {
                                Return ($CompiledObject.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"))
	                }
	                $False {
                                Return ($CompiledObject.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"))
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
                        Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Exception: ' + $_.Exception + "`n" + 'Message: ' + $_.Message + "`n" + 'Line Number: ' + $_.InvocationInfo.ScriptLineNumber)
                        $Products = $null | ConvertTo-Html -Head $a
                }
                Switch ($DebugState) {
                        $True {
                                Return ($Products.Replace('<table>','<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">' + "`n" + '<table id="SearchTable">').Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"))
                        }
                        $False {
                                Return ($Products.Replace('<table>','<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">' + "`n" + '<table id="SearchTable">').Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"))
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
                                        $FixedLinks += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>'
                                }
                                $False {
                                        $FixedLinks += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>'
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
                        Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Exception: ' + $_.Exception + "`n" + 'Message: ' + $_.Message + "`n" + 'Line Number: ' + $_.InvocationInfo.ScriptLineNumber)
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
                        Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Exception: ' + $_.Exception + "`n" + 'Message: ' + $_.Message + "`n" + 'Line Number: ' + $_.InvocationInfo.ScriptLineNumber)
                        $Routes = $null | ConvertTo-Html -Head $a
                }
                Switch ($DebugState) {
                        $True {
                                Return ($Routes.Replace('<table>','<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">' + "`n" + '<table id="SearchTable">').Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"))
                        }
                        $False {
                                Return ($Routes.Replace('<table>','<input type="text" id="SearchInput" onkeyup="SearchFunction()" placeholder="Search for ..." title="Type in a name">' + "`n" + '<table id="SearchTable">').Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"))
                        }
                }

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
                                $a += "`t" + "`t" + '<link href="/Web/CSS/Style.css" rel="stylesheet" />'
                                $a += "`t" + "`t" + '<script src="/Web/JScript/Jscript.js"></script>'
                }
                Else {
                        [string[]] $a = "`t" + "`t" + '<link href="/Web/CSS/Style.css" rel="stylesheet" />'
                        $a += "`t" + "`t" + '<script src="/Web/JScript/Jscript.js"></script>'
                }
        
                Return $a
        }
        Function Get-LoggedOnUsers {
                Param (
                    [Parameter(Mandatory=$True, Position=1)]
                    [String] $Server
                )
        
                Try {
                        $Query = (query user /server:$Server).TrimStart()
                        $Results = $Query -split "\n" -replace '\s\s+', ';'
                        $LoggedOnUsers = @()
        
                        If ($Results.count -gt 0) {
                            For ($i = 1; $i -lt $Results.Count; $i ++) {
                                $User = $Results[$i] -split ";"
                                $LoggedOnUsers += ,(New-Object -TypeName PSObject -Property @{
                                    Username = $User[0]
                                    SessionName = $User[1]
                                    ID = $User[2]
                                    State = $User[3]
                                    IdleTime = $User[4]
                                    LogonTime = $User[5]
                                })
        
                            }
                            $UsersInHTML = $LoggedOnUsers | Select-Object Username, SessionName, ID, State, IdleTime, LogonTime | ConvertTo-Html -Head $a
                            Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Logged on Users found: ' + $LoggedOnUsers.Count.ToString())
                        }
                        Else {
                            $UsersInHTML = $null | ConvertTo-Html -Head $a
                        }
                       
                }
                Catch {
                        Write-Log -LogFile $MainLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ('Exception: ' + $_.Exception + "`n" + 'Message: ' + $_.Message + "`n" + 'Line Number: ' + $_.InvocationInfo.ScriptLineNumber)
                        $UsersInHTML = $null | ConvertTo-Html -Head $a
                }
        
                Switch ($DebugState) {
                    $True {
                        Return ($UsersInHTML.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"),$ErrorAmount)
                    }
                    $False {
                        Return ($UsersInHTML.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>' + "`n"),$ErrorAmount)
                    }
                }
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
                
                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Logged on Users')
                $UsersInHTML = Get-LoggedOnUsers -Server ($Server + '.' + $TestPortResults.Domain)
                $UsersInHTML | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Logged on Users.html')
                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Update information saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\' + $Server + '\' + $Server + ' Logged on Users.html'))
                
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
                                $UnavailableBody += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>'
	                }
	                $False {
                                $UnavailableBody += "`t" + "`t" + "`t" + '<tr><td><a href="http://' + $GlobalConfig.Settings.Hosting.LoggingServer + ':' + $GlobalConfig.Settings.Hosting.LoggingPort + '/Active/' + ($StartTime.ToString("yyyy-MM-dd")) +'/' + $LogFile + '" download>' + 'Log File: ' + $LogFile + '</a></tr></td>'
                                $UnavailableBody += "`t" + "`t" + '</TABLE>'
                                $UnavailableBody += "`t" + "`t" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/' + $StartTime.ToString('yyyy-MM-dd') + '/index.html">Home</a></h2>'
	                }
                }
                $UnavailableBody += "`t" + '</BODY>'
                $UnavailableBody += '</HTML>'
                
                If (!(Test-Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\AllDiskSummary'))) {
                        New-Item ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\AllDiskSummary') -Type Directory | Out-Null
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Created AllDiskSummary directory: '+ ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\Unavailable'))
                }
                If (!(Test-Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\PerfmonSummary'))) {
                        New-Item ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\PerfmonSummary') -Type Directory | Out-Null
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Created PerfmonSummary directory: '+ ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\Unavailable'))
                }
                If (!(Test-Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\ShadowCopySummary'))) {
                        New-Item ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\ShadowCopySummary') -Type Directory | Out-Null
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Created ShadowCopySummary directory: '+ ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\Unavailable'))
                }
                If (!(Test-Path ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\Unavailable'))) {
                        New-Item ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\Unavailable') -Type Directory | Out-Null
                        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Created Unavailable directory: '+ ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\Unavailable'))
                }

                $UnavailableBody | Out-File ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\Unavailable\' + $Server + ' Unavailable.html')
                Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Unavailable file saved to: ' + ($ReportFolder + ($StartTime.ToString("yyyy-MM-dd")) + '\'   + $User + '\Unavailable\' + $Server + ' Unavailable.html'))
        }
        Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Report Completed')
}

$DebugState = $False

$StartTime = Get-Date
[XML] $GlobalConfig = Get-Content 'C:\HealthCheck\Scripts\Config.xml'

Switch ($DebugState) {
        $True {
                If (!(Test-Path ($GlobalConfig.Settings.Sources.LogFolder + 'Debug\'))) {
                    New-Item ($GlobalConfig.Settings.Sources.LogFolder + 'Debug\') -ItemType Directory | Out-Null
                    New-Item ($GlobalConfig.Settings.Sources.LogFolder + 'Debug\' + $StartTime.Tostring("yyyy-MM-dd")) -ItemType Directory | Out-Null
                }
                Else {
                    If (!(Test-Path ($GlobalConfig.Settings.Sources.LogFolder + 'Debug\' + $StartTime.Tostring("yyyy-MM-dd")))) {
                            New-Item ($GlobalConfig.Settings.Sources.LogFolder + 'Debug\' + $StartTime.Tostring("yyyy-MM-dd")) -ItemType Directory | Out-Null
                    }
                }
                $MainLogFile = ($GlobalConfig.Settings.Sources.LogFolder + 'Debug\' + $StartTime.Tostring("yyyy-MM-dd") + '\Main_' + $StartTime.Tostring("yyyy-MM-dd_HH_mm") + '.log')
                
                $ReportFolder = $GlobalConfig.Settings.Sources.DebugFolder
                Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Loading serverlist: ' + $GlobalConfig.Settings.Sources.ServerListFolder + $GlobalConfig.Settings.Lists.DebugServerList)
                $ServerList = Import-CSV ($GlobalConfig.Settings.Sources.ServerListFolder + $GlobalConfig.Settings.Lists.DebugServerList) -Delimiter ";"
                Write-Log -LogFile $MainLogFile -Level Warning -Component $MyInvocation.MyCommand.Name -Message ('Debugging enabled. Debugging server list loaded with ' + $ServerList.Count.ToString() + ' servers')
        }
        $False {
                If (!(Test-Path ($GlobalConfig.Settings.Sources.LogFolder + 'Active\'))) {
                    New-Item ($GlobalConfig.Settings.Sources.LogFolder + 'Active\') -ItemType Directory | Out-Null
                    New-Item ($GlobalConfig.Settings.Sources.LogFolder + 'Active\' + $StartTime.Tostring("yyyy-MM-dd")) -ItemType Directory | Out-Null
                }
                Else {
                    If (!(Test-Path ($GlobalConfig.Settings.Sources.LogFolder + 'Active\' + $StartTime.Tostring("yyyy-MM-dd")))) {
                            New-Item ($GlobalConfig.Settings.Sources.LogFolder + 'Active\' + $StartTime.Tostring("yyyy-MM-dd")) -ItemType Directory | Out-Null
                    }
                }
                $MainLogFile = ($GlobalConfig.Settings.Sources.LogFolder + 'Active\' + $StartTime.Tostring("yyyy-MM-dd") + '\Main_' + $StartTime.Tostring("yyyy-MM-dd_HH_mm") + '.log')

                $ReportFolder = $GlobalConfig.Settings.Sources.ReportFolder
                Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Loading serverlist: ' + $GlobalConfig.Settings.Sources.ServerListFolder + $GlobalConfig.Settings.Lists.ServerList + ' and adding AD Servers')
                $ServerList = Get-ServerList
                Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Server list loaded with ' + $ServerList.Count.ToString() + ' servers')
        }
}

Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Starting Jobs')
Start-Jobs -PassTargetToScriptBlock Both -ScriptBlock $ServerScript -ScriptBlockArguments @($GlobalConfig, $ReportFolder, $DebugState) -Targets $ServerList -WaitTime $GlobalConfig.Settings.Multithreading.JobTimerinSeconds -MaximumJobs $GlobalConfig.Settings.Multithreading.MaximumThreads

ForEach ($User in ($Serverlist.Username | Select-Object -Unique)) {
        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Setting Build HTML for ' + $User)
        Set-BuildHTML -User $User
}

ForEach ($User in ($Serverlist.Username | Select-Object -Unique)) {
        Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Setting Errors for ' + $User)
        Set-Errors -User $User
}


Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Creating All Disk Summary Page')
$DiskErrors = New-AllSummary -Summary 'All Disk Summary'
Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Creating PerfMon Summary Page')
$PerfMonErrors = New-AllSummary -Summary 'Perfmon Summary'
Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Creating Shadow Copy Summary Page')
$ShadowCopyErrors = New-AllSummary -Summary 'Shadow Copy Summary'
Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Creating Unavailable servers Summary Page')
$UnavailableServers = New-AllSummary -Summary 'Unavailable Servers'
Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Creating Servers with Events Summary Page')
$EventsSummary = New-EventSummary -Summary 'Unavailable Servers'

Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Creating All Summary Index Page')
New-AllSummaryIndex -DiskErrors $DiskErrors -PerfMonErrors $PerfMonErrors -ShadowCopyErrors $ShadowCopyErrors -UnavailableServers $UnavailableServers -EventsSummary $EventsSummary

Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Creating Main Index')
New-MainIndex

Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Updating Date Index')
If (Test-Path ($ReportFolder + 'index.html')) {
        Update-DateIndex
}
Else {
        New-DateIndex
}

If ($DebugState -eq $False) { 
        #Send-Email -GlobalConfig $GlobalConfig -DiskErrors $DiskErrors -PerfMonErrors $PerfMonErrors -ShadowCopyErrors $ShadowCopyErrors -UnavailableServers $UnavailableServers -EventsSummary $EventsSummary
}

Write-Log -LogFile $MainLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Jobs completed. Total run time was '+ ((Get-Date) - $StartTime) -f "{0:HH:mm:ss}" +' seconds')
Write-Host ('Runtime was ' + ((Get-Date) - $StartTime) -f "{0:HH:mm:ss}" +' seconds')
