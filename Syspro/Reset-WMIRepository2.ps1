Function Action-Service {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet("Start", "Stop")]
        [String] $Action)

    Switch ($Action) {
        "Start" {
            Write-Host "Enabling $Service"
                Set-Service Winmgmt -StartupType Automatic
            Write-Host "Starting $Service"
                Start-Service Winmgmt
        }
        "Stop" {
            Write-Host "Disabling $Service"
                Set-Service Winmgmt -StartupType Disabled
            Write-Host "Stopping $Service"
                Stop-Service Winmgmt -Force
        }
    }

}
Function Rename-Repository {
    Write-Host "Renaming Repository Folder"
        $RepositoryPath = ($Env:SystemRoot + "\" + "System32\WBEM\Repository")
        $RepositoryNew  = ($RepositoryPath + ".old.001")
        Rename-Item $RepositoryPath -NewName ($RepositoryPath + ".old.001")
}
Function Move-AutoRecover {
    Write-Host "Moving AutoRecover folder to $env:TEMP"
        $AutoRecoverPath = ($Env:SystemRoot + "\" + "System32\WBEM\AutoRecover")
        Move-Item -Path $AutoRecoverPath -Destination $Env:Temp -Force
}
Function Register-DLL {
    $RegEXE         = ($Env:SystemRoot + "\" + "System32\RegSVR32.exe")
    $DLLPath        = ($Env:SystemRoot + "\" + "System32\WBEM\*.dll")
    $DLLFiles       = (Get-ChildItem $DLLPath -Recurse).FullName
    For ($i = 0; $i -lt $DLLFiles.Count; $i ++) {
        $File = $DLLFiles[$i]
        Write-Host (("{0:D3}" -f ($i + 1)).ToString() + "/" + $DLLFiles.Count.ToString() + " - Registering DLL: " + $DLLFiles[$i])
        Invoke-Expression "$RegEXE /s $File"
    }
}
Function Compile-MOF {
    $MOFEXE         = ($Env:SystemRoot + "\" + "System32\WBEM\mofcomp.exe")
    $MOFPath        = ($Env:SystemRoot + "\" + "System32\WBEM\*.mof")
    $MOFFiles       = (Get-ChildItem $MOFPath -Recurse).FullName

    For ($i = 0; $i -lt $MOFFiles.Count; $i ++) {
        $File = $MOFFiles[$i]
        Write-Host (("{0:D3}" -f ($i + 1)).ToString() + "/" + $MOFFiles.Count.ToString() + " - Compiling MOF: " + $File)
        Invoke-Expression "$MOFEXE $File"
    }
}
Function Compile-AutoRecover {
    $AutoFilePath    = ($Env:SystemRoot + "\" + "System32\WBEM\AutoRecover\*.mof")
    $AutoFiles       = (Get-ChildItem $AutoFilePath -Recurse).FullName
    For ($i = 0; $i -lt $AutoFiles.Count; $i ++) {
        $File = $AutoFiles[$i]
        Write-Host (("{0:D3}" -f ($i + 1)).ToString() + "/" + $AutoFiles.Count.ToString() + " - Compiling AutoRecover MOF: " + $File)
        Invoke-Expression "$MOFEXE $File"
    }
}
Clear-Host

$Service        = "Winmgmt"
Action-Service -Action Stop
Rename-Repository
Move-AutoRecover
Register-DLL
Register-MOF
Action-Service -Action Start
Compile-mof
Compile-AutoRecover