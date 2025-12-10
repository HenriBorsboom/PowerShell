# ---------------------------------------------------
# Script: D:\PowerShellGrid_v0.3.ps1
# Version: 0.4
# Author: Stefan Stranger
# Date: 05/19/2014 21:19:49
# Description: PowerShell Grid Widget Helper Function
# Comments: With the latest OM2012 UR2 update new Dashboard Widgets have been added. 
# This helper function helps with the creation of the PowerShell script code needed Grid Widget
# Links: http://blogs.technet.com/b/stefan_stranger/archive/2014/04/28/new-powershell-grid-widget-walkthrough.aspx
# Know issues:
# - First object in returned array will be used as ID property [solved]
# - If a property of an object has multiple values this will not displayed correctly [solved]
# Changes: [04-30-2014]: Added new Id Parameter. This should be an unique property of the objects
#          [05-19-2014]: Added string type to all output objects  
# Disclaimer: 
# This example is provided “AS IS” with no warranty expressed or implied. Run at your own risk. 
# **Always test in your lab first**  Do this at your own risk!! 
# The author will not be held responsible for any damage you incur when making these changes!
# ---------------------------------------------------


Function Show-PSGridWidgetCode
{
<#
.Synopsis
   Create Script code for use in new OM12R2 UR2 PowerShell Grid Widgets.
.DESCRIPTION
   The output of this function can be copied to the Operations Manager Console to create the 
   script code for creating the new PowerShell Grid Widgets.
.EXAMPLE
   Show-PSGridWidgetCode -scriptblock {Get-Service | Select Name, Status}
   This command show the script code needed to create a PowerShell Grid Widget showing the
   Windows NT Services properties Name and Status on the machine where the console is running.
   You can copy the output to the console to have a head start creating the new Widget.
   PS C:\Scripts\PS> Show-PSGridWidgetCode -scriptblock {Get-Service | Select Name, Status} -Id "Name"
        $inputobject = Get-Service | Select Name, Status
        foreach ($object in $inputobject)
        {
            $dataObject = $ScriptContext.CreateInstance("xsd://foo!bar/baz")
            $dataObject["Id"] = ($object.Name).ToString()
                        $dataObject["Name"] = ($object.Name).ToString()
            $dataObject["Status"] = ($object.Status).ToString()
            $ScriptContext.ReturnCollection.Add($dataObject)
        } 
#>
    [CmdletBinding()]
    Param
    (
        # Inputobject parameter
        [Parameter(Mandatory=$true,
                 ValueFromPipelineByPropertyName=$false,
                 Position=0)]
                 [scriptblock]$scriptblock,
        # Name parameter
        [Parameter(Mandatory=$true,
                  ValueFromPipelineByPropertyName=$false)]
                  [string]$id
                 )
                              
        $properties = ((&$scriptblock | Get-Member -MemberType Properties).name)
        #Find properties with a collection of objects
        foreach ($property in $properties)
        {
            $property = $property -join ","
            $testherestring = @"
            `$dataObject["$property"] = [String](`$object.$property)
"@
            [string]$total += "$testherestring`n"
        }

        $script = @"
        `$inputobject = $scriptblock
        foreach (`$object in `$inputobject)
        {
            `$dataObject = `$ScriptContext.CreateInstance("xsd://foo!bar/baz")
            `$dataObject["Id"] = [String](`$object.$id)
            $total            `$ScriptContext.ReturnCollection.Add(`$dataObject)
        }

"@
    
        $script 

}