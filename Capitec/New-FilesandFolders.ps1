$Source = 'C:\Temp1'
$Folders = 3
$Files = 30

For ($FolderI = 1; $FolderI -le $Folders; $FolderI ++) {
    Write-Output ('Creating Folder: ' + $FolderI.ToString())
    $Folder = New-Item ($Source + '\Folder' + $FolderI.ToString()) -ItemType Directory
    For ($FileI = 1; $FileI -le $Files; $FileI ++) {
        Write-Output ('|- Creating File: ' + $FileI.ToString())
        ('Hello World - Index: ' + $FileI.ToString()) | Out-File ($Folder.FullName + '\File_' + $FileI.ToString() + '.txt')
    }
}

$OldFolders = Get-ChildItem -Path $Source -Recurse
$BackupDate = (Get-Date).AddDays(-2)
$DeleteDate = (Get-Date).AddDays(-7)

[Array]::Reverse($OldFolders)

For ($i = 0; $i -le 30; $i ++) {
    $OldFolders[$i].LastWriteTime = $BackupDate
}

For ($i = 31; $i -le 62; $i ++) {
    $OldFolders[$i].LastWriteTime = $DeleteDate
}

$Source = 'C:\Temp1\folder1'
$Folders = 3
$Files = 30

For ($FolderI = 1; $FolderI -le $Folders; $FolderI ++) {
    Write-Output ('Creating Folder: ' + $FolderI.ToString())
    $Folder = New-Item ($Source + '\Folder' + $FolderI.ToString()) -ItemType Directory
    For ($FileI = 1; $FileI -le $Files; $FileI ++) {
        Write-Output ('|- Creating File: ' + $FileI.ToString())
        ('Hello World - Index: ' + $FileI.ToString()) | Out-File ($Folder.FullName + '\File_' + $FileI.ToString() + '.txt')
    }
}

$OldFolders = Get-ChildItem -Path $Source -Recurse
$BackupDate = (Get-Date).AddDays(-2)
$DeleteDate = (Get-Date).AddDays(-7)

[Array]::Reverse($OldFolders)

For ($i = 0; $i -le 30; $i ++) {
    $OldFolders[$i].LastWriteTime = $BackupDate
}

For ($i = 31; $i -le 62; $i ++) {
    $OldFolders[$i].LastWriteTime = $DeleteDate
}

$Source = 'C:\Temp1\folder2'
$Folders = 3
$Files = 30

For ($FolderI = 1; $FolderI -le $Folders; $FolderI ++) {
    Write-Output ('Creating Folder: ' + $FolderI.ToString())
    $Folder = New-Item ($Source + '\Folder' + $FolderI.ToString()) -ItemType Directory
    For ($FileI = 1; $FileI -le $Files; $FileI ++) {
        Write-Output ('|- Creating File: ' + $FileI.ToString())
        ('Hello World - Index: ' + $FileI.ToString()) | Out-File ($Folder.FullName + '\File_' + $FileI.ToString() + '.txt')
    }
}

$OldFolders = Get-ChildItem -Path $Source -Recurse
$BackupDate = (Get-Date).AddDays(-2)
$DeleteDate = (Get-Date).AddDays(-7)

[Array]::Reverse($OldFolders)

For ($i = 0; $i -le 30; $i ++) {
    $OldFolders[$i].LastWriteTime = $BackupDate
}

For ($i = 31; $i -le 62; $i ++) {
    $OldFolders[$i].LastWriteTime = $DeleteDate
}

$Source = 'C:\Temp1\folder3'
$Folders = 3
$Files = 30

For ($FolderI = 1; $FolderI -le $Folders; $FolderI ++) {
    Write-Output ('Creating Folder: ' + $FolderI.ToString())
    $Folder = New-Item ($Source + '\Folder' + $FolderI.ToString()) -ItemType Directory
    For ($FileI = 1; $FileI -le $Files; $FileI ++) {
        Write-Output ('|- Creating File: ' + $FileI.ToString())
        ('Hello World - Index: ' + $FileI.ToString()) | Out-File ($Folder.FullName + '\File_' + $FileI.ToString() + '.txt')
    }
}

$OldFolders = Get-ChildItem -Path $Source -Recurse
$BackupDate = (Get-Date).AddDays(-2)
$DeleteDate = (Get-Date).AddDays(-7)

[Array]::Reverse($OldFolders)

For ($i = 0; $i -le 30; $i ++) {
    $OldFolders[$i].LastWriteTime = $BackupDate
}

For ($i = 31; $i -le 62; $i ++) {
    $OldFolders[$i].LastWriteTime = $DeleteDate
}