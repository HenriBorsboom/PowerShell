# net use y: '\\BACKUPSERVER01\FILESERVER01\D'

#<#
Param (
    [Parameter(Mandatory=$False, Position=1)]
    [Switch] $SpecifyStart=$False, `
    [Parameter(Mandatory=$False, Position=2)]
    [Int] $ReportIndex, `
    [Parameter(Mandatory=$False, Position=3)]
    [Int] $FileIndex, `
    [Parameter(Mandatory=$False, Position=4)]
    [String] $StartReport, `
    [Parameter(Mandatory=$False, Position=5)]
    [Switch] $Continue
)
#>
<#
$SpecifyStart = $True
$ReportIndex = 0
$FileIndex = 0
$StartReport = 'C:\Temp\CommVault\Reports\Shared_ODS Folders_ODS_TREASURY_FOREX.txt'
#>
$ErrorActionPreference = 'Stop'
$PreviousRun = 'NextRun7'
$NextRun = 'NextRun8'

If (-not (Test-Path ('C:\Temp\CommVault\Failed_Reports\' + $NextRun))) {
    New-Item ('C:\Temp\CommVault\Failed_Reports\' + $NextRun) -ItemType Directory | Out-Null
}
If (-not (Test-Path ('C:\Temp\CommVault\Reports\' + $NextRun))) {
    New-Item ('C:\Temp\CommVault\Reports\' + $NextRun) -ItemType Directory | Out-Null
}

Function Send-Notification {
    Try {
        $Message | Out-File '\\CBFP01\Temp\ScriptComplete.txt' -Encoding ascii -Force
    }
    Catch {
        Write-Host $_ -ForegroundColor Red
    }

}
Function Get-ControlStop {
    If ($null -ne $psISE) {
        # in ISE
    }
    Else {
        If ([System.Console]::KeyAvailable) {
            $key = [System.Console]::ReadKey($True)
            if ($Key.Key -eq 'Escape') {
                Write-Host "Script Execution stopped by user"
                $Message = ("Controlled stop of CommVault file restores. Last I: " + (Get-Content $ResumeIFile) + " - Last X: " + (Get-Content $ResumeXFile))
                Send-Notification -Message $Message            
                [GC]::Collect()
                break
            }
        }
    }
}
Function New-ACL {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Path, `
        [Parameter(Mandatory=$True, Position=1)]
        [Object] $ACL
    )

    Try {        
        $Splitpath = $path -Split '\\'
        $TopFolder = $Splitpath[0..($Splitpath.Count - 2)] -join '\'
        $NewAcl = Get-Acl -LiteralPath $TopFolder
        $Newacl.SetOwner([System.Security.Principal.NTAccount]"BUILTIN\Administrators")
        $identity = "BUILTIN\Administrators"
        $fileSystemRights = "FullControl"
        $type = "Allow"
        $Inheritance = 'ContainerInherit,ObjectInherit'
        $Propagation = 'None'
        $fileSystemAccessRuleArgumentList = $identity, $fileSystemRights, $Inheritance, $Propagation, $type
        $fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
        $NewAcl.AddAccessRule($fileSystemAccessRule)
        Write-Host "|- Part 1" -ForegroundColor DarkMagenta
        Set-Acl -LiteralPath $TopFolder -AclObject $NewAcl

        $acl = Get-Acl -LiteralPath $TopFolder
        For ($x = 0; $x -lt $NewAcl.Access.Count; $x ++) {
            $Access = $NewAcl.Access[$x]
            If ($Access.FileSystemRights -eq '268435456') {
                $Permission = $Access.IdentityReference, "FullControl", $Access.InheritanceFlags, $Access.PropagationFlags, $Access.AccessControlType
            }
            Else {
                $Permission = $Access.IdentityReference, $Access.FileSystemRights, $Access.InheritanceFlags, $Access.PropagationFlags, $Access.AccessControlType
            }
    
            $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission
            $acl.AddAccessRule($accessRule)
            
        }
        Write-Host "|- Part 2" -ForegroundColor DarkMagenta
        Set-Acl -LiteralPath $TopFolder -ACLObject $acl
        Remove-Variable acl
        Remove-Variable Permission
    }
    Catch {
        Write-Host ($_) -ForegroundColor Red
        ($Path + ',' + $_) | Out-File $ErrorFile -Encoding ascii -Append
    }
    $NewACL = $null
    [GC]::Collect()
}
Function New-Folders {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $RestoreFile
    )
    $RestorePath = $RestoreFile.Replace('F:\', '') -split '\\'
    For ($y = 0; $y -le ($RestorePath.Count - 2); $y ++) {
        If (Test-Path -LiteralPath ('E:\' + (($RestorePath[0..$y]) -join '\'))) {
            #folder exists
        }
        Else {
            New-Item ('E:\' + (($RestorePath[0..$y]) -join '\')) -ItemType Directory | Out-Null
        }
    }
}
Function New-Copy {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Source, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $Target
    )
    Try {
        Copy-Item -LiteralPath $Source -Destination $Target
    }
    Catch {
        New-ACL -Path $Target -ACL $ACL
        Copy-Item -LiteralPath $Source -Destination $Target
    }
}

Switch ($SpecifyStart) {
    $True {
        $ResumeIFile = ('C:\Temp\CommVault\' + $StartReport.Replace('C:\Temp\CommVault\Reports\','').Replace('\','_').Replace('.txt','_I.txt'))
        $ResumeXFile = ('C:\Temp\CommVault\' + $StartReport.Replace('C:\Temp\CommVault\Reports\','').Replace('\','_').Replace('.txt','_X.txt'))       
        $ReportIndex | Out-File $ResumeIFile -Encoding ascii -Force
        $FileIndex | Out-File $ResumeXFile -Encoding ascii -Force
        $ResumeI = $ReportIndex
        $ResumeX = $FileIndex
        [String[]] $Reports = $StartReport
    }
    $False {
        $ResumeIFile = 'C:\Temp\CommVault\ResumeI.txt'
        $ResumeXFile = 'C:\Temp\CommVault\ResumeX.txt'
        [Int] $ResumeI = Get-Content $ResumeIFile
        [Int] $ResumeX = Get-Content $ResumeXFile
        

        If ($null -eq $ResumeI -or $ResumeI -eq '') {
            $ResumeI = 0
        }
        If ($null -eq $ResumeX -or $ResumeX -eq '') {
            $ResumeX = 0
        }
        $Reports = (Get-ChildItem ('C:\Temp\CommVault\Reports\' + $PreviousRun) -File | Sort-Object BaseName).FullName
    }
}


#$TargetRestoreFolder = 'E:\'

$ACL = Get-ACL 'E:\temp\emptyacl.txt'
$StartTime = Get-Date
#$Continue = $True
Try {
    For ($i = $ResumeI; $i -lt $Reports.Count; $i ++) {
        $i | Out-File $ResumeIFile -Encoding ascii -Force    
        Write-Progress -PercentComplete (($i + 1) / $Reports.Count * 100) -Activity ('Copying Reports - ' + (($i + 1) / $Reports.Count * 100) + '%') -ID 1
        $NewReportFile = $Reports[$i].Replace(('C:\Temp\CommVault\Reports\' + $PreviousRun + '\'), ('C:\Temp\CommVault\Reports\'+ $NextRun + '\'))
        If ((Test-Path -LiteralPath $NewReportFile) -and $Continue -eq $False) {
            # Report already done
            Write-Host ('Report already done: ' + $NewReportFile) -ForegroundColor Yellow
        }
        Else {
            # Report not done yet
            $CopyReportFile = ('C:\Temp\CommVault\Failed_Reports\' + $NextRun + '\FILESERVER01_' + $Reports[$i].Replace(('C:\Temp\CommVault\Reports\' + $PreviousRun + '\'),'').Replace('.txt','') + '_Copy.txt')
            $ArchiveFile = ('C:\Temp\CommVault\Failed_Reports\' + $NextRun + '\FILESERVER01_' + $Reports[$i].Replace(('C:\Temp\CommVault\Reports\' + $PreviousRun + '\'),'').Replace('.txt','') + '_BackupArchived.txt')
            Write-Host (($i + 1).ToString() + '/' + $Reports.Count.ToString() + ' - Getting Contents of ' + $Reports[$i])
            [String[]] $RestoreFiles = Get-Content $Reports[$i]
            #[String[]] $RestoreFiles = $ReportData.FullName
            [Int] $ResumeX = Get-Content $ResumeXFile
            For ($x = $ResumeX; $x -lt $RestoreFiles.Count; $x ++) {
                $x | Out-File $ResumeXFile -Encoding ascii -Force
                Write-Progress -PercentComplete (($x + 1) / $RestoreFiles.Count * 100) -Activity ('Copying Files - ' + (($x + 1) / $RestoreFiles.Count * 100) + '%') -ParentId 1
                Write-Host (($i + 1).ToString() + '/' + $Reports.Count.ToString() + ' | ' + ($x + 1).ToString() + '/' + $RestoreFiles.Count.ToString() + ' Processing ' + $RestoreFiles[$x] + ' - ') -NoNewline
            
                $BackupFile = $RestoreFiles[$x].Replace('F:\', 'X:\')
                $TargetFile = $RestoreFiles[$x].Replace('F:\', 'E:\')

                If (Test-Path -LiteralPath $BackupFile) {
                    # File exists in Backup
                    If ((Get-Item -LiteralPath $BackupFile).Mode.Contains('l')) {
                        # Backup File is archived
                        Write-Host 'Backup is archived' -ForegroundColor DarkRed
                        $RestoreFiles[$x] | Out-File $ArchiveFile -Encoding ascii -Append
                        $RestoreFiles[$x] | Out-File $NewReportFile -Encoding ascii -Append
                    }
                    Else {
                        # Backup file is not archived
                        If ((Get-Item -LiteralPath $BackupFile).Length -eq (Get-Item -LiteralPath $RestoreFiles[$x]).Length) {
                            # File in backup matches size of file in source
                            If (Test-Path -LiteralPath $TargetFile) {
                                # File exists in target location
                                If ((Get-Item -LiteralPath $TargetFile).Mode.Contains('l') -or (Get-Item -LiteralPath $TargetFile).Length -eq 0) {
                                    # Target file is archived or Target file has 0 size
                                    Remove-Item -LiteralPath $TargetFile
                                    New-Copy -Source $BackupFile -Target $TargetFile
                                    Write-Host 'Copied' -ForegroundColor Green
                                    $RestoreFiles[$x] | Out-File $CopyReportFile -Encoding ascii -Append
                                }
                                Else {
                                    # Target file is not archived
                                    Write-Host 'Skipped' -ForegroundColor Cyan
                                }
                            }
                            Else {
                                # File does not exist in target location
                                New-Copy -Source $BackupFile -Target $TargetFile
                                Write-Host 'Copied' -ForegroundColor Green
                                $RestoreFiles[$x] | Out-File $CopyReportFile -Encoding ascii -Append
                            }
                        }
                        Else {
                            # File in backup does not match size of file in source
                            Write-Host "Size mismatch from backup" -ForegroundColor DarkYellow
                            $RestoreFiles[$x] | Out-File $NewReportFile -Encoding ascii -Append
                        }
                    }
                }
                Else {
                    # File not in backup. Save for next run
                    Write-Host "File not in backup" -ForegroundColor Magenta
                    $RestoreFiles[$x] | Out-File $NewReportFile -Encoding ascii -Append
                }
            }
            Get-ControlStop
        }
        0 | Out-File $ResumeXFile -Encoding ascii -Force
        $Continue = $False
        $RestoreFiles = $Null
        Remove-Variable RestoreFiles
        [GC]::Collect()
    }
    0 | Out-File $ResumeIFile -Encoding ascii -Force
    $EndTime = Get-Date
    $Message = ("Start time: " + $StartTime.ToString() + ' - End Time: ' + $EndTime.ToString() + ' - Duration: ' + (($EndTime - $StartTime) -f '{0:HH:mm:ss}') + ' - Restore Complete')
    Send-Notification -Message $Message
}
Catch {
    $EndTime = Get-Date
    $Message = ("Start time: " + $StartTime.ToString() + ' - End Time: ' + $EndTime.ToString() + ' - Duration: ' + (($EndTime - $StartTime) -f '{0:HH:mm:ss}') + ' - Error: ' + $_)
    Send-Notification -Message $Message
    Write-Error $_
}