Function NetworkDetails
{
    #Write-host "--------------------------------------------------- Network Details" -ForegroundColor Yellow
    $CurrentNetAdapter = get-netadapter | where {$_.Status -eq "Up"} | Select Name
    $CurrentIPAddress = Get-NetIPAddress -InterfaceAlias $CurrentNetAdapter.Name | select IPv4Address
    $AdapterName = $CurrentNetAdapter.Name
    $IPv4 = $CurrentIPAddress.IPv4Address
    Write-Host "Current Network Adapter: "-NoNewline
    write-host "$AdapterName - $IPv4" -ForegroundColor Green
    #Write-Host "------------------------------------------------------------- Done" -ForegroundColor Yellow
}

Function Gateways
{
        
    Write-host "--------------------------------------------------------- Gateways" -ForegroundColor Yellow
    Write-Host " Pinging all VLAN Gateways"
    $Hsts = @("10.10.16.129","10.10.145.1","10.10.145.65","10.10.231.193","10.10.29.1","10.10.29.17","10.10.29.33","10.10.29.49","10.10.29.65","10.10.29.81","10.10.29.97","10.10.29.113","10.10.29.129","10.10.29.161","10.10.29.193","10.10.29.225")

    foreach ($Server in $Hsts)
    {
        Try
        {
            $OutputObj  = New-Object -Type PSObject
            If (Test-Connection -count 2 -ComputerName $Server -ErrorAction Stop)
            {
            $OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress -Value $Server            $OutputObj | Add-Member -MemberType NoteProperty -Name Online -Value "Yes"
            $OutputObj
            }
        }
        Catch
        {
            $OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress -Value $Server            $OutputObj | Add-Member -MemberType NoteProperty -Name Online -Value "No"            $OutputObj        }
    }
    Write-Host "-------------------------------------------------------------- Done" -ForegroundColor Yellow
}

Function Hosts
{
    Write-host "------------------------------------------------------------- Hosts" -ForegroundColor Yellow
    Write-Host " Pinging all VM Hosts and File Server" 
    $Hsts = @("10.10.231.201","10.10.231.202","10.10.231.203","10.10.231.204","10.10.231.205","10.10.145.78")
    foreach ($Server in $Hsts)
    {
        Try
        {
            $OutputObj  = New-Object -Type PSObject
            If (Test-Connection -count 2 -ComputerName $Server -ErrorAction Stop)
            {
            $OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress -Value $Server            $OutputObj | Add-Member -MemberType NoteProperty -Name Online -Value "Yes"
            $OutputObj
            }
        }
        Catch
        {
            $OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress -Value $Server            $OutputObj | Add-Member -MemberType NoteProperty -Name Online -Value "No"            $OutputObj        }
    }
    Write-Host "-------------------------------------------------------------- Done" -ForegroundColor Yellow
}

Function LocalSubnets
{
    Write-host "------------------------------------------------------------HB / CSV" -ForegroundColor Yellow
    Write-Host " Pinging HB and CSV network addresses" 
    $Hsts = @("10.10.145.16","10.10.145.74")
    foreach ($Server in $Hsts)
    {
        Try
        {
            $OutputObj  = New-Object -Type PSObject
            If (Test-Connection -count 2 -ComputerName $Server -ErrorAction Stop)
            {
            $OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress -Value $Server            $OutputObj | Add-Member -MemberType NoteProperty -Name Online -Value "Yes"
            $OutputObj
            }
        }
        Catch
        {
            $OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress -Value $Server            $OutputObj | Add-Member -MemberType NoteProperty -Name Online -Value "No"            $OutputObj        }
    }
    Write-Host "-------------------------------------------------------------- Done" -ForegroundColor Yellow
}

Function Go
{
    NetworkDetails
    Write-host ""
    Gateways
    Write-host ""
    Hosts
    Write-Host ""
    LocalSubnets
    NetworkDetails
}

Clear-Host
Go