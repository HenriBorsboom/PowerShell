[XML] $GlobalConfig = Get-Content 'C:\HealthCheck\Scripts\Config.xml'
ForEach ($Folder in $GlobalConfig.Settings.Sources.ChildNodes) {
    If (!(Test-Path $Folder.'#text')) {
        New-Item $Folder.'#text' -ItemType Directory | Out-Null
    }
}