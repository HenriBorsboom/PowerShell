Function Set-VM {
    Write-Host "Renaming the network adapter - " -NoNewline
    Rename-NetAdapter -Name 'Ethernet' -NewName 'Private'
    Write-Host "Complete" -ForegroundColor Green
    $PSUsername = 'Admin1'
    $PSPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force
    $Credential = New-Object PSCredential($PSUsername,$PSPassword)
    Add-Computer -DomainName lab.local -ComputerName $env:COMPUTERNAME -newname LABWSUS2025 -Credential $Credential -Restart
}
Function Install-Roles {
    Install-WindowsFeature UpdateServices -IncludeManagementTools
}