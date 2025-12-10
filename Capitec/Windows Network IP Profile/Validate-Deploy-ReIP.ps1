$Servers = Import-Csv 'D:\Henri\WNIP\Deploy_ReIP_Servers.txt' -Delimiter ';'

# Define the remote script block
$ScriptBlock = {
    param($ServerData)


    # Validate required files
    $RequiredFiles = @(
        "D:\Apps\Captools\Scripts\WNIP.ps1",
        "D:\Apps\Captools\Scripts\Windows Network IP Profile.xml"
    )

    foreach ($File in $RequiredFiles) {
        if (Test-Path $File) {
            $Info = Get-Item $File
            Write-Host ("[OK] [$($ServerData.VM)] File '$File' exists. Size: $($Info.Length) bytes, Created: $($Info.CreationTime)") -ForegroundColor Green
        } else {
            Write-Host ("[MISMATCH] [$($ServerData.VM)] Missing file: $File") -ForegroundColor Red
        }
    }

    # Scheduled task check
    $TaskName = "Windows Network IP Profile"
    try {
        Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop | Out-Null
        Write-Host ("[OK] [$($ServerData.VM)] Scheduled task '$TaskName' exists.") -ForegroundColor Green
    } catch {
       Write-Host ("[MISMATCH] [$($ServerData.VM)] Scheduled task '$TaskName' is NOT registered.") -ForegroundColor Red
    }

    # Registry validation
    function Get-RegistryValue {
        param (
            [string]$Path,
            [string]$Name,
            [string]$Expected
        )
        if (Test-Path $Path) {
            $Actual = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
            if ($Actual -ne $Expected) {
                Write-Host ("[MISMATCH] Mismatch at '$Path\$Name': Expected '$Expected', Found '$Actual'") -ForegroundColor Red
            }
            Else {
                Write-Host ("[OK] '$Path\$Name': Expected '$Expected', Found '$Actual'") -ForegroundColor Green
            }
        } else {
            Write-Host ("[MISMATCH] Missing Registry path: $Path") -ForegroundColor Red
        }
    }

    $RegistryChecks = @(
        @{ Path = "HKLM:\Software\WNIP\BFTC"; Name = "DNS";        Expected = $ServerData.BFTCDNS },
        @{ Path = "HKLM:\Software\WNIP\BFTC"; Name = "Gateway";    Expected = $ServerData.BFTCGateway },
        @{ Path = "HKLM:\Software\WNIP\BFTC"; Name = "IP";         Expected = $ServerData.BFTCIP },
        @{ Path = "HKLM:\Software\WNIP\BFTC"; Name = "SubnetMask"; Expected = $ServerData.BFTCSubnetMask },
        @{ Path = "HKLM:\Software\WNIP\BLIS"; Name = "DNS";        Expected = $ServerData.BLISDNS },
        @{ Path = "HKLM:\Software\WNIP\BLIS"; Name = "Gateway";    Expected = $ServerData.BLISGateway },
        @{ Path = "HKLM:\Software\WNIP\BLIS"; Name = "IP";         Expected = $ServerData.BLISIP },
        @{ Path = "HKLM:\Software\WNIP\BLIS"; Name = "SubnetMask";     Expected = $ServerData.BLISSubnetMask }
    )

    foreach ($Check in $RegistryChecks) {
        Get-RegistryValue -Path $Check.Path -Name $Check.Name -Expected $Check.Expected
    }

}

# Loop through each server
foreach ($Server in $Servers) {
    try {
        Invoke-Command -ComputerName $Server.VM -ScriptBlock $ScriptBlock -ArgumentList $Server -ErrorAction Stop
        Write-Host ""
    } catch {
        "[$($Server.VM)] Remote execution failed: $_"
    }
}

