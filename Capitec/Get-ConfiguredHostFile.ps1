Function Get-ConfiguredHosts {
    # Define the path to the hosts file
    $filePath = "C:\windows\system32\drivers\etc\hosts"

    $Hosts = @()
    # Read and filter the hosts file
    Get-Content -Path $filePath | ForEach-Object {
        # Skip lines starting with '#' (comments) or empty lines
        if ($_ -notmatch "^\s*#|^\s*$") {
            # Use regex to match and split IP and hostname
            if ($_ -match "^\s*(\d{1,3}(\.\d{1,3}){3}|::1)\s+(\S+)") {
                # Output the matched IP and hostname
                $Hosts += ,($matches[1] + " " + $matches[3])
            }
        }
    }
    Return $Hosts -join ';'
}