#Update Common Modules

#region Common Functions
Function Write-Color {
    Param(
        [Parameter(Mandatory=$False, Position = 1)]
        [String[]] $Text, `
        [Parameter(Mandatory=$False, Position = 2)]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory=$False, Position = 3)]
        [ConsoleColor[]] $BackgroundColor, `
        [Parameter(Mandatory=$False, Position = 4)]
        [Switch] $NoNewLine, `
        [Parameter(Mandatory=$False, Position = 5)]
        [Switch] $Complete, `
        [Parameter(Mandatory=$False, Position = 6)]
        [Switch] $SendToLog)

    $CurrentActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'

    If ($Text.Count -gt 0) {
        If ($BackgroundColor.Count -eq 0 -and $ForegroundColor.Count -eq 0) { $OperationMode = 'WriteHost' }
        ElseIf ($BackgroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -gt 0 -and $ForegroundColor.Count -eq 0) { $OperationMode = 'ResetBackground' }
        ElseIf ($ForegroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -gt 0 -and $BackgroundColor.Count -eq 0) { $OperationMode = 'ResetForeground' }
        ElseIf ($BackgroundColor.Count -ge $Text.Count -and $ForegroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -gt 0) { $OperationMode = 'ResetForegroundWithBackground' }
        ElseIf ($ForegroundColor.Count -ge $Text.Count -and $BackgroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -gt 0) { $OperationMode = 'ResetBackgroundWithForeground' }
        ElseIf ($BackgroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -gt 0) { $OperationMode = 'ResetColors' }
        ElseIf ($ForegroundColor.Count -ge $Text.Count -and $BackgroundColor.Count -ge $Text.Count) { $OperationMode = 'Normal' }
        ElseIf ($BackgroundColor.Count -ge $Text.Count -and $ForegroundColor.Count -eq 0) { $OperationMode = 'Background' }
        ElseIf ($ForegroundColor.Count -ge $Text.Count -and $BackgroundColor.Count -eq 0) { $OperationMode = 'Foreground' }
        Else { 
            Write-Host "Text Count: " $Text.Count
            Write-Host "Foreground Count: " $ForegroundColor.Count
            Write-Host "Background Count: " $BackgroundColor.Count
        }
    }
    ElseIf ($Complete -eq $True) {
        $OperationMode = 'Complete'
    }

    Switch ($OperationMode) {
        'Foreground' {
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
            }
        }
        'Background' {
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -BackgroundColor $BackgroundColor[$Index] -NoNewLine
            }
        }
        'WriteHost' {
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -NoNewLine
            }
        }
        'ResetForeground' {
            For ($ForegroundColorIndex = ($ForegroundColor.Count); $ForegroundColorIndex -lt $Text.Count; $ForegroundColorIndex++) {
                    $ForegroundColor += ,($ForegroundColor[0])
            }
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
            }
        }
        'ResetBackground' {
            For ($BackgroundColorIndex = ($BackgroundColor.Count); $BackgroundColorIndex -lt $Text.Count; $BackgroundColorIndex++) {
                    $BackgroundColor += ,($BackgroundColor[0])
            }
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -Background $BackgroundColor[$Index] -NoNewLine
            }
        }
        'ResetForegroundWithBackground' {
            For ($ForegroundColorIndex = ($ForegroundColor.Count); $ForegroundColorIndex -lt $Text.Count; $ForegroundColorIndex++) {
                    $ForegroundColor += ,($ForegroundColor[0])
            }
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -Background $BackgroundColor[$Index] -NoNewLine
            }
        }
        'ResetBackgroundWithForeground' {
            For ($BackgroundColorIndex = ($BackgroundColor.Count); $BackgroundColorIndex -lt $Text.Count; $BackgroundColorIndex++) {
                    $BackgroundColor += ,($BackgroundColor[0])
            }
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -Background $BackgroundColor[$Index] -NoNewLine
            }
        }
        'ResetColors' {
            For ($ForegroundColorIndex = ($ForegroundColor.Count); $ForegroundColorIndex -lt $Text.Count; $ForegroundColorIndex++) {
                    $ForegroundColor += ,($ForegroundColor[0])
            }
            For ($BackgroundColorIndex = ($BackgroundColor.Count); $BackgroundColorIndex -lt $Text.Count; $BackgroundColorIndex++) {
                    $BackgroundColor += ,($BackgroundColor[0])
            }
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -Background $BackgroundColor[$Index] -NoNewLine
            }
        }
        'Complete' {
            Write-Host "Complete" -ForegroundColor Green
        }
        'Normal' {
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -Background $BackgroundColor[$Index] -NoNewLine
            }
        }
        Default {
            Write-Host ("Unknown Issue: ")
            Write-Host ("Text Count: " + $Text.Count.ToString()) -NoNewline
            Write-Host ("Foreground Count: " + $ForegroundColor.Count.ToString()) -NoNewline
            Write-Host ("Background Count: " + $BackgroundColor.Count.ToString()) -NoNewline
            Throw
        }
    }
    If ($SendToLog -eq $True) { Write-Log -LogData @("Write-Color", "SendToLog Switch", $Text, $ForegroundColor.Count, $BackgroundColor.Count) }
    If ($NoNewLine -eq $False) { Write-Host }
    $ErrorActionPreference = $CurrentActionPreference
}
Function Write-Log {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $LogData, `
        [Parameter(Mandatory=$False, Position=1)]
        [String] $FilePath)

    If ($Global:LogFile -eq "") { $FilePath = $env:TEMP + "\log.txt" }
    Else { $FilePath = $Global:LogFile }
    (("[" + '{0:yyyy-MM-dd HH:mm:ss}' -f (Get-Date) + "]") + " - Start ---------------------------------------------------") | Out-File $FilePath -Encoding ascii -Append
    ForEach ($Data in $LogData) { $Data | Out-File $FilePath -Encoding ascii -Append }
    (("[" + '{0:yyyy-MM-dd HH:mm:ss}' -f (Get-Date) + "]") + " - End -----------------------------------------------------") | Out-File $FilePath -Encoding ascii -Append
}
Function Call-Log {
    If ($Global:LogFile -eq "") { $FilePath = ($env:TEMP + "\log.txt") }
    Else { $FilePath = $Global:LogFile }
    notepad $FilePath
}
Function Clear-Log {
    If ($Global:LogFile -eq "") { $FilePath = ($env:TEMP + "\log.txt") }
    Else { $FilePath = $Global:LogFile }
    If (Test-Path $FilePath) { Remove-Item $FilePath }
}
#endregion
Function GetNodesState {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $ClusterNode)
    $WMIResults = Query-WMI -NameSpace 'root\MSCluster' -Class 'MSCluster_Node' -Property @('Name','State') -RemoteServer $ClusterNode
    $ClusterNodes = @()
    ForEach ($Node in $WMIResults) {
        Switch ($Node.State) {
            "-1"    { $ClusterNodes += ,(New-Object -TypeName PSObject -Property @{ Name = $Node.Name; State = "State Unknown" }) }
            "0"     { $ClusterNodes += ,(New-Object -TypeName PSObject -Property @{ Name = $Node.Name; State = "Up" }) }
            "1"     { $ClusterNodes += ,(New-Object -TypeName PSObject -Property @{ Name = $Node.Name; State = "Down" }) }
            "2"     { $ClusterNodes += ,(New-Object -TypeName PSObject -Property @{ Name = $Node.Name; State = "Paused" }) }
            "3"     { $ClusterNodes += ,(New-Object -TypeName PSObject -Property @{ Name = $Node.Name; State = "Joining" }) }
            Default { $ClusterNodes += ,(New-Object -TypeName PSObject -Property @{ Name = $Node.Name; State = $NodeStatus }) }
        }
    }
    Write-Log -LogData @("GetNodesState,", $ClusterNodes)
    Return ($ClusterNodes | Select Name, State)
}
Function GetMountedVHDs {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $Nodes)

    $AllVMSVHDs = @()
    ForEach ($Node in $Nodes.Name) {
        Try {
            Write-Color -Text "|- ", "Getting VM IDs for all VMs on ", $Node, " - " -ForegroundColor DarkCyan, White, Yellow, White -NoNewLine -SendToLog
            $VMIDS = Get-VM –VMname * -Computername $Node | Select-Object VMId
            Write-Log -LogData @("GetMountedVHDs", "Get-VM", $Node, $VMIDS)
            Write-Color -Text "Getting VHDs - " -ForegroundColor White -NoNewLine -SendToLog
            $VMSVhds = Get-VHD -VMID $VMIDS.VMId -ComputerName $Node
            Write-Log -LogData @("GetMountedVHDs","Get-VHD", $Node, $VMSVhds)
            If ($VMSVhds.Count -gt 0) { Write-Color -Text $VMSVhds.Count.ToString(), " Found" -ForegroundColor Green, Green -SendToLog }
            Else                      { Write-Color -Text "0 Found on ", $Node -ForegroundColor Red, Red -SendToLog }
            ForEach ($VMVHD in $VMSVhds) { $AllVMSVHDs += ,($VMVHD) }
        }
        Catch { Write-Color -Text "0 Found" -ForegroundColor Red -SendToLog }
    }
    Write-Log -LogData @("GetMountedVHDs", $AllVMSVHDs )
    Return $AllVMSVHDs
}
Function GetClusterVolumes {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $ClusterNode)
    $WMIResults = Query-WMI -NameSpace 'root\mscluster' -Class 'MSCluster_ClusterSharedVolume' -Property @('Name') -RemoteServer $ClusterNode
    Write-Log -LogData @("GetClusterVolumes", $WMIResults )
    Return $WMIResults.Name
}
Function GetCSVVHDs {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String[]] $TargetVolumes, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $ClusterNode)
    
    $VHDInfo = @()
    ForEach ($Volume in $TargetVolumes) {
        Write-Color -Text "|- ", "Scanning volume(s) ", $Volume, " from ", $ClusterNode -ForegroundColor DarkCyan, White, Yellow, White, Yellow -SendToLog
        Write-Log -LogData @( "GetCSVVHDs", "Job Started", $Volume, $ClusterNode)
        Start-Job -ArgumentList @($ClusterNode, $Volume) -ScriptBlock { Param ($ClusterNode, $Volume); Invoke-Command -ComputerName $ClusterNode -ArgumentList $Volume -ScriptBlock { Param ($Volume); Get-ChildItem -Path $Volume -Recurse | Where-Object { $_.Extension -like "*vhd*"} } }
        Write-Log -LogData @( "GetCSVVHDs", "Job Started", $Volume, $ClusterNode)
    }
    $Counter = 0
    While (Get-Job -State Running) {
	    $ActiveJobCount = (Get-Job -State Running).Count
	    Write-Color -Text "|-- ", ("[" + ("{0:hh\:mm\:ss}" -f [TimeSpan]::FromSeconds($Counter)) + "]"), " - Waiting for scans (", $ActiveJobCount,") to complete (10s)" -ForegroundColor DarkCyan, Cyan, White, Yellow, White
	    $Counter = $Counter + 10
	    Start-Sleep -Seconds 10
    }
    Write-Log -LogData @( "GetCSVVHDs", "Jobs Completed", $Volume, $ClusterNode)
    $Jobs = Get-Job -State Completed -IncludeChildJob
    ForEach ($Job in $Jobs) {
        $VHDFiles = Get-Job -Id $Job.Id | Receive-Job
        ForEach ($VHD in $VHDFiles) {
            $VHDInfo += ,(New-Object -TypeName PSObject -ArgumentList @{FileSize = $VHD.Length; FileName = $VHD.FullName}) # $VHD.FullName)
        }
    }
    Write-Log -LogData @("GetCSVVHDs", $VHDInfo )
    Get-Job | Remove-Job
    Return $VHDInfo
}
Function CompareVHDs {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $MountedVHDS, `
        [Parameter(Mandatory=$True, Position=2)]
        [Object[]] $VHDFiles)

    $OrphanedVHDS = @()
    ForEach ($VHDFile in $VHDFiles) {
        If ($VHDFile.ToString() -like "*psremoting*") { }
        Else {
            If ($MountedVHDS.Path.Contains($VHDFile.FileName)) { 
                Write-Log -LogData @("CompareVHDs", "MountedVHDs HA VHD", $VHDFile.FileName, $VHDFile.FileSize )
            }
            Else {
                $OrphanedVHDS += ,(New-Object -TypeName PSObject -Property @{ 
                    FileName = $VHDFile.FileName; 
                    FileSize = $VHDFile.FileSize;
                } )
                Write-Log -LogData @("CompareVHDs", "MountedVHDs Non-HA VHD", $VHDFile.FileName, $VHDFile.FileSize )
            }
        }
    }
    Write-Log -LogData @("CompareVHDs", $OrphanedVHDS)
    Return $OrphanedVHDS
}
Function Get-OrphanedVHDs {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $ClusterNode)
    
    Write-Color -Text "Getting cluster name for node: ", $ClusterNode, " - " -ForegroundColor White, Yellow, White -NoNewLine -SendToLog
    $TargetCluster = GetClusterName -ClusterNode $ClusterNode
    If ($TargetCluster -eq $null) { Write-Color -Text "Unable to contact Cluster Node, unable to continue" -ForegroundColor Red ;Break }
    Write-Log -LogData @("Get-OrphanedVHDs", "GetClusterName", $ClusterNode, $TargetCluster)
    Write-Color -Text "Complete" -ForegroundColor Green -SendToLog
    Write-Color -Text "Getting Nodes for cluster: ", $TargetCluster, " - " -ForegroundColor White, Yellow, White -NoNewLine -SendToLog
    $ClusterNodes = GetNodesState -ClusterNode $ClusterNode
    Write-Log -LogData @("Get-OrphanedVHDs", "GetNodesState", $ClusterNode, $ClusterNodes)
    Write-Color -Text $ClusterNodes.Count.ToString(), " Nodes Found"  -ForegroundColor Green, Green -SendToLog
    Write-Color -Text "Getting Mounted VHDs on ", $TargetCluster -ForegroundColor White, Yellow -SendToLog
    $MountedVHDS = GetMountedVHDs -Nodes $ClusterNodes
    Write-Log -LogData @("Get-OrphanedVHDs", "GetMountedVHDs", $ClusterNode, $MountedVHDS)
    Write-Color -Text "Getting Cluster Shared Volumes on ", $TargetCluster, " - " -ForegroundColor White, Yellow, White -NoNewLine -SendToLog
    $ClusterVolumes = GetClusterVolumes -ClusterNode $ClusterNode
    Write-Log -LogData @("Get-OrphanedVHDs", "GetClusterVolumes", $ClusterNode, $ClusterVolumes)
    Write-Color -Text $ClusterVolumes.Count.ToString(), " Found" -ForegroundColor Green, Green -SendToLog
    Write-Color -Text "Scanning CSV volumes for ", "*vhd*", " files" -ForegroundColor White, Yellow, White -SendToLog
    $CSVVHDS = GetCSVVHDs -TargetVolumes $ClusterVolumes -ClusterNode $ClusterNode
    Write-Log -LogData @("Get-OrphanedVHDs", "GetCSVVHDs", $ClusterVolumes, $ClusterNode, $CSVVHDS)
    Write-Color -Text "Comparing ", "VMID/VHD", " information with ", "VHD files", " found on CSV volumes - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine -SendToLog
    $OrphanedVHDs = CompareVHDs -MountedVHDS $MountedVHDS -VHDFiles $CSVVHDS
    Write-Log -LogData @("Get-OrphanedVHDs", "CompareVHDs", $MountedVHDS, $CSVVHDS, $OrphanedVHDs)
    If ($OrphanedVHDs.Count -gt 1) { 
        Write-Color -Text $OrphanedVHDs.Count.ToString(), " Found" -ForegroundColor Red, Red -SendToLog
        $TotalWastedSpace = 0
        ForEach ($OrphanedVHD in $OrphanedVHDs) {
            $TotalWastedSpace = $TotalWastedSpace + $OrphanedVHD.FileSize
            If     ($OrphanedVHD.FileSize -lt 1024) { $Size = ([Math]::Round(($OrphanedVHD.FileSize), 2).ToString() + " B") }
            ElseIf ($OrphanedVHD.FileSize -gt 1025 -and $OrphanedVHD.FileSize -lt 1048575) { $Size = ([Math]::Round(($OrphanedVHD.FileSize / 1024 / 1024), 2).ToString() + " MB") }
            ElseIf ($OrphanedVHD.FileSize -gt 1048576 -and $OrphanedVHD.FileSize -lt 1073741824) { $Size = ([Math]::Round(($OrphanedVHD.FileSize / 1024 / 1024), 2).ToString() + " MB") }
            ElseIf ($OrphanedVHD.FileSize -gt 1073741824 -and $OrphanedVHD.FileSize -lt 1099511627776) { $Size = ([Math]::Round(($OrphanedVHD.FileSize / 1024 / 1024 / 1024), 2).ToString() + " GB") }
            Else { $Size = $OrphanedVHD.FileSize }
            Write-Log -LogData @("Get-OrphanedVHDs", "OrphanedVHDs", $OrphanedVHD.Filename, $Size)
            Write-Color -Text "|- ", $OrphanedVHD.Filename, " - ", $Size -ForegroundColor DarkCyan, White, White, Red -SendToLog
        }
        Write-Color -Text "Total Wasted Space identified: ", ([Math]::Round(($TotalWastedSpace / 1024 / 1024 / 1024), 2).ToString() + " GB") -ForegroundColor White, Yellow -SendToLog
        Write-Log -LogData @("Get-OrphanedVHDs", "TotalWastedSpace", $TotalWastedSpace)
    }
    Else {
        Write-Color -Text "None Found" -ForegroundColor Green -SendToLog
    }
}
Function GetClusterName {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $ClusterNode)
    Try {
        $WMIResults = Query-WMI -NameSpace 'root\MSCluster' -Class 'MSCluster_Cluster' -Property @('Name') -RemoteServer $ClusterNode
        Write-Log -LogData @("GetClusterName", $WMIResults)
    }
    Catch {
        Write-Log -LogData @("GetClusterName", "Failure", $_)
    }
    Return $WMIResults
}
$Global:LogFile = ($env:TEMP + "\log.txt")
Clear-Host
$ClusterNode = Read-Host "ClusterNode"
Get-OrphanedVHDs -ClusterNode $ClusterNode
Call-Log