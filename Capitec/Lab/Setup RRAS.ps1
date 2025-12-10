Function Set-VM {
    # Set Computername
    # Set IP Address
    # Set DNS Server
    # Enable RDP
    Write-Host "Renaming Computer - " -NoNewline
    Rename-Computer -ComputerName $env:computername -NewName LABRRAS2025 | Out-Null
    Write-Host "Complete" -ForegroundColor Green
    
    Write-Host "Disabling IPv6 - " -NoNewline
    Disable-NetAdapterBinding -Name 'Ethernet' -ComponentID 'ms_tcpip6'
    Write-Host "Complete" -ForegroundColor Green

    Write-Host "Enabling RDP - " -NoNewline
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0 | Out-Null
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop" | Out-Null
    Write-Host "Complete" -ForegroundColor Green

    Write-Host "Renaming the network adapter - " -NoNewline
    Rename-NetAdapter -Name 'Ethernet' -NewName 'Public'
    Write-Host "Complete" -ForegroundColor Green

    Write-Host "Disabling Firewall - " -NoNewline
    Netsh advfirewall set allprofiles state off
    Write-Host "Complete" -ForegroundColor Green

    Write-Host "Rebooting"
    Restart-Computer -Force
}
Function Install-Roles {
    Install-WindowsFeature Routing -IncludeManagementTools
    Restart-Computer -Force
}