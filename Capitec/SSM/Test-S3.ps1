Function Test-Connectivity {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Address, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $Test, `
        [Parameter(Mandatory=$False, Position=3)]
        [Int] $Port = 443
    )
    $IPs = Resolve-DnsName $Address
    ForEach ($IP in $IPs) {
        Write-Host ("Testing " + $Test + " on " + $IP.IPAddress + " - ") -NoNewline
        $Results = Test-NetConnection $IP.IPAddress -Port $Port
        $Global:Details += ,(New-Object -TypeName PSObject -Property @{
            Address = $Address
            RemoteAddress = $Results.RemoteAddress
            ConnectOn = "IP"
            Test = $Test
            Port = $Port
            Result = $Results.TCPTestSucceeded
        })
        If ($Results.TCPTestSucceeded -eq $False) {
            Write-Host $Results.TCPTestSucceeded -ForegroundColor Red
        }
        Else {
            Write-Host $Results.TCPTestSucceeded -ForegroundColor Green
        }
    }
    Remove-Variable IPs, Results
    Write-Host ("Testing " + $Test + " on " + $Address + " - ") -NoNewline
    $Results = Test-NetConnection $Address -Port 443
    $Global:Details += ,(New-Object -TypeName PSObject -Property @{
        Address = $Address
        RemoteAddress = $Results.RemoteAddress
        ConnectOn = "Name"
        Test = $Test
        Port = $Port
        Result = $Results.TCPTestSucceeded
    })
    If ($Results.TCPTestSucceeded -eq $False) {
        Write-Host $Results.TCPTestSucceeded -ForegroundColor Red
    }
    Else {
        Write-Host $Results.TCPTestSucceeded -ForegroundColor Green
    }
    Remove-Variable Results
    [GC]::Collect()
}
While ($True) {
    Test-Connectivity -Address s3.af-south-1.amazonaws.com -Test S3
}