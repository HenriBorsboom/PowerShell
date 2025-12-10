$Path = "c:\users\"
Function GetUserProfiles
{
    Remove-Item "c:\users\users.csv" -ErrorAction SilentlyContinue
    Get-ChildItem $Path | Where-Object {$_.Mode -match "d"} | select Name | Export-Csv -NoTypeInformation -NoClobber "c:\users\users.csv" -Force
}

Function DeleteLogs
{
    Clear-Host
    $Profiles = Get-Content "c:\users\users.csv"

    foreach ($Profile in $Profiles)
    {
        if ($Profile -ne '"Name"' -and $Profile -ne '"@To be deleted"')
        {
            $CorrectProfile = $Profile.Remove(0,1)
            $CorrectProfile = $CorrectProfile.remove($CorrectProfile.Length -1 , 1)
        
            Write-Host "Retrieving LOG Files in $CorrectProfile - " -NoNewline
            $LogFiles = Get-ChildItem $BuildPath -Recurse -Name "*.log" -Force -ErrorAction SilentlyContinue
            Write-Host "Complete" -ForegroundColor Green -NoNewline

            Write-Host " - Removing LOG Files in $CorrectProfile - " -NoNewline
            if ($LogFiles -ne $null){
                Foreach ($Log in $Logfiles) 
                {
                    $File = $BuildPath + [string] $Log
                    Try{Remove-Item $File -ErrorAction Stop}Catch{}
                }
                Write-Host "Complete" -ForegroundColor Green
            }
            Else
            {
                Write-Host "No LOG files found under $CorrectProfile" -ForegroundColor Green
            }
        }
    } 
}

Function DeleteDB
{
    Clear-Host
    $Profiles = Get-Content "c:\users\users.csv"

    foreach ($Profile in $Profiles)
    {
        if ($Profile -ne '"Name"' -and $Profile -ne '"@To be deleted"')
        {
            $CorrectProfile = $Profile.Remove(0,1)
            $CorrectProfile = $CorrectProfile.remove($CorrectProfile.Length -1 , 1)
        
            Write-Host "Retrieving DB Files in $CorrectProfile - " -NoNewline
            $LogFiles = Get-ChildItem $BuildPath -Recurse -Name "*.DB" -Force -ErrorAction SilentlyContinue
            Write-Host "Complete" -ForegroundColor Green -NoNewline

            Write-Host " - Removing DB Files in $CorrectProfile - " -NoNewline
            if ($LogFiles -ne $null){
                Foreach ($Log in $Logfiles) 
                {
                    $File = $BuildPath + [string] $Log
                    Try{Remove-Item $File -ErrorAction Stop}Catch{}
                }
                Write-Host "Complete" -ForegroundColor Green
            }
            Else
            {
                Write-Host "No DB files found under $CorrectProfile" -ForegroundColor Green
            }
        }
    } 
}

Function DeleteDMP
{
    Clear-Host
    $Profiles = Get-Content "c:\users\users.csv"

    foreach ($Profile in $Profiles)
    {
        if ($Profile -ne '"Name"' -and $Profile -ne '"@To be deleted"')
        {
            $CorrectProfile = $Profile.Remove(0,1)
            $CorrectProfile = $CorrectProfile.remove($CorrectProfile.Length -1 , 1)
        
            Write-Host "Retrieving DMP Files in $CorrectProfile - " -NoNewline
            $LogFiles = Get-ChildItem $BuildPath -Recurse -Name "*.DMP" -Force -ErrorAction SilentlyContinue
            Write-Host "Complete" -ForegroundColor Green -NoNewline

            Write-Host " - Removing DMP Files in $CorrectProfile - " -NoNewline
            if ($LogFiles -ne $null){
                Foreach ($Log in $Logfiles) 
                {
                    $File = $BuildPath + [string] $Log
                    Try{Remove-Item $File -ErrorAction Stop}Catch{}
                }
                Write-Host "Complete" -ForegroundColor Green
            }
            Else
            {
                Write-Host "No DMP files found under $CorrectProfile" -ForegroundColor Green
            }
        }
    } 
}

Function DeleteTempFilesAndFolders
{
    Clear-Host
    $Profiles = Get-Content "c:\users\users.csv"

    foreach ($Profile in $Profiles)
    {
        if ($Profile -ne '"Name"' -and $Profile -ne '"@To be deleted"')
        {
            $CorrectProfile = $Profile.Remove(0,1)
            $CorrectProfile = $CorrectProfile.remove($CorrectProfile.Length -1 , 1)
        
            Write-Host "Retrieving DMP Files in $CorrectProfile - " -NoNewline
            $buildpath = ".\" + $CorrectProfile + "\AppData\Local\Temp"
            remove-item -Path $buildpath -Recurse -ErrorAction SilentlyContinue            
            Write-Host "Complete" -ForegroundColor Green -NoNewline
        }
    } 
}

GetUserProfiles
DeleteLogs
DeleteDB
DeleteDMP
DeleteTempFilesAndFolders
