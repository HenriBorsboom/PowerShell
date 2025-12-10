$OU = 'OU=DEV,OU=Servers,DC=capitecbank,DC=fin,DC=sky'
$Group = 'G_GPO-WSUS-Updates'

Write-Host "Getting servers in group - " -NoNewline
$GroupServers = Get-ADGroup $Group -server cbdc004.capitecbank.fin.sky -Properties members | Select-Object -expand members
$StrippedGroupServers = @()
ForEach ($Server in $GroupServers) {
    $StrippedGroupServers += ,(($Server -split ',')[0].ToString().Replace('CN=',''))
}
Write-Host "Complete"

Write-Host "Getting servers from OU - " -NoNewline
$OUServers = (Get-ADComputer -SearchBase $OU -Filter {Name -like '*' -and Enabled -eq $True} -Server cbdc004.capitecbank.fin.sky).Name
$ServersToRemoveFromADGroup = @()
ForEach ($Server in $OUServers) {
    If ($StrippedGroupServers.Contains($Server)) {
        $ServersToRemoveFromADGroup += ,($Server)
    }
}
Write-Host "Complete"

Write-Host "Confirming results"
$Confirmation = @()
For ($i = 0; $i -lt $ServersToRemoveFromADGroup.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $ServersToRemoveFromADGroup.Count.ToString() + ' - Verifying ' + $ServersToRemoveFromADGroup[$i] + ' - ') -NoNewline
    If ((Get-ADComputer $ServersToRemoveFromADGroup[$i] -Server CBDC004.capitecbank.fin.sky -Properties DistinguishedName).DistinguishedName.ToString().Contains($OU)) {
        Write-Host 'Verified' -ForegroundColor Green
        $Confirmation += ,(New-Object -TypeName PSObject -Property @{
            ServerGroup = $Group
            ServerOU = $OU
            Server = $ServersToRemoveFromADGroup[$i]})
    }
    Else {
        Write-Host 'Failed' -ForegroundColor Red
    }
}
Write-Host "Complete"
$Confirmation | Select-Object Server, ServerGroup, ServerOU | Out-GridView