Function Set-VM {
    Write-Host "Renaming the network adapter - " -NoNewline
    Rename-NetAdapter -Name 'Ethernet' -NewName 'Private'
    Write-Host "Complete" -ForegroundColor Green
    $PSUsername = 'Admin1'
    $PSPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force
    $Credential = New-Object PSCredential($PSUsername,$PSPassword)
    Add-Computer -DomainName lab.local -ComputerName $env:COMPUTERNAME -newname LABISCSI2025 -Credential $Credential -Restart
}
Function Install-Roles {
    Install-WindowsFeature FS-iSCSITarget-Server -IncludeManagementTools
}
Function Set-Disk {
    Get-Disk | Where-Object partitionstyle -eq 'RAW' | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "ISCSI" -Confirm:$false
}
Function New-iSCSIDisk {
    New-Item -Path D:\ISCSI -ItemType Directory | Out-Null
    New-IscsiVirtualDisk -Path "D:\iSCSI\iSCSI.vhdx" -Size 10GB | Out-Null
    New-IscsiVirtualDisk -Path "D:\iSCSI\Quorum.vhdx" -Size 1GB | Out-Null
}
Function New-iSCSITargetGroup {
    New-iSCSITarget -TargetName "LabCluster" -InitiatorID @("IPAddress:11.0.0.2","IPAddress:10.0.0.3")
}
Function Set-iSCSIDISK {
    Add-IscsiVirtualDiskTargetMapping -TargetName "LabCluster" -DevicePath "D:\iSCSI\iSCSI.vhdx"
    Add-IscsiVirtualDiskTargetMapping -TargetName "LabCluster" -DevicePath "D:\iSCSI\Quorum.vhdx"
}