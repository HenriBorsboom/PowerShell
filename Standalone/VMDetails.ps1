$VMs = @(
    "NGNRouter", `
    "SBC2_test", `
    "VPN2", `
    "F2E_Out01", `
    "F2E_CNV01", `
    "Riley_DB01", `
    "Kramer_CS03", `
    "Riley_Out01", `
    "Riley_CS02", `
    "F2E_DB01", `
    "F2E_CS02", `
    "Kramer_CS01", `
    "ngn_sbc_01", `
    "Kramer_DB01", `
    "ngn_sbc_02", `
    "Riley_CNV01", `
    "Whatsup_Gold", `
    "Edge_CS03", `
    "Faxmailer01", `
    "Edge_CS02", `
    "Edge_CS01", `
    "Edge_CNV01", `
    "Kramer_CNV01", `
    "VPN2", `
    "Fax_VPN", `
    "Edge_DB01", `
    "NS1", `
    "Edge_Out01", `
    "VMRouter", `
    "OCR", `
    "Mailscanner", `
    "Riley_CS01", `
    "Kramer_CS02", `
    "stanbank01", `
    "test_colt45", `
    "F2E_CS01", `
    "OCR_Buro", `
    "Kramer_Out01", `
    "Faxmail_Sita")

$VMDetails = @()
$Count = $VMs.Count
$Counter = 1
ForEach ($VM in $VMs) {
    Write-Host ($Counter.ToString() + "/" + $Count.ToString() + " - " + $VM)
    $SCVM = Get-SCVirtualMachine -Name $VM
    #$VMVHDs = Get-SCVirtualHardDisk -VM $SCVM
    
    $TotalDrives = 0
    $Totalsize = 0
    ForEach ($VHD in $SCVM.VirtualHardDisks) {
        $TotalDrives = $TotalDrives + 1
        $TotalSize = $TotalSize + $VHD.MaximumSize
    }
    $VMDetail = New-Object PSObject -Property @{
        "Name"        = $SCVM.Name; -join 
        "Host"        = $SCVM.HostName; -join 
        "OS"          = $SCVM.OperatingSystem; -join 
        "CPU"         = $SCVM.CPUCount; -join 
        "RAM"         = $SCVM.Memory; -join 
        "TotalDrives" = $TotalDrives;
        "TotalSize"   = [Math]::Round(($TotalSize/1024/1024/1024),2);
        "IPs"         = $SCVM.VirtualNetworkAdapters.IPv4Addresses -join ";"
    }
    $VMDetails = $VMDetails + $VMDetail
    $Counter ++
}

$VMDetails | Select Name, Host, OS, CPU, RAM, TotalDrives, TotalSize, IPs | Format-Table -AutoSize
