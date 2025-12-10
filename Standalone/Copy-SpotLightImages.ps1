Function Write-Color {    
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $Color, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)
    $ErrorActionPreference = "Stop"
    Try {
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $Color[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch {
        Write-Error $_ 
    }
}
Function Wait {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Int64] $Duration)

    For ($Tick = 0; $Tick -lt $Duration; $Tick ++) {
        Write-Host "." -NoNewline
        Sleep 1
    }
    Write-Host ""
}
Function Copy-SpotlightImages {
    #copy all of the  items from today to C:\temp\Spotlight
    $Files = Get-ChildItem $SpotLightPath 
    ForEach ( $File in $Files ) {
        $Image = [System.Drawing.Image]::FromFile($File.FullName)
        if (($Image.Width -gt "1900") -and ($File.LastWriteTime -gt (Get-Date).ToShortDateString() )) { 
            Copy-Item $File.FullName -Destination $SpotLightTempPath -ErrorAction SilentlyContinue; 
            $TotalCopied ++
        }
    }
    Return $TotalCopied
}
Function Rename-SpotlightFiles {
    #rename all of the files
    $CopiedFiles = Get-ChildItem $SpotLightTempPath -Exclude "Older" 
    ForEach ($CopiedFile in $CopiedFiles) {
        $NewName = $CopiedFile.FullName + ".jpg"
        Rename-Item $CopiedFile.FullName -NewName $NewName -ErrorAction SilentlyContinue
    }
}
Function Move-OldSpotLightFiles {
    #move all of the older files
    $OlderFiles = Get-ChildItem  $SpotLightTempPath -Exclude "Older" 
    ForEach ($OldFile in $OlderFiles) {
        If ( $OldFile.LastWriteTime -lt (Get-Date).ToShortDateString() ) {
            Move-Item $OldFile.FullName $SpotLightOlderTempPath -ErrorAction SilentlyContinue
            $TotalMoved ++
        }
    }
    Return $TotalMoved
}
Function Move-ToPicturesFolder {
    $ImageFiles = Get-ChildItem $SpotLightTempPath -Exclude "Older"
    ForEach ($Image in $ImageFiles) { Move-Item $Image.FullName $MyPicturesFolder -ErrorAction SilentlyContinue; $MyPictures ++}
}
Function Start-SpotlightCopy {
    Add-Type -Path "C:\WINDOWS\Microsoft.NET\Framework\v4.0.30319\System.Drawing.dll"
    $TotalCopied = Copy-SpotlightImages
    Rename-SpotlightFiles
    $TotalMoved = Move-OldSpotLightFiles
    Move-ToPicturesFolder
    Write-Color -Text "A total of ", $TotalCopied, " new images were copied into the ", $SpotLightTempPath, " folder" -Color White, Green, White, Yellow, White
    Write-Color -Text "A total of ", $TotalMoved, " images were moved into the ", $SpotLightOlderTempPath, " folder" -Color White, Yellow, White, Yellow, White
    Write-Color -Text "A total of ", $MyPictures, " images were moved into the ", $MyPicturesFolder, " folder" -Color White, Yellow, White, Yellow, White
    Wait 5
}
#region Variables
    $SpotLightPath          = "$env:userprofile\AppData\Local\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets"
    $SpotLightTempPath      = "C:\temp\Spotlight"
    $SpotLightOlderTempPath = "C:\temp\Spotlight\Older"
    $MyPicturesFolder       = "C:\Users\henri\Pictures\Backgrounds"
    $TotalMoved             = 0
    $TotalCopied            = 0
    $MyPictures             = 0

#endregion
Start-SpotlightCopy