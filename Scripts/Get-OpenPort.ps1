Function Get-OpenPort {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [string] $Computer, `
        [Parameter(Mandatory=$true,Position=2)]
        [string] $Port)

    $Socket = New-Object Net.Sockets.TcpClient
    $ErrorActionPreference = 'SilentlyContinue'
    $Socket.Connect($Computer, $Port)
        
    # Make error messages visible again
    $ErrorActionPreference = 'Continue'
    
    # Determine if we are connected.
    if ($Socket.Connected) {
        Write-Host "${Computer}" -ForegroundColor Cyan -NoNewline
        Write-Host ": Port " -NoNewline
        Write-Host "$Port" -ForegroundColor Cyan -NoNewline
        Write-Host " is open" -ForegroundColor Green
        $Socket.Close()
    }
    else {
        Write-Host "${Computer}" -ForegroundColor Cyan -NoNewline
        Write-Host ": Port "-NoNewline
        Write-Host "$Port" -ForegroundColor Cyan -NoNewline
        Write-Host " is closed or filtered" -ForegroundColor Red
    }
        
    # Apparently resetting the variable between iterations is necessary.
    $Socket = $null
}

$Destination = "bcxazure-adfs.domain1.local"
$Port        = 443
Get-OpenPort -Computer $Destination -Port $Port
