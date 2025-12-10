$OUs = Get-ADOrganizationalUnit -SearchBase 'OU=Servers,DC=capitecbank,DC=fin,DC=sky' -Filter {Name -like '*'} -Server cbdc004.capitecbank.fin.sky | Select-Object DistinguishedName
$RewritingOUs = @()
For ($i = 0; $i -lt $OUs.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $OUs.Count.ToString() + ' - Processing ' + $OUs[$i].DistinguishedName) -NoNewline
    $Split = $OUs[$i].DistinguishedName -split ','
    $Rewrite = @()
    For ($x = ($Split.Count - 1); $x -ge 0; $x --) { 
        If ($Split[$x] -notlike 'DC=*') {
            $Rewrite += $Split[$x].Replace('OU=', '')
        }
    }
    $RewritingOUs += New-Object -TypeName PSObject -Property @{
        Rewrite = $ReWrite -join '\'
        Original = $OUs[$i].DistinguishedName
    }
}
$RewritingOUs | Out-GridView