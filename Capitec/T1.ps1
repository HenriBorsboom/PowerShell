[String] $InterdepartmentalShare = 'C:\temp1'
[String] $BackupShare = 'C:\Backup'
$BackupDate = (Get-Date).AddDays(-3)
$DeleteDate = (Get-Date).AddDays(-8)

$BackupFiles = Get-ChildItem $InterdepartmentalShare -Recurse
ForEach ($File in $BackupFiles) {
    $File.LastWriteTime = $BackupDate
}
$BackupFiles = Get-Item $InterdepartmentalShare
ForEach ($File in $BackupFiles) {
    $File.LastWriteTime = $BackupDate
}

$BackupFiles = Get-ChildItem $BackupShare -Recurse
ForEach ($File in $BackupFiles) {
    $File.LastWriteTime = $DeleteDate
}
$BackupFiles = Get-Item $BackupShare
ForEach ($File in $BackupFiles) {
    $File.LastWriteTime = $DeleteDate
}