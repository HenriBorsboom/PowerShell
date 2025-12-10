Clear-Host
$File = 'C:\Users\t333119\desktop\servers.txt'
$Active = $True
While ($Active -eq $True) {
    #Write-Host "Active - " -NoNewline
    Try {
        $Exists = Get-Process netdom -ErrorAction Stop
        $Active = $True
    }
    Catch {
        $Active = $False
    }
    $Details = Get-Content $File
    $Item1 = ($Details.Item(($Details.Length - 2)))
    $Time  = (Get-Date).ToShortTimeString()
    Write-Host "Item 1: $Item1 - Time: $Time" -ForegroundColor Yellow
    #Write-Host "Sleeping 5 seconds"
    Sleep 60
}