Clear-Host
Write-Host "Getting Servers from AD - " -NoNewline
    $Servers = Get-ADComputer -Filter {Name -like "NRAZ*"}
    $Servers = $Servers | Sort Name
    $Servers = $Servers | Select -Unique
    $Servers = $Servers.Name
    $ExcludeList = Get-Content C:\temp\Computers\Exclude.TXT
    $ServerCounter = 1
    $ServerCount = $Servers.Count
Write-Host "Complete" -ForegroundColor Green -NoNewline
Write-Host " - " -NoNewline
Write-Host "$ServerCount servers found" -ForegroundColor Yellow

ForEach ($Server in $Servers) {
    Write-Host "$ServerCounter/$ServerCount" -NoNewline -ForegroundColor Cyan
    If ($ExcludeList -notcontains $Server) {
        Write-Host " - Copying files from " -NoNewline
        Write-Host $Server -ForegroundColor Yellow -NoNewline
        Write-Host " - " -NoNewline
            $Source = "\\" + $Server + "\c$\users\username\Desktop\"
            $Destination = "C:\Temp\Desktops\" + $Server
            $Empty = New-Item $Destination -ItemType Directory -Force
            $GetChildItemJob = Start-Job -Name "Copy" -ArgumentList $Source,$Destination -ScriptBlock {Param($Source,$Destination); Copy-Item $Source -Destination $Destination -Recurse} -ErrorAction Stop
            $GetChildItemJobState = Get-Job $GetChildItemJob.Id
            If ($GetChildItemJobState.State -ne "Running") { Write-Host "Error" -ForegroundColor Red; Receive-Job -Job $GetChildItemJob; Exit 1}
            While ($GetChildItemJobState.State -eq "Running") {
                Write-Host "." -NoNewline -ForegroundColor Cyan
                Sleep 3
                $x ++
            }
            $GetChildItemJobResults = Receive-Job -Job $GetChildItemJob
        Write-Host " - " -NoNewline
        Write-Host "Complete" -ForegroundColor Green
        
    }
    Else {
        Write-Host " - " -NoNewline
        Write-Host "$Server" -ForegroundColor Yellow -NoNewline
        Write-Host " - " -NoNewline
        Write-Host "Skipped" -ForegroundColor Red
    }
    $ServerCounter ++
}
