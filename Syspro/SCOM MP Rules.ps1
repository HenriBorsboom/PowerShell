Function AzureHealthStatesRule {
    $errorActionPreference = 'Stop'
    Set-StrictMode -Version 2

    $SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
    $SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory "OperationsManager"
    Import-module $SCOMModulePath

    # set default counts as zero
    $totalAgentCount        = 0
    $UnavailableAgentsCount = 0
    $UnmonitoredAgentsCount = 0
    $HealthyAgentsCount     = 0
    $CriticalAgentsCount    = 0
    $WarningAgentsCount     = 0

    # get the agent data and put it in a hash
    $agents = Get-SCOMAgent | Where-Object {$_.DisplayName -notlike "*.sysproza.net*"}
    # if there's no agents, just simply set all counts to zero
    If (!$agents) {
        # do nothing, the counts will be zero as default
    }
    Else {
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
        ForEach ($agent in $allAgentsTable.GetEnumerator()) {
            # get count of healthy agents
            If ($agent.Value -eq 'Success' -and $allHeartbeatMonitorsTable[$agent.Name] -eq 'Success') {
                $HealthyAgentsCount++
            }
            # get count of warning agents
            ElseIf ($agent.Value -eq 'Warning' -and $allHeartbeatMonitorsTable[$agent.Name] -eq 'Success') {
                $WarningAgentsCount++
            }
            # get count of critical agents
            ElseIf ($agent.Value -eq 'Error' -and $allHeartbeatMonitorsTable[$agent.Name] -eq 'Success') {
                $CriticalAgentsCount++
            }
        }
        # get count of unmonitored agents
        $UnmonitoredAgentsCount = @($allAgentsTable.GetEnumerator() | ? {$_.Value -eq 'Uninitialized'}).Count
        # get count of unavailable agents
        $UnavailableAgentsCount = $totalAgentCount - $HealthyAgentsCount - $WarningAgentsCount - $CriticalAgentsCount - $UnmonitoredAgentsCount

        #check if the Unavailable agents count is negative
        If ($UnavailableAgentsCount -lt 0) {
            Write-EventLog -LogName "Operations Manager" -Source "Health Service Script" -EventId 21000 -EntryType Warning -Message "AgentStateRollup script detected the Uavailable agents count is negative, script interrupted, will wait for next execution"
            exit
        }
    }

    #add a helper class to get the localized display strings
    $langClass = New-Module {
        $lang = (Get-Culture).ThreeLetterWindowsLanguageName
        $mp = Get-SCOMManagementPack -Name  Microsoft.SystemCenter.OperationsManager.SummaryDashboard
        # Set localized language to ENU if the expected language is not found in MP
        Try {
            $temp = $mp.GetDisplayString($lang)
        }
        Catch [Microsoft.EnterpriseManagement.Common.ObjectNotFoundException] {
            $lang = "ENU"
        }

        Function GetLocalizedDisplayString($elementId) {
            $mp.FindManagementPackElementByName($elementId).GetDisplayString($lang).Name
        }
        
        Export-ModuleMember -Variable * -Function *
    } -asCustomObject

    $api = New-Object -comObject 'MOM.ScriptAPI'
    Function AddPropertyBag ($Name, [System.Int32]$Value) {
        If (!$Value) {$Value = 0}

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
Function AzureAlertsCountRule {
    $ErrorActionPreference = 'Stop'
    Set-StrictMode -Version 2

    $SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
    $SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory “OperationsManager”

    Import-module $SCOMModulePath

    $API = New-Object -comObject 'MOM.ScriptAPI'
    $Bag = $API.CreatePropertyBag()

    #$API.LogScriptEvent("GetAzureAlertsCount.ps1",3280,0,"Get Azure Active Alerts Script is starting")

    $AlertsCount = 0
    $AlertsByObject = Get-SCOMAlert -Criteria "ResolutionState = 0 AND Severity NOT LIKE '%Information%' AND PrincipalName NOT LIKE '%.sysproza.net%'" | Group-Object MonitoringObjectId
    ForEach ($Alert in $AlertsByObject.GetEnumerator()) {
        $AlertsCount = $AlertsCount + $Alert.Count
    }

    $Bag.AddValue('AlertsCount', [System.Int32]$AlertsCount)
    #$API.LogScriptEvent("GetAzureAlertsCount.ps1",3281,0,"Get Azure Active Alerts Script is complete. Number of alerts is $AlertsCount")
    $Bag
}
Function EnvironmentAlertsCountRule {
    $ErrorActionPreference = 'Stop'
    Set-StrictMode -Version 2

    $SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
    $SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory “OperationsManager”

    Import-module $SCOMModulePath

    $API = New-Object -comObject 'MOM.ScriptAPI'
    $Bag = $API.CreatePropertyBag()

    #$API.LogScriptEvent("GetEnvironmentAlertsCount.ps1",3280,0,"Get Environment Active Alerts Script is starting")

    $AlertsCount = 0
    $AlertsByObject = Get-SCOMAlert -Criteria "ResolutionState = 0 AND Severity NOT LIKE '%Information%'" | Group-Object MonitoringObjectId
            ForEach ($Alert in $AlertsByObject.GetEnumerator()) {
              $AlertsCount = $AlertsCount + $Alert.Count
              }

    $Bag.AddValue('AlertsCount', [System.Int32]$AlertsCount)
    #$API.LogScriptEvent("GetEnvironmentAlertsCount.ps1",3281,0,"Get Environment Active Alerts Script is complete. Number of alerts is $AlertsCount")
    $Bag
}
Function UnhealthySystems_PowerShellGrid {
    $errorActionPreference = 'Stop'
    Set-StrictMode -Version 2

    $SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
    $SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory "OperationsManager"
    Import-module $SCOMModulePath

    $AlertsByObject = Get-SCOMAlert -Criteria "ResolutionState = 0" | Group-Object Severity
    $UnhealthySystems = $AlertsByObject.Group.PrincipalName | Select -Unique | Sort
    $ID = 0
    ForEach ($System in $UnhealthySystems) {
        $dataObject = $ScriptContext.CreateInstance("xsd://foo!bar/baz02")
        $dataObject["Id"]       = [String]($ID.ToString())
        $dataObject["Computer"] = [String]($System)
        $ScriptContext.ReturnCollection.Add($dataObject)
        $ID ++
    }
}
Function AlertSeverity_PowerShellGrid {
    $errorActionPreference = 'Stop'
    Set-StrictMode -Version 2

    $SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
    $SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory "OperationsManager"
    Import-module $SCOMModulePath

    $AlertsByObject = Get-SCOMAlert -Criteria "ResolutionState = 0" | Group-Object Severity
    $ID = 0
    ForEach ($AlertType in $AlertsByObject) {
        $dataObject = $ScriptContext.CreateInstance("xsd://foo!bar/baz01")
        $dataObject["Id"]       = [String]($ID.ToString())
        $dataObject["Severity"] = [String]($AlertType.Name)
        $dataObject["Count"]    = [String]($AlertType.Count)
        $ScriptContext.ReturnCollection.Add($dataObject)
        $ID ++
    }
}
Function NewestAlerts_PowerShellGrid {
    $errorActionPreference = 'Stop'
    Set-StrictMode -Version 2

    $SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
    $SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory "OperationsManager"
    Import-module $SCOMModulePath

    $Alerts = Get-SCOMAlert -Criteria "ResolutionState = 0" | Sort TimeRaised -Descending
    $MyAlerts = @()
    $ID = 0
    ForEach ($Alert in $Alerts) {
        $AlertDetails = New-Object PSObject -Property @{
            ID = $ID.ToString()
            Age = [String]"{0:HH:mm:ss}" -f ([datetime]((Get-Date)-$Alert.TimeRaised).Ticks)
            Severity = [String]($Alert.Severity)
            Computer = [String]($Alert.PrincipalName)
            Name = [String]($Alert.Name)
        }
        $MyAlerts = $MyAlerts + $AlertDetails
        $ID ++
    }
    $SCOMAlerts = $MyAlerts | Sort Age
    ForEach ($Alert in $SCOMAlerts) {
        $dataObject = $ScriptContext.CreateInstance("xsd://foo!bar/baz03")
        $dataObject["Id"]       = [String]($Alert.ID)
        $dataObject["Age"]      = [String]($Alert.Age)
        $dataObject["Severity"] = [String]($Alert.Severity)
        $dataObject["Computer"] = [String]($Alert.Computer)
        $dataObject["Name"]     = [String]($Alert.Name)
        $ScriptContext.ReturnCollection.Add($dataObject)
    }
}