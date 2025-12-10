$Path = "c:\users\"

Function GetUserProfiles
{
    Remove-Item "c:\users\users.csv" -ErrorAction SilentlyContinue
    Get-ChildItem $Path | Where-Object {$_.Mode -match "d"} | select Name | Export-Csv -NoTypeInformation -NoClobber "c:\users\users.csv" -Force 
}

Function DeleteExtensions
{
    Param(
            [Parameter(Mandatory=$True,Position=1)]
            [string] $Extension
         )
    
    GetUserProfiles
    $Profiles = Get-Content "c:\users\users.csv"

    foreach ($Profile in $Profiles)
    {
        if ($Profile -ne '"Name"' -and $Profile -ne '"@To be deleted"')
        {
            $CorrectProfile = $Profile.Remove(0,1)
            $CorrectProfile = $CorrectProfile.remove($CorrectProfile.Length -1 , 1)
        
            $LogFiles = Get-ChildItem $BuildPath -Recurse -Name $Extension -Force -ErrorAction SilentlyContinue
            if ($LogFiles -ne $null){
                Foreach ($Log in $Logfiles) 
                {
                    $OutputObj  = New-Object -Type PSObject
                    
                    $File = $BuildPath + [string] $Log
                    Try
                    {
                        Remove-Item $File -ErrorAction Stop -Force
                        $OutputObj | Add-Member -MemberType NoteProperty -Name Profile -Value $CorrectProfile
                        $OutputObj | Add-Member -MemberType NoteProperty -Name LOGFile -Value $Log
                        $OutputObj | Add-Member -MemberType NoteProperty -Name Extension -Value $Extension
                        $OutputObj | Add-Member -MemberType NoteProperty -Name Deleted -Value "Yes"
                    }
                    Catch
                    {
                        $OutputObj | Add-Member -MemberType NoteProperty -Name Profile -Value $CorrectProfile
                        $OutputObj | Add-Member -MemberType NoteProperty -Name LOGFile -Value $Log
                        $OutputObj | Add-Member -MemberType NoteProperty -Name Extension -Value $Extension
                        $OutputObj | Add-Member -MemberType NoteProperty -Name Deleted -Value "No"
                    }
                    $OutputObj
                }
            }
            Else
            {
                Write-Host "No $Extension files found under $CorrectProfile" -ForegroundColor Green
            }
        }
    } 
}

Function DeleteTempFilesAndFolders
{
    $Profiles = Get-Content "c:\users\users.csv"

    foreach ($Profile in $Profiles)
    {
        $OutputObj  = New-Object -Type PSObject
        if ($Profile -ne '"Name"' -and $Profile -ne '"@To be deleted"')
        {
            $CorrectProfile = $Profile.Remove(0,1)
            $CorrectProfile = $CorrectProfile.remove($CorrectProfile.Length -1 , 1)
        
            $buildpath = ".\" + $CorrectProfile + "\AppData\Local\Temp"
            Try
            {
                Remove-Item -Path $buildpath -Recurse -ErrorAction SilentlyContinue            
                $OutputObj | Add-Member -MemberType NoteProperty -Name Profile -Value $CorrectProfile
                $OutputObj | Add-Member -MemberType NoteProperty -Name Path -Value $buildpath
                $OutputObj | Add-Member -MemberType NoteProperty -Name Deleted -Value "Yes"
            }
            Catch
            {
                $OutputObj | Add-Member -MemberType NoteProperty -Name Profile -Value $CorrectProfile
                $OutputObj | Add-Member -MemberType NoteProperty -Name Path -Value $buildpath
                $OutputObj | Add-Member -MemberType NoteProperty -Name Deleted -Value "No"
            }
        }
    } 
}

DeleteExtensions -Extension "*.log"
DeleteExtensions -Extension "*.DB"
DeleteExtensions -Extension "*.dmp"
DeleteTempFilesAndFolders