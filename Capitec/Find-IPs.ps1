$Range = '10.224.5.'
$StartIP = 1  # Replace with the starting IP address of your range
$EndIP = 254  # Replace with the ending IP address of your range

$availableIPs = @()

for ($i = $startIP; $i -le $EndIP; $i++) {
    $IP = ($Range + $i.ToString())
    Write-Host "Testing $IP"
    if (Test-Connection -ComputerName $IP -Count 1 -Quiet) {
        Write-Host "Unavailable" -ForegroundColor Red
    }
    Else {
        Write-Host "Available" -ForegroundColor Green
        $availableIPs += $ip
    }
}

if ($availableIPs) {
    Write-Host "Available IPs:"
    $availableIPs
} else {
    Write-Host "No available IPs found in the specified range."
}