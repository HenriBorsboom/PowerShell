Param (
    [Parameter(Mandatory=$False, Position=1)]
    [Switch] $Backup, `
    [Parameter(Mandatory=$False, Position=2)]
    [Switch] $Restore)

Function MakeBackup {
    $SavedGamesSource = 'C:\Users\henri.borsboom\Saved Games'
    $Game = 'Diablo II'
    Copy -LiteralPath ($SavedGamesSource + '\' + $Game) -Destination ($SavedGamesSource + '\' + $Game + ' ' + (Get-Date -Format 'dd-MM-yyyy HH.mm.ss')) -Recurse
    Write-Color -Text 'Backup created: ', ($SavedGamesSource + '\' + $Game + ' ' + (Get-Date -Format 'dd-MM-yyyy HH.mm.ss')) -ForegroundColor Green, White
}
Function RestoreBackup {
    $SavedGamesSource = 'C:\Users\henri.borsboom\Saved Games'
    $Game = 'Diablo II'
    $SaveGames = Get-ChildItem $SavedGamesSource
    For ($SaveGameI = 0; $SaveGameI -lt $SaveGames.Count; $SaveGameI ++) {
        Write-Color -Text '[', $SaveGameI, '] ', $SaveGames[$SaveGameI].Name -ForegroundColor DarkCyan, DarkCyan, DarkCyan, White
    }
    $RestoreGameIndex = Read-Host "Specify the index to restore"
    $RestoreGame = $SaveGames[$RestoreGameIndex].FullName
    Rename-Item ($SavedGamesSource + '\' + $Game) -NewName ($SavedGamesSource + '\' + $Game + ' Restored')
    Write-Color -Text 'Secondary Backup Made: ', ($SavedGamesSource + '\' + $Game + ' Restored') -ForegroundColor Yellow, White
    Rename-Item $RestoreGame -NewName ($SavedGamesSource + '\' + $Game)
    Write-Color -Text 'Restore completed: ', $RestoreGame -ForegroundColor Green, White
}

Switch ($Backup) {
    $True { MakeBackup }
    $False { 
        Write-Host ""
        Write-Host "Use the switch -Backup to make a backup" 
        Write-Host ""
    }
}
Switch ($Restore) {
    $True { RestoreBackup }
    $False { 
        Write-Host ""
        Write-Host "Use the switch -Restore to restore the last backup made" 
        Write-Host ""
    }
}