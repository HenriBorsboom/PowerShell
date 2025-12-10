$HyperVHosts = @("ESKORT-ERMHYPV1", `
    "ESKORT-HBGHYPV1", `
    "ESKORT-NSPHYPV1", `
    "ESKORT-ROOHYPV1", `
    "ESKORT-SVTHYPV1", `
    "ESKORT-XVBHYPV1", `
    "ESKRT-EST-HYPV1")
$Date = '{0:dd/MM/yyyy - HH:mm:ss}' -f (Get-Date)
Clear-Host
ForEach ($Server in $HyperVHosts) {
    If (Test-Connection $Server -Quiet) {
        #Write-Host "Current Server: $Server"
        $Drives =  Get-WmiObject -Query "Select DeviceID,Size,FreeSpace from Win32_LogicalDisk where DriveType = 3" -ComputerName $Server
        $Results = @()
        ForEach ($Drive in $Drives) {
            $Result = New-Object -TypeName PSObject -Property @{
                Server    = $Server
                DeviceID  = $Drive.DeviceID
                Size      = [Math]::Round(($Drive.Size / 1024 /1024 / 1024), 2)
                FreeSpace = [Math]::Round(($Drive.FreeSpace / 1024 / 1024 / 1024) , 2)
                FreePerc  = [Math]::Round(($Drive.FreeSpace / $Drive.Size * 100), 2)
                Date      = $Date
            }
            $Results += $Result
        }
        $Results | Select Server,DeviceID, Size, FreeSpace, FreePerc, Date | Format-Table -AutoSize 
    }
    Else {
        Write-Host "Unable to access: $Server" -ForegroundColor Red
    }
}