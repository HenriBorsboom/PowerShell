clear-host
$NewComputers = @()
$Computers = get-adcomputer -Filter "Name -like 'NRAZURE*'" | select name
foreach ($computer in $Computers)
{
    [string] $NewComputer = $computer
    $newcomputer = $NewComputer.Remove(0,7)
    $newcomputer = $NewComputer.Remove(($NewComputer.Length) -1 ,1)
    $NewComputers += $NewComputer
}

Foreach ($Server in $NewComputers)
{
    
    $WMIObject = Get-WmiObject -Query "Select HotfixID from Win32_QuickFixEngineering" -ComputerName $Server | Select HotFixID
    
    foreach ($Patch in $WMIObject)    {        [string] $NewID = $Patch
        $NewID = $NewID.Remove(0,11)
        $NewID = $NewID.Remove(($NewID.Length) -1 ,1)
            $OutputObj  = New-Object -Type PSObject        $OutputObj | Add-Member -MemberType NoteProperty -Name HotFixID -Value $NewID -ErrorAction Stop        $OutputObj | Add-Member -MemberType NoteProperty -Name Server -Value $Server
        #$OutputObj    }    Write-Host "Completed Server $Server"    }
$OutputObj | Export-Csv -Path .\Patches.txt -NoClobber -NoTypeInformation
