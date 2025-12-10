$NewComputers = @()
foreach ($computer in $Computers)
{
    [string] $NewComputer = $computer
    $newcomputer = $NewComputer.Remove(0,7)
    $newcomputer = $NewComputer.Remove(($NewComputer.Length) -1 ,1)
    $NewComputers += $NewComputer
}
$NewComputers