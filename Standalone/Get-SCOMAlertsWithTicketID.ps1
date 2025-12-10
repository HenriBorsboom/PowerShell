Clear-Host
Import-Module OperationsManager
$Empty = Start-OperationsManagerClientShell -ManagementServerName: "" -PersistConnection: $true -Interactive: $true
$Alerts = Get-SCOMAlert

$AllTickets = @()
ForEach ($Alert in $Alerts) {
    If ($Alert.Severity -eq "Error" -and $Alert.TimeResolved -ne $null) {
        $Ticket = New-Object PSObject @{
            Priority     = $Alert.Priority;
            Name         = $Alert.Name;
            TimeRaised   = $Alert.TimeRaised;
            TimeResolved = $Alert.TimeResolved
            TicketId     = $Alert.TicketID
        }
        Write-Host "Adding " -NoNewline; Write-Host $Alert.TicketID -ForegroundColor Red
        $AllTickets = $AllTickets + $Ticket
    }
}
$AllTickets.TicketID