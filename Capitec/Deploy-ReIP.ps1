$ErrorActionPreference = 'Stop'
#$Servers = @()
[Object[]] $Servers = Import-Csv D:\Henri\Deploy_ReIP_Servers.txt -Delimiter ';'

$OutFile = ('C:\Temp\Henri\ReIP\ReIPResult - ' + (Get-Date).ToString('yyyy-MM-dd HH-mm-ss') + '.csv')
"Logs" | Out-File $OutFile -Encoding ascii -Force
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i].VM)
    (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i].VM) | Out-File $OutFile -Encoding ascii -Append
    Try {
        If (Test-Path ('\\' + $Servers[$i].VM + '\D$\Apps\CapTools\Scripts')) {
            Write-Host '|- Directory exists'
            '|- Directory exists' | Out-File $OutFile -Encoding ascii -Append
        }
        Else {
            New-Item ('\\' + $Servers[$i].VM + '\D$\Apps\CapTools\Scripts') -ItemType Directory
            Write-Host '|- Directory created'
            '|- Directory created' | Out-File $OutFile -Encoding ascii -Append
        }
        
        Invoke-Command $Servers[$i].VM -ScriptBlock {Set-ExecutionPolicy -ExecutionPolicy Bypass}
        Write-Host '|- Execution Policy set'
        '|- Execution Policy set' | Out-File $OutFile -Encoding ascii -Append
        Copy-Item -LiteralPath 'C:\Temp\Henri\WNIP\WNIP.ps1' -Destination ('\\' + $Servers[$i].VM + '\D$\Apps\CapTools\Scripts') -Force
        Write-Host '|- Script copied'
        '|- Script copied' | Out-File $OutFile -Encoding ascii -Append
        Copy-Item -LiteralPath 'C:\Temp\Henri\WNIP\Windows Network IP Profile.xml' -Destination ('\\' + $Servers[$i].VM + '\D$\Apps\CapTools\Scripts') -Force
        Write-Host '|- Task copied'
        '|- Task copied' | Out-File $OutFile -Encoding ascii -Append
        Invoke-Command -ComputerName $Servers[$i].VM -ScriptBlock {
            Register-ScheduledTask -Xml (Get-Content "D:\Apps\Captools\Scripts\Windows Network IP Profile.xml" | Out-String) -TaskName "Windows Network IP Profile"
        }
        Write-Host '|- Task registered'
        '|- Task registered' | Out-File $OutFile -Encoding ascii -Append
        Invoke-Command $Servers[$i].VM -ArgumentList ($Servers[$i].'BLIS IP', $Servers[$i].'BLIS Subnet', $Servers[$i].'BLIS Gateway', (($Servers[$i].'BLIS DNS1', $Servers[$i].'BLIS DNS2', $Servers[$i].'BLIS DNS3') -join ','), $Servers[$i].'BFTC IP', $Servers[$i].'BFTC Subnet', $Servers[$i].'BFTC Gateway', (($Servers[$i].'BFTC DNS1', $Servers[$i].'BFTC DNS2', $Servers[$i].'BFTC DNS3') -join ',')) -ScriptBlock {
            Param (
                $BLISIP,
                $BLISSubnetMask,
                $BLISGateway,
                $BLISDNS,
                $BFTCIP,
                $BFTCSubnetMask,
                $BFTCGateway,
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

        #region BLIS
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
            Set-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'SubnetMask' -Value $BLISSubnetMask
        }
        Catch {
            New-ItemProperty HKLM:\Software\WNIP\BLIS -Name 'SubnetMask' -Value $BLISSubnetMask -PropertyType String
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
        #endregion
        #region BFTC
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
            Set-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'SubnetMask' -Value $BFTCSubnetMask
        }
        Catch {
            New-ItemProperty HKLM:\Software\WNIP\BFTC -Name 'SubnetMask' -Value $BFTCSubnetMask -PropertyType String
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
        Write-Host '|- Registry keys created'
        #endregion
        '|- Registry keys created' | Out-File $OutFile -Encoding ascii -Append
    }
    Catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
        $_ | Out-File $OutFile -Encoding ascii -Append
    }
}