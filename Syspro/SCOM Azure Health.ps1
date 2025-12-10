Import-Module OperationsManager
New-SCOMManagementGroupConnection -ComputerName "SYSJHBOPSMGR.sysproza.net"

Function Get-AzureAgentHealth {
$errorActionPreference = 'Stop'
Set-StrictMode -Version 2

$SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
$SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory “OperationsManager”
Import-module $SCOMModulePath

# set default counts as zero
$totalAgentCount = 0
$UnavailableAgentsCount = 0
$UnmonitoredAgentsCount = 0
$HealthyAgentsCount = 0
$CriticalAgentsCount = 0
$WarningAgentsCount = 0

# get the agent data and put it in a hash
$agents = Get-SCOMAgent | Where-Object {$_.DisplayName -like "*.sysprolive.cloud*" -or $_.DisplayName -like "*.dmc.cloud*"}
# if there's no agents, just simply set all counts to zero
if (!$agents)
{
	# do nothing, the counts will be zero as default
}
else
{
	$totalAgentCount = @($agents).Count

	#map to all agents table
	$allAgentsTable = @{}
	$agents | % {$allAgentsTable.Add($_.DisplayName, $_.HealthState)}
	
	#get the agent watcher class and heartbeat monitor
	$monitor = Get-SCOMMonitor -Name Microsoft.SystemCenter.HealthService.Heartbeat
	$monitorCollection = @($monitor)
	$monitorCollection = $monitorCollection -as [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitor[]]
	$watcherClass = Get-SCOMClass -Name Microsoft.SystemCenter.AgentWatcher
	$watcherInstances = @(Get-SCOMClassInstance -Class $watcherClass)

	#map to all heartbeat monitors table
	$allHeartbeatMonitorsTable = @{}
	$watcherInstances | % {$allHeartbeatMonitorsTable.Add($_.DisplayName, $_.GetMonitoringStates($monitorCollection)[0].HealthState.ToString())}

	#get agents count in different states
	foreach ($agent in $allAgentsTable.GetEnumerator())
	{
		# get count of healthy agents
		if ($agent.Value -eq 'Success' -and $allHeartbeatMonitorsTable[$agent.Name] -eq 'Success')
		{
			$HealthyAgentsCount++
		}
		# get count of warning agents
		elseif ($agent.Value -eq 'Warning' -and $allHeartbeatMonitorsTable[$agent.Name] -eq 'Success')
		{
			$WarningAgentsCount++
		}
		# get count of critical agents
		elseif ($agent.Value -eq 'Error' -and $allHeartbeatMonitorsTable[$agent.Name] -eq 'Success')
		{
			$CriticalAgentsCount++
		}
	}
	# get count of unmonitored agents
	$UnmonitoredAgentsCount = @($allAgentsTable.GetEnumerator() | ? {$_.Value -eq 'Uninitialized'}).Count
	# get count of unavailable agents
	$UnavailableAgentsCount = $totalAgentCount - $HealthyAgentsCount - $WarningAgentsCount - $CriticalAgentsCount - $UnmonitoredAgentsCount

	#check if the Unavailable agents count is negative
	if ($UnavailableAgentsCount -lt 0)
	{
		Write-EventLog -LogName "Operations Manager" -Source "Health Service Script" -EventId 21000 -EntryType Warning -Message "AgentStateRollup script detected the Uavailable agents count is negative, script interrupted, will wait for next execution"
		exit
	}
}
	
#add a helper class to get the localized display strings
$langClass = New-Module {

	$lang = (Get-Culture).ThreeLetterWindowsLanguageName
	$mp = Get-SCOMManagementPack -Name Syspro.SystemCenter.Azure.SummaryDashboard
	# Set localized language to ENU if the expected language is not found in MP
	try
	{
		$temp = $mp.GetDisplayString($lang)
	}
	catch [Microsoft.EnterpriseManagement.Common.ObjectNotFoundException]
	{
		$lang = "ENU"
	}

	function GetLocalizedDisplayString($elementId)
	{
		$mp.FindManagementPackElementByName($elementId).GetDisplayString($lang).Name
	}
	Export-ModuleMember -Variable * -Function *
} -asCustomObject

$api = New-Object -comObject 'MOM.ScriptAPI'
function AddPropertyBag ($Name, [System.Int32]$Value)
{
	if (!$Value) {$Value = 0}

	$bag = $api.CreateTypedPropertyBag(2)
	$bag.AddValue('AgentStates', $Name)
	$bag.AddValue('Value', $Value)
	$api.AddItem($bag)
	$bag
}

#create propertybags for output
AddPropertyBag $langClass.GetLocalizedDisplayString('HeathStateTotal') $totalAgentCount
AddPropertyBag $langClass.GetLocalizedDisplayString('HeathStateUninitialized') $UnavailableAgentsCount
AddPropertyBag $langClass.GetLocalizedDisplayString('HeathStateUnmonitored') $UnmonitoredAgentsCount
AddPropertyBag $langClass.GetLocalizedDisplayString('HeathStateSuccess') $HealthyAgentsCount
AddPropertyBag $langClass.GetLocalizedDisplayString('HeathStateError') $CriticalAgentsCount
AddPropertyBag $langClass.GetLocalizedDisplayString('HeathStateWarning') $WarningAgentsCount
}
Function Get-AzureActiveAlertsv2 {
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

$SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
$SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory “OperationsManager”

Import-module $SCOMModulePath

$API = New-Object -comObject 'MOM.ScriptAPI'
$Bag = $API.CreatePropertyBag()

#$API.LogScriptEvent("GetAzureAlertsCount.ps1",3280,0,"Get Azure Active Alerts Script is starting")

$AlertsCount = 0
$AlertsByObject = Get-SCOMAlert -ResolutionState 0 | Where-Object {$_.PrincipalName -like "*dmc.cloud*" -or $_.PrincipalName -like "*.sysprolive.cloud" -and $_.Severity -ne "Information"} | Group-Object MonitoringObjectId
ForEach ($Alert in $AlertsByObject.GetEnumerator()) {
$AlertsCount = $AlertsCount + $Alert.Count
}

$Bag.AddValue('AlertsCount', [System.Int32]$AlertsCount)
#$API.LogScriptEvent("GetAzureAlertsCount.ps1",3281,0,"Get Azure Active Alerts Script is complete. Number of alerts is $AlertsCount")
$Bag
}
Function Get-ActiveAlerts {
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

$SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
$SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory “OperationsManager”

Import-module $SCOMModulePath

$API = New-Object -comObject 'MOM.ScriptAPI'
$Bag = $API.CreatePropertyBag()

$AlertsCount = 0
$AlertsByObject = Get-SCOMAlert -ResolutionState 0 | Where-Object {$_.Severity -ne "Information"} | Group-Object MonitoringObjectId
ForEach ($Alert in $AlertsByObject.GetEnumerator()) {
$AlertsCount = $AlertsCount + $Alert.Count
}

$Bag.AddValue('AlertsCount', [System.Int32]$AlertsCount)
$Bag
}
Function RepeatAlerts_PowerShellGrid {
$AlertDateWeekBegin = [DateTime]::Today.AddDays(-7)
$AlertDateWeekEnd   = [DateTime]::Today.AddDays(-1).AddSeconds(86399)

$WeekAlerts = Get-SCOMAlert | Where-Object {$_.TimeRaised -gt $AlertDateWeekBegin -and $_.TimeRaised -lt $AlertDateWeekEnd -and $_.Severity -ne 0} | Group-Object Name | Sort -Descending Count | Select-Object -First 10
#$SortedAlerts = $WeekAlerts | Group-Object Name | Sort -Descending Count

$ID = 0
ForEach ($AlertCount in $WeekAlerts) {
    $dataObject = $ScriptContext.CreateInstance("xsd://foo!bar/baz")
    $dataObject["Id"]    = [String]($ID.ToString())
    $dataObject["Count"] = [String]($AlertCount.Count)
    $dataobject["Name"]  = [String]($AlertCount.Name)
    $ScriptContext.ReturnCollection.Add($dataObject)
    $ID ++
}
}
Function RepeatAlertsDetails_PowerShellGrid {
Param($globalSelectedItems)
 
$i = 1
ForEach ($globalSelectedItem in $globalSelectedItems) {
    
    $AlertDateWeekBegin = [DateTime]::Today.AddDays(-7)
    $AlertDateWeekEnd   = [DateTime]::Today.AddDays(-1).AddSeconds(86399)
    $WeekAlerts = Get-SCOMAlert | Where-Object {$_.TimeRaised -gt $AlertDateWeekBegin -and $_.TimeRaised -lt $AlertDateWeekEnd -and $_.Severity -ne 0 -and $_.Name -eq $globalSelectedItem["Name"]}
    ForEach ($relatedItem in $WeekAlerts) { 
        # Create the data object which will be the output for our dashboard.
        $dataObject                        = $ScriptContext.CreateInstance("xsd://foo!bar/baz1")
        $dataObject["Id"]                  = $i.ToString()
        $dataObject["Name"]                = [String]($relatedItem.PrincipalName)
        If ($relatedItem.ResolutionState -eq "255") { $dataObject["ResolutionState"] = "Closed" }
        Else { $dataObject["ResolutionState"] = "New" }
        $dataObject["LastModified"]        = [String]($relatedItem.LastModified)
    
        $ScriptContext.ReturnCollection.Add($dataObject) 
        $i++
    }
}
}
Function DiscoverAzureAgentConfiguration {
$errorActionPreference = 'Stop'
Set-StrictMode -Version 2

$SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
$SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory “OperationsManager”
Import-module $SCOMModulePath

# group agents by version and sort
$configurationGroups = Get-SCOMPendingManagement | Where-Object {$_.AgentName -like "*.dmc.cloud*" -or $_.AgentName -like "*.sysprolive.cloud*"} | group AgentPendingActionType
              
#add a helper class to get the localized display strings
$langClass = New-Module {            
    
	$lang = (Get-Culture).ThreeLetterWindowsLanguageName
	$mp = Get-SCOMManagementPack -Name  Syspro.SystemCenter.Azure.SummaryDashboard
	# Set localized language to ENU if the expected language is not found in MP
	try
	{
	$temp = $mp.GetDisplayString($lang)
	}
	catch [Microsoft.EnterpriseManagement.Common.ObjectNotFoundException]
	{
	$lang = "ENU"
	}

    function GetLocalizedDisplayString($elementId) 
	{            
        $localizedName = $mp.FindManagementPackElementByName($elementId).GetDisplayString($lang).Name
        if (!$localizedName) {$localizedName = $elementId}
        $localizedName
    }            
    Export-ModuleMember -Variable * -Function *                
} -asCustomObject 
            

$api = New-Object -comObject "MOM.ScriptAPI"
$discoveryData = $api.CreateDiscoveryData(0, "$MPElement$", "$Target/Id$")
              
if ($configurationGroups)
{
foreach ($configurationGroup in $configurationGroups)
{
    $instance = $discoveryData.CreateClassInstance("$MPElement[Name='Syspro.SystemCenter.AgentConfiguration']$")
    $localizedName = $langClass.GetLocalizedDisplayString($configurationGroup.Name)
    $instance.AddProperty("$MPElement[Name='Syspro.SystemCenter.AgentConfiguration']/Configuration$", $localizedName)
    $instance.AddProperty("$MPElement[Name='Syspro.SystemCenter.AgentConfiguration']/CountOfConfiguration$", $configurationGroup.Group.Count)

    $discoveryData.AddInstance($instance)
                 
}
}
else
{
    $instance = $discoveryData.CreateClassInstance("$MPElement[Name='Syspro.SystemCenter.AgentConfiguration']$")
    $localizedName = $langClass.GetLocalizedDisplayString("NoConfigurationData")
    $instance.AddProperty("$MPElement[Name='Syspro.SystemCenter.AgentConfiguration']/Configuration$", $localizedName)
    $discoveryData.AddInstance($instance)
}
$discoveryData
}
Function DiscoverAzureAgentVersions {
$errorActionPreference = 'Stop'
Set-StrictMode -Version 2

$SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
$SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory “OperationsManager”
Import-module $SCOMModulePath

# group agents by version and sort
$versionGroups = Get-SCOMAgent | Where-Object {$_.DisplayName -like "*.sysprolive.cloud*" -or $_.DisplayName -like "*.dmc.cloud*"} | group Version, PatchList.Value
              
#add a helper class to get the localized display strings
$langClass = New-Module {            
    
	$lang = (Get-Culture).ThreeLetterWindowsLanguageName
	$mp = Get-SCOMManagementPack -Name  Syspro.SystemCenter.Azure.SummaryDashboard
	# Set localized language to ENU if the expected language is not found in MP
	try
	{
	$temp = $mp.GetDisplayString($lang)
	}
	catch [Microsoft.EnterpriseManagement.Common.ObjectNotFoundException]
	{
	$lang = "ENU"
	}

    function GetLocalizedDisplayString($elementId) 
	{            
        $localizedName = $mp.FindManagementPackElementByName($elementId).GetDisplayString($lang).Name
        if (!$localizedName) {$localizedName = $elementId}
        $localizedName
    }            
    Export-ModuleMember -Variable * -Function *                
} -asCustomObject 

$api = New-Object -comObject "MOM.ScriptAPI"
$discoveryData = $api.CreateDiscoveryData(0, "$MPElement$", "$Target/Id$")

if ($versionGroups)
{
foreach ($versionGroup in $versionGroups)
{
    $name = $versionGroup.Values[0]
    if ($name.Trim() -eq '') {$name = $langClass.GetLocalizedDisplayString("NoVersionData")}
                  
    $instance = $discoveryData.CreateClassInstance("$MPElement[Name='Syspro.SystemCenter.AgentVersions']$")
    $instance.AddProperty("$MPElement[Name='Syspro.SystemCenter.AgentVersions']/Version$", $name)
    $instance.AddProperty("$MPElement[Name='Syspro.SystemCenter.AgentVersions']/CumulativeUpdate$", $versionGroup.Values[1])
    $instance.AddProperty("$MPElement[Name='Syspro.SystemCenter.AgentVersions']/CountOfVersion$", $versionGroup.Group.Count)

    $discoveryData.AddInstance($instance)
}
}
else
{
    $instance = $discoveryData.CreateClassInstance("$MPElement[Name='Syspro.SystemCenter.AgentVersions']$")
    $localizedName = $langClass.GetLocalizedDisplayString("NoAgentsFound")
	$instance.AddProperty("$MPElement[Name='Syspro.SystemCenter.AgentVersions']/CumulativeUpdate$", "")
    $instance.AddProperty("$MPElement[Name='Syspro.SystemCenter.AgentVersions']/Version$", $localizedName)
    $discoveryData.AddInstance($instance)
}
$discoveryData
}