Clear-Host
$Server = 'CBDC002.capitecbank.fin.sky'
$Users = @()
$Users += ,('CP352134')
$Users += ,('CP352143')
$Users += ,('CP352147')
$Users += ,('CP352148')
$Users += ,('CP352195')
$Users += ,('CP352214')
$Users += ,('CP352220')
$Users += ,('CP352253')
$Users += ,('CP352266')
$Users += ,('CP352307')
$Users += ,('CP352346')
$Users += ,('CP352459')
$Users += ,('CP352845')
$Users += ,('CP352849')
$Users += ,('CP352851')
$Users += ,('CP352593')
$Users += ,('CP352541')
$Users += ,('CP352578')
$Users += ,('CP352596')
$Users += ,('CP363614')


$Details = @()
For ($i = 0; $i -lt $Users.Count; $i ++) {
    Write-Output (($i + 1).ToString() + '/' + $Users.Count.ToString() + ' - Processing ' + $Users[$i])
    $User = Get-ADUser $Users[$i] -Server $Server -Properties Department, Manager, Enabled | Select-Object SAMAccountName, Name, Enabled, Department, @{Name="Manager"; Expression={($_.Manager -split ',')[0].Replace('CN=','')}}
    $Details += ,(New-Object -TypeName PSObject -Property @{
        SAMAccountName = $User.SAMAccountName
        Name = $User.Name
        Enabled = $User.Enabled
        Department = $User.Department
        Manager = $User.Manager
    })
}
$Details | Where-Object Enabled -eq $True | Sort-Object Manager | Format-Table -AutoSize
#$Details | Out-GridView