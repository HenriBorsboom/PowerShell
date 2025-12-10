Function Test-Connectivity {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Address, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $Test, `
        [Parameter(Mandatory=$False, Position=3)]
        [Int] $Port = 443, `
        [Parameter(Mandatory=$True, Position=4)]
        [String] $Server
    )
    $Result = Invoke-Command $Server -ArgumentList $Address -ScriptBlock {
        Param ($Address)
        $IPs = Resolve-DnsName $Address
        $Details = @()
        ForEach ($IP in $IPs) {
            #Write-Host ("Testing " + $Test + " on " + $IP.IPAddress + " - ") -NoNewline
            $Results = Test-NetConnection $IP.IPAddress -Port 443
            $Details += ,(New-Object -TypeName PSObject -Property @{
                Address = $Address
                RemoteAddress = $Results.RemoteAddress
                ConnectOn = "IP"
                Test = "S3"
                Port = $Port
                Result = $Results.TCPTestSucceeded
            })
        }
        $Results = Test-NetConnection $Address -Port 443
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Address = $Address
            RemoteAddress = $Results.RemoteAddress
            ConnectOn = "Name"
            Test = "S3"
            Port = $Port
            Result = $Results.TCPTestSucceeded
        })
        Return $Details
    }
    Return $Result
}

$Servers = @()
$Servers += ,('CBWLPPRWFW043')


$Details = @()
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing - ' + $Servers[$i])
    $Results = Test-Connectivity -Address s3.af-south-1.amazonaws.com -Test S3 -Server $Servers[$i]
    ForEach ($Result in $Results) {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            ConnectOn = $Result.ConnectOn
            RemoteAddress = $Result.RemoteAddress
            Result = $Result.Result
            Server = $Servers[$i]
        })
    }
}
$Details | Out-GridView