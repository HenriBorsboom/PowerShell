Clear-Host
#region Registry Hives and Keys
$HKCR = 2147483648 #HKEY_CLASSES_ROOT
$HKCU = 2147483649 #HKEY_CURRENT_USER
$HKLM = 2147483650 #HKEY_LOCAL_MACHINE
$HKUS = 2147483651 #HKEY_USERS
$HKCC = 2147483653 #HKEY_CURRENT_CONFIG

$Keys = @(
    "SOFTWARE\Microsoft\Microsoft SQL Server\110\Tools\Setup", `
    "SOFTWARE\Microsoft\Microsoft SQL Server\110\DQ\Setup", `
    "SOFTWARE\Microsoft\Microsoft SQL Server\140\Tools\Setup", `
    "SOFTWARE\Microsoft\Microsoft SQL Server\140\DQ\Setup")
#endregion
#region Servers
$Servers = Get-ADComputer -Filter {Name -like "NRA*"}
$Servers = $Servers | Sort Name
$Servers = $Servers | Select -Unique
$Servers = $Servers.Name
$ExcludeServers = Get-Content "C:\temp\Computers\Exclude.TXT"
#endregion
ForEach ($Server in $Servers) {
    If ($ExcludeServers -notcontains $Server) {
        $RegConnection = [WMIClass]"\\$Server\root\default:StdRegprov"
        ForEach ($Key in $Keys) {
            $value = "Edition"
            $Edition = $RegConnection.GetStringValue($HKLM, $key, $value) ## REG_SZ
            $Edition = $Edition.sValue
            If ($Edition -ne $null) {Write-Host "$Server - $Edition"}
        }
    }
}



