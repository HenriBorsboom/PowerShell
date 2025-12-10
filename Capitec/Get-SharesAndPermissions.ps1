$ErrorActionPreference = 'Stop'

$Shares = Get-SmbShare

$Details = @()

For ($i = 0; $i -lt $Shares.Count; $i ++) {
    $Share = $Shares[$i]
    Write-Host (($i + 1).ToString() + '/' + $Shares.Count + ' - Processing ' + $Shares[$i].Name)
    Try {
        [String[]]$Access = Get-ACL -Path $Share.Path -ErrorAction stop | Select -ExpandProperty AccessToString
        $ACLs = ($Access -split '\n')
        ForEach ($ACL in $ACLs) {
            $SplitACL = $ACL -split " "
            If ($SplitACL.Count -gt 4) {
                #Write-Host ($ACL + " - " + $SplitACL.Count)
                If ($SplitACL[-2] -like '*,*') {
                    $Owner = $SplitACL[0..($SplitACL.Count - 5)] -join ' '
                    $Allow = $SplitACL[-4]
                    $Security = $SplitACL[-2..-1] -join ' '
                }
                Else {
                    $Owner = $SplitACL[0..($SplitACL.Count - 4)] -join ' '
                    $Allow = $SplitACL[-3]
                    $Security = $SplitACL[-1]
                }
                
            }
            Else {
                $Owner = $SplitACL[0]
                $Allow = $SplitACL[-3]
                $Security = $SplitACL[-1]
            }
            
            $Details += ,(New-Object -TypeName PSObject -Property @{
                ShareName = $Share.Name
                SharePath = $Share.Path
                ACLMember = $Owner
                ACLAllow = $Allow
                ACLSecurity = $Security
            }) | Select ShareName, SharePath, ACLMember, ACLAllow, ACLSecurity
        }
    }
    Catch {
        $Details += ,(New-Object -TypeName PSObject -Property @{
                ShareName = $Share.Name
                SharePath = $Share.Path
                ACLMember = $Member
                ACLAllow = $Allow
                ACLSecurity = $Security
            }) | Select ShareName, SharePath, ACLMember, ACLAllow, ACLSecurity
    }
}
$OutFile = ('\\cbfp01\temp\Henri\shares' + $env:COMPUTERNAME + '.csv')
If (Test-Path $OutFile) { Remove-Item $OutFile }
$Details | Select ShareName, SharePath, ACLMember, ACLAllow, ACLSecurity | Export-Csv $OutFile -Delimiter ';' -Force -NoClobber -Encoding ASCII -NoTypeInformation