Import-Module 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.DeployAutomation'
Import-Module 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.ImageBuilder'
Import-Module 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.Cis.Core'
Import-Module 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.Cloud'
Import-Module 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.Common'
Import-Module 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.Core'
Import-Module 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.HA'
Import-Module 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.HorizonView'
Import-Module 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.License'
Import-Module 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.PCloud'
Import-Module 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.Sdk'
Import-Module 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.Storage'
Import-Module 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.Vds'
Import-Module 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.vROps'
Import-Module 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VumAutomation'


Connect-VIServer -Server 10.31.251.152 -Username root -Password 'P@ssw0rd1'
Clear-Host
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host "Getting VMs"
$SourceVMs = Get-VM | Select *
$ROBORESXI01VMs = $SourceVMs | Where VMHost -like '*roboresxi01*'
$ROBORESXI02VMs = $SourceVMs | Where VMHost -like '*roboresxi02*'
$ROBORESXI03VMs = $SourceVMs | Where VMHost -like '*roboresxi03*'

Function Move-HostVMS {
    Param ($VMList, $Target)
    
    For ($i = 0; $i -lt $VMList.Count; $i ++) {
        Write-Host (($i + 1).ToString() + '/' + $VMList.Count.ToString() + ' - Moving VM ' + $VMList[$i].Name + ' to ' + $Target + ' - ') -ForegroundColor Yellow
        Move-VM $VMList[$i].Name -Destination $Target
        Write-Host 'Complete' -ForegroundColor Green
    }
}
#Prep Host 1 for reboot
#Move 1 to 3
Move-HostVMS -VMList $ROBORESXI01VMs -Target 'roboresxi03.bwsteel.co.za'
#Reboot Host 1

#Prep Host 2 for reboot
#Move 2 to 1
Move-HostVMS -VMList $ROBORESXI02VMs -Target 'roboresxi01.bwsteel.co.za'
#Reboot Host 2

#Prep Host 3 for reboot
#Move 1 to 2
$ROBORESXI02VMs = Get-VM | Where-Object {$_.VMHost -like '*roboresxi01*'}
Move-HostVMS -VMList $ROBORESXI02VMs -Target 'roboresxi02.bwsteel.co.za'
#Move 3 to 1
Move-HostVMS -VMList $ROBORESXI03VMs -Target 'roboresxi01.bwsteel.co.za'
Move-HostVMS -VMList $ROBORESXI01VMs -Target 'roboresxi01.bwsteel.co.za'
#Reboot Host 3

#Balance
Move-HostVMS -VMList $ROBORESXI03VMs -Target 'roboresxi03.bwsteel.co.za'
