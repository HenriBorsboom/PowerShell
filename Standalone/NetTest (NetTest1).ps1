Function NetworkDetails
{
    $CurrentNetAdapter = get-netadapter | where {$_.Status -eq "Up"} | Select Name
    $CurrentIPAddress = Get-NetIPAddress -InterfaceAlias $CurrentNetAdapter.Name | select IPv4Address
    $AdapterName = $CurrentNetAdapter.Name
    $IPv4 = $CurrentIPAddress.IPv4Address
    
    $NetworkDetails = "Current Network Adapter: " + $AdapterName + " - " + $IPv4

    return ,$NetworkDetails
}

Function Gateways
{
    $Gateways = @("10.10.16.129","10.10.145.1","10.10.145.65","10.10.231.193","10.10.29.1","10.10.29.17","10.10.29.33","10.10.29.49","10.10.29.65","10.10.29.81","10.10.29.97",
            "10.10.29.113","10.10.29.129","10.10.29.161","10.10.29.193","10.10.29.225")
            
    $Output = RunLoop -Target $Gateways -Caller "Gateways"
    Return ,$Output
}

Function Hosts
{
    $Hosts = @("10.10.231.201",
            "10.10.231.202",
            "10.10.231.203",
            "10.10.231.204",
            "10.10.231.205",
            "10.10.145.78")

    ForEach ($TestHost in $Hosts)
    {
        $Output = RunLoop -Target $TestHost -Caller "Hosts and File Servers"
        $Output | export-csv -Path "c:\users\username\desktop\test.csv" -NoClobber -Append
    }
    Get-Content -Path "c:\users\username\desktop\test.csv" | Write-Host
    #Return ,$Output
}

Function LocalSubnets
{
    $LocalSubnet = @("10.10.145.16","10.10.145.74")
    
    $Output = RunLoop -Target $LocalSubnet -Caller "Heart beat and CSV"
    Return ,$Output
}

Function Go
{
    $NetworkDetails = NetworkDetails
    $GatewayOutput = Gateways
    $HostsOutput = Hosts
    $LocalSubnetsOutput = LocalSubnets
    
    #Print Output
    $NetworkDetails
    $GatewayOutput 
    $HostsOutput
    $LocalSubnetsOutput
}

Function Testing
{
    #$NetworkDetails = NetworkDetails
    #$GatewayOutput = Gateways
    Hosts
    #$LocalSubnetsOutput = LocalSubnets
    
    #Print Output
    #$NetworkDetails
    #$GatewayOutput 
    #$HostsOutput
    #$LocalSubnetsOutput
}

Function RunLoop
{
    Param(        [Parameter(Mandatory=$True,Position=1)]
        $Target,
        [Parameter(Mandatory=$True,Position=2)]
        [string] $Caller)

    #ForEach ($Device in $Target)
    #{
        Clear-Host
        Write-host "Testing connection on $Caller"
        Write-Host "  Testing connection to $Target"
        $OutputObj  = New-Object -Type PSObject
        
        Try
        {
            If (Test-Connection -count 2 -ComputerName $Target -ErrorAction Stop)
            {
                $OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress -Value $Target                $OutputObj | Add-Member -MemberType NoteProperty -Name Online -Value "Yes"
            }
        }
        Catch
        {
            $OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress -Value $Target            $OutputObj | Add-Member -MemberType NoteProperty -Name Online -Value "No"        }
    #}
    $OutputObj
}

#Clear-Host
#Go
Testing

