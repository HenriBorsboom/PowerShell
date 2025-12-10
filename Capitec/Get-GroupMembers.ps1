Param ($Group)
#$Group = 'G_AWS_BBBANCSREPORTING_FSX_ADMINS'
$Members = Get-ADGroup $Group -Properties Members -Server CBDC004.capitecbank.fin.sky | Select-Object -ExpandProperty Members
$Users = @()
ForEach ($Member in $Members) {
    $Users += ,(New-Object -TypeName PSObject -Property @{
        Group = $Group
        Users = ($Member -split ",")[0].Replace('CN=','')
    })
}
$Users | Select-Object Group, Users | Out-GridView