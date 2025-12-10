$SleepTime = 5
$Properties = @('Username', 'Computername', 'Sharename')
$Details = @()
$OutFile = 'C:\temp\Henri\Active_Sessions.csv'
'"Username";"Computername";"Sharename";"Date"' | Out-File $OutFile -Encoding ascii -Force
While ($True) {
    $Details = Import-Csv $OutFile -Delimiter ';'
    $AddCounter = 0
    $OpenFiles = Get-WmiObject win32_serverconnection | Select-Object $Properties
    $Date = get-date -Format('yyyy/MM/dd HH:mm:ss')
    Write-Output ($Date + ' - Processing ' + $OpenFiles.Count.ToString())
    For ($i = 0; $i -lt $OpenFiles.Count; $i ++) {
        If ($Details.Username -contains $OpenFiles[$i].Username -and $Details.Computername -contains $OpenFiles[$i].ComputerName -and $Details.Sharename -contains $OpenFiles[$i].ShareName) {
        }
        Else {
            $Details += ,(New-Object -TypeName PSObject -Property @{
                Username = $OpenFiles[$i].Username
                Computername = $OpenFiles[$i].ComputerName
                Sharename = $OpenFiles[$i].Sharename
            })
            ('"' + $OpenFiles[$i].Username + '";"' + $OpenFiles[$i].ComputerName + '";"' + $OpenFiles[$i].Sharename + '";"' + $Date + '"') | Out-File $OutFile -Encoding ascii -Append
            $AddCounter ++
        }
    }
    Write-Output ('|- ' + $AddCounter.ToString() + ' files added.')
    Remove-Variable Details
    Remove-Variable OpenFiles
    [GC]::Collect()
    Start-Sleep -Seconds ($SleepTime * 60)
}

#$Details | Select Path, ClientUserName, CommonName, Department, Description, Manager | Export-Csv C:\temp\filter.csv -Delimiter ',' -Force -NoTypeInformation