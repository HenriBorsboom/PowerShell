#Update Common Modules

#region Common Functions
Function Write-Log {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $LogData, `
        [Parameter(Mandatory=$False, Position=1)]
        [String] $FilePath = ($env:TEMP + "\log.txt"))
    (("[" + '{0:yyyy-MM-dd HH:mm:ss}' -f (Get-Date) + "]") + " - Start ---------------------------------------------------") | Out-File $FilePath -Encoding ascii -Append
    ForEach ($Data in $LogData) { $Data | Out-File $FilePath -Encoding ascii -Append }
    (("[" + '{0:yyyy-MM-dd HH:mm:ss}' -f (Get-Date) + "]") + " - End -----------------------------------------------------") | Out-File $FilePath -Encoding ascii -Append
}
Function Call-Log {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $FilePath = ($env:TEMP + "\log.txt"))
    
     notepad $FilePath
}
Function Clear-Log {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $FilePath = ($env:TEMP + "\log.txt"))
    
     If (Test-Path $FilePath) { Remove-Item $FilePath }
}
Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)

    $ErrorActionPreference = "Stop"
    Try {
        If ($Text.Count -ne $ForegroundColor.Count) {
            Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $ForegroundColor.Count.ToString()) -ForegroundColor Red
            Throw
        }
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch { 
        Write-Host "Text Count:  " $Text.Count
        Write-Host "Color Count: " $ForegroundColor.Count
        Write-Host $_
    }
}
Function Query-WMI {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $RemoteServer, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $NameSpace, `
        [Parameter(Mandatory=$True, Position=3, ParameterSetName="Properties")]
        [String] $Class, `
        [Parameter(Mandatory=$True, Position=4, ParameterSetName="Properties")]
        [String[]] $Property, `
        [Parameter(Mandatory=$True, Position=2, ParameterSetName="Query")]
        [String] $Query)

    Try {
        $WMIResults = Get-WmiObject -Namespace $NameSpace -Class $Class -Property $Property -ComputerName $RemoteServer -ErrorAction Stop
        Write-Log -LogData @("Query-WMI", $NameSpace, $Property, $RemoteServer, $WMIResults)
    }
    Catch {
        Write-Log -LogData @("Query-WMI", "Failure", $_)
        Write-Color -Text $_ -ForegroundColor Red
    }
    Return $WMIResults
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
            Write-Color -Text "|- ", "Getting VM IDs for all VMs on ", $Node, " - " -ForegroundColor DarkCyan, White, Yellow, White -NoNewLine
            $VMIDS = Get-VM –VMname * -Computername $Node | Select-Object VMId
            Write-Log -LogData @("GetMountedVHDs", "Get-VM", $Node, $VMIDS)
            Write-Color -Text "Getting VHDs - " -ForegroundColor White -NoNewLine
            $VMSVhds = Get-VHD -VMID $VMIDS.VMId -ComputerName $Node
            Write-Log -LogData @("GetMountedVHDs","Get-VHD", $Node, $VMSVhds)
            If ($VMSVhds.Count -gt 0) { Write-Color -Text $VMSVhds.Count.ToString(), " Found" -ForegroundColor Green, Green}
            Else                      { Write-Color -Text "0 Found on ", $Node -ForegroundColor Red, Red }
            ForEach ($VMVHD in $VMSVhds) { $AllVMSVHDs += ,($VMVHD) }
        }
        Catch { Write-Color -Text "0 Found" -ForegroundColor Red }
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
        Write-Color -Text "|- ", "Scanning volume(s) ", $Volume, " from ", $ClusterNode -ForegroundColor DarkCyan, White, Yellow, White, Yellow
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
        #If ($VHDFiles.Count -gt 0) { 
        #    Write-Color "|- ", $VHDFiles.Count.ToString(), " Found" -ForegroundColor DarkCyan, Yellow, White 
        #}
        #Else { 
        #    Write-Color -Text "0 Found " -ForegroundColor Red 
        #}
        ForEach ($VHD in $VHDFiles) {
            $VHDInfo += ,(New-Object -TypeName PSObject -ArgumentList @{FileSize = $VHD.Length; FileName = $VHD.FullName}) # $VHD.FullName)
        }
        #Remove-Job -Job $Job
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
    
    Write-Color -Text "Getting cluster name for node: ", $ClusterNode, " - " -ForegroundColor White, Yellow, White -NoNewLine
    $TargetCluster = GetClusterName -ClusterNode $ClusterNode
    If ($TargetCluster -eq $null) { Write-Color -Text "Unable to contact Cluster Node, unable to continue" -ForegroundColor Red ;Break }
    Write-Log -LogData @("Get-OrphanedVHDs", "GetClusterName", $ClusterNode, $TargetCluster)
    Write-Color -Text "Complete" -ForegroundColor Green
    Write-Color -Text "Getting Nodes for cluster: ", $TargetCluster, " - " -ForegroundColor White, Yellow, White -NoNewLine
    $ClusterNodes = GetNodesState -ClusterNode $ClusterNode
    Write-Log -LogData @("Get-OrphanedVHDs", "GetNodesState", $ClusterNode, $ClusterNodes)
    Write-Color -Text $ClusterNodes.Count.ToString(), " Nodes Found"  -ForegroundColor Green, Green
    Write-Color -Text "Getting Mounted VHDs on ", $TargetCluster -ForegroundColor White, Yellow
    $MountedVHDS = GetMountedVHDs -Nodes $ClusterNodes
    Write-Log -LogData @("Get-OrphanedVHDs", "GetMountedVHDs", $ClusterNode, $MountedVHDS)
    Write-Color -Text "Getting Cluster Shared Volumes on ", $TargetCluster, " - " -ForegroundColor White, Yellow, White -NoNewLine
    $ClusterVolumes = GetClusterVolumes -ClusterNode $ClusterNode
    Write-Log -LogData @("Get-OrphanedVHDs", "GetClusterVolumes", $ClusterNode, $ClusterVolumes)
    Write-Color -Text $ClusterVolumes.Count.ToString(), " Found" -ForegroundColor Green, Green
    Write-Color -Text "Scanning CSV volumes for ", "*vhd*", " files" -ForegroundColor White, Yellow, White
    $CSVVHDS = GetCSVVHDs -TargetVolumes $ClusterVolumes -ClusterNode $ClusterNode
    Write-Log -LogData @("Get-OrphanedVHDs", "GetCSVVHDs", $ClusterVolumes, $ClusterNode, $CSVVHDS)
    Write-Color -Text "Comparing ", "VMID/VHD", " information with ", "VHD files", " found on CSV volumes - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine
    $OrphanedVHDs = CompareVHDs -MountedVHDS $MountedVHDS -VHDFiles $CSVVHDS
    Write-Log -LogData @("Get-OrphanedVHDs", "CompareVHDs", $MountedVHDS, $CSVVHDS, $OrphanedVHDs)
    If ($OrphanedVHDs.Count -gt 1) { 
        Write-Color -Text $OrphanedVHDs.Count.ToString(), " Found" -ForegroundColor Red, Red
        $TotalWastedSpace = 0
        ForEach ($OrphanedVHD in $OrphanedVHDs) {
            $TotalWastedSpace = $TotalWastedSpace + $OrphanedVHD.FileSize
            If     ($OrphanedVHD.FileSize -lt 1024) { $Size = ([Math]::Round(($OrphanedVHD.FileSize), 2).ToString() + " B") }
            ElseIf ($OrphanedVHD.FileSize -gt 1025 -and $OrphanedVHD.FileSize -lt 1048575) { $Size = ([Math]::Round(($OrphanedVHD.FileSize / 1024 / 1024), 2).ToString() + " MB") }
            ElseIf ($OrphanedVHD.FileSize -gt 1048576 -and $OrphanedVHD.FileSize -lt 1073741824) { $Size = ([Math]::Round(($OrphanedVHD.FileSize / 1024 / 1024), 2).ToString() + " MB") }
            ElseIf ($OrphanedVHD.FileSize -gt 1073741824 -and $OrphanedVHD.FileSize -lt 1099511627776) { $Size = ([Math]::Round(($OrphanedVHD.FileSize / 1024 / 1024 / 1024), 2).ToString() + " GB") }
            Else { $Size = $OrphanedVHD.FileSize }
            Write-Log -LogData @("Get-OrphanedVHDs", "OrphanedVHDs", $OrphanedVHD.Filename, $Size)
            Write-Color -Text "|- ", $OrphanedVHD.Filename, " - ", $Size -ForegroundColor DarkCyan, White, White, Red
        }
        Write-Color -Text "Total Wasted Space identified: ", ([Math]::Round(($TotalWastedSpace / 1024 / 1024 / 1024), 2).ToString() + " GB") -ForegroundColor White, Yellow
        Write-Log -LogData @("Get-OrphanedVHDs", "TotalWastedSpace", $TotalWastedSpace)
    }
    Else {
        Write-Color -Text "None Found" -ForegroundColor Green
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
    Return $WMIResults.Name
}
$Global:LogFile = ($env:TEMP + "\log.txt")
Clear-Host
$ClusterNode = Read-Host "ClusterNode"
Get-OrphanedVHDs -ClusterNode $ClusterNode
#Call-Log
