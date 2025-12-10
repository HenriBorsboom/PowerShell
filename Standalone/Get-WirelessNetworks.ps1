Function Get-WifiNetwork {
    End {
        NetSH WLAN Show Networks Mode=Bssid | % -process {
            if ($_ -match '^SSID (\d+) : (.*)$') {
                $current = @{}
                $networks += $current
                $current.Index = $matches[1].trim()
                $current.SSID = $matches[2].trim()
            } 
            else {
                if ($_ -match '^\s+(.*)\s+:\s+(.*)\s*$') {
                    $current[$matches[1].trim()] = $matches[2].trim()
                }
            }
        } -begin { 
            $networks = @() 
            } -end { 
                $networks | % { new-object psobject -property $_ } }
    }
}

Get-WifiNetwork | select index, ssid, signal, 'radio type' | sort signal -desc | ft -auto

