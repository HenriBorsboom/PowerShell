$FoldersCount = 10
$FilesCount = 100

$Path = 'C:\Temp'
For ($i = 0; $i -lt $FoldersCount; $i ++) {
    $FolderPath = ($Path + '\Folder' + $i.ToString())
    New-Item -Path $FolderPath -ItemType Directory | Out-Null
    For ($x = 0; $x -lt $FilesCount; $x ++) {
        New-Item -Path ($FolderPath + '\File' + $x.ToString() + '.txt') -ItemType File | Out-Null
        ($FolderPath + '\File' + $x.ToString() + '.txt') | Out-File ($FolderPath + '\File' + $x.ToString() + '.txt') -Encoding ascii -Force
    }
}