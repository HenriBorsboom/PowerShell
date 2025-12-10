Clear-Host

$Web = @(
        "WEBSERVER101", `
        "WEBSERVER102", `
        "WEBSERVER103", `
        "WEBSERVER104", `
        "WEBSERVER105", `
        "WEBSERVER106", `
        "WEBSERVER107", `
        "WEBSERVER108")

ForEach ($Server in $Web)
{
    Write-Host "Processing $Server - " -NoNewline
    $Path = "\\" + $Server + "\C$\InetPub"
    $Results = Ls $Path -Recurse | Where-Object {$_.Mode -match "d"} | Select Name
    ForEach ($Item in $Results)
    {
        [String] $OutputItem = $Item
        $OutputItem = $OutputItem.Remove(0, 7)
        $OutputItem = $OutputItem.Remove($OutputItem.Length -1, 1)

        $Output = New-Object PSObject
        $Output | Add-Member -MemberType NoteProperty -Name Server -Value $Server
        $Output | Add-Member -MemberType NoteProperty -Name Item -Value $OutputItem
        $Output | Export-Csv Folders.csv -NoClobber -NoTypeInformation -Append -Force        
    }
    Write-Host "Complete" -ForegroundColor Green
}
