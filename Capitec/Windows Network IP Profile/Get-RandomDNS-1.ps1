# Define the initial list of servers
$DNSServers = @()
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'AWSZA'
    SDLC = 'PRD'
    DNS = '10.233.0.119'
})
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'AWSZA'
    SDLC = 'PRD'
    DNS = '10.233.0.49'
})
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'AWSZA'
    SDLC = 'PRD'
    DNS = '10.233.0.185'
})
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'AWSEU'
    SDLC = 'PRD'
    DNS = '10.232.0.177'
})
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'AWSEU'
    SDLC = 'PRD'
    DNS = '10.232.0.119'
})
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'AWSEU'
    SDLC = 'PRD'
    DNS = '10.232.0.43'
})
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'BLIS'
    SDLC = 'PRD'
    DNS = '10.224.97.221'
})
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'BLIS'
    SDLC = 'PRD'
    DNS = '10.224.97.220'
})
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'BLIS'
    SDLC = 'PRD'
    DNS = '10.224.97.200'
})
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'BLIS'
    SDLC = 'NP'
    DNS = '10.224.106.201'
})
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'BLIS'
    SDLC = 'NP'
    DNS = '10.224.106.200'
})
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'BFTC'
    SDLC = 'PRD'
    DNS = '10.225.97.201'
})
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'BFTC'
    SDLC = 'PRD'
    DNS = '10.225.97.202'
})
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'BFTC'
    SDLC = 'PRD'
    DNS = '10.225.97.220'
})
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'BFTC'
    SDLC = 'PRD'
    DNS = '10.225.97.221'
})
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'AZUREZA'
    SDLC = 'PRD'
    DNS = '10.231.1.5'
})
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'AZUREZA'
    SDLC = 'PRD'
    DNS = '10.231.1.4'
})
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'AZUREEU'
    SDLC = 'PRD'
    DNS = '10.229.143.4'
})
$DNSServers += ,(New-Object -TypeName PSObject -Property @{
    DC = 'AZUREEU'
    SDLC = 'PRD'
    DNS = '10.229.143.6'
})

# Function to get and remove a random server
Function Get-AndRemoveRandomServer {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $DNSServers,
        [Parameter(Mandatory=$True, Position=2)][ValidateSet('AWSZA', 'AWSEU', 'BLIS', 'BFTC', 'AZUREZA', 'AZUREEU')]
        [String] $DC,
        [Parameter(Mandatory=$True, Position=3)][ValidateSet('PRD','NP')]
        [String] $SDLC
    )
    # Check if the list is empty
    If (($DNSServers | Where-Object { $_.DC -eq $DC -and $_.SDLC -eq $SDLC }).Count -eq 0) {
        Write-Host "No servers left in the list!"
        Return $null
    }

    # Get a random server from the list
    $RandomServer = $DNSServers | Where-Object { $_.DC -eq $DC -and $_.SDLC -eq $SDLC } | Get-Random

    # Remove the selected server from the list
    $dnsServers = $DNSServers | Where-Object { $_ -ne $RandomServer }

    # Return the selected server
    return $RandomServer, $DNSServers
}
Function Get-DNSServers {
    Param (
        $SDLC,
        $DC
    )
    $DNSResults = @()
    If ($SDLC -eq 'NP' -and $DC -eq 'BFTC') {
        $selectedServer = Get-AndRemoveRandomServer -dnsServers $DNSServers -SDLC 'PRD' -DC $DC
        Write-Host ($DC + ": " + $SDLC + " Server: " + $selectedServer[0].DNS)
        $selectedServer = Get-AndRemoveRandomServer -dnsServers $selectedServer[1] -SDLC 'PRD' -DC $DC
        Write-Host ($DC + ": " + $SDLC + " Server: " + $selectedServer[0].DNS)
        $selectedServer = Get-AndRemoveRandomServer -dnsServers $selectedServer[1] -SDLC 'PRD' -DC $DC
        Write-Host ($DC + ": " + $SDLC + " Server: " + $selectedServer[0].DNS)
    }
    ElseIf ($SDLC -eq 'NP' -and $DC -eq 'BLIS' -or $DC -eq 'AZUREEU' -or $DC -eq 'AZUREZA'){
        $selectedServer = Get-AndRemoveRandomServer -dnsServers $DNSServers -SDLC $SDLC -DC $DC
        Write-Host ($DC + ": " + $SDLC + " Server: " + $selectedServer[0].DNS)
        $selectedServer = Get-AndRemoveRandomServer -dnsServers $selectedServer[1] -SDLC $SDLC -DC $DC
        Write-Host ($DC + ": " + $SDLC + " Server: " + $selectedServer[0].DNS)
    }
    Else {
        $selectedServer = Get-AndRemoveRandomServer -dnsServers $DNSServers -SDLC $SDLC -DC $DC
        #Write-Host ($DC + ": " + $SDLC + " Server: " + $selectedServer[0].DNS)
        #Write-Host ($selectedServer[0].DNS + ",") -NoNewline
        $DNSResults += $selectedServer[0].DNS
        $selectedServer = Get-AndRemoveRandomServer -dnsServers $selectedServer[1] -SDLC $SDLC -DC $DC
        #Write-Host ($DC + ": " + $SDLC + " Server: " + $selectedServer[0].DNS)
        #Write-Host ($selectedServer[0].DNS + ",") -NoNewline
        $DNSResults += $selectedServer[0].DNS
        $selectedServer = Get-AndRemoveRandomServer -dnsServers $selectedServer[1] -SDLC $SDLC -DC $DC
        #Write-Host ($DC + ": " + $SDLC + " Server: " + $selectedServer[0].DNS)
        #Write-Host ($selectedServer[0].DNS)
        $DNSResults += $selectedServer[0].DNS
    }
    Return $DNSResults

}
Clear-Host
$Details = @()
For ($i = 0; $i -lt 8; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Randomizing - ') -NoNewline
    Try {
        $BLISDNS = Get-DnsServers -SDLC 'PRD' -DC 'BLIS'
        $Details += ,(New-Object -TypeName PSObject -Property @{
            BLISDNS1 = $BLISDNS[0]
            BLISDNS2 = $BLISDNS[1]
            BLISDNS3 = $BLISDNS[2]
        })
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Servers[$i]        
        })
        Write-Host $_ -ForegroundColor Red
    }
    $i ++
}
$Details | Select-Object BLISDNS1, BLISDNS2, BLISDNS3 | Out-GridView