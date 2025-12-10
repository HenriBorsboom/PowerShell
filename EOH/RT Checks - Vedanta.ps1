$HyperVHosts = @(
    "ABSKSKO141", `
    "ABSKSKO142", `
    "ABSKSKO146")
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