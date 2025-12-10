Clear-Host

$VMS = Get-Content "C:\Temp\computers.txt"

ForEach ($Server in $VMS)
{
    #$Server = "APPSERVER101"
    $FullPath = "\\" + $Server + "\C$\Windows\System32\WindowsPowerShell\v1.0\Modules\PSWindowsUpdate"

    $Source = "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\PSWindowsUpdate"
    Write-Host "Copying to $server - " -NoNewline
    Try
    {
        Copy-Item $Source -Destination $FullPath -Recurse -force -ErrorAction Stop
        Write-Host " Complete" -ForegroundColor Green
    }
    Catch
    {
        Write-Host " Failed" -ForegroundColor Red
    }
}

