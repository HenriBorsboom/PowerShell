$Users = @()
$Users += ,('CAPITECBANK\CP352158')
$Users += ,('CAPITECBANK\CP352179')
$Users += ,('CAPITECBANK\CP352298')
$Users += ,('CAPITECBANK\CP352402')
$Users += ,('CAPITECBANK\CP352433')
$Users += ,('CAPITECBANK\CP352455')
$Users += ,('CAPITECBANK\CT302328')

$Details = @()
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Users.Count.ToString() + ' - Processing ' + $Users[$i] + ' - ') -NoNewline
    Try {
        Get-ADUser ($Users[$i].Split - '\\')[1] -Server CBDC004.capitecbank.fin.sky
        $Details += ,(New-Object -TypeName PSObject -Property @{
            User = $Users[$i]
            
        })
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            User = $Users[$i]
            
        })
        Write-Host $_ -ForegroundColor Red
    }
}
$Details | Out-GridView