<Configuration>
  <IntervalSeconds>900</IntervalSeconds>
  <SyncTime />
  <ScriptName>GetMGAlertsCount.ps1</ScriptName>
  <ScriptBody>
$errorActionPreference = 'Stop'
Set-StrictMode -Version 2

$SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
$SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory “OperationsManager”
Import-module $SCOMModulePath

$alertsCount = 0
$alertsByObjectHash = @{}
$alertsByObject = Get-SCOMAlert -ResolutionState 0 | Where-Object {$_.PrincipalName -like "*dmc.cloud*" -or $_.PrincipalName -like "*.sysprolive.cloud"} | group MonitoringObjectId
if (!$alertsByObject)
{
    # do nothing, alerts count is zero as default
}
else
{
    function PopulateClassHash($class)
    {
        if (!$allMGRelatedClassHash.ContainsKey($class.Id))
        {
            $allMGRelatedClassHash.Add($class.Id, $class.Name)
        
            # recursively get target classes in relationships with source is current class and add into the hashtable
            $relationships = @(Get-SCOMRelationship -Source $class) | Where {$_.Base.GetElement().Name -ne "System.Reference"}
            if ($relationships)
            {
                foreach ($relationship in $relationships)
                {
                    PopulateClassHash $relationship.Target.Type.GetElement()
                }
            }
        }
    }

    $mgClass = Get-SCOMClass -Name "Microsoft.SystemCenter.AllOperationsManagerObjectsGroup"
    $mgGroup = Get-SCOMGroup -Id $mgClass.Id
    $mgMembers = $mgGroup.GetChildMonitoringObjectGroups()
    $firstLvlMemberClassHash = @{}

    foreach ($member in $mgMembers)
    {
        $cls = $member.GetClasses()
        foreach ($c in $cls)
        {
            if (!$firstLvlMemberClassHash.ContainsKey($c.Id))
            {
                $firstLvlMemberClassHash.Add($c.Id, $c.name)
            }
        }
    }

    $allMGRelatedClassHash = @{}

    # populate the all MG related class hashtable
    foreach ($firstLvlMember in $firstLvlMemberClassHash.GetEnumerator())
    {
        $firstLvlClass = Get-SCOMClass -Id $firstLvlMember.Name
        PopulateClassHash $firstLvlClass
    }

    $alertsByObject | % {$alertsByObjectHash.Add($_.Name, $_.Count)}

    foreach ($obj in $alertsByObjectHash.GetEnumerator())
    {
        $objInstance = Get-SCOMClassInstance -Id $obj.Name
        $objClasses = $objInstance.GetClasses()
        foreach ($objCls in $objClasses)
        {
            if ($allMGRelatedClassHash.ContainsKey($objCls.Id))
            {
                $alertsCount += $obj.Value
                break
            }
        }
    }
}

$api = New-Object -comObject 'MOM.ScriptAPI'
$bag = $api.CreateTypedPropertyBag(2)
$bag.AddValue('AlertsCount', [System.Int32]$alertsCount)
$api.AddItem($bag)
$bag
</ScriptBody>
  <Parameters />
  <TimeoutSeconds>300</TimeoutSeconds>
  <StrictErrorHandling>false</StrictErrorHandling>
  <ObjectName>ManagementGroupAlerts</ObjectName>
  <CounterName>AlertsCount</CounterName>
  <InstanceName>Total</InstanceName>
  <Value>$Data/Property[@Name='AlertsCount']$</Value>
</Configuration>

$StrictErrorHandling/Handling$
$ObjectName/ManagementGroupAlerts$
$CounterName/AlertsCount$
$InstanceName/Total$