Function Set-Registry {
    Param (
        $Server,
        $BLISIP,
        $BLISGateway,
        $BLISSubnet,
        $BLISDNS,
        $BFTCIP,
        $BFTCGateway,
        $BFTCSubnet,
        $BFTCDNS
    )
    Invoke-Command -ComputerName $Server -ArgumentList $BLISIP, $BLISGateway, $BLISSubnet, $BLISDNS, $BFTCIP, $BFTCGateway, $BFTCSubnet, $BFTCDNS -ScriptBlock {
       Param (
        $Server,
        $BLISIP,
        $BLISGateway,
        $BLISSubnet,
        $BLISDNS,
        $BFTCIP,
        $BFTCGateway,
        $BFTCSubnet,
        $BFTCDNS
    )    
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
            Set-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'IP' -Value $BLISIP
        }
        Catch {
            New-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'IP' -Value $BLISIP -PropertyType String
        }
        Try {
            Get-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'SubnetMask'
            Set-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'SubnetMask' -Value $BLISSubnet
        }
        Catch {
            New-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'SubnetMask' -Value $BLISSubnet -PropertyType String
        }
        Try {
            Get-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'Gateway'
            Set-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'Gateway' -Value $BLISGateway
        }
        Catch {
            New-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'Gateway' -Value $BLISGateway -PropertyType String
        }
        Try {
            Get-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'DNS'
            Set-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'DNS' -Value $BLISDNS
        }
        Catch {
            New-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'DNS' -Value $BLISDNS -PropertyType String
        }

        # Create BFTC IP configuration
        Try {
            Get-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'IP'
            Set-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'IP' -Value $BFTCIP
        }
        Catch {
            New-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'IP' -Value $BFTCIP -PropertyType String
        }
        Try {
            Get-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'SubnetMask'
            Set-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'SubnetMask' -Value $BFTCSubnet
        }
        Catch {
            New-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'SubnetMask' -Value $BFTCSubnet -PropertyType String
        }
        Try {
            Get-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'Gateway'
            Set-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'Gateway' -Value $BFTCGateway
        }
        Catch {
            New-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'Gateway' -Value $BFTCGateway -PropertyType String
        }
        Try {
            Get-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'DNS'
            Set-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'DNS' -Value $BFTCDNS
        }
        Catch {
            New-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'DNS' -Value $BFTCDNS -PropertyType String
        }
    }
}
Set-Registry -Server $Servers[0].VM -BLISIP $Servers[0].BLISIP -BLISGateway $Servers[0].BLISGateway -BLISSubnet $Servers[0].BLISSubnetMask -BLISDNS $Servers[0].BLISDNS -BFTCIP $Servers[0].BFTCIP -BFTCGateway $Servers[0].BFTCGateway -BFTCSubnet $Servers[0].BFTCSubnetMask -BFTCDNS $Servers[0].BFTCDNS