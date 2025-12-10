$SCVMMSERVER = Get-SCVMMServer -ComputerName vmm01.domain2.local -ForOnBehalfOf 
$vmnamesource = "ngn_sbc_01"

get-vm -name $vmnamesource |ft name, selfserviceuserrole, owner 


$vmnametarget = "Edge_CS03"

$vminfo = Get-SCVirtualMachine -name $vmnamesource

$vmowner = $vminfo.owner

$vmselfserviceuserrole = $vminfo.selfserviceuserrole

Set-SCVirtualMachine –VM $vmnametarget –UserRole $vmselfserviceuserrole –Owner $vmowner








