# Back Net
$BackNetInterface = Get-NetIPAddress | where IPAddress -like '10.10.16.*'
Rename-NetAdapter -Name $BackNetInterface.InterfaceAlias -NewName "Back Net"

# External
$ExternalInterface = Get-NetIPAddress | where IPAddress -like '165.233.*'
Rename-NetAdapter -Name $ExternalInterface.InterfaceAlias -NewName "External"

# Virtual Switch
$VirtualSwitchInterface = Get-NetIPAddress | where IPAddress -like '169.254.*'
Rename-NetAdapter -Name $VirtualSwitchInterface.InterfaceAlias -NewName "Virtual Switch"
