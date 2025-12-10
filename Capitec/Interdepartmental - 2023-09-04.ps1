#region
# Compiled by Henri Borsboom

# Change Log:
# 2023/09/04
# Created script
#endregion

$ErrorActionPreference = 'SilentlyContinue'
Function Backup-InterdepartmentalShare {
    $BackupFiles = Get-ChildItem -Path $InterdepartmentalShare -Recurse -Force | Where-Object LastWriteTime -le $BackupDate
    ForEach ($BackupFile in $BackupFiles) {
        $BackupTarget = $BackupFile.FullName.Replace($InterdepartmentalShare, $BackupShare)
        Move-Item -Path $BackupFile.Fullname -Destination $BackupTarget
    }
}
Function Remove-Backup {
    $BackupFiles = Get-ChildItem -Path $BackupShare -Recurse -Force | Where-Object LastWriteTime -le $DeleteDate
    [Array]::Reverse($BackupFiles)
    ForEach ($BackupFile in $BackupFiles) {
        Remove-Item $BackupFile.FullName
    }
}
# Parameters
[String] $InterdepartmentalShare = 'F:\Temporary (48 hours)'
[String] $BackupShare = 'F:\Temporary Backup'
[Int] $KeepDataInShareForXDays = 2
[Int] $KeepDataInBackupsForXDays = 7
$BackupDate = (Get-Date).AddDays(-$KeepDataInShareForXDays)
$DeleteDate = (Get-Date).AddDays(-$KeepDataInBackupsForXDays)
Clear-Host
Backup-InterdepartmentalShare
Remove-Backup