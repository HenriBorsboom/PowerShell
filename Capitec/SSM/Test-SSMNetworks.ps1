Param (
    [Parameter(Mandatory=$False)]
    [Switch] $LoopS3 = $False
)
$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
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
Clear-Host
# s3.af-south-1.amazonaws.com
$Global:Details = @()
Switch ($LoopS3) {
    $True {
        For ($i = 0; $i -lt 30; $i ++) {
            Write-Host (($i + 1).ToString() + '/' + '30 - Testing')
            Test-Connectivity -Address s3.af-south-1.amazonaws.com -Test S3
            Start-Sleep -Seconds 1
        }
    }
    $False {
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Test-Connectivity -Address s3.af-south-1.amazonaws.com -Test S3
        Test-Connectivity -Address ssm.af-south-1.amazonaws.com -Test SSM
        Test-Connectivity -Address ec2messages.af-south-1.amazonaws.com -Test "EC2 Messages"
        Test-Connectivity -Address ssmmessages.af-south-1.amazonaws.com -Test "SSM Messages"
        Test-Connectivity -Address vpce-0f0aa223b0138bc2a-xic89qrn.ec2messages.af-south-1.vpce.amazonaws.com -Test "MDS VPC"
        Test-Connectivity -Address vpce-07a8e3dd46b450071-npxk99ch.ssm.af-south-1.vpce.amazonaws.com -Test "SSM VPC"
        Test-Connectivity -Address vpce-0290e50465bae45f8-aiwyuffs.ssmmessages.af-south-1.vpce.amazonaws.com -Test "Messages VPC"

        Write-Host ""
        $WSUS = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate").WUServer
        Write-Host ("WSUS Server: " + $WSUS) -ForegroundColor Yellow

        If ($Null -ne $WSUS) {
            $WSUSServer = $WSUS.Replace("http://","") -split ":"
            $Results = Test-NetConnection $WSUSServer[0] -Port $WSUSServer[1]

            $Global:Details += ,(New-Object -TypeName PSObject -Property @{
                Address = $Results.ComputerName
                RemoteAddress = $Results.RemoteAddress
                ConnectOn = "Name"
                Test = "WSUS"
                Result = $Results.TcpTestSucceeded
                Port = $WSUSServer[1]
            })
        }
        Else {
            $Global:Details += ,(New-Object -TypeName PSObject -Property @{
                Address = $WSUS
                RemoteAddress = "WSUS"
                ConnectOn = "Registry"
                Test = "WSUS"
                Result = $False
                Port = $null
            })
        }
    }
}


$Global:Details | Select-Object Test, ConnectOn, Address, RemoteAddress, Port, Result | Out-GridView