$Path = "c:\users\"
Function RemoveUsersReference
{
    Remove-Item "c:\users\users.csv" -ErrorAction SilentlyContinue
}

Function DeleteLogs
{
    Write-Host "Gathering LOG files in USERS"
    $LogFiles = Get-ChildItem -Recurse -Path $Path -Name "*.log" -Force -ErrorAction SilentlyContinue
    Write-Host "      Deleting LOG files in USERS" -ForegroundColor Green
    if ($LogFiles -ne $null){
        Foreach ($Log in $Logfiles) 
        {
            $File = $Path + [string] $Log
            Try{Remove-Item $file -exclude "*com.ibm.collaboration.realtime.login*" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue}Catch{}
        }
    }
    Else
    {
        Write-Host "No LOG files found under USERS" -ForegroundColor Green
    }
}

Function DeleteDB
{
    Write-Host "Gathering DB files in USERS"
    $profiles = Get-ChildItem -Path $path -Directory
    foreach ($profile in $profiles)
    {
        if ($profile -ne "All Users")
        {
            $DBFiles = Try{Get-ChildItem -Recurse -Path $profile -Name "*.db" -Force -ErrorAction SilentlyContinue}Catch{Write-host "      Unable to gather DB files on $Profile" -ForegroundColor Red}
            if ($DBFiles -ne $null)
            {
                Write-Host "      Deleting DB Files in $Profile" -ForegroundColor Green
                foreach ($DB in $DBFiles)
                {
                    Try{Remove-Item $DB -WarningAction SilentlyContinue -ErrorAction SilentlyContinue}Catch{}
                }
            }
        }
    }
}

Function DeleteDMP
{
    Write-Host "Gathering DMP files in USERS"
    $DMPFiles = Get-ChildItem -Recurse -Path $Path -Name "*.dmp" -Force -ErrorAction SilentlyContinue
    Write-Host "      Deleting DMP files in USERS" -ForegroundColor Green
    if ($DMPFiles -ne $null) 
    {
        Foreach ($DMP in $DMPFiles)
        {
            $File = $Path + [string] $Log
            Try{Remove-Item $DMP -WarningAction SilentlyContinue -ErrorAction SilentlyContinue}Catch{}
        }
    }
    Else 
    {
        Write-Host "No DMP Files"
    }
}

Function DeleteTempFilesAndFolders
{
    Write-Host "Deleting Temp files and folders"
    Get-ChildItem -path $Path | select name | Export-Csv -NoTypeInformation -NoClobber "c:\users\users.csv"
    $profiles = Get-Content "c:\users\users.csv"
    foreach ($profile in $profiles)
    {
        if ($profile -ne '"Name"' -and $profile -ne '"users.csv"')
        {
        $CorrectProfile = $profile.Remove(0,1)
        $CorrectProfile = $CorrectProfile.remove($correctprofile.Length -1 , 1)
        
        Write-Host "Deleting Temp Files and Folders in $CorrectProfile" -foregroundcolor Green
        
        $buildpath = ".\" + $CorrectProfile + "\AppData\Local\Temp"
        remove-item -Path $buildpath -Recurse -ErrorAction SilentlyContinue
        }
    }
}

RemoveUsersReference
DeleteLogs
DeleteDB
DeleteDMP
DeleteTempFilesAndFolders