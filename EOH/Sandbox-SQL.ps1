Clear-Host

#$AdminCreds = Get-Credential

$Servers = @()
$Servers += , ("EOH-CLOUD-DC04")
$Servers += , ("EOH-CLOUD-DHCP")
$Servers += , ("EOHBEDFS01")
$Servers += , ("EOHCLOUDADFS")
$Servers += , ("EOHCLOUDDIRSYNC")
$Servers += , ("EOHCLOUDRMS01")
$Servers += , ("EOHCLOUDRMS02")
$Servers += , ("EOHDCCRMQV")
$Servers += , ("EOHDCINV02V")
$Servers += , ("EOHERSCRMAPP01V")
$Servers += , ("EOHQNP")
$Servers += , ("EOHQRL")
$Servers += , ("EOHQSDev")
$Servers += , ("EOHQSProd")
$Servers += , ("EOHTERSPAPP02")
$Servers += , ("EOHTERSPDB01")
$Servers += , ("EOHTERSPDEV01")
$Servers += , ("EOHTERWEB01")


$Details = @()

For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - ' + $Servers[$i] + ' - ') -NoNewline
    $Products = Get-WmiObject -Class Win32_Product -ComputerName $Servers[$i] -Credential $AdminCreds
    If ($Products.Name -like '*SQL*') {
        $ServerDetails = New-Object -TypeName PSObject -Property @{
            Server = $Servers[$i]
            Apps   = ($Products.Name -like '*SQL*')
        }
        $Details += ,($ServerDetails)
        Write-Host "Added" -ForegroundColor Yellow
    }
    Else {
        Write-Host "Nothing" -ForegroundColor Green
    }
}
$Details

$NewDetails = @()

For ($y = 0; $y -lt $Details.Count; $y ++) {
    $NewDetails += ,(New-Object -TypeName PSObject -Property @{
        Server = $Details[$y].Server
        Apps   = $Details[$y].Apps -join ","
    })
}

$NewDetails | Fl
