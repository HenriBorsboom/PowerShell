$NameSpaces = @(
                "AdminAPI", `
                "AdminSite", `
                "AuthSite", `
                "TenantAPI", `
                "TenantSite", `
                "WindowsAuthSite")

$WAPServers = @(
                "NRAZUREAPP105", `
                "NRAZUREAPP106", `
                "NRAZUREAPP107", `
                "NRAZUREAPP108", `
                "NRAZUREAPP109", `
                "NRAZUREAPP110", `
                "NRAZUREAPP111")

$WebServers = @(
                "WEBSERVER101", `
                "WEBSERVER102", `
                "WEBSERVER103", `
                "WEBSERVER104", `
                "WEBSERVER105", `
                "WEBSERVER106", `
                "WEBSERVER107", `
                "WEBSERVER108")

Function Disable-Certificate-Validation-False{
    Param($WAPServers,$WebServers,$NameSpaces)

    $x = 1
    Write-Host "Total WAP Servers: " $WAPServers.Count
    ForEach ($WapServer in $WAPServers){
        Write-Host " $x - $WapServer"

        $y = 1
        Write-Host "  Total Commands: " $NameSpaces.Count
        ForEach ($Command in $NameSpaces){
            Try{
                $Result = Invoke-Command -ComputerName $WapServer -ArgumentList $Command -ScriptBlock {Param($par) Set-MgmtSvcSetting -Namespace $par -Name "DisableSslCertValidation" -Value $false} -ErrorAction Stop
                Write-Host "$WapServer executed $Command" -ForegroundColor green
            }
            Catch{
                Write-Host "$WapServer failed to execute $Command" -ForegroundColor Red
            }
            $y ++
        }
        $y = 1
        $x ++
    }
    $x = 1

    $x = 1
    Write-Host "Total Web Servers: " $WebServers.Count
    ForEach ($WebServer in $WebServers){
        Write-Host " $x - $WebServer"

        $y = 1
        Write-Host "  Total Commands: " $NameSpaces.Count
        ForEach ($Command in $NameSpaces){
            Try{
                $Result = Invoke-Command -ComputerName $WebServer -ArgumentList $Command -ScriptBlock {Param($par) Set-MgmtSvcSetting -Namespace $par -Name "DisableSslCertValidation" -Value $false} -ErrorAction Stop
                Write-Host "$WebServer executed $Command" -ForegroundColor green
            }
            Catch{
                Write-Host "$WebServer failed to execute $Command" -ForegroundColor Red
            }
            $y ++
        }
        $y = 1
        $x ++
    }
}

Function Disable-Certificate-Validation-True{
    Param($WAPServers,$WebServers,$NameSpaces)

    $x = 1
    Write-Host "Total WAP Servers: " $WAPServers.Count
    ForEach ($WapServer in $WAPServers){
        Write-Host " $x - $WapServer"

        $y = 1
        Write-Host "  Total Commands: " $NameSpaces.Count
        ForEach ($Command in $NameSpaces){
            Try{
                $Result = Invoke-Command -ComputerName $WapServer -ArgumentList $Command -ScriptBlock {Param($par) Set-MgmtSvcSetting -Namespace $par -Name "DisableSslCertValidation" -Value $true} -ErrorAction Stop
                Write-Host "$WapServer executed $Command" -ForegroundColor green
            }
            Catch{
                Write-Host "$WapServer failed to execute $Command" -ForegroundColor Red
            }
            $y ++
        }
        $y = 1
        $x ++
    }
    $x = 1

    $x = 1
    Write-Host "Total Web Servers: " $WebServers.Count
    ForEach ($WebServer in $WebServers){
        Write-Host " $x - $WebServer"

        $y = 1
        Write-Host "  Total Commands: " $NameSpaces.Count
        ForEach ($Command in $NameSpaces){
            Try{
                $Result = Invoke-Command -ComputerName $WebServer -ArgumentList $Command -ScriptBlock {Param($par) Set-MgmtSvcSetting -Namespace $par -Name "DisableSslCertValidation" -Value $true} -ErrorAction Stop
                Write-Host "$WebServer executed $Command" -ForegroundColor green
            }
            Catch{
                Write-Host "$WebServer failed to execute $Command" -ForegroundColor Red
            }
            $y ++
        }
        $y = 1
        $x ++
    }
}

#Disable-Certificate-Validation-False -WAPServers $WAPServers -WebServers $WebServers -NameSpaces $NameSpaces
Disable-Certificate-Validation-True -WAPServers $WAPServers -WebServers $WebServers -NameSpaces $NameSpaces


#Set-MgmtSvcSetting -Namespace "AdminSite" -Name "DisableCertificateValidation" -Value False
