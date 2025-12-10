# http://stackoverflow.com/questions/9601118/running-multiple-scriptblocks-at-the-same-time-with-start-job-instead-of-loopin
# Question 
<#
# List 4 servers (for testing)
$servers = Get-QADComputer -sizelimit 4 -WarningAction SilentlyContinue -OSName *server*,*hyper*

# Create list
$serverlistlist = @()

# Loop servers
foreach($server in $servers) {

    # Fetch IP
    $ipaddress = [System.Net.Dns]::GetHostAddresses($Server.name)| select-object IPAddressToString -expandproperty IPAddressToString

    # Gather OSName through WMI
    $OSName = (Get-WmiObject Win32_OperatingSystem -ComputerName $server.name ).caption

    # Ping the server
    if (Test-Connection -ComputerName $server.name -count 1 -Quiet ) {
        $reachable = "Yes"
    }

    # Save info about server
    $serverInfo = New-Object -TypeName PSObject -Property @{
        SystemName = ($server.name).ToLower()
        IPAddress = $IPAddress
        OSName = $OSName
    }
    $serverlist += $serverinfo | Select-Object SystemName,IPAddress,OSName
}
#>
# Answer
<#
$sb = {
    $serverInfos = @()
    $args | % {
        $IPAddress = [Net.Dns]::GetHostAddresses($_) | select -expand IPAddressToString
        # More processing here... 
        $serverInfos += New-Object -TypeName PsObject -Property @{ IPAddress = $IPAddress }
    }
    return $serverInfos
}

[string[]] $servers = Get-QADComputer -sizelimit 500 -WarningAction SilentlyContinue -OSName *server*,*hyper* | Select -Expand Name

$maxJobs = 10 # Max concurrent running jobs.
$chunkSize = 5 # Number of servers to process in a job.
$jobs = @()

# Process server list.
for ($i = 0 ; $i -le $servers.Count ; $i+=($chunkSize)) {
    if ($servers.Count - $i -le $chunkSize) 
        { $c = $servers.Count - $i } else { $c = $chunkSize }
    $c-- # Array is 0 indexed.

    # Spin up job.
    $jobs += Start-Job -ScriptBlock $sb -ArgumentList ( $servers[($i)..($i+$c)] ) 
    $running = @($jobs | ? {$_.State -eq 'Running'})

    # Throttle jobs.
    while ($running.Count -ge $maxJobs) {
        $finished = Wait-Job -Job $jobs -Any
        $running = @($jobs | ? {$_.State -eq 'Running'})
    }
}

# Wait for remaining.
Wait-Job -Job $jobs > $null

$jobs | Receive-Job | Select IPAddress
#>