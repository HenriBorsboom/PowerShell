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
Function Zip-SYSPRO {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $SourceFolder, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $TargetFolder)
    
    $New_Zip = {
        Param ($ZipFileName, $SourceDirectory)
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $CompressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
        [System.IO.Compression.ZipFile]::CreateFromDirectory($SourceDirectory, $ZipFileName, $CompressionLevel, $false)
    }

    Start-Job -ScriptBlock $New_Zip -ArgumentList $TargetFolder, $SourceFolder | Out-Null

    While ((Get-Job).State -eq "Running") {
        Write-Host "-" -NoNewline -ForegroundColor DarkYellow
        Sleep 1
    }
    If ((Get-Job).State -eq "Completed") { Write-Host " Complete" -ForegroundColor Green }
    Else                                 { Write-Host (" " + (Get-Job).State) -ForegroundColor Red }
    Get-Job | Remove-Job
}

Clear-Host
$SourceFolder = 'C:\SYSPRO7'
$TargetFolder = 'E:\SYSPRO_Backup\SYSPRO7 - ' + '{0:dd-MM-yyyy}' -f (Get-Date) + '.zip'

Write-Color -Text "Compressing ", $SourceFolder, " to ", $TargetFolder, " " -ForegroundColor White, DarkCyan, White, DarkCyan, White -NoNewLine
Zip-SYSPRO -SourceFolder $SourceFolder -TargetFolder $TargetFolder
Write-Color -Text "Complete" -ForegroundColor Green