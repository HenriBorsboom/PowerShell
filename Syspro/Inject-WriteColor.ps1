Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $File)

Function Inject-WriteColor {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $File)

    $WriteColorText = (
        'Function Write-Color {
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
        }'
        )
    $TempInjection = Get-Content $File -Raw
    ($WriteColorText.ToString() + "`r`n" + $TempInjection.ToString() ) | Out-File $File -Encoding ascii -Force
    Notepad $File
}
Inject-WriteColor -File $File