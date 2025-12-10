Function Create-CopyScript {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $SourceDrive, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $TargetDrive, `
        [Parameter(Mandatory=$False, Position=3)]
        [String] $LogPath = 'C:\Temp\Henri')

    $Folders = Get-ChildItem $SourceDrive -Force | Where-Object {$_.Mode -like 'd*'}
    [String[]] $ScriptOutput = @()
    For ($i = 0; $i -lt $Folders.Count; $i ++) {
        $Source = $Folders[$i].FullName
        $Target = $TargetDrive + '\' + $Folders[$i].BaseName
        $Log = $LogPath + '\' + $Folders[$i].BaseName + '.log'
        $JobName = $Folders[$i].BaseName
        $ScriptOutput += "Start-Job -Name '$JobName' {c:\temp\psexec.exe /s Robocopy '$Source' '$Target' /log:'$Log' /e /zb /copyall /r:0 /w:0 /np /purge /mt:32 /ns /nc /nfl /ndl}"
    }
    $ScriptFile = ($LogPath + '\' + $SourceDrive[0] + '-' + $TargetDrive[0] + '.ps1')
    $ScriptOutput | Out-File ($LogPath + '\' + $SourceDrive[0] + '-' + $TargetDrive[0] + '.ps1') -Encoding ascii -Force
    Return $ScriptFile
}

#Create-CopyScript -SourceDrive C:\Windows -TargetDrive C:\Temp4
Create-CopyScript U: G:
Create-CopyScript M: I: