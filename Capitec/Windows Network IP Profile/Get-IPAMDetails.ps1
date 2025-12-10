param (
    $Server
)
Function Get-IPAddresses {
    Param (
        $Server
    )
    $IPs = Get-IpamAddress -AddressFamily IPv4 | Where-Object Description -like "*$server*"
    If ($null -eq $IPs) {
        Return $null
    }
    ElseIf ($IPs.Count -eq 2) {
        Return $IPs
    }
    Else {
        Return $False
    }
}
Function Get-Subnet-Gateway {
    Param (
        $StartIP,
        $EndIP
    )
    $Range = Get-IpamRange -StartIPAddress $StartIP -EndIPAddress $EndIP
    $NetworkID = $Range.NetworkID.Split('/')[1]
    $Gateway = ($Range.Gateway -split '/')[0]
    $SubnetMask = $Range.SubnetMask
    Return (New-Object -TypeName PSObject -Property @{
        NetworkID = $NetworkID
        Gateway = $Gateway
        SubnetMask = $SubnetMask
    })
}
$IPs = Get-IPAddresses -Server $Server

If ($null -eq $IPs) {
    Write-Host "No IPs found" -ForegroundColor Red
}
ElseIf ($IPs.Count -eq 2) {
    $Details = @()
    For ($i = 0; $i -lt $IPs.Count; $i ++) {
        $SubnetDetails = (Get-Subnet-Gateway -StartIP ($IPs[$i].IPRange -split '-')[0] -EndIP ($IPs[$i].IPRange -split '-')[1])
        $Details += ,(New-Object -TypeName PSObject -Property @{
            IP = $IPs[$i].IpAddress
            NetworkID = $SubnetDetails.NetworkID
            Gateway = $SubnetDetails.Gateway
            SubnetMask = $SubnetDetails.Subnetmask
        })
    }
}
Else {
    Write-Host "Too many IPs found" -ForegroundColor Red
}
$Details