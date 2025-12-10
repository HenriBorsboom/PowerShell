#region Variable
$Path = "C:\Users\username\Documents\Scripts"
$WinFolder = "C:\Windows"
#endregion

#region Get Scripts
Write-Host "Getting Scripts in $Path ... " -NoNewline
$Scripts = Get-ChildItem -Path $Path
Write-Host "Done" -ForegroundColor Green
#endregion

#region Copy Scripts
Write-Host "Copying PowerShell Scripts to $WinFolder folder ..."

[Array] $ScriptsCount = $Scripts.Name
Write-Host " Total Scripts to copy: " -NoNewline
Write-Host $ScriptsCount.Count -ForegroundColor Yellow
[int] $x = 1


ForEach ($File in $Scripts)
{
    $CopyFile = $Path + "\" + $File
    Write-host " $x - Copying" -NoNewline
    Write-Host " $File " -ForegroundColor Yellow -NoNewline
    Write-Host "- " -NoNewline
    Try
    {
        Copy-Item -Path $CopyFile -Destination "c:\windows" -Force -Include "*.ps1" -ErrorAction Stop
        Write-Host "Done" -ForegroundColor Green
    }
    Catch
    {
        Write-Host "Failed" -ForegroundColor Red
    }
    $x ++
}
#endregion