Function DiskSizes {
<#
Param (
    [Parameter(Mandatory=$True, Position=1)]
    [String] $Computer, `
    [Parameter(Mandatory=$false, Position=1)]
    [Switch] $Raw)
#>
Function Test-Online {
    Param (
        [Parameter(Mandatory=$True,  Position=1)]
        [String] $Computer)

    If (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
        Return $True
    }
    Else {
        Return $False
    }
}
Function Get-DiskSize {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Computer, `
        [Parameter(Mandatory=$false, Position=1)]
        [Switch] $Raw)

    If (Test-Online -Computer $Computer) {
        $WMIProperties = @(
            'Name'
            'Size'
            'FreeSpace')
        $FormattedProperties = @(
            'Computer'
            'Name'
            'Size'
            'Free Space'
            'Free Space %')
        $WMIQuery = "SELECT Name, Size, FreeSpace FROM Win32_LogicalDisk WHERE DriveType = 3"
        $Results = Get-WmiObject -Query $WMIQuery -ComputerName $Computer
        
        Switch ($Raw) {
            $False  {
                $FormattedResults = @()
                ForEach ($Volume in $Results) {
                    $FormattedResult = New-Object -TypeName PSObject -Property @{
                        'Computer'     = $Computer
                        'Name'         = $Volume.Name
                        'Size'         = ([string]::Format( "{0:N2}", ($Volume.Size / 1024 / 1024)) + " GB")
                        'Free Space'   = ([string]::Format( "{0:N2}", ($Volume.FreeSpace / 1024 / 1024)) + " GB")
                        'Free Space %' = ([string]::Format( "{0:N1}", ($Volume.FreeSpace / $Volume.Size * 100)) + "%")
                    }
                    $FormattedResults += ,($FormattedResult)
                }
                #$FormattedResults | Select $FormattedProperties
                Return $FormattedResults
            }
            $True  {
                $Results | Select $WMIProperties
            }
        }
    }
    Else {
        Write-Host ($Computer + " is offline") -ForegroundColor Red
    }
}

Clear-Host
$ClusterNodes = @(
    'SYSJHBHV1'
    '192.168.1.151'
    'SYSJHBHV3'
    'SYSJHBHV4')

$FormattedProperties = @(
    'Computer'
    'Name'
    'Size'
    'Free Space'
    'Free Space %')

