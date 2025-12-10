$ErrorActionPreference = 'Stop'
$Accounts = @()
Write-Host "Getting Accounts associated with CP - " -NoNewline
$Accounts += (Get-ADUser -Filter {Name -like '*335596*'} -Server cbdc004.capitecbank.fin.sky)
$Accounts += (Get-ADUser 'CP335596' -Server CBDC004.capitecbank.fin.sky)
Write-Host "Complete" -ForegroundColor Green

$Details = @()
For ($i = 0; $i -lt $Accounts.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Accounts.Count.ToString() + ' - Processing account ' + $Accounts[$i].Name + ' - ') -NoNewline
    $AccountGroups = Get-ADUser -Identity $Accounts[$i].SamAccountName -Properties MemberOf -Server cbdc004.capitecbank.fin.sky | Select-Object -ExpandProperty MemberOf
    ForEach ($Group in $AccountGroups) {
        Try {
            $Description = (Get-ADGroup ($Group -split ",")[0].Replace("CN=", "") -Server cbdc004.capitecbank.fin.sky -Properties Description).Description
        }
        Catch {
            $Description = ''
        }
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Account = $Accounts[$i].Name
            Group = ($Group -split ",")[0].Replace("CN=", "")
            Description = $Description
        })
    }
    Write-Host 'Complete' -ForegroundColor Green
}
$Details | Export-CSV 'C:\Temp\CP335596_Details - Craig.csv' -Encoding ascii -Delimiter ';' -NoHeader
$Details | Out-GridView
