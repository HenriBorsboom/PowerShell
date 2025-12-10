Function Set-VM {
    # Set Computername
    # Set IP Address
    # Set DNS Server
    # Enable RDP
    Write-Host "Renaming Computer - " -NoNewline
    Rename-Computer -ComputerName $env:computername -NewName LABAD2025 | Out-Null
    Write-Host "Complete" -ForegroundColor Green
    
    Write-Host "Disabling IPv6 - " -NoNewline
    Disable-NetAdapterBinding -Name 'Ethernet' -ComponentID 'ms_tcpip6'
    Write-Host "Complete" -ForegroundColor Green

    Write-Host "Setting IP address - " -NoNewline
    New-NetIPAddress -IPAddress 10.0.0.2 -DefaultGateway 10.0.0.1 -AddressFamily IPv4 -PrefixLength 24 -InterfaceIndex ((Get-NetAdapter | Select-Object ifIndex).Ifindex) | Out-Null
    Write-Host "Complete" -ForegroundColor Green

    Write-Host "Setting DNS Server - " -NoNewline
    Set-DnsClientServerAddress -ServerAddresses 10.0.0.2 -InterfaceIndex ((Get-NetAdapter | Select-Object ifIndex).Ifindex) | Out-Null
    Write-Host "Complete" -ForegroundColor Green

    Write-Host "Enabling RDP - " -NoNewline
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0 | Out-Null
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop" | Out-Null
    Write-Host "Complete" -ForegroundColor Green

    Write-Host "Rebooting"
    Restart-Computer -Force
}
Function Install-DCRoles {
    # install ADDS
    # Install DNS
    # Install DHCP
    $Roles = @()
    $Roles += ,('AD-Domain-Services')
    $Roles += ,('DHCP')
    $Roles += ,('DNS')
    Install-WindowsFeature -Name $Roles -IncludeManagementTools
}
Function Set-DC {
    # Promote to DC
    Import-Module ADDSDeployment
    Install-ADDSForest `
        -CreateDnsDelegation:$false `
        -DatabasePath "C:\WINDOWS\NTDS" `
        -DomainMode "Win2025" `
        -DomainName "lab.local" `
        -DomainNetbiosName "LAB" `
        -ForestMode "Win2025" `
        -InstallDns:$true `
        -LogPath "C:\WINDOWS\NTDS" `
        -NoRebootOnCompletion:$false `
        -SysvolPath "C:\WINDOWS\SYSVOL" `
        -Force:$true 
}
Function Set-DNS {
    Write-Host "Configuring DNS - " -NoNewline
    Set-DnsClientServerAddress -ServerAddresses 10.0.0.2 -InterfaceIndex ((Get-NetAdapter | Select-Object ifIndex).Ifindex)
    Write-Host "Complete" -ForegroundColor Green
}
Function Install-DHCP {
    # Authorize DHCP
    # Create Scope
    Write-Host "Authorizing DHCP Server - " -NoNewline
    Add-DhcpServerInDC
    Write-Host "Complete" -ForegroundColor Green

    Write-Host "Creating DHCP Scope - " -NoNewline
    Add-DhcpServerv4Scope -Name "Lab Network" -StartRange 10.0.0.10 -EndRange 10.0.0.100 -SubnetMask 255.255.255.0
    Write-Host "Complete" -ForegroundColor Green

    Write-Host "Adding router, DNS, domain options - " -NoNewline
    Set-DhcpServerv4OptionValue -ScopeID 10.0.0.0 -DnsServer 10.0.0.2 -DnsDomain "lab.local" -Router 10.0.0.1
    Write-Host "Complete" -ForegroundColor Green
}
Function Install-DNS {
    # Create Reverse Lookup Zone
    Write-Host "Setting up reverse DNS - " -NoNewline
    Add-DnsServerPrimaryZone -NetworkID "10.0.0.0/24" -ReplicationScope "Forest"
    Write-Host "Complete" -ForegroundColor Green
}
Function Set-OUs {
    # Create Lab OU
    # Create Computers OU
    #   Create Servers OU
    #   Create Workstations OU
    # Create Users OU
    #   Create Groups OU
    #   Create GMSA OU
    #   Create DMSA OU
    # Create Admins Group
    # Make Admins member of Domain Admins
    # Create RDP Users group
    # Make RDP Users member of Remote Desktop Users group
    # Create Admin1
    # Add Admin1 to Admins and RDP Users group
    
    New-ADOrganizationalUnit -Name "Lab" -Path "DC=lab,DC=local"
    New-ADOrganizationalUnit -Name "Computers" -Path "OU=Lab,DC=lab,DC=local"
    New-ADOrganizationalUnit -Name "Servers" -Path "OU=Computers,OU=Lab,DC=lab,DC=local"
    New-ADOrganizationalUnit -Name "Workstations" -Path "OU=Computers,OU=Lab,DC=lab,DC=local"
    New-ADOrganizationalUnit -Name "Users" -Path "OU=Lab,DC=lab,DC=local"
    New-ADOrganizationalUnit -Name "Users" -Path "OU=Users,OU=Lab,DC=lab,DC=local"
    New-ADOrganizationalUnit -Name "Groups" -Path "OU=Users,OU=Lab,DC=lab,DC=local"
    New-ADOrganizationalUnit -Name "GMSA" -Path "OU=Users,OU=Lab,DC=lab,DC=local"
    New-ADOrganizationalUnit -Name "DMSA" -Path "OU=Users,OU=Lab,DC=lab,DC=local"
    New-ADOrganizationalUnit -Name "Admins" -Path "OU=Users,OU=Lab,DC=lab,DC=local"

    New-ADGroup -DisplayName "Admins" -GroupScope Global -GroupCategory Security -Name "Admins" -Path "OU=Groups,OU=Users,OU=Lab,DC=lab,DC=local"
    New-ADGroup -DisplayName "RDP Users" -GroupScope Global -GroupCategory Security -Name "RDP Users" -Path "OU=Groups,OU=Users,OU=Lab,DC=lab,DC=local"

    Add-ADGroupMember -Identity 'Remote Desktop Users' -Members 'RDP Users'
    Add-ADGroupMember -Identity 'Domain Admins' -Members 'Admins'

    $Cred = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force
    New-ADUser -AccountPassword $Cred -ChangePasswordAtLogon $false -Description 'Admin 1' -DisplayName 'Admin1' -Enabled $True -Name 'Admin' -Surname '1' -Path 'OU=Admins,OU=Users,OU=Lab,DC=lab,DC=local' -PasswordNeverExpires $True -SamAccountName 'Admin1' -UserPrincipalName 'Admin1@lab.local'
    Add-ADGroupMember -Identity 'Admins' -Members 'Admin1'

    New-ADUser -AccountPassword $Cred -ChangePasswordAtLogon $false -Description 'User 1' -DisplayName 'User1' -Enabled $True -Name 'User' -Surname '1' -Path 'OU=Users,OU=Users,OU=Lab,DC=lab,DC=local' -PasswordNeverExpires $True -SamAccountName 'User1' -UserPrincipalName 'User1@lab.local'
    Add-ADGroupMember -Identity 'RDP Users' -Members 'User1'

    redircmp OU=Servers,OU=Computers,OU=Lab,DC=lab,DC=local
}
