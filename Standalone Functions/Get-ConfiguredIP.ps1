 Function GetIP
 {
    $CurrentNetAdapter = Invoke-Command -ComputerName "NRAZUREAPP105" -ScriptBlock {$netadapt = get-netadapter | where {$_.Status -eq "Up"; return $netadapt} | Select Name}
    #$CurrentNetAdapter = get-netadapter | where {$_.Status -eq "Up"} | Select Name
    foreach ($Adapter in $CurrentNetAdapter)
    {
        $OutputObj  = New-Object -Type PSObject
        try
        {
            $CurrentIPAddress = Get-NetIPAddress -InterfaceAlias $Adapter.Name  -ErrorAction Stop | select IPv4Address
            $AdapterName = $Adapter.Name
            $IPv4 = $CurrentIPAddress.IPv4Address
        }
        Catch
        {
            $IPv4 = "0.0.0.0"
        }
        Finally
        {
            $OutputObj | Add-Member -MemberType NoteProperty -Name Adapter -Value $Adapter.Name            $OutputObj | Add-Member -MemberType NoteProperty -Name IPv4 -Value $IPv4
            $OutputObj
        }
        
    }
}

GetIP