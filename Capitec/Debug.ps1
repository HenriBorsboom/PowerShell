Function Clear-DebugLogs {
    Get-ChildItem ($GlobalConfig.Settings.Sources.LogFolder + 'Debug\' + $StartTime.Tostring("yyyy-MM-dd")) | Remove-Item
    #Get-ChildItem ($ReportFolder + ((Get-Date).ToString("yyyy-MM-dd"))) -Recurse | Remove-Item -Force -Recurse
}
Function Clear-Reports {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Environment)
}
$Server = $Env:ComputerName
$User = 'BB-Infrastructure'
[XML] $GlobalConfig = Get-Content 'C:\HealthCheck\Scripts\Config.xml'

$Server
$user
$GlobalConfig
