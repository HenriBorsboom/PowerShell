Param (
    [Parameter(Mandatory=$true,Position=1)]
    [Bool] $Continues, `
    [Parameter(Mandatory=$true,Position=2)]
    [Int64] $PauseDuration, `
    [Parameter(Mandatory=$false,Position=2)]
    [Int64] $LoopCount)

Switch ($Continues) {
    $true {
        For ($x = 1; $x -lt 1000000; $x ++) {
            .\Read-AzureLogs-Multi.ps1
            Write-Host "------------- Pause -------------" -ForegroundColor Yellow
            Write-Host "-------------- $PauseDuration ---------------" -ForegroundColor Yellow
            Write-Host "--------------- $x ---------------" -ForegroundColor Yellow
            Sleep $PauseDuration
        }
    }
    $false {
        For ($x = 1; $x -lt ($LoopCount +1); $x ++) {
           .\Read-AzureLogs-Multi.ps1
            Write-Host "------------- Pause -------------" -ForegroundColor Yellow
            Sleep $PauseDuration
        }
    }
}