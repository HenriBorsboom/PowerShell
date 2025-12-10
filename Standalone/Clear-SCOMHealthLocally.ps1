$ErrorActionPreference = "Stop"

Function Clear-Locally {
    $Services = @(
        "healthservice"
        "System Center Management APM"
        "AdtAgent")
    $ReconfigureServices = @(
        "System Center Management APM"
        "AdtAgent")
    
    ForEach ($Service in $Services) {
        Stop-Service -Name $Service -Force -Verbose
    }
    ForEach ($Service in $ReconfigureServices) {
        Set-Service -Name $Service -StartupType Manual
    }
    Get-ChildItem -Path "c:\Program Files\microsoft Monitoring Agent\Agent\health Service State" -Recurse -Force | Remove-Item -Recurse -Force
    ForEach ($Service in $Services) {
        Start-Service -Name $Service -Verbose
    }
}
Clear-Locally