$TotalDisks = @()
ForEach ($Server in $ClusterNodes) {
    Write-Host "Getting Disk Sizes from $Server - " -NoNewline
    $Disks = Get-DiskSize -Computer $Server
    Write-Host "Complete - " -NoNewline
    Write-Host "Adding disks to report - " -NoNewline
    ForEach ($Disk in $Disks) {
        $This_Disk = New-Object -TypeName PSObject -Property @{
            'Computer'     = $Disk.'Computer'
            'Name'         = $Disk.'Name'
            'Size'         = $Disk.'Size'
            'Free Space'   = $Disk.'Free Space'
            'Free Space %' = $Disk.'Free Space %'
        }
        $TotalDisks += ,($This_Disk)
    }
    Write-Host "Complete"
}
$TotalDisks | Select $FormattedProperties | Format-Table -AutoSize
        
}
Function VHDLength {
Clear-Host

$DeleteVHDs = @(
"\\SYSJHBHV1\C$\ClusterStorage\Volume3\Absalom\Absalom.vhd"
"\\SYSJHBHV1\C$\ClusterStorage\Volume5\SYSJHBSCDB01Temp.vhdx")

$VHDInfo = @()
$TotalSize = 0
ForEach ($VHD in $DeleteVHDs) {
    $VHDSize = [Math]::Round(((LS $VHD).Length / 1024 /1024 /1024), 2)
    $TotalSize += $VHDSize
    $VHDInfo += ,(New-Object -TypeName PSObject -Property @{ VHD = $VHD; Size = $VHDSize})
}

$VHDInfo
Write-Host
Write-Host ("Total Size: " + $TotalSize.ToString() + " GB")
}
Function VHD-Details {
Clear-Host

$VHDs = @(
"C:/ClusterStorage/Volume2/SHAREPOINT2013/SHAREPOINT2013.VHD",
"C:/ClusterStorage/Volume2/SYSJHBDEV/SYSJHBDEV.vhd",
"C:/ClusterStorage/Volume2/Syspro-CMS/Syspro-CMS.vhd",
"C:/ClusterStorage/Volume2/syspro-develop/U_2013-08-17T173508.vhd",
"C:/ClusterStorage/Volume2/TMG Back Firewall/TMG Back Firewall.vhd",
"C:/ClusterStorage/Volume3/Certification/Certification.vhd",
"C:/ClusterStorage/Volume3/SYSJHBACC/SYSJHBACC.vhdx",
"C:/ClusterStorage/Volume3/SYSJHBACC/SYSJHBACC-Disk2.vhd",
"C:/ClusterStorage/volume3/sysjhbacc/SYSJHBACC-Disk2.vhdx",
"C:/ClusterStorage/Volume3/SYSJHBERRTRK/SYSJHBERRTRK-Disk2.vhdx",
"C:/ClusterStorage/Volume3/SYSJHBERRTRK/Virtual Hard Disks/SYSJHBERRTRK.vhdx",
"C:/ClusterStorage/Volume3/SYSJHBLYNC/SYSJHBLYNC.vhdx",
"C:/ClusterStorage/volume3/sysjhblync/SYSJHBLYNC-Disk2.vhdx",
"C:/ClusterStorage/Volume3/SYSJHBWA/Virtual Hard Disks/SYSJHBWA.vhdx",
"C:/ClusterStorage/Volume3/SYSPRO-DCVM/SYSPRO-DCVM.vhd",
"C:/ClusterStorage/Volume5/SYSJHBMAIL/SYSJHBMAIL-Disk2.vhdx",
"C:/ClusterStorage/Volume5/SYSJHBMAIL/SYSJHBMAIL-F.vhdx",
"C:/ClusterStorage/Volume5/SYSJHBSCOM01/SYSJHBSCOM01.vhdx",
"C:/ClusterStorage/Volume5/SYSJHBSQLSP/SYSJHBSQLSP2.VHD",
"C:/ClusterStorage/Volume5/SYSPRO-ERRTRK/SYSPRO-ERRTRK-1.VHD",
"C:/ClusterStorage/Volume6/Stage-New/second-drive_EE65F7F7-6F0E-41EA-953D-F0502BE98268.avhd",
"C:/ClusterStorage/Volume6/Stage-New/STAGE-OS_3C751701-D577-46EB-BB58-6B6FD0DB6EEA.avhd",
"C:/ClusterStorage/Volume6/SYSJHBDEV/HD-For-SYSPRO-Buildsvhdx.vhdx",
"C:/ClusterStorage/Volume6/SYSJHBFS/SYSJHBFS-Disk2.vhdx",
"C:/ClusterStorage/Volume6/SYSJHBSQLSP/SYSJHBSQLSP-DISK4.VHDX",
"C:/ClusterStorage/Volume6/SYSJHBSQLSP/SYSJHBSQLSP-DISK5.VHDX",
"C:/ClusterStorage/volume7/sysjhbdev/g_2013-08-17t173508.vhd",
"C:/ClusterStorage/Volume7/SYSJHBFS/SYSJHBFS.vhdx",
"C:/ClusterStorage/Volume7/SYSJHBMAIL/SYSJHBMAIL.vhdx",
"C:/ClusterStorage/Volume7/SYSJHBSQLSP/SYSJHBSQLSP.VHD",
"C:/ClusterStorage/Volume7/SYSJHBSQLSP/SYSJHBSQLSP-DISK3.VHDX",
"C:/ClusterStorage/Volume7/sysjhbvmm/Sysjhbvm.vhd",
"C:/ClusterStorage/Volume7/SYSPRO-Build/SYSPRO-BUILD.vhd",
"C:/ClusterStorage/Volume7/SYSPRO-ERRTRK/SYSPRO-ERRTRK-0.VHD")

$VHDTable = @()
ForEach ($VHDPath in $VHDs) {
    $NewString = $VHDPath -split ("/")
    $This_VHD = New-Object -TypeName psobject -Property @{
        Volume = $NewString[2]
        VM     = $NewString[3]
        VHD    = $NewString[-1]
    }
    $VHDTable += ,($This_VHD)
}

Clear-Host; $VHDTable.VHD
}
Function VHD-Details2 {
Clear-Host
$ClusterNodes = @(
    'SYSJHBHV1'
    'SYSJHBHV2'
    'SYSJHBHV3'
    'SYSJHBHV4')

$HostsVMS = @()

ForEach ($Node in $ClusterNodes) {
    Write-Host "Getting VMs on $Node - " -NoNewline
    $NodeVMS = Get-VM -ComputerName $Node
    Write-Host "Complete" -NoNewline
    Write-Host " - Collecting VHD info - " -NoNewline
    ForEach ($VM in $NodeVMS.HardDrives) {
        $This_VM = New-Object -TypeName PSObject -Property @{
            VMName = $VM.VMName
            Path = $VM.Path
        }
        $HostsVMS += ,($This_VM)
    }
    Write-Host "Complete"
}

$CSVVHDs = Get-ChildItem \\sysjhbhv1\c$\ClusterStorage -Recurse -Include "*.*vhd*" | Select FullName
$CSVVHDs
$HostsVMS.Path
}
Function MultiThreadVHDFiles {
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
        [Int32]    $MaximumJobs=$env:NUMBER_OF_PROCESSORS)

    Function Write-Color {
        Param(
            [Parameter(Mandatory = $True  , Position = 1)]
            [String[]]       $Text, `
            [Parameter(Mandatory = $True  , Position = 2)]
            [ConsoleColor[]] $Color, `
            [Parameter(Mandatory = $False , Position = 3)]
            [Switch]           $NoNewLine)

        $ErrorActionPreference = "Stop"
        Try {
            If ($Text.Count -ne $Color.Count) {
                Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $Color.Count.ToString()) -ForegroundColor Red
                Throw
            }
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -Foreground $Color[$Index] -NoNewLine
            }
            Switch ($NoNewLine){
                $True  { Write-Host -NoNewline }
                $False { Write-Host }
            }
        }
        Catch { }
    }
    $Jobs = @()
    
    Switch ($ReportImmediate) {
        $True { Write-Color -Text "Starting Jobs for ", $Targets.Count, " targets.", " Please wait for the results." -Color White, Cyan, White, Yellow }
    }
    ForEach ($Target in $Targets) {
        Switch ($ReportImmediate) {
            $False { Write-Color -Text "Starting Job for ", $Target -Color White, Yellow }
        }
        Switch ($PassTargetToScriptBlock) {
            "TargetOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Target)}
            "ArgumentsOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ScriptBlockArguments)}
            "Both" {
                $Arguments = @()
                $Arguments = $Arguments + $Target
                ForEach ($ScriptBlockArgument in $ScriptBlockArguments) {
                    $Arguments = $Arguments + $ScriptBlockArgument
                }
                $Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Arguments)}
        }
        $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})

        While ($RunningJobs.Count -ge $MaximumJobs) {
            $FinishedJobs = Wait-Job -Job $Jobs -Any
            Switch ($ReportImmediate) {
                $True {
                    $CompletedJobs = @($Jobs | Where {$_.HasMoreData -eq "True"})
                    ForEach ($CompleteJob in $CompletedJobs) {
                        Receive-Job $CompleteJob
                    }
                }
            }
            $RunningJobs  = @($Jobs | Where-Object {$_.State -eq 'Running'})
        }
    }
    Wait-Job -Job $Jobs | Out-Null
    $FailedJobs = @($Jobs | Where-Object {$_.State -eq 'Failed'})
    If ($FailedJobs.Count -gt 0) {
        ForEach ($FailedJob in $FailedJobs) {
            $FailedJob.ChildJobs[0].JobStateInfo.Reason.Message
        }
    }
    $JobResults = @()
    Switch ($ReportImmediate) {
        $False {
            ForEach ($Job in $Jobs) {
                $JobResults = $JobResults + (Receive-Job $Job)
            }
        }
    }
    Get-Job | Wait-Job | Remove-Job
    Return $JobResults
}
$SB2 = {
    Param ($Server)
    $WMIQuery = "SELECT Name, Size, FreeSpace FROM Win32_LogicalDisk WHERE DriveType = 3"
    Write-Host "Getting Logical Disks on $Server - " -NoNewline
    $Results = Get-WmiObject -Query $WMIQuery -ComputerName $Server
    Write-Host "Complete"
    $AllVHDs = @()
    ForEach ($Volume in $Results) {
        Write-Host ("Getting VHD files on " + $Volume.Name[0] + " - ") -NoNewline
        $ServerPath = "\\"+ $Server + "\" + $Volume.Name[0] + "$\"
        $VHDs = Get-ChildItem $ServerPath -Include "*.*vhd*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Complete"
        Write-Host "Adding VHDs to report - " -NoNewline
        ForEach ($VHD in $VHDs) {
            $AllVHDs += ,($VHd.FullName)
        }
        Write-Host "Complete"
    }
    $AllVHDs
}

