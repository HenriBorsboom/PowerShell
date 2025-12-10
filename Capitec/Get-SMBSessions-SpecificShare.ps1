$ErrorActionPreference = 'Stop'
$SleepTime = 5
$Properties = @('Username', 'Computername', 'Sharename')
$ShareName = 'Users'
$Details = @()
$OutFile = ('C:\temp\Henri\' + $env:COMPUTERNAME + '_Active_Sessions.csv')
Try {
    $SplitPath = $OutFile -Split '\\'
    For ($Spliti = 0; $Spliti -lt ($SplitPath.Count - 1); $Spliti ++) {
            Write-Output ($SplitPath[0..$Spliti] -join '\')
            If (!(Test-Path ($SplitPath[0..$Spliti] -join '\'))) {
                    New-Item ($SplitPath[0..$Spliti] -join '\') -ItemType Directory | Out-Null
            }
    }
    If ((Test-Path $OutFile)) {
            $OutFile = (($SplitPath[0..($SplitPath.Count-2)] -join '\') + '\'+ (get-date -Format('yyyy-MM-dd HH-mm-ss')) + '__' + $SplitPath[-1])
    }
}
Catch {
    Write-Output $_
}
'"Username";"Computername";"Sharename";"Date"' | Out-File $OutFile -Encoding ascii -Force
While ($True) {
    $AddCounter = 0
    $OpenFiles = Get-WmiObject -Query ("Select Username, ComputerName, ShareName from win32_serverconnection Where Sharename = '" + $ShareName + "'") | Select-Object $Properties
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
    Start-Sleep -Seconds ($SleepTime * 60)
}

#$Details | Select Path, ClientUserName, CommonName, Department, Description, Manager | Export-Csv C:\temp\filter.csv -Delimiter ',' -Force -NoTypeInformation