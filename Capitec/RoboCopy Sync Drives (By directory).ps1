Function Copy-Drives {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $SourceDrive, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $TargetDrive, `
        [Parameter(Mandatory=$False, Position=3)]
        [String] $LogPath = 'C:\Temp\Henri')

    $Folders = Get-ChildItem $SourceDrive | Where-Object {$_.Mode -like 'd*'}
    For ($i = 0; $i -lt $Folders.Count; $i ++) {
        Write-Host (($i + 1).ToString() + '/' + $Folders.Count.ToString() + ' - Starting job for ' + $Folders[$i].BaseName)
        $Source = $Folders[$i].FullName
        $Target = $TargetDrive + '\' + $Folders[$i].BaseName
        $Log = $LogPath + '\' + $Folders[$i].BaseName + '.log'
        Start-Job -Name $Folders[$i].BaseName -ArgumentList $Source, $Target, $Log -ScriptBlock {Param ($Source, $Target, $Log); Robocopy $Source $Target /log:$Log /e /zb /copyall /r:0 /w:0 /np /purge /mt:32 /ns /nc /nfl /ndl} | Out-Null
    }
}

Copy-Drives -SourceDrive C:\Windows -TargetDrive C:\Temp4