Function Encrypt-Folder {
    $Folder = 'C:\users\Temp\Temp'
    cd $Folder
    $Files = Get-ChildItem -Path $Folder
    ForEach ($File in $Files) {
        If ($File.Extension -eq ".mp4") {
            $NewName = ""
            For ($i = (($File.BaseName).Length - 1); $i -gt -1; $i --) { $NewName = $NewName + ($File.BaseName).ToString().Chars($i) }
            Rename-Item $File.Name -NewName ($NewName + ".4pm")
        }
        If ($File.Extension -eq ".swf") {
            $NewName = ""
            For ($i = (($File.BaseName).Length - 1); $i -gt -1; $i --) { $NewName = $NewName + ($File.BaseName).ToString().Chars($i) }
            Rename-Item $File.Name -NewName ($NewName + ".fws")
        }
    }
}
Function Decrypt-Folder {
    $Folder = 'C:\users\Temp\Temp'
    cd $Folder
    $Files = Get-ChildItem -Path $Folder
    ForEach ($File in $Files) {
        If ($File.Extension -eq ".4pm") {
            $NewName = ""
            For ($i = (($File.BaseName).Length - 1); $i -gt -1; $i --) { $NewName = $NewName + ($File.BaseName).ToString().Chars($i) }
            Rename-Item $File.Name -NewName ($NewName + ".mp4")
        }
        If ($File.Extension -eq ".fws") {
            $NewName = ""
            For ($i = (($File.BaseName).Length - 1); $i -gt 1; $i --) { $NewName = $NewName + ($File.BaseName).ToString().Chars($i) }
            Rename-Item $File.Name -NewName ($NewName + ".swf")
        }
    }
}

Encrypt-Folder
ls
Read-Host
Decrypt-Folder
ls
Read-Host