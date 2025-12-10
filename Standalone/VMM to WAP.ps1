$Servers = @(
    "VIP-Cloud-SCCM", `
    "VIP-Cloud-CPGP", `
    "VIP-CLOUD-IDL", `
    "VIP-CLOUD-QLINK", `
    "VIP-Cloud-ESS", `
    "VIP-Cloud-Medscheme", `
    "VIP-CLOUD-SAMEngineering", `
    "VIP-CURO", `
    "VIP-CLOUD-BDC", `
    "VIP-Cloud-XenApp2", `
    "VIP-CLOUD-PPL", `
    "VIP-CLOUD-STORTECH", `
    "VIP-Cloud-MangolongoloTransport", `
    "VIP-Cloud-HRToolbox", `
    "VIP-CLOUD-FOCUS", `
    "VIP-CLOUD-QSA", `
    "VIP-CLOUD-MQA", `
    "VIP-CLOUD-GMT", `
    "VIP-CLOUD-IZAZI", `
    "VIP-CLOUD-FGF", `
    "VIP-LDE", `
    "VIP-MORE", `
    "VIP-CLOUD-BIC", `
    "VIP-CLOUD-ASCENT", `
    "VIP-CLOUD-BAR", `
    "VIP-CLOUD-H2R", `
    "VIP-CLOUD-FFC", `
    "VIP-CLOUD-DEUTS", `
    "VIP-CLOUD-SRAS", `
    "VIP-CLOUD-DB", `
    "VIP-EFKON", `
    "VIP-PG_LABOUR", `
    "VIP-CLOUD-WPACK", `
    "VIP-CLOUD-PSC", `
    "VIP-CLOUD-MACSF", `
    "VIP-CLOUD-TEST", `
    "VIP-CONVISTA", `
    "VIP-TRIDENT", `
    "VIP-MRM", `
    "VIP-RUSMAR", `
    "VIP-GearHold", `
    "VIP-Limberger", `
    "VIP-ASSET", `
    "VIP-ELS", `
    "VIP-MOTION", `
    "VIP-VIKING", `
    "VIP-BINGO", `
    "VIP-PENFORD", `
    "VIP-WESTERN", `
    "VIP-RG_CONS", `
    "VIP-Cloud-Medscheme2", `
    "VIP-P-CORP", `
    "VIP-TFSE", `
    "VIP-VETUS", `
    "VIP-MEDSCHEME", `
    "VIP-CORREDOR", `
    "VIP-RECKITT", `
    "VIP-SPACE", `
    "VIP-FISHING", `
    "VIP-DUMMY", `
    "VIP-MOTHERS", `
    "VIP-SACLAWA", `
    "VIP-OCTOGEN", `
    "VIP-DEMO-ESS", `
    "VIP-COAL", `
    "VIP-TAXI", `
    "VIP-GPI", `
    "VIP-JWT", `
    "VIP-ENSIGHT", `
    "VIP-FCB", `
    "VIP-AXIOMATIC", `
    "VIP-FALCORP", `
    "VIP-SYNERGY", `
    "VIP-CLOUD-FTP", `
    "VIP-CLOUD-NAGIOS", `
    "VIP-HRM", `
    "VIP-PERNOD", `
    "VIP-AFB", `
    "VIP-GP_CONS", `
    "VIP-HERITAGE", `
    "VIP-GAUTENG", `
    "VIP-CAMBRIDGE", `
    "VIP-CLOUD-BCSG", `
    "VIP-DONAVENTA", `
    "VIP-STUDIO", `
    "VIP-LIQUID", `
    "VIP-LEAD", `
    "VIP-REALPAY", `
    "VIP-TERRASAN", `
    "VIP-VALE")
$Servers = @(
"VIP-ARMADA", `
"VIP-CREATIVE")

Function RemoveVMNIC {
Try{
ForEach ($Server in $Servers) {
    Write-Host "$Server - " -NoNewline
    $VMServer = Get-SCVirtualMachine -Name $Server
    $VirtualNetworkAdapter = Get-SCVirtualNetworkAdapter -VM $VMServer

    $Empty = Remove-SCVirtualNetworkAdapter -VirtualNetworkAdapter $VirtualNetworkAdapter
    Write-Host "Done" -ForegroundColor Green
}
}
Catch {
    Write-Host "Failed" -ForegroundColor Red
    Write-Output $_
    Break
}
}

Function SetStamp {
    Param ($vmnametarget)
    Try {
    $VMNameTarget= "NRAZUREBCK102"
    $SCVMMSERVER = Get-SCVMMServer -ComputerName vmm01.domain2.local -ForOnBehalfOf 
    #Get-SCVirtualMachine -name StampVM |ft name, selfserviceuserrole, owner 
    $vmnamesource = "VIP-AFB"
    $vminfo = Get-SCVirtualMachine -name $vmnamesource
    $vmowner = $vminfo.owner
    $vmselfserviceuserrole = $vminfo.selfserviceuserrole
    Write-Host "Setting $VMNameTarget - " -NoNewline
    $Empty = Set-SCVirtualMachine –VM $vmnametarget –UserRole $vmselfserviceuserrole –Owner $vmowner
    Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Output $_
        Break
    }
}

ForEach ($Server in $Servers) {
    
$VM = Get-SCVirtualMachine -VMMServer vmm01.domain2.local -Name $Server
$OperatingSystem = Get-SCOperatingSystem -VMMServer vmm01.domain2.local | where {$_.Name -eq "64-bit edition of Windows Server 2008 R2 Standard"}
$UserRole = Get-SCUserRole -VMMServer vmm01.domain2.local  -Name "e5589114-39bf-41af-90ee-38c_b222b18a-8a02-4594-93ed-1cde1a463196"

$Cloud = Get-SCCloud -VMMServer vmm01.domain2.local | where {$_.Name -eq "Business Connexion Azure Pack"}

Set-SCVirtualMachine -VM $VM -Name $Server -Description "" -OperatingSystem $OperatingSystem -Owner "username@domain2.local" -UserRole $UserRole -Cloud $Cloud -RunAsSystem

}
