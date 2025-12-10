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
Function Get-TotalTime {
    Param(
        [Parameter(Mandatory = $True,  Position = 1)]
        [DateTime] $StartTime, `
        [Parameter(Mandatory = $True,  Position = 2)]
        [DateTime] $EndTime)

    $Duration = New-TimeSpan -Start $StartTime -End $EndTime

    $TotalSeconds = $Duration.TotalSeconds
    $TimeSpan =  [TimeSpan]::FromSeconds($TotalSeconds)
    $ReturnVariable = ("{0:hh\:mm\:ss}" -f $TimeSpan)
    Return $ReturnVariable
}
Function Start-Windows {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String] $Process)
        
    Write-Color -Text "Starting ", $Process, " - " -ForegroundColor White, Yellow, White -NoNewLine
        $StartTime = Get-Date
        Start-Process -FilePath $Process
        $Duration = Get-TotalTime -StartTime $StartTime -EndTime (Get-Date)
    Write-Color -Text "Complete ", $Duration -ForegroundColor Green, DarkCyan
}

Clear-Host
$Processes = @{
    'Outlook'                = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Office 2013\Outlook 2013.lnk'
    'Skype'                  = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Office 2013\Skype for Business 2015.lnk'
    'Remote Desktop Manager' = 'C:\Program Files (x86)\Microsoft\Remote Desktop Connection Manager\RDCMan.exe'
    'FireFox'                = 'C:\Program Files\Mozilla Firefox\firefox.exe'
    'SCOM'                   = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft System Center 2016\Operations Manager\Operations Console.lnk'
    'BlueStacks'             = 'C:\ProgramData\Microsoft\Windows\Start Menu\BlueStacks.lnk'}

Start-Windows -Process $Processes.'Outlook'
Start-Windows -Process $Processes.'Skype'
Start-Windows -Process $Processes.'Remote Desktop Manager'
Start-Windows -Process $Processes.'FireFox'
Start-Windows -Process $Processes.'SCOM'
Start-Windows -Process $Processes.'BlueStacks'