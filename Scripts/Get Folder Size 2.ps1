Function Delete-LastLine {
    Param (
        [Parameter(Mandatory = $false)]
        [Switch] $SameLine)
    $x = [Console]::CursorLeft
    $y = [Console]::CursorTop
    Switch ($SameLine) {
        $true {
            [Console]::SetCursorPosition($x,$y)
            Write-Host "                                                                                                                                            "
            [Console]::SetCursorPosition($x,$y)
        }
        $False {
            [Console]::SetCursorPosition($x,$y - 1)
            Write-Host "                                                                                                                                            "
            [Console]::SetCursorPosition($x,$y - 1)
        }
    }
}
Function Timer {
    Param(
        [Parameter(Mandatory=$true, Position = 1)]
        [Int64] $StartCount)

    $Duration = New-TimeSpan -Seconds($x)
    $s = $Duration.TotalSeconds
    $ts =  [timespan]::fromseconds($s)
    $ReturnVariable = ("{0:hh\:mm\:ss}" -f $ts)
    Return $ReturnVariable
}
Function JobUpdate {
    Param (
        [Parameter(Mandatory=$true, Position = 1)]
        [Int64] $StartCounter, `
        [Parameter(Mandatory=$false, Position = 2)]
        [Switch] $FinalUpdate)
    $Counter = Timer -StartCount $StartCounter
    Write-Host "Getting folders in " -NoNewline
    Write-Host $startFolder -ForegroundColor Yellow -NoNewline
    Write-Host " - " -NoNewline
    Write-Host $Counter -ForegroundColor Red
    Write-Host " - " -NoNewline
    Sleep 1
    Delete-LastLine -SameLine
    #Switch ($FinalUpdate) {$false {Delete-LastLine}}
}

Clear-Host
Get-Job | Remove-Job
Remove-Item C:\temp\foldersize.csv -Force -ErrorAction SilentlyContinue
$ErrorActionPreference = "SilentlyContinue"
$StartFolder = "C:\"
$x = 1
$GetChildItemJob = Start-Job -Name "Folders" -ScriptBlock {Param($Target); Get-ChildItem $Target -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_.PSIsContainer -eq $True} | Sort-Object} -ArgumentList $StartFolder -ErrorAction Stop
$GetChildItemJobState = Get-Job $GetChildItemJob.Id
While ($GetChildItemJobState.State -eq "Running") {
    JobUpdate -StartCounter $x
    $x ++
}
$GetChildItemJobResults = Receive-Job -Job $GetChildItemJob
#JobUpdate -StartCounter $x -FinalUpdate
Write-Host "Complete" -ForegroundColor Green
$x = 1
ForEach ($Folder in $GetChildItemJobResults) {
        $SubFolderItems = (Get-ChildItem $Folder.FullName | Measure-Object -Property Length -Sum)
        $Result = "{0:N2}" -f ($SubFolderItems.sum / 1MB)
        $Output = $Folder.FullName + ";" + $Result
        $Output | Out-File C:\temp\foldersize.csv -Append -Encoding ascii -Force
        $Output
}
