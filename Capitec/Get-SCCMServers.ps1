#region Start
$SiteCode = "M01" # Site code 
$ProviderMachineName = "SCCMPRD02.mercantile.co.za" # SMS Provider machine name

$initParams = @{}

if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

Set-Location "$($SiteCode):\" @initParams
#endregion

#$SLDC = "DEV"
#$SLDC = "PROD"
$SLDC = "DR"

Switch ($SLDC) {
    "DEV" {
        $DevServers = Get-CMDeviceCollection -Name 'DEV Servers'
        Get-CMDevice -Collection $DevServers | select Name, DeviceOS | Out-GridView
    }
    "PROD" {
        $PRODServers = Get-CMDeviceCollection -Name 'PROD Servers'
        Get-CMDevice -Collection $PRODServers | select Name, DeviceOS | Out-GridView
    }
    "DR" {
        $DRBackupServers = Get-CMDeviceCollection -Name 'DR Backup Servers'
        $DRServers = Get-CMDeviceCollection -Name 'DR Servers'
        Get-CMDevice -Collection $DRBackupServers | select Name, DeviceOS | Out-GridView
        Get-CMDevice -Collection $DRServers | select Name, DeviceOS | Out-GridView
    }
}