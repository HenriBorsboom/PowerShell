$LogPath = "E:\DominoTL"
$BackupPath = "E:\DominoTL\Backup"

Move-Item -Path $LogPath -Destination $BackupPath -Filter "*.TXN" -ErrorAction SilentlyContinue