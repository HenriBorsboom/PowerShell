Function Clear-BranchCache {
    Netsh branchcache flush
}
Function Clear-SpecificUserFolder {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Path, `
        [Parameter(Mandatory=$False, Position=2)]
        [Switch] $Force = $False
    )

    $Profiles = Get-ChildItem 'C:\Users'
    For ($i = 0; $i -lt $Profiles.Count; $i ++) {
        Write-Host (($i + 1).ToString() + '/' + $Profiles.Count.ToString() + ' - Processing ' + $Profiles[$i].BaseName)
        Switch ($Force) {
            $True {
                Get-ChildItem ($Profiles[$i].FullName + '\' + $Path) -Recurse | Remove-Item -Force
            }
            $False {
                Get-ChildItem ($Profiles[$i].FullName + '\' + $Path) -Recurse | Remove-Item
            }
        }
    }
}

Function Get-ProfilesLastAccessTimes {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $AllowedDate = (Get-Date).AddYears(-1)
    )
    $Profiles = Get-ChildItem 'C:\Users' | Where-Object LastAccessTime -lt $AllowedDate
    $Profiles.BaseName
}
Function Clear-Image {
    Dism /Online /Cleanup-Image /StartComponentCleanup
}
Function Clear-CrashDumps {
    $Users = Get-ChildItem C:\Users

    For ($i = 0; $i -lt $Users.Count; $i ++) {
        Write-host (($i + 1).ToString() + '/' + $Users.Count.ToString() + ' - Processing ' + $Users[$i].BaseName + ' - ') -NoNewline
        If (Test-Path ($Users[$i].FullName + '\AppData\Local\CrashDumps')) {
            Write-Host 'Deleting files in CrashDumps' -ForegroundColor Green
            Get-ChildItem ($Users[$i].FullName + '\AppData\Local\CrashDumps') | Remove-Item
        }
        Else {
            Write-Host 'No CrashDumps located'
        }
    }
}