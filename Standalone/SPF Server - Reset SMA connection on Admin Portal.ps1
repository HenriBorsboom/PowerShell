import-module spfadmin

Get-SCSpfStamp | fl

$stamp = get-SCSpfStamp –name “vmm01.domain2.local”
$SCSPFServer = Get-SCSpfServer -Name "vmm01.domain2.local"
Remove-SCSpfServer -Server $SCSPFServer

New-SCSpfServer –name “vmm01.domain2.local” -ServerType none –Stamps $stamp

$Server = Get-SCSpfServer –name “vmm01.domain2.local”

New-SCSpfSetting –Name EndpointURL –SettingType EndpointconnectionString –Value “https://nrazureapp212.domain2.local:9090/” –Server $Server
