$BackupPath = "E:\DominoTL\Backup"

Get-ChildItem -Path $BackupPath -Include "*.TXN" | Remove-Item -Force -ErrorAction SilentlyContinue