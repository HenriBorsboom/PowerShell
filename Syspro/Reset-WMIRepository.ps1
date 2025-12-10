Function Write-Color {
            Param(
                [Parameter(Mandatory = $True  , Position = 1)]
                [String[]]       $Text, `
                [Parameter(Mandatory = $True  , Position = 2)]
                [ConsoleColor[]] $ForegroundColor, `
                [Parameter(Mandatory = $False , Position = 3)]
                [Switch]           $NoNewLine)

            $ErrorActionPreference = "Stop"
            Try {
                If ($Text.Count -ne $ForegroundColor.Count) {
                    Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $ForegroundColor.Count.ToString()) -ForegroundColor Red
                    Throw
                }
                For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                    Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
                }
                Switch ($NoNewLine){
                    $True  { Write-Host -NoNewline }
                    $False { Write-Host }
                }
            }
            Catch { 
                Write-Host "Text Count:  " $Text.Count
                Write-Host "Color Count: " $ForegroundColor.Count
                Write-Host $_
            }
        }
Clear-Host

$Service        = "Winmgmt"

$RegEXE         = ($Env:SystemRoot + "\" + "System32\RegSVR32.exe")
$DLLPath        = ($Env:SystemRoot + "\" + "System32\WBEM\*.dll")
$DLLFiles       = (Get-ChildItem $DLLPath -Recurse).FullName

$MOFEXE         = ($Env:SystemRoot + "\" + "System32\WBEM\mofcomp.exe")
$MOFPath        = ($Env:SystemRoot + "\" + "System32\WBEM\*.mof")

$AutoRecoverPath = ($Env:SystemRoot + "\" + "System32\WBEM\AutoRecover")
$AutoFilePath    = ($Env:SystemRoot + "\" + "System32\WBEM\AutoRecover\*.mof")

$RepositoryPath = ($Env:SystemRoot + "\" + "System32\WBEM\Repository")
$RepositoryNew  = ($RepositoryPath + ".old.001")

Write-Host "Disabling $Service"
Set-Service Winmgmt -StartupType Disabled
Write-Host "Stopping $Service"
Stop-Service Winmgmt -Force

Write-Host "Renaming Repository Folder"
Rename-Item $RepositoryPath -NewName ($RepositoryPath + ".old.001")

Write-Host "Moving AutoRecover folder to $env:TEMP"
Move-Item -Path $AutoRecoverPath -Destination $Env:Temp -Force

For ($i = 0; $i -lt $DLLFiles.Count; $i ++) {
    $File = $DLLFiles[$i]
    Write-Host (("{0:D3}" -f ($i + 1)).ToString() + "/" + $DLLFiles.Count.ToString() + " - Registering DLL: " + $DLLFiles[$i])
    Invoke-Expression "$RegEXE /s $File"
}

$MOFFiles        = (Get-ChildItem $MOFPath -Recurse).FullName

Write-Host "Enabling $Service"
Set-Service Winmgmt -StartupType Automatic
Write-Host "Starting $Service"
Start-Service Winmgmt

For ($i = 0; $i -lt $MOFFiles.Count; $i ++) {
    $File = $MOFFiles[$i]
    Write-Host (("{0:D3}" -f ($i + 1)).ToString() + "/" + $MOFFiles.Count.ToString() + " - Compiling MOF: " + $File)
    Invoke-Expression "$MOFEXE $File"
}
$AutoFiles       = (Get-ChildItem $AutoFilePath -Recurse).FullName
For ($i = 0; $i -lt $AutoFiles.Count; $i ++) {
    $File = $AutoFiles[$i]
    Write-Host (("{0:D3}" -f ($i + 1)).ToString() + "/" + $AutoFiles.Count.ToString() + " - Compiling AutoRecover MOF: " + $File)
    Invoke-Expression "$MOFEXE $File"
}
