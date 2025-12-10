$Servers = @()
$Servers += ,('cbwlpprapw601')
$Servers += ,('cbwlpprapw594')
$Servers += ,('cbwlpprdbw053')

$Details = @()
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i] + ' - ') -NoNewline
    Try {
        $Session = New-CimSession $Servers[$i]
        $Results = Get-DnsClientServerAddress -CimSession $Session
        ForEach ($Result in $Results) {
            If ($null -ne $Result.ServerAddresses[0] -and $Result.InterfaceAlias -notlike '*loop*' -and $Result.InterfaceAlias -notlike '*isa*') {
                $Details += ,(New-Object -TypeName PSObject -Property @{
                    Server = $Servers[$i]
                    InterfaceAlias = $Result.InterfaceAlias
                    DNSServers = $Result.ServerAddresses
                }) 
            }
        }
        Remove-Variable Session
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Servers[$i]
            InterfaceAlias = $null
            DNSServers = $_
        })
        Write-Host $_ -ForegroundColor Red
    }
}
$Details | Out-GridView