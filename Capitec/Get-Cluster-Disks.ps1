

$AllDevices = Get-WmiObject -Class Win32_DiskDrive -Namespace 'root\CIMV2' -Property *
$Disks = @()
ForEach ($Device in $AllDevices) {
    If ($Device.Model -like 'PURE FlashArray*') {
        $Disks += ,(New-Object -TypeName PSObject -Property @{
            Name =$Device.Name;
            Caption=$Device.Caption;
            Index=$Device.Index;
            SizeGB=($Device.Size/1024/1024/1024)
            SerialNo=$Device.SerialNumber;
        })
    }
    ElseIf ($Device.Model -like 'IBM *') {
        $DiskSerial = ("Select Disk " + $Device.Index), "Detail Disk" | DiskPart | Select-String "Disk ID: "
        $Disks += ,(New-Object -TypeName PSObject -Property @{
            Name =$Device.Name;
            Caption=$Device.Caption;
            Index=$Device.Index;
            SizeGB=($Device.Size/1024/1024/1024)
            SerialNo=$DiskSerial;
        })
    }
}
$Disks | Select Index, Name, Caption, SizeGB, SerialNo | Sort Index | Out-GridView
