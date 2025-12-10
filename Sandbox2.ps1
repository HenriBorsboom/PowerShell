Clear-Host
$Test2 = Get-Content 'C:\temp\InstalledApplications\NRAPCAPP201 - 23.01.27 - 15-09-2015.CSV'
#$x = 1
#ForEach ($Item in $Test1) {
#    Write-Host "Test $x - " -NoNewline
#    Write-Host $Item -NoNewline
#    Write-Host " - End"
#    $x ++
#}


$Starters = New-Object psobject -Property @{"Server" = 0; "Name" = 0; "Version" = 0;}
ForEach ($Item in $Test2) {
    #Try {
        If ($Item -ne "" -and $Item -notlike "*-*") {
        If ($Item.Trim().SubString(0, $Item.Trim().IndexOf(" ")) -eq "Server") {
            $Starters.Name = $Item.indexof("Name");
            $Starters.Version = $Item.indexof("Version");
            Continue;
        }
        #$Starters.Name; Break
        #$Item.Substring($Item.IndexOf(" ", $Starters.Name), $Starters.Version - $Item.IndexOf("  ", $Starters.Name) + 2).trim();
        #Break
        New-Object psobject -Property @{
            "Server" = $Item.trim().substring(0, $Item.trim().indexof(" ")).trim(">");
            "Name" = $Item.Substring($Starters.Name, $Item.IndexOf("  ", $Starters.Name) - $Starters.Name);
            "Version" = $Item.Substring($Item.IndexOf(" ", $Starters.Name), $Starters.Version - $Item.IndexOf(" ", $Starters.Name) + 2).trim();
        }
        }
    #} 
    #Catch {
    #    $e = $_;
    #    Write-Log "ERROR: " + $e.PSMessageDetails
    #}
}