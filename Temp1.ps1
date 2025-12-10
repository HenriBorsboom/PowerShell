$Computers = @("NRAZUREAPP108","NRAZUREAPP109","NRAZUREAPP110","NRAZUREAPP111")
foreach ($Computer in $Computers)
{

    [string] $DestComputer = $Computer
    #$DestComputer = $DestComputer.Remove(0, 7)
    #$DestComputer = $DestComputer.Remove(($DestComputer.Length) - 1, 1)
    If ($DestComputer -ne "NRAZUREAPP210" -or $DestComputer -ne "NRAZUREAPP212")
    {
        $File = "C:\windows\system32\drivers\etc\hosts"
        $Path = "c$\windows\system32\drivers\etc"
    
        $Dest = "\\" + $DestComputer + "\" + $Path
        Try
        {
            copy-item $File -Destination $Dest -Force
            sleep (1)
            Write-Host "Copied $File to \\$DestComputer\$Path"
        }
        Catch
        {
            Write-Host "Could not copy $File to \\$DestComputer\$Path" -ForegroundColor Red
        }
    }
}