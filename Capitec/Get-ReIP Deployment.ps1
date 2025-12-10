$ErrorActionPreference = 'Stop'
[Object[]] $Servers = Import-Csv D:\Henri\Deploy_ReIP_Servers.txt -Delimiter ';'
# Create D:\Apps\Captools\Scripts
# Confirm that Execution Policy is unrestricted/Bypass
# Copy WNIP.ps1 to server
# Import Scheduled Task to server
# Set Registry Keys
$OutFile = 'C:\Temp\Henri\ReIP\ReIPAuditResult.csv'
"Logs" | Out-File $OutFile -Encoding ascii -Force
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i].VM)
    (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i].VM) | Out-File $OutFile -Encoding ascii -Append
    Try {
        If (Test-Path ('\\' + $Servers[$i].VM + '\D$\Apps\CapTools\Scripts\WNIP.ps1')) {
            Write-Host '|- Directory and file exists'
            '|- Directory and file exists' | Out-File $OutFile -Encoding ascii -Append
        }
        Else {
            Write-Host '|- Directory or file does not exist' -ForegroundColor Red
            '|- Directory or file does not exist' | Out-File $OutFile -Encoding ascii -Append
        }
        If (Test-Path ('\\' + $Servers[0].VM + '\C$\Windows\System32\Tasks\Windows Network IP Profile')) {
            Write-Host '|- Task registered'
            '|- Task registered' | Out-File $OutFile -Encoding ascii -Append
        }
        Else {
            Write-Host '|- Task does not exist' -ForegroundColor Red
            '|- Task does not exist' | Out-File $OutFile -Encoding ascii -Append
        }
        
        $hive = [Microsoft.Win32.RegistryHive]::LocalMachine
        $path = "SOFTWARE\WNIP\BFTC"

        $base = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($hive, $Servers[$i].VM)
        $key  = $base.OpenSubKey($path)
        if (!$key) {
            Write-Warning "Registry key '$path' does not exist"
        }
        else {
            ForEach ($Value in $key.GetValueNames()) {
                If ($Value -eq 'IP') {
                    If ($Key.GetValue($Value) -eq $Servers[$i].'BFTC IP') {
                        Write-Host '|- BFTC IP set correctly in registry'
                        '|- BFTC IP set correctly in registry' | Out-File $OutFile -Encoding ascii -Append
                    }
                    Else {
                        Write-Host '|- BFTC IP not set correctly in registry' -ForegroundColor Red
                        '|- BFTC IP set correctly in registry' | Out-File $OutFile -Encoding ascii -Append
                    }
                }
                ElseIf ($Value -eq 'Subnet') {
                    If ($Key.GetValue($Value) -eq $Servers[$i].'BFTC Subnet') {
                        Write-Host '|- BFTC Subnet set correctly in registry'
                        '|- BFTC Subnet set correctly in registry' | Out-File $OutFile -Encoding ascii -Append
                    }
                    Else {
                        Write-Host '|- BFTC Subnet not set correctly in registry' -ForegroundColor Red
                        '|- BFTC Subnet set correctly in registry' | Out-File $OutFile -Encoding ascii -Append
                    }
                }
                ElseIf ($Value -eq 'Gateway') {
                    If ($Key.GetValue($Value) -eq $Servers[$i].'BFTC Gateway') {
                        Write-Host '|- BFTC Gateway set correctly in registry'
                        '|- BFTC Gateway set correctly in registry' | Out-File $OutFile -Encoding ascii -Append
                    }
                    Else {
                        Write-Host '|- BFTC Gateway not set correctly in registry' -ForegroundColor Red
                        '|- BFTC Gateway set correctly in registry' | Out-File $OutFile -Encoding ascii -Append
                    }
                }
                ElseIf ($Value -eq 'DNS') {
                    If ($Key.GetValue($Value) -eq ($Servers[$i].'BFTC DNS1',$Servers[$i].'BFTC DNS2',$Servers[$i].'BFTC DNS3' -join ',')) {
                        Write-Host '|- BFTC DNS set correctly in registry'
                        '|- BFTC DNS set correctly in registry' | Out-File $OutFile -Encoding ascii -Append
                    }
                    Else {
                        Write-Host '|- BFTC DNS not set correctly in registry' -ForegroundColor Red
                        '|- BFTC DNS set correctly in registry' | Out-File $OutFile -Encoding ascii -Append
                    }
                }
            }
        }
        $path = "SOFTWARE\WNIP\BLIS"

        $base = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($hive, $Servers[$i].VM)
        $key  = $base.OpenSubKey($path)
        if (!$key) {
            Write-Warning "Registry key '$path' does not exist"
        }
        else {
            ForEach ($Value in $key.GetValueNames()) {
                If ($Value -eq 'IP') {
                    If ($Key.GetValue($Value) -eq $Servers[$i].'BLIS IP') {
                        Write-Host '|- BLIS IP set correctly in registry'
                        '|- BLIS IP set correctly in registry' | Out-File $OutFile -Encoding ascii -Append
                    }
                    Else {
                        Write-Host '|- BLIS IP not set correctly in registry' -ForegroundColor Red
                        '|- BLIS IP set correctly in registry' | Out-File $OutFile -Encoding ascii -Append
                    }
                }
                ElseIf ($Value -eq 'Subnet') {
                    If ($Key.GetValue($Value) -eq $Servers[$i].'BLIS Subnet') {
                        Write-Host '|- BLIS Subnet set correctly in registry'
                        '|- BLIS Subnet set correctly in registry' | Out-File $OutFile -Encoding ascii -Append
                    }
                    Else {
                        Write-Host '|- BLIS Subnet not set correctly in registry' -ForegroundColor Red
                        '|- BLIS Subnet set correctly in registry' | Out-File $OutFile -Encoding ascii -Append
                    }
                }
                ElseIf ($Value -eq 'Gateway') {
                    If ($Key.GetValue($Value) -eq $Servers[$i].'BLIS Gateway') {
                        Write-Host '|- BLIS Gateway set correctly in registry'
                        '|- BLIS Gateway set correctly in registry' | Out-File $OutFile -Encoding ascii -Append
                    }
                    Else {
                        Write-Host '|- BLIS Gateway not set correctly in registry' -ForegroundColor Red
                        '|- BLIS Gateway set correctly in registry' | Out-File $OutFile -Encoding ascii -Append
                    }
                }
                ElseIf ($Value -eq 'DNS') {
                    If ($Key.GetValue($Value) -eq ($Servers[$i].'BLIS DNS1',$Servers[$i].'BLIS DNS2',$Servers[$i].'BLIS DNS3' -join ',')) {
                        Write-Host '|- BLIS DNS set correctly in registry'
                        '|- BLIS DNS set correctly in registry' | Out-File $OutFile -Encoding ascii -Append
                    }
                    Else {
                        Write-Host '|- BLIS DNS not set correctly in registry' -ForegroundColor Red
                        '|- BLIS DNS set correctly in registry' | Out-File $OutFile -Encoding ascii -Append
                    }
                }
            }
        }
    }
    Catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
        $_ | Out-File $OutFile -Encoding ascii -Append
    }
}