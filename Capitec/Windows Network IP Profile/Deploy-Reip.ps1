$ErrorActionPreference = 'Stop'
Clear-Host
[Object[]] $Servers = Import-Csv 'D:\Henri\WNIP\Deploy_ReIP_Servers.txt' -Delimiter ';'
$Servers
Write-Host '----------------------------------------------------------' -ForegroundColor Red
$Correct = Read-Host "PLEASE CONFIRM THAT THE DATA READ FROM THE CSV FILE IS CORRECT (n/y): "

If ($Correct.ToLower() -eq 'y') {
    $OutFile = ('D:\Henri\WNIP\Results\ReIPResult - ' + (Get-Date).ToString('yyyy-MM-dd HH-mm-ss') + '.csv')

    $OutDirectory = Split-Path -Path $OutFile -Parent

    if (-not (Test-Path -Path $OutDirectory)) {
        New-Item -Path $OutDirectory -ItemType Directory -Force | Out-Null
    }

    "Logs" | Out-File $OutFile -Encoding ascii -Force
    For ($i = 0; $i -lt $Servers.Count; $i ++) {
        Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i].VM)
        (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i].VM) | Out-File $OutFile -Encoding ascii -Append
        Try {
            Write-Host '|- Checking if directory exists'
            If (Test-Path ('\\' + $Servers[$i].VM + '\D$\Apps\CapTools\Scripts')) {
                Write-Host '|- Directory exists'
                '|- Directory exists' | Out-File $OutFile -Encoding ascii -Append
            }
            Else {
                New-Item ('\\' + $Servers[$i].VM + '\D$\Apps\CapTools\Scripts') -ItemType Directory
                Write-Host '|- Directory created'
                '|- Directory created' | Out-File $OutFile -Encoding ascii -Append
            }
        
            Write-Host '|- Changing Execution Policy'
            Invoke-Command $Servers[$i].VM -ScriptBlock {Set-ExecutionPolicy -ExecutionPolicy Bypass}
            Write-Host '|- Execution Policy set'
            '|- Execution Policy set' | Out-File $OutFile -Encoding ascii -Append
        
            Write-Host '|- Copying WNIP Script'
            Copy-Item -LiteralPath 'D:\Henri\WNIP\WNIP.ps1' -Destination ('\\' + $Servers[$i].VM + '\D$\Apps\CapTools\Scripts') -Force
            Write-Host '|- Script copied'
            '|- Script copied' | Out-File $OutFile -Encoding ascii -Append

            Write-Host '|- Copying WNIP Scheduled Task'
            Copy-Item -LiteralPath 'D:\Henri\WNIP\Windows Network IP Profile.xml' -Destination ('\\' + $Servers[$i].VM + '\D$\Apps\CapTools\Scripts') -Force
            Write-Host '|- Task copied'
            '|- Task copied' | Out-File $OutFile -Encoding ascii -Append

            Write-Host '|- Setting registry keys'
            Invoke-Command $Servers[$i].VM -ArgumentList ($Servers[$i].'BLISIP', $Servers[$i].'BLISSubnetMask', $Servers[$i].'BLISGateway', $Servers[$i].'BLISDNS', $Servers[$i].'BFTCIP', $Servers[$i].'BFTCSubnetMask', $Servers[$i].'BFTCGateway', $Servers[$i].'BFTCDNS') -ScriptBlock {
                Param (
                    [Parameter(Mandatory=$True, Position=1)]
                    [String] $BLISIP,
                    [Parameter(Mandatory=$True, Position=2)]
                    [String] $BLISSubnetMask,
                    [Parameter(Mandatory=$True, Position=3)]
                    [String] $BLISGateway,
                    [Parameter(Mandatory=$True, Position=4)]
                    [String] $BLISDNS,
                    [Parameter(Mandatory=$True, Position=5)]
                    [String] $BFTCIP,
                    [Parameter(Mandatory=$True, Position=6)]
                    [String] $BFTCSubnetMask,
                    [Parameter(Mandatory=$True, Position=7)]
                    [String] $BFTCGateway,
                    [Parameter(Mandatory=$True, Position=8)]
                    [String] $BFTCDNS
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

            Write-Host "- Checking for and registering task on $($Servers[$i].VM)..."
            Invoke-Command -ComputerName $Servers[$i].VM -ScriptBlock {
                $TaskName = "Windows Network IP Profile"
                $XmlPath = "D:\Apps\Captools\Scripts\Windows Network IP Profile.xml"

                $ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

                if (-not $ExistingTask) {
                    Write-Host "  |- Task '$TaskName' not found. Registering new task..."
                    Register-ScheduledTask -Xml (Get-Content -Path $XmlPath | Out-String) -TaskName $TaskName
                    return "Task '$TaskName' registered successfully."
                }
                else {
                    Write-Host "  |- Task '$TaskName' already exists. Skipping registration."
                    return "Task '$TaskName' already exists."
                }
            }
            '|- Task registered' | Out-File $OutFile -Encoding ascii -Append
        }
        Catch {
            Write-Host $_.Exception.Message -ForegroundColor Red
            $_ | Out-File $OutFile -Encoding ascii -Append
        }
    }
}