$LogPath = "E:\DominoTL"
$BackupPath = "E:\DominoTL\Backup"

Copy-Item -Path $LogPath -Destination $BackupPath -Filter "*.TXN" -ErrorAction SilentlyContinue