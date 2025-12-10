
$Servers = Get-Content C:\Temp\Henri\SCOM\New\servers.txt

Invoke-Command $Servers -Credential $Credential -ThrottleLimit 20 -Scriptblock {
    Function Uninstall {
        Param ($ProductCode)
        $uninstallString = ("MsiExec.exe /I" + $ProductCode)
        $command, $arguments = $uninstallString -split ' ', 2
        $uninstallArgs = "$($arguments.Replace('/I', '/X')) /qn /norestart"
        Write-Host ($env:Computername + ":|- Starting uninstallation command: " + $command + ' ' + $uninstallArgs) -FOregroundColor Yellow
        Start-Process -FilePath $command -ArgumentList $uninstallArgs -Wait
        Write-Host ($env:Computername + ":|- Uninstallation process has finished.") -ForegroundColor Green
    }
    $productA = "Microsoft Monitoring Agent"
    $productB = "Configuration Manager Client"

    $paths = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    $Products = Get-ItemProperty $paths | Where-Object { $_.DisplayName -eq $productA -or $_.DisplayName -eq $productB } | Select-Object DisplayName, PSChildName
    If ($Products) {
        ForEach ($Product in $Products) {
            Write-Host ($env:Computername + ":|- Initiating uninstall of " + $Product.DisplayName) -ForegroundColor Yellow
            #("|- Initiating uninstall of " + $Product.DisplayName) | Out-File $LogFile -Encoding ascii
            Uninstall -ProductCode $Product.PSChildName 
        }
    }
    Else {
        Write-Host ($env:Computername + ":|- Agents not found") -ForegroundColor Cyan
        #"|- Agents not found" | Out-File $LogFile -Encoding ascii
    }
}

#$Credential = Get-Credential
#region Servers
