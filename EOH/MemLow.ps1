Param (
    [Parameter(Mandatory=$True, Position=1)]
    [String] $Server, `
    [Parameter(Mandatory=$False, Position=2)]
    [Switch] $ShowServers)

Function ResetSession {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Int] $SessionID)

    Reset Session $SessionID /server:$Global:Server
}
$MemlowServersFile = ($env:TEMP) + "\MemlowServers.txt"
If (Test-Path $MemlowServersFile) {
    $AllServers = Get-Content $MemlowServersFile
}
Else {
    $AllServers = @()
}
Switch ($ShowServers) {
    $True { $AllServers }
    $False {
        $AllServers += $Server
        $Global:Server = $Server

        Query Session /Server:$Global:Server

        Write-Host "Amount of sessions to reset? " -ForegroundColor Yellow -NoNewline
        $QuestionReset = Read-Host
        If ($QuestionReset -gt 0) {
            For ($i = 0; $i -lt $QuestionReset; $i ++) {
                ResetSession -SessionID (Read-Host "Session ID")
            }
        }

        Write-Host "Do you want to RDP to the server? " -ForegroundColor Yellow -NoNewline
        $QuestionRDP = Read-Host
        If ($QuestionRDP.ToString().ToLower() -eq "y") {
            mstsc /v:$Global:Server
        }
        Remove-Item $MemlowServersFile
        $AllServers | Out-File $MemlowServersFile -Encoding ascii -Force -NoClobber
    }
}