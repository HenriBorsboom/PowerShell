Function Copy-Script {
$Folder = "C:\Temp2"
$empty = New-Item -Path $Folder -ItemType Directory -Force
$empty = Copy-Item .\*.* -Destination $Folder
}
Copy-Script

Function InstallRoles {
    $Source = "\\nrazurefls101\Windows Server 2012 R2 ISO Extract\sources\sxs"
    $Features = @()
    $Feature1 = Get-WindowsFeature -Name "NET-Framework-Core"
    $Feature2 = Get-WindowsFeature -Name "NET-Framework-Core"
    $Features = $Features + $Feature1
    $Features = $Features + $Feature2

    Install-WindowsFeature -Name $Features -Source $Source
}