Function RepeatAlerts {
    $AlertDateWeekBegin = [DateTime]::Today.AddDays(-7)
    $AlertDateWeekEnd   = [DateTime]::Today.AddDays(-1).AddSeconds(86399)

    $WeekAlerts = Get-SCOMAlert -Criteria `
        "TimeRaised >= '$AlertDateWeekBegin' AND TimeRaised <= '$AlertDateWeekEnd' AND Severity <> '0'" | `
        Group-Object Name | Sort -Descending Count | Select-Object -First 10
    
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
Function ContextualAlerts {
    Param($globalSelectedItems)
 
    $i = 1
    ForEach ($globalSelectedItem in $globalSelectedItems) {
    
        $AlertDateWeekBegin = [DateTime]::Today.AddDays(-7)
        $AlertDateWeekEnd   = [DateTime]::Today.AddDays(-1).AddSeconds(86399)
        $AlertName = $globalSelectedItem["Name"]
        $WeekAlerts = Get-SCOMAlert -Criteria "TimeRaised >= '$AlertDateWeekBegin' AND TimeRaised <= '$AlertDateWeekEnd' AND Severity <> '0' AND Name = '$AlertName'"
        ForEach ($relatedItem in $WeekAlerts) { 
            # Create the data object which will be the output for our dashboard.
            $dataObject                        = $ScriptContext.CreateInstance("xsd://foo!bar/baz1")
            $dataObject["Id"]                  = $i.ToString()
            $dataObject["Name"]                = [String]($relatedItem.PrincipalName)
            If ($relatedItem.ResolutionState -eq "255") { $dataObject["ResolutionState"] = "Closed" }
            Else { $dataObject["ResolutionState"] = "New" }
            $dataObject["LastModified"]        = [String]($relatedItem.LastModified)
            $dataObject["AlertID"]             = [String]($relatedItem.id)
            $ScriptContext.ReturnCollection.Add($dataObject) 
            $i++
        }
    }
}
Function ContextualAlertDetails {
    Param($globalSelectedItems)
 
    $i = 1
    ForEach ($globalSelectedItem in $globalSelectedItems) {
    
        $RepeatAlerts = Get-SCOMAlert -Id $globalSelectedItem["AlertID"]
        ForEach ($relatedItem in $RepeatAlerts) { 
            # Create the data object which will be the output for our dashboard.
            $dataObject                  = $ScriptContext.CreateInstance("xsd://foo!bar/baz2")
            $dataObject["Id"]            = $i.ToString()
            $dataObject["PrincipalName"] = [String]($relatedItem.PrincipalName)
            $dataObject["Severity"]      = [String]($relatedItem.Severity)
            $dataObject["Priority"]      = [String]($relatedItem.Priority)
            $dataObject["Description"]   = [String]($relatedItem.Description)
            $dataObject["Context"]       = [String]($relatedItem.Context)    
            $ScriptContext.ReturnCollection.Add($dataObject) 
            $i++
        }
    }
}
Function RepeatAzureAlerts {
    $AlertDateWeekBegin = [DateTime]::Today.AddDays(-7)
    $AlertDateWeekEnd   = [DateTime]::Today.AddDays(-1).AddSeconds(86399)

    $WeekAlerts = Get-SCOMAlert | `
        Where-Object {`
            $_.TimeRaised -gt $AlertDateWeekBegin -and `
            $_.TimeRaised -lt $AlertDateWeekEnd -and `
            $_.Severity -ne 0 -and `
            $_.PrincipalName -like "*.sysprolive.cloud*" -or `
            $_.PrincipalName -like "*.dmc.cloud*"} | `
        Group-Object Name | Sort -Descending Count | Select-Object -First 10

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
