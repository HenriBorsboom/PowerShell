Clear-Host
Import-Module VirtualMachineManager
$VMs = @()
$VMs += ,('SYSJHBSCSP01')
$VMs += ,('SYSJHBSCSM01')

ForEach ($VM in $VMs) {
    $SCVM = Get-SCVirtualMachine -Name $VM
    $VMCheckPoints = Get-SCVMCheckpoint -VM $SCVM
    $VMCheckPoints | Select VM, Name, Description
    ForEach ($CheckPoint in $VMCheckPoints) {
        Remove-VMCheckpoint -VMCheckpoint $CheckPoint
    }
}