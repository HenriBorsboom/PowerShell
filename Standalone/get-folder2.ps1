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
Function Start-Thread {
    Param (
        [Parameter(Mandatory=$True,  Position=1)]
        [String] $Path, `
        [Parameter(Mandatory=$True,  Position=2)]
        [Int64] $SourceCounter, `
        [Parameter(Mandatory=$True,  Position=3)]
        [Int64] $SourceCount)
    $StartJob = Start-Job -ArgumentList $Path -ScriptBlock { Param ($Path); Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_.PSIsContainer -eq $True} | Sort-Object } -ErrorAction Stop
    $Timer = 1
    While ((Get-Job -Id $StartJob.Id).State -eq "Running") {
                Update-Thread -TimerValue $Timer -Path $Path -SourceCounter $SourceCounter -SourceCount $SourceCount -FinalUpdate:$False 
                $Timer ++
            }
    Update-Thread -TimerValue $Timer -Path $Path -SourceCounter $SourceCounter -SourceCount $SourceCount -FinalUpdate:$True
    $Job = Receive-Job -Job $StartJob
    $FolderSizes = Receive-Thread -Job $Job -Duration $Timer
    Return $FolderSizes    
}
Function Process-Duration {
    Param (
        [Parameter(Mandatory=$True,  Position=1)]
        [Object[]] $Folders)

    $TotalDuration = 0
    ForEach ($Folder in $Folders) {
        If ($Folder -like "Duration: *") {
            [Int64] $Duration = $Folder.Remove(0, 10)
            $TotalDuration = $TotalDuration + $Duration
        }
    }
    Return $TotalDuration
}
Function Receive-Thread {
    Param (
        [Parameter(Mandatory=$True,  Position=1)]
        [Object] $Job, `
        [Parameter(Mandatory=$True,  Position=2)]
        [Int64] $Duration)
Function Format-Size {
    Param (
            [Parameter(Mandatory=$True,  Position=1)]
            [String] $Path)

    $SubFolders     = (Get-ChildItem -Path $Path -Recurse | Measure-Object -Property Length -Sum)
    $FolderSize     = "{0:N2}" -f ($SubFolders.sum / 1MB)
    $FormatSize     = $FolderSize + " --- " + $Path
    Return $FormatSize
}
    #c$ReceiveJob = Receive-Job -Job $Job
    $FolderSizes = @()
    ForEach ($Folder in $Job) {
            $FolderSize = Format-Size -Path $Folder.FullName
            $FolderSizes = $FolderSizes + $FolderSize
            Write-Host "." -NoNewline
    }
    Return $FolderSizes
    #endregion
}
Function Update-Thread {
    Param (
        [Parameter(Mandatory=$True,  Position=1)]
        [Int64] $TimerValue, `
        [Parameter(Mandatory=$True,  Position=2)]
        [String] $Path, `
        [Parameter(Mandatory=$True,  Position=3)]
        [Int64] $SourceCounter, `
        [Parameter(Mandatory=$True,  Position=4)]
        [Int64] $SourceCount, `
        [Parameter(Mandatory=$False, Position=5)]
        [Switch] $FinalUpdate)
    
    $ThreadCounter = ("{0:hh\:mm\:ss}" -f ([TimeSpan]::FromSeconds(((New-TimeSpan -Seconds($TimerValue)).TotalSeconds))))
    Write-Color -Text "$SourceCounter/$SourceCount", " - Getting folders in ", $Path, " - ", $ThreadCounter -Color Cyan, White, Yellow, White, Red -EndLine:$True
    Sleep 1
    Switch ($FinalUpdate) {
        $False { Delete-LastLine }
    }
}
Function Gather-Information {
    Param (
        [Parameter(Mandatory=$True,  Position=1)]
        [String] $Path)

    $TotalSize      = @()
    $Folders        = Get-ChildItem -Path $Path
    $FolderCounter  = 1
    $FolderCount    = $Folders.Count
    Write-Color -Text "Total Folders: ", $FolderCount -Color White, Yellow -EndLine:$True
    ForEach ($Folder in $Folders.FullName) {
        $FolderSize = Start-Thread -Path $Folder -SourceCounter $FolderCounter -SourceCount $FolderCount
        $TotalSize  = $TotalSize + $FolderSize
        $FolderCounter ++
    }
    $TotalDuration  = Process-Duration -Folders $TotalSize
    Write-Host "Exporting to TXT - " -NoNewline
        $TotalSize | Out-File "c:\temp\Files.txt" -Encoding ascii
    Write-Host "Complete" -ForegroundColor Green
    Write-Host $TotalSize
    $TotalDuration | Out-File "c:\temp\Files.txt" -Encoding ascii -Append
    Write-Color -Text "Total Duration: ", $TotalDuration -Color White, Yellow
}
$ErrorActionPreference = "Stop"
Clear-Host
Gather-Information -Path "c:\"