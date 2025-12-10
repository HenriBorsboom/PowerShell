#region
# Compiled by Henri Borsboom

# Change Log:
# 2023/09/18
# Enabled Logging
# Enabled compression of logs on schedule
# Enabled cleanup of empty folders
# Change Variable and Function from InterdepartmentalShare to TempShare
#
# 2023/09/04
# Created script
#endregion

Function Backup-TempShare {
    $BackupFiles = Get-ChildItem -Path $TempShare -Recurse -Force | Where-Object LastWriteTime -le $BackupDate
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Files for backup found: ' + $BackupFiles.Count.ToString())
    For ($BackupI = 0; $BackupI -lt $BackupFiles.Count; $BackupI ++) {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Backup File: ' + $BackupFiles[$BackupI].FullName)
        $BackupTarget = $BackupFiles[$BackupI].FullName.ToLower().Replace($TempShare.ToLower(), $BackupShare)
        $SplitPathTest = $BackupTarget -split '\\'
        If (!(Test-Path ($SplitPathTest[0..($SplitPathTest.Length - 2)] -join '\'))) {
            New-Item ($SplitPathTest[0..($SplitPathTest.Length - 2)] -join '\') -ItemType Directory | Out-Null 
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Target location created: ' + ($SplitPathTest[0..($SplitPathTest.Length - 2)] -join '\'))
        }
        ElseIf (Test-Path $BackupTarget) {
            Write-Log -LogFile $LogFile -Level Warning -Component $MyInvocation.MyCommand.Name -Message ('File already exists in backup and will be removed from backup: ' + $BackupTarget)
            Remove-Item $BackupTarget
            Write-Log -LogFile $LogFile -Level Warning -Component $MyInvocation.MyCommand.Name -Message ('File removed: ' + $BackupTarget)
        }

        If ($OpenFiles.Path -Contains $BackupFiles[$BackupI].Fullname -and $BackupFiles[$BackupI].LastWriteTime -le $KillDate) {
            Close-SmbOpenFile -FileId ($OpenFiles | Where-Object Path -eq $BackupFiles[$BackupI].Fullname | Select-Object FileID).FileID -Force
            Write-Log -LogFile $LogFile -Level Warning -Component $MyInvocation.MyCommand.Name -Message ('Terminated open file as kill date has been reached. File name and ID: ' + $BackupFiles[$BackupI].Fullname + ' - ' + ($OpenFiles | Where-Object Path -eq $BackupFiles[$BackupI].Fullname | Select-Object FileID).FileID.ToString())
        }
        Move-Item -Path $BackupFiles[$BackupI].Fullname -Destination $BackupTarget
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Moved Source file to target location: ' + $BackupFiles[$BackupI].Fullname + ' - ' + $BackupTarget)
    }
    Remove-EmptyFolders -Path $TempShare
}
Function Remove-EmptyFolders {
    Param (
        [Parameter(Mandatory = $True, Position = 1)]
        [String] $Path
    )
    $TopDir  = $Path
    # first get a list of all folders below the $TopDir directory that are named 'Archiv' (FullNames only)
    $archiveDirs = (Get-ChildItem -LiteralPath $TopDir -Recurse -Directory -Force).FullName | 
                    # sort on the FullName.Length property in Descending order to get 'deepest-nesting-first' 
                    Sort-Object -Property Length -Descending 

    # next, remove all empty subfolders in each of the $archiveDirs
    #foreach ($dir in $archiveDirs) {
    For ($DirI = 0; $DirI -lt $archiveDirs.Count; $DirI ++) {
        $Dir = $archiveDirs[$DirI]
        (Get-ChildItem -LiteralPath $dir -Directory -Force) |
        # sort on the FullName.Length property in Descending order to get 'deepest-nesting-first' 
        Sort-Object @{Expression = {$_.FullName.Length}} -Descending | 
        ForEach-Object {
        # if this folder is empty, remove it and output its FullName for the log
        if (@($_.GetFileSystemInfos()).Count -eq 0) { 
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Removing Empty folder: ' + $_.FullName)
            Remove-Item -LiteralPath $_.FullName -Force| Out-Null
        }
        }
        # next remove the 'Archiv' folder that is now possibly empty too
        if (@(Get-ChildItem -LiteralPath $dir -Force).Count -eq 0) {
            # output this folders fullname and delete
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Removing Empty folder: ' + $dir)
            Remove-Item -LiteralPath $dir -Force | Out-Null
        }
    }
}
Function Remove-Backup {
    $BackupFiles = Get-ChildItem -Path $BackupShare -Recurse -Force | Where-Object LastWriteTime -le $DeleteDate
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Files to be removed from Backup location: ' + $BackupFiles.Count.ToString())
    [Array]::Reverse($BackupFiles)
    ForEach ($BackupFile in $BackupFiles) {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Removing backup file: ' + $BackupFile.FullName)
        Remove-Item $BackupFile.FullName
    }
    Remove-EmptyFolders -Path $BackupShare
}
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
Function New-LogZip {
    $FilesToZip = Get-ChildItem -Path $LogFolder -Filter *.log | Where-Object LastWriteTime -le $ZipDate
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Old logs to Compress: ' + $FilesToZip.Count.ToString())
    If ($null -ne $FilesToZip) {
        Compress-Archive $FilesToZip -DestinationPath ($LogFolder + '\Compressed Logs__' + ((Get-Date).ToString('yyyy_MM_dd__HH_mm')) + 'zip')
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('New Zipped Log file: ' + ($LogFolder + '\Compressed Logs__' + ((Get-Date).ToString('yyyy_MM_dd__HH_mm')) + 'zip'))
    }
    Else {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('No old logs to Zip')
    }
}
# Parameters
[String] $TempShare = 'F:\Temporary (48 hours)'
[String] $BackupShare = 'F:\Temporary Backup'
[String] $LogFolder = 'F:\Temprary Logs'
[String] $LogFile = ($LogFolder + '\Cleanup_' + (Get-Date).ToString('yyyy-MM-dd__HH_mm') + '.log')
[Int] $KeepDataInShareForXDays = 2
[Int] $KeepDataInBackupsForXDays = 7
[Int] $KillOpenHandleAfterXDays = 4
[Int] $ZipLogAfterXDays = 30
[DateTime] $BackupDate = (Get-Date).AddDays(-$KeepDataInShareForXDays)
[DateTime] $KillDate = (Get-Date).AddDays(-$KillOpenHandleAfterXDays)
[DateTime] $DeleteDate = (Get-Date).AddDays(-$KeepDataInBackupsForXDays)
[DateTime] $ZipDate = (Get-Date).AddDays(-$ZipLogAfterXDays)

Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Start of Cleanup job logging')
Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Backup files older than: ' + $BackupDate)
Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Delete files older than: ' + $DeleteDate)
Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Kill open handles on files older than: ' + $KillDate)

Clear-Host
$OpenFiles = Get-SmbOpenFile
If ($null -ne $OpenFiles -or $OpenFiles.Count -gt 0 ) {
    For ($OpenFileI = 0; $OpenFileI -lt $OpenFiles.Count; $OpenFileI ++) {
        Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Open File and File ID: ' + $OpenFiles[$OpenFileI].Path + ' - ' + $OpenFiles[$OpenFileI].FileID)
    }
}
Else {
    Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('No Open SMB Files')
}
Backup-TempShare
Remove-Backup
New-LogZip