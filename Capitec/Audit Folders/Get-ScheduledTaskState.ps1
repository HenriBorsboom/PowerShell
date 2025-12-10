# Define list of servers and scheduled task name
$servers = @()  # Update with your server names
$Servers += ,('CBFP01')
$Servers += ,('CBFP02')
$Servers += ,('CBSTBFSFIN01')
$Servers += ,('cbwlpprapw594')
$Servers += ,('cbwlpprapw601')
$Servers += ,('CCPRDAPP131')
$Servers += ,('CCPRDAPP180')
$Servers += ,('ccprdapp187')
$Servers += ,('CCPRDAPP213')
$Servers += ,('ccprdapp227')
$Servers += ,('ccprdapp228')
$Servers += ,('CCPRDAPP229')

$taskName = "Scan File Age"              # Task path, e.g., "\DNS Update Task"

foreach ($server in $servers) {
    try {
        $CimSession = New-CimSession $Server
        Get-ScheduledTask -TaskName $taskName -CimSession $CimSession
    } catch {
        Write-Host ($server + ":`t Could not query task. $_")
    }
    Remove-CimSession $CimSession
}
