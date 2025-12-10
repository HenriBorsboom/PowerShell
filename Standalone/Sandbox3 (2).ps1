Clear-Host

#$AvailableNetworks     = @()
$AvailableNetworks     = @{}
$WirelessNetworks      = NetSH WLAN Show Networks Mode=Bssid 
ForEach ($Line in $WirelessNetworks) {
    If ($Line -match '^SSID (\d+) : (.*)$') {
        $CurrentItem        = @{}
        $AvailableNetworks += $CurrentItem
        $CurrentItem.Index  = $matches[1].trim()
        $CurrentItem.SSID   = $matches[2].trim()
    } 
    Else {
        If ($Line -match '^\s+(.*)\s+:\s+(.*)\s*$') {
            $CurrentItem[$matches[1].trim()] = $matches[2].trim()
        }
    }
}
#$AvailableNetworks | % { new-object psobject -property $_ } | Ft index, ssid, signal, 'radio type' -AutoSize
$column1 = @{expression="Other rates (Mbps)"}
$column2 = @{expression="Encryption"}
$column3 = @{expression="Network type"}
$column4 = @{expression="Basic rates (Mbps)"}
$column5 = @{expression="Signal"}
$column6 = @{expression="Index"}
$column7 = @{expression="Channel"}
$column8 = @{expression="SSID"}
$column9 = @{expression="BSSID 1"}
$column10 = @{expression="Radio type"}
$column11 = @{expression="Authentication"}

$AvailableNetworks | ft $column1, $column2, $column3, $column4, $column5, $column6, $column7, $column8, $column9, $column10, $column11