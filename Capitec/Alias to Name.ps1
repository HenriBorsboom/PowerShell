$Aliasses = @()
$Aliasses += ,('bbtreasuryappdev.capitecbank.fin.sky')
$Aliasses += ,('bbtreasuryappqa2.int.capinet')
$Aliasses += ,('bbtreasuryappqa1.int.capinet')
$Aliasses += ,('bbreconappint.capitecbank.fin.sky')
$Aliasses += ,('bbreconappqa2.int.capinet')
$Aliasses += ,('bbreconbatch2.int.capinet')

$Details = @()
For ($i = 0; $i -lt $Aliasses.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Aliasses.Count.ToString() + ' - Processing ' + $Aliasses[$i] + ' - ') -NoNewline
    $NameHost = (Resolve-DnsName $Aliasses[$i]).NameHost
    $Details += ,(New-Object -TypeName PSObject -Property @{
        Alias = $Aliasses[$i]
        NameHost = $NameHost
    })
}
$Details | Out-GridView

$Servers = @()
$Servers += ,('cbawndvapl180')
$Servers += ,('cbawnqaapl029')
$Servers += ,('cbawnqaapl024')
$Servers += ,('cbawndvapl185')
$Servers += ,('cbawnqaapl049')
$Servers += ,('cbawnqaapl048')

$Details1 = @()
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i] + ' - ') -NoNewline
    $NameHost = (Resolve-DnsName $Servers[$i]).IPAddress
    $Details1 += ,(New-Object -TypeName PSObject -Property @{
        Server = $Servers[$i]
        IPAddress = $NameHost
    })
}
$Details1 | Out-GridView