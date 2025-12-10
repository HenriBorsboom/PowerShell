Function CompareServices {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [Object] $ReferenceServerWMI, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $ReferenceServer, `
        [Parameter(Mandatory=$true, Position=3)]
        [String] $TargetServer)

    $TargetServerWMI = Get-WmiObject -Query "Select Caption,StartMode from Win32_Service" -ComputerName $TargetServer
    $FoundMismatch = @()
    Write-Host "$ReferenceServer - $TargetServer" -ForegroundColor Cyan
    ForEach ($Service in $ReferenceServerWMI) {
        If($TargetServerWMI.contains($Service)) {} 
        Else {
            $OutputResult = $ReferenceServer + ";" + $TargetServer + ";" + $Service.Caption + ";" + $Service.StartMode
            Write-Host $OutputResult -ForegroundColor Yellow -BackgroundColor Black
            $FoundMismatch = $FoundMismatch + $OutputResult
        }
    }
    Return $FoundMismatch
}
Function 1 {


$Servers = @(
    "NRAPCAPP201", `
    "NRAPCAPP202", `
    "NRAPCAPP203", `
    "NRAPCAPP204")
$ExportResult = @()
ForEach ($ReferenceServer in $Servers) {
    $ReferenceWMI = Get-WmiObject -Query "Select Caption,StartMode from Win32_Service" -ComputerName $ReferenceServer
    ForEach ($TargetServer in $Servers) {
        If ($TargetServer -ne $ReferenceServer) {
            $ExportResult = $ExportResult + (CompareServices -ReferenceServerWMI $ReferenceWMI -ReferenceServer $ReferenceServer -TargetServer $TargetServer)
        }
    }
}
$ExportResult | Out-File c:\temp\mismatchservices.txt -Encoding ascii -Append -Force -NoClobber
}
Function 2 {
$Server1 = "NRAZUREVMH104"
$Server2 = "NRAZUREVMH105"

$Server1WMI = Get-WmiObject -Query "Select Caption,StartMode from Win32_Service" -ComputerName $Server1
$Server2WMI = Get-WmiObject -Query "Select Caption,StartMode from Win32_Service" -ComputerName $Server2

Write-Host "$Server1" -ForegroundColor Cyan
ForEach ($Service in $Server1WMI) {
    If($Server2WMI.contains($Service)) {
        #Write-Host "Found"
        #Write-Host $Service.Caption "-" $Service.StartMode
    } 
    Else {
        #Write-Host "Not Found"
        Write-Host $Service.Caption "-" $Service.StartMode -ForegroundColor Red
    }
}


}
Function 3 {
#region Null Values
$Server1 = $null
$Server2 = $null
$Service1 = $null
$ReferenceWMI = $null
$ReferenceResult = $null
$TargetWMI = $null
$TargetResult = $null
#endregion
Clear-Host
$Server1 = "NRAPCAPP203"
$Server2 = "NRAPCAPP204"
$Service1 = "Windows Presentation Foundation Font Cache 3.0.0.0"

#region Reference Check
$ReferenceWMI = Get-WmiObject -Query "Select Caption,StartMode from Win32_Service" `
    -ComputerName $Server1
    
$ReferenceResult = $ReferenceWMI | Where Caption -eq $Service1 `
| Select Caption,StartMode `
| Sort Caption
Write-Host $ReferenceResult
#endregion
#region Target Check
$TargetWMI = Get-WmiObject -Query "Select Caption,StartMode from Win32_Service" `
-ComputerName $Server2

$TargetResult = $TargetWMI | Where Caption -eq $Service1 `
| Select Caption,StartMode `
| Sort Caption
Write-Host $TargetResult
#endregion

}
Function 4 {
Get-WindowsFeature -ComputerName NRAPCAPP201 | Where InstallState -eq Installed | Install-WindowsFeature -Source $Location
}
