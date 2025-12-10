Param (
    [Parameter(Mandatory=$False, Position=1)]
    [String] $Computer = $env:COMPUTERNAME)
Clear-Host
$WQLFilter = "NOT SID = 'S-1-5-18' AND NOT SID = 'S-1-5-19' AND NOT SID = 'S-1-5-20'"
$Users = Get-WmiObject -Class Win32_UserProfile -Filter $WQLFilter -ComputerName $Computer
$FilteredOutput = @()
ForEach ($User in $Users) {
    $FilteredOutput += ,( 
            New-Object -TypeName PSObject -Property @{
                LocalPath = $User.LocalPath
                LastUseTime = [Management.ManagementDateTimeConverter]::ToDateTime($User.LastUseTime)
        }
    )
}
$FilteredOutput | Select LocalPath, LastUseTime