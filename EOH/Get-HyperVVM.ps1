Function Get-HyperVVMS {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $VMHost)
        
    If ((Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption' -ComputerName $VMHost).Caption -like '*2008*') {
        $Namespace = 'root\virtualization'
    }
    ElseIf ((Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption' -ComputerName $VMHost).Caption -like '*2012*') {
        $Namespace = 'root\virtualization\v2'
    }
    Else {
        $Namespace = 'root\virtualization'
    }
    $VMs = Get-WmiObject -Query "Select * from MSVM_ComputerSystem Where Caption = 'Virtual Machine'" -Namespace $Namespace -ComputerName $VMHost
    Return $VMs
}
$Servers = @()
$Servers += ,("BL-BASE1")
$Servers += ,("BL-BASE2")
$Servers += ,("BL-BASE3")
$Servers += ,("BL-BASE4")

$AllVMs = @()
ForEach ($Server in $Servers) {
    $AllVMs += Get-HyperVVMS -VMHost $Server
}
$AllVMs