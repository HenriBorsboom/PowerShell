$ServerList = @()
ForEach ($ADServer in $ADServers) {
    $list = $ADServer.DistinguishedName -split ','
    [Array]::Reverse($list)
    $OU = ($list -join ',').Replace('DC=sky,DC=fin,DC=capitecbank,','').Replace('OU=','/').Replace(',CN=', '/').Replace(',','')
    $ServerList += ,(New-Object -TypeName PSObject -Property @{
        Server = $ADServer.Name
        OU = $OU
        OperatingSystem = $ADServer.OperatingSystem
    })
}
$ServerList | Select Server, OU, OperatingSystem | Out-GridView