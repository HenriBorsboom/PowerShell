Function Write-Log {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $LogData, `
        [Parameter(Mandatory=$False, Position=1)]
        [String] $FilePath = ($env:TEMP + "\log.txt"))

    ("[" + '{0:dd-MM-yyyy HH:mm:ss}' -f (Get-Date) + "],") | Out-File $FilePath -Encoding ascii -Append -Force -NoClobber -NoNewline
    $LogData | Out-File $FilePath -Encoding ascii -Append -Force -NoClobber -NoNewline
    (" ") | Out-File $FilePath -Encoding ascii -Append -Force -NoClobber
}
Function Call-Log {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $FilePath = ($env:TEMP + "\log.txt"))
    
     notepad $FilePath
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

    $CurrentErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference ='Stop'
    Try {
        Write-Log -LogData @("Query-WMI,",, $NameSpace, ",", $Property, ",", $RemoteServer)
        $WMIResults = Get-WmiObject -Namespace $NameSpace -Class $Class -Property $Property -ComputerName $RemoteServer -ErrorAction Stop
    }
    Catch {
        Write-Log -LogData @("Query-WMI,", "Failure,", $_)
        Write-Host $_
    }
    Finally {
        If ($WMIResults -eq $null) { $WMIResults =  $False }
    }
    $ErrorActionPreference = $CurrentErrorActionPreference
    Return $WMIResults
}
Function GetNodesState {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $TargetCluster)
    $WMIResults = Query-WMI -NameSpace 'root\MSCluster' -Class 'MSCluster_Node' -Property @('Name','State') -RemoteServer $TargetCluster
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
            Write-Log -LogData @("GetMountedVHDs,", "Get-VM,", $Node, ",", $VMIDS)
            Write-Color -Text "Complete" -ForegroundColor Green
            Write-Color -Text "|- ", "Getting VM VHDs for all VMs on ", $Node, " - " -ForegroundColor DarkCyan, White, Yellow, White -NoNewLine
            $VMSVhds = Get-VHD -VMID $VMIDS.VMId -ComputerName $Node
            Write-Log -LogData @("GetMountedVHDs,","Get-VHD,", $Node, ",", $VMSVhds)
            If ($VMSVhds.Count -gt 0) { Write-Color -Text $VMSVhds.Count.ToString(), " Found on ", $Node -ForegroundColor Yellow, Green, Yellow }
            Else                      { Write-Color -Text "0 Found on ", $Node -ForegroundColor White, Yellow }
            ForEach ($VMVHD in $VMSVhds) { $AllVMSVHDs += ,($VMVHD) }
        }
        Catch { Write-Color -Text $Node, " is not hosting any VMs" -ForegroundColor Yellow, Red }
    }
    Write-Log -LogData @("GetMountedVHDs,", $AllVMSVHDs )
    Return $AllVMSVHDs
}
Function GetClusterVolumes {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $TargetCluster)
    $WMIResults = Query-WMI -NameSpace 'root\mscluster' -Class 'MSCluster_ClusterSharedVolume' -Property @('Name') -RemoteServer $TargetCluster
    Write-Log -LogData @("GetClusterVolumes,", $WMIResults )
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
        Write-Color -Text "|- ", "Scanning volume ", $Volume, " from ", $ClusterNode, " - " -ForegroundColor DarkCyan, White, Yellow, White, Yellow, White -NoNewLine
        $VHDFiles = Invoke-Command -ComputerName $ClusterNode -ArgumentList $Volume -ScriptBlock { Param ($Volume); Get-ChildItem -Path $Volume -Recurse | Where-Object { $_.Extension -like "*vhd*"} }
        Write-Log -LogData @( "GetCSVVHDs,", $Volume, ",", $ClusterNode, ",", $VHDFiles)
        ForEach ($VHD in $VHDFiles) {
            $VHDInfo += ,($VHD.FullName)
        }
        If ($VHDFiles.Count -gt 0) { Write-Color $VHDFiles.Count.ToString(), " Found" -ForegroundColor Yellow, White }
        Else                       { Write-Color -Text "0 Found " -ForegroundColor Red }
    }
    Write-Log -LogData @("GetCSVVHDs,", $VHDInfo )
    Return $VHDInfo
}
Function CompareVHDs {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $MountedVHDS, `
        [Parameter(Mandatory=$True, Position=2)]
        [String[]] $VHDFiles)

    $OrphanedVHDS = @()
    ForEach ($VHDFile in $VHDFiles) {
        If ($MountedVHDS.Path.Contains($VHDFile)) { 
            Write-Log -LogData @("CompareVHDs,", "MountedVHDs Contains $VHDFile", ",", $VHDFile )
        }
        Else {
            $OrphanedVHDS += ,(New-Object -TypeName PSObject -Property @{ 
                FileName = $VHDFile; 
                FileSize = $MountedVHDS.Item($MountedVHDS.Path.IndexOf($VHDFile).FileSize).FileSize 
            } )
            Write-Log -LogData @("CompareVHDs,", "MountedVHDs Does Not Contain $VHDFile", ",", $MountedVHDS.Item($MountedVHDS.Path.IndexOf($VHDFile).FileSize), ",", $MountedVHDS )
        }
    }
    Write-Log -LogData @("CompareVHDs,", ",", $OrphanedVHDS)
    Return $OrphanedVHDS
}
Function Get-OrphanedVHDs {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $ClusterNode)
    
    Write-Color -Text "Getting cluster name for node: ", $ClusterNode, " - " -ForegroundColor White, Yellow, White -NoNewLine
    $TargetCluster = GetClusterName -ClusterNode $ClusterNode
    Write-Log -LogData @("Get-OrphanedVHDs,", "GetClusterName,", ",", $ClusterNode, "," , $TargetCluster)
    Write-Color -Text "Complete" -ForegroundColor Green
    Write-Color -Text "Getting Nodes for cluster: ", $TargetCluster, " - " -ForegroundColor White, Yellow, White -NoNewLine
    $ClusterNodes = GetNodesState -ClusterNode $ClusterNode
    Write-Log -LogData @("Get-OrphanedVHDs,", "GetNodesState,", ",", $ClusterNode, "," , $ClusterNodes)
    Write-Color -Text "Complete ", $ClusterNodes.Count.ToString(), " - Nodes Found"  -ForegroundColor Green, Yellow, Green
    Write-Color -Text "Getting Mounted VHDs on ", $TargetCluster, " - " -ForegroundColor White, Yellow, White
    $MountedVHDS = GetMountedVHDs -Nodes $ClusterNodes
    Write-Log -LogData @("Get-OrphanedVHDs,", "GetMountedVHDs,", ",", $ClusterNode, "," , $MountedVHDS)
    Write-Color -Text "Getting Cluster Shared Volumes on ", $TargetCluster, " - " -ForegroundColor White, Yellow, White -NoNewLine
    $ClusterVolumes = GetClusterVolumes -ClusterNode $ClusterNode
    Write-Log -LogData @("Get-OrphanedVHDs,", "GetClusterVolumes,", ",", $ClusterNode, "," , $ClusterVolumes)
    Write-Color -Text $ClusterVolumes.Count.ToString(), " Found" -ForegroundColor Yellow, Green
    Write-Color -Text "Scanning CSV volumes for ", "*vhd*", " files - " -ForegroundColor White, Yellow, White
    $CSVVHDS = GetCSVVHDs -TargetVolumes $ClusterVolumes -ClusterNode $ClusterNode
    Write-Log -LogData @("Get-OrphanedVHDs,", "GetCSVVHDs,", ",", $ClusterVolumes, "," , $ClusterNode, ",", $CSVVHDS)
    Write-Color -Text "Comparing ", "VMID/VHD", " information with ", "VHD files", " found on CSV volumes - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine
    $OrphanedVHDs = CompareVHDs -MountedVHDS $MountedVHDS -VHDFiles $CSVVHDS
    Write-Log -LogData @("Get-OrphanedVHDs,", "CompareVHDs,", ",", $MountedVHDS, "," , $CSVVHDS, ",", $OrphanedVHDs)
    If ($OrphanedVHDs.Count -gt 1) { 
        Write-Color -Text $OrphanedVHDs.Count.ToString(), " Found" -ForegroundColor Red, Red
        $FormattedOutput = @()
        ForEach ($OrphanedVHD in $OrphanedVHDs) {
            Switch ($OrphanedVHD.FileSize) {
                0-1024 { 
                    $Size = ([Math]::Round(($OrphanedVHD.FileSize / 1024), 2).ToString() + " KB")
                }
                1025-1048576 { 
                    $Size = ([Math]::Round(($OrphanedVHD.FileSize / 1024 / 1024), 2).ToString() + " MB")
                }
                1048577-1073741824 { 
                    $Size = ([Math]::Round(($OrphanedVHD.FileSize / 1024 / 1024 / 1024), 2).ToString() + " GB")
                } # GB
                Default { 
                    $Size = $OrphanedVHD.FileSize
                }
            }
            Write-Log -LogData @("Get-OrphanedVHDs,", "OrphanedVHDs,", ",", $FileName, "," , $Size)
            Write-Color -Text "|- ", $OrphanedVHD.Filename, $Size -ForegroundColor DarkCyan, White, Red
        }
    }
    Else {
        Write-Color -Text "None Found" -ForegroundColor Green
    }
}
Function GetClusterName {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $ClusterNode)
    $WMIResults = Query-WMI -NameSpace 'root\MSCluster' -Class 'MSCluster_Cluster' -Property @('Name') -RemoteServer $ClusterNode
    Write-Log -LogData @("GetClusterName,", $WMIResults.Name)
    Return $WMIResults.Name
}

Clear-Host
Get-OrphanedVHDs -ClusterNode 'LEADVMHOST01'
