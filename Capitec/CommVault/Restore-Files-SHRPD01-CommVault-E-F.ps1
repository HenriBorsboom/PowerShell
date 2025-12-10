# New-PSDrive -Name Y -PSProvider FileSystem -Root '\\BACKUPSERVER01\FILESERVER01\Restore' -Credential (Get-Credential)
# net use y: '\\BACKUPSERVER01\FILESERVER01\Restore'

$ErrorActionPreference = 'Stop'
if ($null -eq $psISE) {
    Import-Module BitsTransfer
}

Function Send-Notification {
    $Message | Out-File '\\CBFP01\Temp\ScriptComplete.txt' -Encoding ascii -Force

}
Function Get-ControlStop {
    If ($null -eq $psISE) {
        # in ISE
    }
    Else {
        If ([System.Console]::KeyAvailable) {
            $key = [System.Console]::ReadKey($True)
            if ($Key.Key -eq 'Escape') {
                Write-Host "Script Execution stopped by user"
                $Message = ("Controlled stop of CommVault file restores. Last I: " + (Get-Content $ResumeIFile) + " - Last X: " + (Get-Content $ResumeXFile))
                Send-Notification -Message $Message            
                Remove-Variable RestoreFiles
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
        # Set properties
        $Newacl.SetOwner([System.Security.Principal.NTAccount]"BUILTIN\Administrators")
        $identity = "BUILTIN\Administrators"
        $fileSystemRights = "FullControl"
        $type = "Allow"
        $Inheritance = 'ContainerInherit,ObjectInherit'
        $Propagation = 'None'
        # Create new rule
        $fileSystemAccessRuleArgumentList = $identity, $fileSystemRights, $Inheritance, $Propagation, $type
        $fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
        # Apply new rule
        $NewAcl.AddAccessRule($fileSystemAccessRule)
        #$NewAcl.SetAccessRuleProtection($True, $False) #$True = isProtected (Disable Inheritance); $False = PreserveInheritance (Copy Existing Permissions)
        Set-Acl -LiteralPath $TopFolder -AclObject $NewAcl

        #$CurrentAccess = $NewAcl.Access

        # Grant modify permissions to each user
        #foreach ($Access in $NewAcl.Access) {
        $acl = Get-Acl -LiteralPath $TopFolder
        For ($x = 0; $x -lt $NewAcl.Access.Count; $x ++) {
            $Access = $NewAcl.Access[$x]
            
            $Permission = $Access.IdentityReference, $Access.FileSystemRights, $Access.InheritanceFlags, $Access.PropagationFlags, $Access.AccessControlType
    
            $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission
            #$acl.SetAccessRule($accessRule)
            $acl.AddAccessRule($accessRule)
            
        }
        Set-Acl -LiteralPath $TopFolder -ACLObject $acl
        Remove-Variable acl
        Remove-Variable Permission
    }
    Catch {
        Write-Host ($_) -ForegroundColor Red
        ($Path + ',' + $_) | Out-File $ErrorFile -Encoding ascii -Append
    }
    $NewACL = $null
    Remove-Variable NewACL
    [GC]::Collect()
}
$Reports = Get-ChildItem 'D:\Temp\CommVault\Copy_Reports'-File | Sort-Object BaseName
$TargetRestoreFolder = 'E:\'
$ResumeIFile = 'D:\Temp\CommVault\ResumeI.txt'
$ResumeXFile = 'D:\Temp\CommVault\ResumeX.txt'
[Int] $ResumeI = Get-Content $ResumeIFile
[Int] $ResumeX = Get-Content $ResumeXFile
$ACL = Get-ACL 'E:\temp\emptyacl.txt'

If ($null -eq $ResumeI -or $ResumeI -eq '') {
    $ResumeI = 0
}
If ($null -eq $ResumeX -or $ResumeX -eq '') {
    $ResumeX = 0
}

$StartTime = Get-Date
Try {
    For ($i = $ResumeI; $i -lt $Reports.Count; $i ++) {
        $i | Out-File $ResumeIFile -Encoding ascii -Force    
        Write-Progress -PercentComplete ($i / $Reports.Count * 100) -Activity ('Copying Reports - ' + ($i / $Reports.Count * 100) + '%') -ID 1
        $RemovedReportFile = ('D:\Temp\CommVault\Failed_Reports\FILESERVER01_' + $Reports[$i].BaseName + '_Removed.txt')
        $MisMatchReportFile = ('D:\Temp\CommVault\Failed_Reports\FILESERVER01_' + $Reports[$i].BaseName + '_MisMatch.txt')
        #$FixACLReportFile = ('D:\Temp\CommVault\Failed_Reports\FILESERVER01_' + $Reports[$i].BaseName + '_FixACL.txt')
        $ErrorFile = ('D:\Temp\CommVault\Failed_Reports\FILESERVER01_' + $Reports[$i].BaseName + '_Errors.txt')
        $NotExistReportFile = ('D:\Temp\CommVault\Failed_Reports\FILESERVER01_' + $Reports[$i].BaseName + '_NotExist.txt')
        Write-Host (($i + 1).ToString() + '/' + $Reports.Count.ToString() + ' - Getting Contents of ' + $Reports[$i])
        [String[]] $RestoreFiles = Get-Content $Reports[$i].FullName
        [Int] $ResumeX = Get-Content $ResumeXFile
        For ($x = $ResumeX; $x -lt $RestoreFiles.Count; $x ++) {
            $x | Out-File $ResumeXFile -Encoding ascii -Force
            Write-Progress -PercentComplete ($x / $RestoreFiles.Count * 100) -Activity ('Copying Files - ' + ($x / $RestoreFiles.Count * 100) + '%') -ParentId 1
            Write-Host (($i + 1).ToString() + '/' + $Reports.Count.ToString() + ' | ' + ($x + 1).ToString() + '/' + $RestoreFiles.Count.ToString() + ' Processing ' + $RestoreFiles[$x].Replace('F:\FILESERVER01\Restore\', 'Y:\') + ' - ') -NoNewline
            $RestoreFile = $RestoreFiles[$x].Replace('F:\FILESERVER01\Restore\', 'Y:\')
            Try {
                [Void] (Get-ChildItem -LiteralPath $RestoreFile.Replace('Y:\', 'E:\'))
                $CopyFlag = $False
            }
            Catch {
                If ($_ -like '*does not exist*') {
                    $CopyFlag = $True
                }
                Else {
                    Throw $_
                }
            }
            If ($CopyFlag -eq $True) {
                ($RestoreFile.Replace('Y:\', $TargetRestoreFolder)) | Out-File $NotExistReportFile -Encoding ascii -Append
                If ($null -eq $psISE) {
                    Start-BitsTransfer -Source $RestoreFile -Destination ($RestoreFile.Replace('Y:\', 'F:\')) -Description ($RestoreFile.Replace('Y:\', 'F:\')) -DisplayName $RestoreFile
                }
                Else {
                    Copy-Item -LiteralPath $RestoreFile -Destination ($RestoreFile.Replace('Y:\', 'F:\')) -Force
                }
                Write-Host 'Copied' -ForegroundColor Green
                $CopyFlag = $False
            }
            ElseIf ((Get-ChildItem -LiteralPath $RestoreFile.Replace('Y:\', 'E:\')).Attributes -like '*l*') {
                If ((Get-ChildItem -LiteralPath $RestoreFile).Length -eq (Get-ChildItem -LiteralPath $RestoreFile.Replace('Y:\', 'E:\')).Length) {
                    ($RestoreFile.Replace('Y:\', $TargetRestoreFolder)) | Out-File $RemovedReportFile -Encoding ascii -Append
                    #Try {
                    #    Remove-Item -LiteralPath ($RestoreFile.Replace('Y:\', $TargetRestoreFolder))
                    #}
                    #Catch {
                    #    ($RestoreFile.Replace('Y:\', $TargetRestoreFolder)) | Out-File $FixACLReportFile -Encoding ascii -Append
                    #    Write-Host 'Fixing ACL - ' -ForegroundColor DarkYellow
                    #    New-ACL -Path ($RestoreFile.Replace('Y:\', 'F:\')) -ACL $ACL
                        #Remove-Item -LiteralPath ($RestoreFile.Replace('Y:\', $TargetRestoreFolder))
                    #}
                    #Finally {
                        If ($null -eq $psISE) {
                            Start-BitsTransfer -Source $RestoreFile -Destination ($RestoreFile.Replace('Y:\', 'F:\')) -Description ($RestoreFile.Replace('Y:\', 'F:\')) -DisplayName $RestoreFile
                        }
                        Else {
                            Copy-Item -LiteralPath $RestoreFile -Destination ($RestoreFile.Replace('Y:\', 'F:\')) -Force
                        }
                        Write-Host 'Copied' -ForegroundColor Green
                    #}
                }
                Else {
                    ($RestoreFile.Replace('Y:\', $TargetRestoreFolder)) | Out-File $MisMatchReportFile -Encoding ascii -Append
                    Write-Host 'Skipped' -ForegroundColor Cyan
                }
            }
            Else {
                Write-Host 'Source not archived' -ForegroundColor Yellow
            }
            Get-ControlStop
        }
        0 | Out-File $ResumeXFile -Encoding ascii -Force
        Remove-Variable RestoreFiles
        [GC]::Collect()
    }
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