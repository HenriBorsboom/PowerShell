$Modules = @(
'C:\Program Files\Microsoft System Center 2012 R2\Service Manager\Microsoft.EnterpriseManagement.Warehouse.Cmdlets.dll'
'C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\Microsoft.PowerShell.Management\Microsoft.PowerShell.Management.psd1'
'C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\Microsoft.PowerShell.Utility\Microsoft.PowerShell.Utility.psd1'
'C:\Program Files\WindowsPowerShell\Modules\PSReadline\1.2\PSReadLine.psm1'
'C:\Program Files\Microsoft System Center 2012 R2\Service Manager\Powershell\System.Center.Service.Manager.psm1')

ForEach ($Module in $Modules) { Import-Module $Module }