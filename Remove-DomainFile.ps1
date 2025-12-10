#Remove-Item "\\APPSERVER101\C$\Users\username\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Windows Update.lnk"

Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string] $File, `
    [Parameter(Mandatory=$True,Position=2)]
    [string] $Path)

#Import-Module ActiveDirectory
$Computers = Get-Content "c:\temp\computers.txt"
foreach ($Computer in $Computers)
{

    [string] $DestComputer = $Computer
        $Dest = "\\" + $DestComputer + "\" + $Path + "\" + $File
        Try
        {
            
            Remove-Item $Dest
            #sleep (1)
            Write-Host "Removed $File on \\$DestComputer\$Path" -ErrorAction Stop
        }
        Catch
        {
            Write-Host "Could not remove $File at \\$DestComputer\$Path" -ForegroundColor Red
        }
    #}
}
