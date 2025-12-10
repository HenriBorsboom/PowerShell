#region Common Functions
Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $Color, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Bool]           $EndLine)
    Begin {
    }
    Process {
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $Color[$Index] -NoNewLine
        }
        Switch ($EndLine){
            $True  { Write-Host            }
            $False { Write-Host -NoNewline }
        }
    }
}
Function Delete-LastLine {
    $CursorLeft = [System.Console]::CursorLeft
    $CursorTop  = [System.Console]::CursorTop
    [System.Console]::SetCursorPosition($CursorLeft ,$CursorTop  - 1)
    Write-Host "                                                                                                                                            "
    [System.Console]::SetCursorPosition($CursorLeft ,$CursorTop  - 1)
}
#endregion
Function Update-Job {
    Param (
        [Parameter(Mandatory=$True,  Position=1)]
        [Int64] $TimerCounter, `
        [Parameter(Mandatory=$True,  Position=2)]
        [String] $TargetFolder, `
        [Parameter(Mandatory=$True,  Position=3)]
        [Int64] $SourceCounter, `
        [Parameter(Mandatory=$True,  Position=4)]
        [Int64] $SourceCount, `
        [Parameter(Mandatory=$False, Position=5)]
        [Switch] $FinalUpdate)
    
    $Counter = ("{0:hh\:mm\:ss}" -f ([TimeSpan]::FromSeconds(((New-TimeSpan -Seconds($TimerCounter)).TotalSeconds))))
    Write-Color -Text "$SourceCounter/$SourceCount", " - Getting folders in ", $TargetFolder, " - ", $Counter -Color Cyan, White, Yellow, White, Red -EndLine:$True
    Sleep 1
    Switch ($FinalUpdate) {
        $False { Delete-LastLine }
    }
}
Function Process-Folder {
    Param (
        [Parameter(Mandatory=$True,  Position=1)]
        [String] $TargetFolder, `
        [Parameter(Mandatory=$True,  Position=2)]
        [Int64]  $RootCounter, `
        [Parameter(Mandatory=$True,  Position=3)]
        [Int64]  $RootCount)
    #region Start Job
    $ChildItemJob = Start-Job -ArgumentList $TargetFolder -ScriptBlock { Param($TargetFolder); Get-ChildItem $TargetFolder -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_.PSIsContainer -eq $True} | Sort-Object } -ErrorAction Stop
    $ChildItemJobState = Get-Job $ChildItemJob.Id
    $JobCounter = 1
    While ($ChildItemJobState.State -eq "Running") {
        Update-Job -TimerCounter $JobCounter -TargetFolder $TargetFolder -SourceCounter $RootCounter -SourceCount $RootCount -FinalUpdate:$False
        $JobCounter ++
    }
    Update-Job -TimerCounter $JobCounter -TargetFolder $TargetFolder -SourceCounter $RootCounter -SourceCount $RootCount -FinalUpdate:$True
    $TotalTime = $TotalTime + $JobCounter
    #endregion
    #region Receive Job
    $ChildItemJobResults = Receive-Job -Job $ChildItemJob
    
    $JobFolders = @()
    ForEach ($Folder in $ChildItemJobResults) {
            $SubFolderItems = (Get-ChildItem $Folder.FullName | Measure-Object -Property Length -Sum)
            $FolderSize     = "{0:N2}" -f ($SubFolderItems.sum / 1MB)
            $Result         = $FolderSize + " --- " + $Folder.FullName
            $JobFolders     = $JobFolders + $Result
    }
    #endregion
    Return $JobFolders
}
Function Gather-Information {
    Param (
        [Parameter(Mandatory=$True,  Position=1)]
        [String] $TargetFolder)

    Write-Color -Text "Getting Folders in ", $TargetFolder, " - " -Color White, Yellow, White -EndLine:$False
        $RootFolders = Get-ChildItem -Path $TargetFolder
    Write-Host "Complete" -ForegroundColor Green
    Write-Host
    Write-Color -Text "Total Folders: ", $RootFolders.FullName.Count -Color White, Yellow -EndLine:$True
    
    $Folders = @()
    
    $RootCounter = 1
    $RootCount = $RootFolders.FullName.Count
    ForEach ($RootFolder in $RootFolders.FullName) {
        $FolderResults = Process-Folder -TargetFolder $RootFolder -RootCounter $RootCounter -RootCount $RootCount
        $Folders = $Folders + $FolderResults
        $RootCounter ++
    }
    $TotalDuration = 0
    ForEach ($Duration in $TotalTime) {
        $TotalDuration = $TotalDuration + $Duration
        Write-Color -Text "Total Duration: ", ("{0:hh\:mm\:ss}" -f $TotalDuration) -Color White, Yellow
    }
    Return $FolderResults
}
$TotalTime = @()
Clear-Host
$ErrorActionPreference = "SilentlyContinue"

$Results = Gather-Information -TargetFolder "C:\"
$Results | Out-File c:\temp\files.txt -Encoding ascii -Force
Notepad c:\temp\files.txt