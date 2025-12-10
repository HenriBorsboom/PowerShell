Param (
    [Parameter(Mandatory=$true, Position = 1)]
    [String] $Filter)
    
Get-SCIPAddress | Where Name -like $Filter | Select Name, Description | Sort Name