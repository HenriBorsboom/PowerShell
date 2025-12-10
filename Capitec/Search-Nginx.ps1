$ErrorActionPreference = 'Stop'
Clear-Host
$ConfigFiles = Get-ChildItem *.conf

$Details = @()
For ($CI = 12; $CI -lt $ConfigFiles.Count; $CI ++) {
    $file = Get-Content $ConfigFiles[$CI]
    $searchString1 = "server_name"
    $searchString2 = "proxy_pass"
    Write-Output (($CI + 1).ToString() + '/' + $ConfigFiles.Count.ToString() + ' - Processing ' + $ConfigFiles[$CI].Name)
    for ($i = 5; $i -lt $file.Count; $i++) {
        if ($file[$i] -match $searchString1 -or $file[$i] -match $searchString2) {
            
            $ServerName = ($($file[$i]).Trim() -split " ")[1].Replace(";","")
            #Write-Output $($file[$i])
            #Write-Output ('|- Found Server name' + $ServerName)
            #Write-Output ('|- Resolving IP Address of ' + $ServerName)
            Try {
                If ($ServerName -like '*http*') {
                    $Details += ,(New-Object -TypeName PSObject -Property @{
                        FileIndex = $CI
                        File = $ConfigFiles[$CI].Name
                        Line = $i
                        ServerName = $ServerName
                        IPAddress = $IPAddress
                        NamedHost = $NamedHost
                        ProxyPass = $ServerName
                    })
                }
                Else {
                    $IPAddress = (Resolve-DnsName $ServerName).IPAddress
                    #Write-Output ('Resolving Name Servers of ' + $IPAddress)
                    Try {
                        [String[]] $NamedHosts = (Resolve-DnsName $IPAddress).NameHost
                        Foreach ($NamedHost in $NamedHosts) {
                            $Details += ,(New-Object -TypeName PSObject -Property @{
                                FileIndex = $CI
                                File = $ConfigFiles[$CI].Name
                                Line = $i
                                ServerName = $ServerName
                                IPAddress = $IPAddress
                                NamedHost = $NamedHost
                                ProxyPass = $null
                            })
                        }
                    }
                    Catch {
                        $Details += ,(New-Object -TypeName PSObject -Property @{
                            FileIndex = $CI
                            File = $ConfigFiles[$CI].Name
                            Line = $i
                            ServerName = $ServerName
                            IPAddress = $_
                            NamedHost = 'Not Resolved'
                            ProxyPass = $null
                        })
                    }
                }
            }
            Catch {
                $Details += ,(New-Object -TypeName PSObject -Property @{
                        FileIndex = $CI
                        File = $ConfigFiles[$CI].Name
                        Line = $i
                        ServerName = $ServerName
                        IPAddress = $IPAddress
                        NamedHost = $_
                        ProxyPass = $null
                    })
            }
        }

    }
}
$Details | Select-Object FileIndex, File, Line, ServerName, IPAddress, NamedHost, ProxyPass | Out-GridView
#$Details | Select File, ServerName, IPAddress, NamedHost