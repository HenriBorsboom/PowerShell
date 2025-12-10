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
Function Get-ImageDetails {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $SourceFolder)

    Write-Color -Text "Getting Files in ", $SourceFolder, " - " -ForegroundColor White, Cyan, White -NoNewLine
        $Files = Get-ChildItem $SourceFolder
    Write-Color -Text ($Files.Count).ToString(), " Found" -ForegroundColor Green, White
    
    $Length         = $Files.Count.ToString().Length
    $ImageDetails   = @()
    For ($i = 0; $i -lt $Files.Count; $i ++) {
        Write-Color -Text (("{0:D$Length}" -f ($i + 1)).ToString() + "/" + $Files.Count.ToString()), " - Processing details for ", $Files[$i].FullName, " - " -ForegroundColor Magenta, White, Cyan, White -NoNewLine
        $Image = [System.Drawing.Image]::FromFile($Files[$i].FullName)
        $ImageDetails += ,(New-Object -TypeName PSObject -Property @{
            FileName  = $Files[$i].FullName
            Width     = $Image.Width
            Height    = $Image.Height
        })
        Write-Color -Text "Complete" -ForegroundColor Green
    }
    Return $ImageDetails
}
Function Rename-Images {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $Images)

    $ImagesCount = $Images.Count
    $ImagesLength = $ImagesCount.ToString().Length
    For ($i = 0; $i -lt $ImagesCount; $i ++) {
        Write-Color -Text (("{0:D$ImagesLength}" -f ($i + 1)).ToString() + "/" + $ImagesCount.ToString()), " - Renaming ", $Images[$i].FileName, " - " -ForegroundColor Cyan, White, Yellow, White -NoNewLine
        $NewName = ("[" + ("{0:D$ImagesLength}" -f ($i + 1)).ToString() + "] - Car - " + $Images[$i].Width.ToString() + "x" + $Images[$i].Height.ToString() + $Images[$i].FileName.Substring(($Images[$i].FileName.Length -4)))
        Try {
            Rename-Item -Path $Images[$i].FileName -NewName $NewName
            Write-Color -Text "Success" -ForegroundColor Green
        }
        Catch {
            Write-Color -Text "Failed - $_" -ForegroundColor Red
        }
    }
}

$ErrorActionPreference = 'Stop'
Clear-Host

$Folder = 'C:\Users\Henri.Borsboom\Downloads\Imgur Album - Car Wallpapers Collection'

$Images = Get-ImageDetails -SourceFolder $Folder
Rename-Images -Images $Images