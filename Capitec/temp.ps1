
Function Test-Port {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Server,
        [Parameter(Mandatory=$True, Position=2)]
        [Int] $Port, `
        [Parameter(Mandatory=$False, Position=3)]
        [Int] $Timeout = 50)
       
    $Domains = @()
    $Domains += 'mercantile.co.za'
    $Domains += 'mblcard.co.za'
    $Domains += 'MBLWEBDC.co.za'

    ForEach ($Domain in $Domains) {
        Try {
            $IP = [System.Net.Dns]::GetHostAddresses($Server + '.' + $Domain)| Where AddressFamily -eq 'Internetwork' | Select-Object IPAddressToString -Expandproperty IPAddressToString
            If ($IP.GetType().Name -eq 'Object[]') {
                #If we have several ip's for that address, let's take first one
                $IP = $IP[0]
            }
            break
        } 
        Catch {
            Try {
                $IP = [System.Net.Dns]::GetHostAddresses($Server) | Where AddressFamily -eq 'Internetwork'| Select-Object IPAddressToString -Expandproperty IPAddressToString
                If ($IP.GetType().Name -eq 'Object[]') {
                    #If we have several ip's for that address, let's take first one
                    $IP = $IP[0]
                }
                break
            }
            Catch {
                #Write-Host $Server -ForegroundColor Red
                #Read-Host
            }
        }
    }
    Try {        
        $requestCallback = $state = $null
        $client = New-Object System.Net.Sockets.TcpClient
        $beginConnect = $client.BeginConnect($IP,$Port,$requestCallback,$state)
        Start-Sleep -Milliseconds $Timeout
        if ($client.Connected) { $State = $true } else { $State = $false }
        $client.Close()
        $ReturnValue = New-Object -TypeName PSObject -Property @{
            Server = $Server
            IP = $IP
            Domain = $Domain
            Open = $State
            Port = $Port
        }
        Return $ReturnValue
    }
    Catch {
        Write-Host ("1: " + $Server) -ForegroundColor Red
        Read-Host
    }
}
        
#Test-Port prmadprd01 -port 135
$ServerList = Import-Csv C:\HealthCheck\ServerList\Serverlist.csv -Delimiter ";"
$Details = @()
For ($i = 0; $i -lt $ServerList.Count; $i ++) {
    $Server = $ServerList[$i].ServerName
    Write-Progress -Activity "Testing Ports" -PercentComplete ($i / $ServerList.Count * 100) -Status ("Processing " + $Serverlist[$i])
    $Details += ,(Test-Port $Server -Port 135)
}
$Redone = @()
ForEach ($Item in $Details) {
    $Redone += ,(New-Object -TypeName PSObject -Property @{
        Port = $Item.Port
        Server  = $Item.Server
        Domain = $Item.Domain
        IP = $Item.IP
        Open = $Item.Open
    })
}
$Redone | Out-GridView
