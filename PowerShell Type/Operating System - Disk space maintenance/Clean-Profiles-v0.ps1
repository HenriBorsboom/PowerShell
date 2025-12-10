$Path = "c:\users\"

Function GetUserProfiles {
    Remove-Item "c:\users\users.csv" -ErrorAction SilentlyContinue
    Get-ChildItem $Path | Where-Object {$_.Mode -match "d"} | select Name | Export-Csv -NoTypeInformation -NoClobber "c:\users\users.csv" -Force 
}

Function DeleteExtensions {
    Param(
        [Parameter(Mandatory = $True,  Position = 1)]
        [String] $Extension)
    
    GetUserProfiles
    $Profiles = Get-Content "c:\users\users.csv"

    ForEach ($Profile in $Profiles) {
        If (($Profile -ne '"Name"') -and ($Profile -ne '"@To be deleted"')) {
            $CorrectProfile = $Profile.Remove(0,1)
            $CorrectProfile = $CorrectProfile.remove($CorrectProfile.Length -1 , 1)
        
            $LogFiles = Get-ChildItem $BuildPath -Recurse -Name $Extension -Force -ErrorAction SilentlyContinue
            Ff ($LogFiles -ne $null) {
                ForEach ($Log in $Logfiles) {
                    $File = $BuildPath + [string] $Log
                    Try {
                        Remove-Item $File -ErrorAction Stop -Force
                        $OutputObj  = New-Object -Type PSObject -Property @{
                            Profile = $CorrectProfile;
                            LOGFile = $Log;
                            Extension = $Extension;
                            Deleted = "Yes";
                        }
                    }
                    Catch {
                        $OutputObj  = New-Object -Type PSObject -Property @{
                            Profile = $CorrectProfile;
                            LOGFile = $Log;
                            Extension = $Extension;
                            Deleted = "No";
                        }
                    }
                    $OutputObj
                }
            }
            Else { Write-Host "No $Extension files found under $CorrectProfile" -ForegroundColor Green }
        }
    } 
}

Function DeleteTempFilesAndFolders {
    $Profiles = Get-Content "c:\users\users.csv"

    ForEach ($Profile in $Profiles) {
        If ($Profile -ne '"Name"' -and $Profile -ne '"@To be deleted"') {
            $CorrectProfile = $Profile.Remove(0,1)
            $CorrectProfile = $CorrectProfile.remove($CorrectProfile.Length -1 , 1)
        
            $buildpath = ".\" + $CorrectProfile + "\AppData\Local\Temp"
            Try {
                Remove-Item -Path $buildpath -Recurse -ErrorAction SilentlyContinue            
                $OutputObj  = New-Object -Type PSObject @{
                    Profile = $CorrectProfile;
                    Path    = $buildpath;
                    Deleted = "Yes";
                }
            }
            Catch {
                $OutputObj  = New-Object -Type PSObject @{
                    Profile = $CorrectProfile;
                    Path    = $buildpath;
                    Deleted = "No";
                }
            }
        }
    }
}

DeleteExtensions -Extension "*.log"
DeleteExtensions -Extension "*.DB"
DeleteExtensions -Extension "*.dmp"
DeleteTempFilesAndFolders