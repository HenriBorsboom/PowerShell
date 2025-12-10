$ErrorActionPreference = 'Stop'
Clear-Host
$ConfigFiles = Get-ChildItem 'C:\Users\ct302255\OneDrive - Capitec Bank Ltd\NGINX\Nginx' *.conf -Recurse

$Details = @()
For ($CI = 0; $CI -lt $ConfigFiles.Count; $CI ++) {
    #$CI = 95
    $file = Get-Content $ConfigFiles[$CI]
    $searchString1 = "server_name"
    $searchString2 = "location"
    $searchString3 = "proxy_pass"
    $searchString4 = "upstream"
    Write-Output (($CI + 1).ToString() + '/' + $ConfigFiles.Count.ToString() + ' - Processing ' + $ConfigFiles[$CI].Name)
    $Indexes = @()
    for ($i = 0; $i -lt $file.Count; $i++) {
        If ($file[$i] -match $searchString1 -and $file[$i] -notlike '*#*') { # ServerName
            If ($file[$i] -notlike '*return*') {
                If ($File[$i -1] -notlike "*:80*" -and $File[$i -2] -notlike "*:80*" -and $File[$i -3] -notlike "*:80*") {
                    $Array = ($($file[$i]).Trim() -split " ")
                    [String[]] $Servers = $Array[1..($array.Length - 1)]
                    ForEach ($Server in $Servers) {
                        $Indexes += ,(New-Object -TypeName PSobject -Property @{
                            Item = 'ServerName'
                            Value = ($Server).Replace(";", "")
                            Index = $i
                        })
                    }
                }
            }
        }
        ElseIf ($file[$i] -match $searchString2 -and $file[$i] -notlike '*#*') { #Location
                $Indexes += ,(New-Object -TypeName PSobject -Property @{
                    Item = 'Location'
                    Value = ($($file[$i]).Trim() -split " ")[1].Replace(";","") 
                    Index = $i
                })
        }
        ElseIf ($file[$i] -match $searchString3 -and $file[$i] -notlike '*#*') { #Proxy Pass
            $Indexes += ,(New-Object -TypeName PSobject -Property @{
                Item = 'ProxyPass'
                Value = ($($file[$i]).Trim() -split " ")[1].Replace(";","") 
                Index = $i
            })
        }
        ElseIf ($file[$i] -match $searchString4) { #Upstream
            If ($file[$i] -notlike '*upstream_*' -and $file[$i] -notlike '*#*') {
                $Indexes += ,(New-Object -TypeName PSobject -Property @{
                    Item = 'Upstream'
                    Value = ($($file[$i]).Trim() -split " ")[1].Replace(";","") 
                    Index = $i
                })
                For ($Si = $i; $Si -lt ($i + 5); $Si++) {
                    If ($file[$si] -match $searchString5) { #Server
                        If ($File[$si] -notlike 'server {*' -and $File[$si] -notlike '*#*') {
                            $Indexes += ,(New-Object -TypeName PSobject -Property @{
                                Item = 'UpstreamServer'
                                Value = ($($file[$i]).Trim() -split " ")[1].Replace(";","") 
                                Index = $i
                            })
                        }
                        ElseIf ($File[$si] -eq 'server {*') {
                            Continue
                        }
                    }
                }
            }
        }
    }
    [String[]] $Servers = ($Indexes | Where-Object {$_.Item -eq 'ServerName'} | Select-Object -Unique Value).Value
    ForEach ($Server in $Servers) {
        Try {
            $IPAddress = $null
            $NamedHosts = $null
            Write-Output "|- Resolving IP of $Server"
            $IPAddress = (Resolve-DnsName $Server -Server 10.10.0.11).IPAddress
            [String[]] $NamedHosts = (Resolve-DnsName $IPAddress -Server 10.10.0.11).NameHost
            <#Foreach ($NameServer in $NamedHosts) {
                $Details += ,(New-Object -TypeName PSObject -Property @{
                    File = $ConfigFiles[$CI]
                    Server = $Server
                    IPAddress = $IPAddress
                    NamedHosts = $NamedHosts
                    Locations = ($Indexes | Where Item -eq 'Location').Value
                    ProxyPass = ($Indexes | Where Item -eq 'ProxyPass').Value
                    Upstreams = ($Indexes | Where Item -eq 'Upstream').Value
                    UpStreamServers = ($Indexes | Where Item -eq 'UpstreamServer').Value
                })
            }#>
        }
        Catch {
            If ($IPAddress -eq $null) {
                $IPAddress = $null
            }
            ElseIf ($NamedHosts -eq $null) {
                Try {
                    [String[]] $NamedHosts = (Resolve-DnsName $IPAddress).NameHost
                }
                Catch {
                    $NamedHosts = 'Not resolved'
                }
            }
        }
        Finally {
            $Details += ,(New-Object -TypeName PSObject -Property @{
                File = $ConfigFiles[$CI]
                Servers = $Server
                IPAddress = $IPAddress
                NamedHosts = $NamedHosts
                Locations = ($Indexes | Where-Object {$_.Item -eq 'Location'}).Value
                ProxyPass = ($Indexes | Where-Object {$_. Item -eq 'ProxyPass'}).Value
                Upstreams = ($Indexes | Where-Object {$_. Item -eq 'Upstream'}).Value
                UpStreamServers = ($Indexes | Where-Object {$_. Item -eq 'UpstreamServer'}).Value
            })
        }
    }
    #$Details | Select File, Servers, IPAddress, NamedHosts, ProxyPass, Locations, Upstreams, UpStreamServers | Out-GridView
}
$Details | Select-Object File, Servers, IPAddress, NamedHosts, ProxyPass, Locations, Upstreams, UpStreamServers | Out-GridView