Clear-Host
$ClusterNodes = @(
    'SYSJHBHV1'
    'SYSJHBHV2'
    'SYSJHBHV3'
    'SYSJHBHV4')
Start-Jobs -PassTargetToScriptBlock TargetOnly -ScriptBlock $SB2 -MaximumJobs 4 -Targets $ClusterNodes
}
Function MultiThreadVHDFiles2 {
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
        [Int32]    $MaximumJobs=$env:NUMBER_OF_PROCESSORS)

    Function Write-Color {
        Param(
            [Parameter(Mandatory = $True  , Position = 1)]
            [String[]]       $Text, `
            [Parameter(Mandatory = $True  , Position = 2)]
            [ConsoleColor[]] $Color, `
            [Parameter(Mandatory = $False , Position = 3)]
            [Switch]           $NoNewLine)

        $ErrorActionPreference = "Stop"
        Try {
            If ($Text.Count -ne $Color.Count) {
                Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $Color.Count.ToString()) -ForegroundColor Red
                Throw
            }
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -Foreground $Color[$Index] -NoNewLine
            }
            Switch ($NoNewLine){
                $True  { Write-Host -NoNewline }
                $False { Write-Host }
            }
        }
        Catch { }
    }
    $Jobs = @()
    
    Switch ($ReportImmediate) {
        $True { Write-Color -Text "Starting Jobs for ", $Targets.Count, " targets.", " Please wait for the results." -Color White, Cyan, White, Yellow }
    }
    ForEach ($Target in $Targets) {
        Switch ($ReportImmediate) {
            $False { Write-Color -Text "Starting Job for ", $Target -Color White, Yellow }
        }
        Switch ($PassTargetToScriptBlock) {
            "TargetOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Target)}
            "ArgumentsOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ScriptBlockArguments)}
            "Both" {
                $Arguments = @()
                $Arguments = $Arguments + $Target
                ForEach ($ScriptBlockArgument in $ScriptBlockArguments) {
                    $Arguments = $Arguments + $ScriptBlockArgument
                }
                $Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Arguments)}
        }
        $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})

        While ($RunningJobs.Count -ge $MaximumJobs) {
            $FinishedJobs = Wait-Job -Job $Jobs -Any
            Switch ($ReportImmediate) {
                $True {
                    $CompletedJobs = @($Jobs | Where {$_.HasMoreData -eq "True"})
                    ForEach ($CompleteJob in $CompletedJobs) {
                        Receive-Job $CompleteJob
                    }
                }
            }
            $RunningJobs  = @($Jobs | Where-Object {$_.State -eq 'Running'})
        }
    }
    Wait-Job -Job $Jobs | Out-Null
    $FailedJobs = @($Jobs | Where-Object {$_.State -eq 'Failed'})
    If ($FailedJobs.Count -gt 0) {
        ForEach ($FailedJob in $FailedJobs) {
            $FailedJob.ChildJobs[0].JobStateInfo.Reason.Message
        }
    }
    $JobResults = @()
    Switch ($ReportImmediate) {
        $False {
            ForEach ($Job in $Jobs) {
                $JobResults = $JobResults + (Receive-Job $Job)
            }
        }
    }
    Get-Job | Wait-Job | Remove-Job
    Return $JobResults
}

