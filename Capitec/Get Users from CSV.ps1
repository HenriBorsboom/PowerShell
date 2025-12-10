$CSVFiles = Get-ChildItem '\\cbfp01\temp\Henri' -File

For ($i = 0; $i -lt $CSVFiles.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $CSVFiles.Count.ToString() + ' - Processing ' + $CSVFiles[$i].FullName)
    $CSVData = Import-Csv $CSVFiles[$i].FullName
    If ($null -eq $CSVData) {
        Write-Host '|- Empty file' -ForegroundColor Yellow
    }
    Else {
        $Details = @()
        For ($x = 0; $x -lt $CSVData.Count; $x ++) {
            Write-Host ('|- ' + ($x + 1).ToString() + '/' + $CSVData.Count.ToString() + ' - Getting User ' + $CSVData[$x].User + ' - ') -NoNewline
            $User = ($CSVData[$x].User -split '\\')[1]
            Try {
                $Username = (Get-ADUser $User -Server CBDC004.capitecbank.fin.sky).Name
            }
            Catch {
                $Username = (Get-ADUser $User -Server CBDC004.capitecbank.fin.sky).Name
            }
            $Details += ,(New-Object -TypeName PSObject -Property @{
                ShareName = $CSVData.ShareName[0]
                User = $CSVData[$x].User
                UserName = $Username
            })
            Write-Host $Username
        }
    
        $Details | Select-Object ShareName, User, UserName | Export-CSV $CSVFiles[$i].FullName.Replace('.csv', '_Updated.csv') -Delimiter ',' -NoTypeInformation
    }
}