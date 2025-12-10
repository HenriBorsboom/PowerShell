# 'HKEY_LOCAL_MACHINE\SOFTWARE\WNIP
$ErrorActionPreference = 'Stop'

# Create Registry folder structure
If (-not (Test-Path HKLM:\Software\WNIP)) {
    New-Item HKLM:\Software\WNIP -ItemType Directory
}
If (-not (Test-Path HKLM:\Software\WNIP\BLIS)) {
    New-Item HKLM:\Software\WNIP\BLIS -ItemType Directory
}
If (-not (Test-Path HKLM:\Software\WNIP\BFTC)) {
    New-Item HKLM:\Software\WNIP\BFTC -ItemType Directory
}

# Create BLIS IP configuration
Try {
    Get-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'IP'
    Set-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'IP' -Value '10.224.50.191'
}
Catch {
    New-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'IP' -Value '10.224.50.190' -PropertyType String
}
Try {
    Get-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'SubnetMask'
    Set-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'SubnetMask' -Value '255.255.255.0'
}
Catch {
    New-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'SubnetMask' -Value '255.255.255.0' -PropertyType String
}
Try {
    Get-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'Gateway'
    Set-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'Gateway' -Value '10.224.50.1'
}
Catch {
    New-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'Gateway' -Value '10.224.50.1' -PropertyType String
}
Try {
    Get-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'DNS'
    Set-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'DNS' -Value '10.224.106.200,10.224.106.201'
}
Catch {
    New-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'DNS' -Value '10.224.106.200,10.224.106.201' -PropertyType String
}

# Create BFTC IP configuration
Try {
    Get-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'IP'
    Set-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'IP' -Value '10.224.57.16'
}
Catch {
    New-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'IP' -Value '10.224.57.16' -PropertyType String
}
Try {
    Get-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'SubnetMask'
    Set-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'SubnetMask' -Value '255.255.255.0'
}
Catch {
    New-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'SubnetMask' -Value '255.255.255.0' -PropertyType String
}
Try {
    Get-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'Gateway'
    Set-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'Gateway' -Value '10.224.57.1'
}
Catch {
    New-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'Gateway' -Value '10.224.57.1' -PropertyType String
}
Try {
    Get-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'DNS'
    Set-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'DNS' -Value '10.224.106.201,10.224.106.200'
}
Catch {
    New-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'DNS' -Value '10.224.106.201,10.224.106.200' -PropertyType String
}