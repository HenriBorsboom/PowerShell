$erroractionpreference = "stop"
$Servers = Get-Content C:\Temp\Servers.txt

$ipamaddresses = invoke-command -ComputerName cbstbipam01 -ScriptBlock {Get-IpamAddress -AddressFamily IPv4 | Select-Object *}
for ($i = 4; $i -lt $Servers.Count; $i ++) {
    write-host (($i+1).ToString() + "/" + $Servers.count.tostring() + " - processing " + $Servers[$i] + " - ") -NoNewline
    [object[]] $ips = $ipamaddresses | where-object {$_.description -EQ $Servers[$i]} | Select-Object ipaddress   
    Write-Host ($ips.count.tostring() + " found")
    $online = "offline"  
    foreach ($ip in $ips) {
        if (test-connection $Servers[$i] -Count 1 -Quiet) {
            $online = "online"
            Write-Host ("|- " + $Servers[$i] + " online")
            ($servers[$i] + "," + $null) | Out-File c:\temp\onlineservers.csv -Encoding ascii -Append
        }
        elseif (test-connection $ip.ipaddress -Count 1 -Quiet) {
            $online = "online"
            Write-Host ("|- " + $Servers[$i] + " online")
            ($servers[$i] + "," + $ip.ipaddress) | Out-File c:\temp\onlineservers.csv -Encoding ascii -Append
        }
        else {
            invoke-command -ComputerName cbstbipam01 -ArgumentList $ip -ScriptBlock {param ($ip); Remove-IpamAddress -IpAddress $ip.ipaddress -force} 
            ($servers[$i] + "," + $ip.ipaddress) | Out-File c:\temp\offlineservers.csv -Encoding ascii -Append 
            Write-Host ("|- " + $Servers[$i] + " offline. removed ipaddress; " + $ip.ipaddress)                     
        } 
    }
 
    if ($online -eq "offline") {
        Try {
            Remove-ADComputer $Servers[$i] -confirm:$false
        }
        Catch {
            Write-Error $_
        }
        Write-Host ("|- " + $Servers[$i] + " removed from AD")
    }
}