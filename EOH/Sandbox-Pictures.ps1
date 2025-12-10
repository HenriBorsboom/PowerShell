$ErrorActionPreference = 'Stop'
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
Function Process-Images {
    $Folder = 'C:\Users\Henri.Borsboom\Pictures\Backgrounds'
    $SmallFolder = 'C:\Users\Henri.Borsboom\Pictures\Below 1366'
    $LargeFolder = 'C:\Users\Henri.Borsboom\Pictures\Above 1920'
    $ImageDetails = @()
    Write-Color -Text "Getting Files in ", $Folder, " - " -ForegroundColor White, Cyan, White -NoNewLine
        $Files = Get-ChildItem $Folder
    Write-Color -Text ($Files.Count).ToString(), " Found" -ForegroundColor Green, White
    $Length = $Files.Count.ToString().Length
    $SmallMoveCount = 0
    $LargeMoveCount = 0
    $LargeFiles = @()
    $SmallFiles = @()
    For ($i = 0; $i -lt $Files.Count; $i ++) {
        Write-Color -Text (("{0:D$Length}" -f ($i + 1)).ToString() + "/" + $Files.Count.ToString()), " - Processing details for ", $Files[$i].FullName, " - " -ForegroundColor Magenta, White, Cyan, White -NoNewLine
        $Image = [System.Drawing.Image]::FromFile($Files[$i].FullName)
        <#
        If ($Image.Width -lt 1366) {
            $SmallMoveCount ++
            $SmallFiles += ,(New-Object -TypeName PSObject -Property @{
                FileName  = $Files[$i].FullName
                Width     = $Image.Width
                Height    = $Image.Height
            })
            Remove-Variable Image
            Write-Color -Text ("[" + $SmallMoveCount.ToString() + "]"), " Small Copying" -ForegroundColor Yellow, Yellow -NoNewLine
            Try { Copy-Item $Files[$i].FullName -Destination $SmallFolder -Force -ErrorAction Stop; Write-Color -Text " - Success" -ForegroundColor Green }
            Catch { Write-Color -Text " - Failed" -ForegroundColor Red }
        
        }
        ElseIf ($Image.Width -gt 1920) {
            $LargeMoveCount ++
            Write-Color -Text ("[" + $LargeMoveCount.ToString() + "]"), " Small Copying" -ForegroundColor Yellow, Yellow -NoNewLine
            Try { Copy-Item $Files[$i].FullName -Destination $LargeFolder -Force -ErrorAction Stop; Write-Color -Text " - Success" -ForegroundColor Green }
            Catch { Write-Color -Text " - Failed" -ForegroundColor Red }
            $LargeFiles += ,(New-Object -TypeName PSObject -Property @{
                FileName  = $Files[$i].FullName
                Width     = $Image.Width
                Height    = $Image.Height
            })
        }
        Else {
            Write-Color -Text "Skipping" -ForegroundColor Green
        }
        #>
        $ImageDetails += ,(New-Object -TypeName PSObject -Property @{
            FileName  = $Files[$i].FullName
            Width     = $Image.Width
            Height    = $Image.Height
        })
        Write-Color -Text "Complete" -ForegroundColor Green
    }
    #Read-Host "Continue"
    #$ImageDetails | Select FileName, Width, Height | Format-Table -AutoSize
    Return $ImageDetails
}
Clear-Host
$Images = Process-Images
$ImagesCount = $Images.Count
$ImagesLength = $ImagesCount.ToString().Length
$WrongFiles = ls
For ($i = 0; $i -lt $WrongFiles.Count; $i ++) {
    Write-Color -Text (("{0:D$ImagesLength}" -f ($i + 1)).ToString() + "/" + $ImagesCount.ToString()), " - Renaming ", $Images[$i].FileName, " - " -ForegroundColor Cyan, White, Yellow, White -NoNewLine
    $NewName = ("[" + ("{0:D$ImagesLength}" -f ($i + 1)).ToString() + "] - " + $Images[$i].Width.ToString() + "x" + $Images[$i].Height.ToString() + $Images[$i].FileName.Substring(($Images[$i].FileName.Length -4)))
    Try {
        Rename-Item -Path $WrongFiles[$i].FullName -NewName $NewName
        #Rename-Item -Path $Images[$i].FileName -NewName $NewName
        Write-Color -Text "Success" -ForegroundColor Green
    }
    Catch {
        Write-Color -Text "Failed - $_" -ForegroundColor Red
    }
}