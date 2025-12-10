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

Function Temp_Storage {
$Destination = "203.0.113.10"
$Port        = 30004
Get-OpenPort -Computer $Destination -Port $Port

$Destination = "203.0.113.11"
$Port        = 30081
Get-OpenPort -Computer $Destination -Port $Port

$Destination = "203.0.113.12"
$Port        = 30071
Get-OpenPort -Computer $Destination -Port $Port

$Destination = "203.0.113.13"
$Port        = 443
Get-OpenPort -Computer $Destination -Port $Port

$Destination = "203.0.113.14"
$Port        = 443
Get-OpenPort -Computer $Destination -Port $Port

$Destination = "203.0.113.15"
$Port        = 443
Get-OpenPort -Computer $Destination -Port $Port

$Destination = "203.0.113.16"
$Port        = 1434
Get-OpenPort -Computer $Destination -Port $Port

$Destination = "203.0.113.17"
$Port        = 3306
Get-OpenPort -Computer $Destination -Port $Port
}