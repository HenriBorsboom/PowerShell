Param (
    [Parameter(Mandatory=$True, Position=1)]
    [String] $Computer)

$Installed = Get-WmiObject -class Win32_OperatingSystem -ComputerName $Computer -Property LastBootupTime | Select-Object @{label='LastBootupTime';expression={$_.ConvertToDateTime($_.LastBootupTime)}}
    
$Details = New-Object PSObject -Property @{
    "Computer" = $Computer
    "BootTime" = $Installed.LastBootupTime
}

$Details