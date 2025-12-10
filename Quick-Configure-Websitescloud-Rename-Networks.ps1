Function Copy-Script {
$Folder = "C:\Temp2"
$empty = New-Item -Path $Folder -ItemType Directory -Force
$empty = Copy-Item .\*.* -Destination $Folder
}
Copy-Script
# External
$ExternalInterface = Get-NetIPAddress | where IPAddress -like '166.233.*'; Rename-NetAdapter -Name $ExternalInterface.InterfaceAlias -NewName "External"

# Back Net
$BackNetInterface = Get-NetIPAddress | where IPAddress -like '10.10.17.*'; Rename-NetAdapter -Name $BackNetInterface.InterfaceAlias -NewName "Ethernet"