$SB2 = {
    Param ($Server)
    $WMIQuery = "SELECT Name, Size, FreeSpace FROM Win32_LogicalDisk WHERE DriveType = 3"
    Write-Host "Getting Logical Disks on $Server - " -NoNewline
    $Results = Get-WmiObject -Query $WMIQuery -ComputerName $Server
    Write-Host "Complete"
    $AllVHDs = @()
    $Properties = @('Root', 'Parent', 'Name', 'FullName', 'Extension', 'Length')
    ForEach ($Volume in $Results) {
        Write-Host ("Getting VHD files on " + $Volume.Name[0] + " - ") -NoNewline
        If ($Volume.Name[0].ToString().ToLower() -eq 'c') {
            $ServerPath = "\\"+ $Server + "\" + $Volume.Name[0] + "$\"
            $VHDs = Get-ChildItem $ServerPath -Include "*.*vhd*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Complete"
            Write-Host "Adding VHDs to report - " -NoNewline
            ForEach ($VHD in $VHDs) {
                $AllVHDs += ,($VHD | Select $Properties)
            }
            Write-Host "Complete"
        }
    }
    $AllVHDs
}

Clear-Host
$ClusterNodes = @(
    'SYSJHBHV1'
    'SYSJHBHV2'
    'SYSJHBHV3'
    'SYSJHBHV4')
$Results_Excluding_C = Start-Jobs -PassTargetToScriptBlock TargetOnly -ScriptBlock $SB2 -MaximumJobs 4 -Targets $ClusterNodes
$Results_Only_C = Start-Jobs -PassTargetToScriptBlock TargetOnly -ScriptBlock $SB2 -MaximumJobs 4 -Targets $ClusterNodes
$HostsVMS = @()

ForEach ($Node in $ClusterNodes) {
    Write-Host "Getting VMs on $Node - " -NoNewline
    $NodeVMS = Get-VM -ComputerName $Node
    Write-Host "Complete" -NoNewline
    Write-Host " - Collecting VHD info - " -NoNewline
    ForEach ($VM in $NodeVMS.HardDrives) {
        $This_VM = New-Object -TypeName PSObject -Property @{
            VMName = $VM.VMName
            Path = $VM.Path
        }
        $HostsVMS += ,($This_VM)
    }
    Write-Host "Complete"
}
$HostsVMS
}