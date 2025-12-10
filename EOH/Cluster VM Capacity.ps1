Param (
    [Parameter(Mandatory=$True)]
    [String] $Cluster)
Function Write-Color {
    <#
    .SYNOPSIS
	    Write Host with Simpler Color Management
    .DESCRIPTION
	    Write-Color gives you the same functionality as Write-Host but with simpler and quicker color management
    .EXAMPLE
	    Write-Color -Text 'Test 1 '
    .EXAMPLE
	    Write-Color -Text 'Test 1 ' -ForegroundColor Black
    .EXAMPLE
	    Write-Color -Text 'Test 1 ' -BackgroundColor Yellow
    .EXAMPLE
	    Write-Color -Text 'Test 1 ' -ForegroundColor Black -BackgroundColor Yellow
    .EXAMPLE
	    Write-Color -Text 'Test 1 ', 'Test 2 ' -ForegroundColor Yellow -BackgroundColor Black
    .EXAMPLE
	    Write-Color -Text 'Test 1 ', 'Test 2 ' -ForegroundColor Yellow, Green -BackgroundColor Black, Yellow
    .EXAMPLE
	    Write-Color -Complete
    .EXAMPLE
	    Write-Color -Text 'Test 1 ', 'Test 2 ' -ForegroundColor Yellow, Green -BackgroundColor Black, Yellow -NoNewline
    .EXAMPLE
	    Write-Color -Complete -NoNewline
    .INPUTS
	    [String[]]
    .PARAMETER Text
	    This is the collection of text that needs to be written to the host
    .INPUTS
	    [ConsoleColor[]]
    .PARAMETER ForegroundColor
	    This is the collection of Foreground colors that needs to be applied to the text
	    If there is more text in the collection and only 1 Foreground color is specified
	    then the first foreground color will be applied to all text
    .INPUTS
	    [ConsoleColor[]]
    .PARAMETER BackgroundColor
	    This is the collection of Background colors that needs to be applied to the text
	    If there is more text in the collection and only 1 Background color is specified
	    then the first Background color will be applied to all text
    .INPUTS
	    [Switch]
    .PARAMETER NoNewLine
	    This is to specify if you want to terminate the line or not
    .INPUTS
	    [Switch]
    .PARAMETER Complete
	    This is will write to the host "Complete" with the Foreground color set to Green
    .INPUTS
	    [Int64]
    .PARAMETER IndexCounter
	    This is the counter for the current item
    .INPUTS
	    [Int64]
    .PARAMETER TotalCounter
	    This is the total number of items that needs to be processed. This is needed
        to format the counter properly
    .Notes
        NAME:  Write-Color
        AUTHOR: Henri Borsboom
        LASTEDIT: 30/08/2017
        KEYWORDS: Write-Host, Console Output, Color
    .Link
        https://www.linkedin.com/pulse/powershell-<>-henri-borsboom
        #Requires -Version 2.0
    #>
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
Function VM-Resources {
    Write-Color -Text 'Getting VMs on ', $Cluster, ' - ' -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Text -NoNewLine
    $ClusterResources = Get-ClusterResource -Cluster $Cluster
    $ClusterVMs = $ClusterResources | Where-Object {$_.ResourceType -eq 'Virtual Machine'}
    Write-Color -Text $ClusterVMs.Count, ' Found' -ForegroundColor $MyColors.Value, $MyColors.Value
    $ReturnDetails = @()
    For ($i =0; $i -lt $ClusterVMs.Count; $i ++) {
        Write-Color -IndexCounter $i -TotalCounter $ClusterVMs.Count -Text 'Gathering VM Details for ', $ClusterVMs[$i].OwnerGroup, ' - ' -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Text -NoNewLine
        $VM = Get-VM -Name $ClusterVMs[$i].OwnerGroup -ComputerName $ClusterVMs[$i].OwnerNode
        $VHDDisks = Get-VHD -VMId $VM.VMId -ComputerName $ClusterVMs[$i].OwnerNode
        $TotalFileSize = 0
        $TotalVHDSize = 0
        For ($y = 0; $y -lt $VHDDisks.Count; $y ++) {
               $TotalFileSize += $VHDDisks[$y].FileSize
               $TotalVHDSize += $VHDDisks[$y].Size
        }
        $VMDetails = New-Object -TypeName PSObject -Property @{
            Node = $ClusterVMs[$i].OwnerNode
            VMName = $ClusterVMs[$i].OwnerGroup
            CPU = $VM.ProcessorCount
            RAM = $VM.MemoryStartup
            TotalFileSize = [Math]::Round($TotalFileSize / 1024 / 1024 /1024, 2)
            TotalVHDSize = [Math]::Round($TotalVHDSize / 1024 / 1024 /1024, 2)
        }
        $ReturnDetails += $VMDetails
        Write-Color -Complete
    }
    Return $ReturnDetails
}
Function Cluster-Resources {
    Write-Color -Text 'Getting Nodes for ', $Cluster, ' - ' -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Text -NoNewLine
    $ClusterNodes = Get-ClusterNode -Cluster $Cluster
    $ClusterDetails = @()
    Write-Color -Text $ClusterNodes.Count, ' Found' -ForegroundColor $MyColors.Value, $MyColors.Value
    For ($i = 0; $i -lt $ClusterNodes.Count; $i ++) {
        Write-Color -IndexCounter $i -TotalCounter $ClusterNodes.Count -Text 'Getting Host Details for ', $ClusterNodes[$i].Name, ' - ' -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Text -NoNewLine
        $HostPhysicalMemory = (Get-WmiObject -Class Win32_ComputerSystem -Property TotalPhysicalMemory -ComputerName $ClusterNodes[$i].Name).TotalPhysicalMemory
        $HostCPU = (Get-WmiObject -Class Win32_Processor -Property NumberOfLogicalProcessors -ComputerName $ClusterNodes[$i].Name | Measure-Object -Sum NumberOfLogicalProcessors).Sum
        $NodeDetail = New-Object -TypeName PSObject -Property @{
            NodeName = $ClusterNodes[$i].Name
            CPU      = $HostCPU
            RAM   = $HostPhysicalMemory
        }
        $ClusterDetails += $NodeDetail
        Write-Color -Complete
    }
    Return $ClusterDetails
}
Function Get-CSVDetails {
    Param(
        [Parameter(Mandatory=$true)] 
        [String] $Cluster)

    $Objs = @()
    Write-Color -Text 'Getting CSV details for ', $Cluster, ' - ' -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Text -NoNewLine
    $CSVs = Get-ClusterSharedVolume -Cluster $Cluster
    Write-Color -Text $CSVs.Count, ' Found' -ForegroundColor $MyColors.Value, $MyColors.Value
    For ($i = 0; $i -lt $CSVs.Count; $i ++) {
    #ForEach ($CSV in $CSVs[$i]) {
       Write-Color -IndexCounter $i -TotalCounter $CSVs.Count -Text 'Gathering CSV details for ', $CSVs[$i].Name, ' - ' -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Text -NoNewLine
       $CSVInfos = $CSVs[$i] | Select -Property Name -ExpandProperty SharedVolumeInfo
       ForEach ($CSVInfo in $CSVInfos) {
          $Obj = New-Object PSObject -Property @{
             Name        = $CSVs[$i].Name
             Path        = $CSVInfo.FriendlyVolumeName
             Size        = [Math]::Round($CSVInfo.Partition.Size / 1024 / 1024 / 1024, 2)
             FreeSpace   = [Math]::Round($CSVInfo.Partition.FreeSpace / 1024 / 1024 / 1024, 2)
             UsedSpace   = [Math]::Round($CSVInfo.Partition.UsedSpace / 1024 / 1024 / 1024, 2)
             PercentFree = [Math]::Round($CSVInfo.Partition.PercentFree,2)
          }
          $Objs += $Obj
       }
       Write-Color -Complete
    }

    If ($Objs -eq $null) {
        $Results = Get-WmiObject -Query "select caption,freespace from Win32_LogicalDisk" -ComputerName $Cluster
        Return $Results
    }
    Else {
        Return $Objs
    }
}   
Function aa {
    #Get CSV volumes
        Write-Color -Text 'Getting CSV details for ', $Cluster, ' - ' -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Text -NoNewLine
    $CSVs = Get-ClusterSharedVolume -Cluster $Cluster
    Write-Color -Text $CSVs.Count, ' Found' -ForegroundColor $MyColors.Value, $MyColors.Value
    #Get VMs on Volume
    #Get VMID from VM
    #Get Disk Thin/Thick Size
    


    Write-Color -Text 'Getting VMs on ', $Cluster, ' - ' -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Text -NoNewLine
    $ClusterResources = Get-ClusterResource -Cluster $Cluster
    $ClusterVMs = $ClusterResources | Where-Object {$_.ResourceType -eq 'Virtual Machine'}
    Write-Color -Text $ClusterVMs.Count, ' Found' -ForegroundColor $MyColors.Value, $MyColors.Value
    $ReturnDetails = @()
}

Clear-Host
#region Colors
$MyColors = @{}
$MyColors.Add("Text",    ([ConsoleColor]::White))
$MyColors.Add("Value",   ([ConsoleColor]::Cyan))
$MyColors.Add("Warning", ([ConsoleColor]::Yellow))
$MyColors.Add("Error",   ([ConsoleColor]::Red))
#endregion

$ClusterVMs         = VM-Resources;                     $ClusterVMs | Select Node, VMName, CPU, RAM, TotalFileSize, TotalVHDSize | Format-Table -AutoSize
$ClusterHosts       = Cluster-Resources;                $ClusterHosts | Select NodeName, CPU, RAM | Format-Table -AutoSize
$ClusterHostStorage = Get-CSVDetails -Cluster $Cluster; $ClusterHostStorage | Select Name, Path, Size, FreeSpace, UsedSpace, PercentFree | Format-Table -AutoSize

#VM Details
$ClusterVMCPUCount = ($ClusterVMs | Measure-Object -Sum CPU).Sum
$ClusterVMRAMCount = ($ClusterVMs | Measure-Object -Sum RAM).Sum
$ClusterFileSize   = ($ClusterVMs | Measure-Object -Sum TotalFileSize).Sum
$ClusterVHDSize    = ($ClusterVMs | Measure-Object -Sum TotalVHDSize).Sum

#Host
$ClusterHostCPUCount = ($ClusterHosts | Measure-Object -Sum CPU).Sum
$ClusterHostRAMCount = ($ClusterHosts | Measure-Object -Sum RAM).Sum

$ClusterStorageTotal = ($ClusterHostStorage | Measure-Object -Sum Size).Sum
$ClusterStorageFree  = ($ClusterHostStorage | Measure-Object -Sum FreeSpace).Sum

Write-Color -Text '------ ', 'VM Details' -ForegroundColor $MyColors.Warning, $MyColors.Value
Write-Color -Text 'Total VM CPU Count:   ', $ClusterVMCPUCount.ToString() -ForegroundColor $MyColors.Text, $MyColors.Value
Write-Color -Text 'Total VM RAM Count:   ', ([Math]::Round($ClusterVMRAMCount / 1024 / 1024 / 1024, 2).ToString()), ' GB' -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Value
Write-Color -Text 'Total VM Thin VHD:    ', $ClusterFileSize.ToString(), ' GB' -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Value
Write-Color -Text 'Total VM Thick VHD:   ', $ClusterVHDSize, ' GB' -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Value
Write-Host ""

Write-Color -Text '------ ', 'Host Details' -ForegroundColor $MyColors.Warning, $MyColors.Value
Write-Color -Text 'Total Host CPU Count:   ', $ClusterHostCPUCount.ToString() -ForegroundColor $MyColors.Text, $MyColors.Value
Write-Color -Text 'Total Host RAM Count:   ', ([Math]::Round($ClusterHostRAMCount / 1024 / 1024 / 1024, 2).ToString()), ' GB' -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Value
Write-Host ""

Write-Color -Text '------ ', 'Storage Details' -ForegroundColor $MyColors.Warning, $MyColors.Value
Write-Color -Text 'Total Storage Size:    ', $ClusterStorageTotal.ToString(), ' GB' -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Value
Write-Color -Text 'Total Storage Free:    ', $ClusterStorageFree.ToString(), ' GB' -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Value
