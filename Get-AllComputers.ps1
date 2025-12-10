Begin {
#region Domain1Credentials 
Write-Host "Creating BCX Cloud Credentials"
$Domain1 = New-Object PSCredential("DOMAIN1\username",(ConvertTo-SecureString "YourPasswordHere" -AsPlainText -Force))
#endregion
    $ErrorActionPreference = "Stop"
    $AllDevices = @()
    $Domain2Hosts = @(
        "NRAZUREVMH101", `
        "NRAZUREVMH102", `
        "NRAZUREVMH103", `
        "NRAZUREVMH104", `
        "NRAZUREVMH105")
    $Domain1Hosts = @(
        "NRAPCDBS101", `
        "NRAPCDBS201")

    Clear-Host
}
Process {
#region Domain2Computers
Write-Host "Getting BCX Online Computer Objects in AD"
$Domain2Computers = Get-ADComputer -Filter { ObjectClass -eq "computer" }
ForEach ($Domain2ComputerObject in $Domain2Computers) {
    $DeviceInfo = New-Object PSObject -Property @{
        DeviceName                = $Domain2ComputerObject.Name
        Type                      = "ADObject"
        Source                    = "Domain2Computers"
    }
    #If ($AllDevices.DeviceName.Contains($DeviceInfo.DeviceName)) { } Else { $AllDevices = $AllDevices + $DeviceInfo }
    $AllDevices = $AllDevices + $DeviceInfo
}
#endregion
#region Domain1Computers
Write-Host "Getting BCX Cloud Computer Objects in AD"
$Domain1Computers = Invoke-Command -ComputerName VMSERVER112 -Credential $Domain1 -ScriptBlock { Get-ADComputer -Filter { ObjectClass -eq "computer" } }
ForEach ($Domain1ComputerObject in $Domain1Computers) {
    $DeviceInfo = New-Object PSObject -Property @{
        DeviceName                = $Domain1ComputerObject.Name
        Type                      = "ADObject"
        Source                    = "Domain1Computers"
    }
    If ($AllDevices.DeviceName.Contains($DeviceInfo.DeviceName)) { } Else { $AllDevices = $AllDevices + $DeviceInfo }
}
#endregion
#region Domain2Hosts
ForEach ($Server in $Domain2Hosts) {
    Write-Host "Getting VMs on $Server"
    $VMs = Get-VM -ComputerName $Server
    ForEach ($VM in $VMs) {
        $DeviceInfo = New-Object PSObject -Property @{
            DeviceName                = $VM.Name
            Type                      = "VM"
            Source                    = $Server
        }
        If ($AllDevices.DeviceName.Contains($DeviceInfo.DeviceName)) { } Else { $AllDevices = $AllDevices + $DeviceInfo }
    }
}
#endregion
#region Domain1Hosts
ForEach ($Server in $Domain1Hosts) {
    Write-Host "Getting VMs on $Server"
    $VMs = Invoke-Command -ComputerName $Server -Credential $Domain1 -ScriptBlock { Get-VM -ComputerName $env:COMPUTERNAME }
    ForEach ($VM in $VMs) {
        $DeviceInfo = New-Object PSObject -Property @{
            DeviceName                = $VM.Name
            Type                      = "VM"
            Source                    = $Server
        }
        If ($AllDevices.DeviceName.Contains($DeviceInfo.DeviceName)) { } Else { $AllDevices = $AllDevices + $DeviceInfo }
    }
}
#endregion
}

End {
    $AllDevices
    $AllDevices | Export-Csv -Path "$env:TEMP\AllComputers.csv" -Force -NoTypeInformation
    notepad "$env:TEMP\AllComputers.csv"
}