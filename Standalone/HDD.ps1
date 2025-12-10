$PhysicalHosts = @("NRAZUREVMH101","NRAZUREVMH201","NRAZUREVMH103")

ForEach ($PhysHost in $PhysicalHosts) {
    $VMS = Get-VMIDsOnHost -VMHosts $PhysHost

    ForEach ($VMID in $VMS) {
        $VHD = Get-VHD -VMId $VMID.ID -ComputerName $PhysHost
         Write-Host $VMID.VM -ForegroundColor Cyan
         $VHDDetails = $VHD | select Path, Size
         ForEach ($item in $VHDDetails) {
            Write-Host $item
        }
         Write-Host

    }
}
