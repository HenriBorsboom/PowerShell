$COMObjects = Get-ChildItem HKLM:\Software\Classes -ea 0| ? {$_.PSChildName -match '^\w+\.\w+$' -and (gp "$($_.PSPath)\CLSID" -ea 0)} | ft PSChildName

$COMObjects1 = Get-ChildItem HKLM:\Software\Classes -ErrorAction SilentlyContinue
$COMObjects = @()
$COMObjects2 = ForEach ($COMObject in $COMObjects1) {
    If ($COMObject.PSChildname -match '^\w+\.\w+$' -and (Get-ItemProperty "$($_.PSPath)\CLSID" -ErrorAction SilentlyContinue )) {
        $COMObjects = $COMObjects + $COMObject
    }
}
$COMObjects | Format-Table PSChildName


$COMObjects | Where PSChildname -like "*AgentConfigManager*"

Get-ChildItem -ErrorAction 