$Files = LS
$ReplaceString = " For Free On 123Moviesto"
For ($i = 0; $i -lt $Files.Count; $i ++) {
    If ($Files[$i].Name.Contains($ReplaceString)) {
        Rename-Item $Files[$i].Name -NewName ($Files[$i].Name.Replace($ReplaceString, ""))
    }
    Else {
        Write-Host "Not Found"
    }
}