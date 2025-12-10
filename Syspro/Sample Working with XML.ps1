Function Get-ConfigXML {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$False, Position=0)]
        [String] $XMLFilePath)
	
	If (Test-Path "$XMLFilePath") {
        Try {
			Write-Host " Loading Variable.xml... " -NoNewline
			$global:Variable = [XML](Get-Content "$XMLFilePath" -ErrorAction Stop)
			Write-Host -ForegroundColor 'Green' "Loaded"
			
			# Script Component Variables
			Write-Host -ForegroundColor 'Cyan' " Setting Component Variables" 
			$Components = $Variable.Test.Component | ForEach-Object {$_.Name}
			$Components | ForEach-Object {
				$Component = $_
				$Variable.Installer.Components.Component | Where-Object {$_.Name -eq $Component} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -ne $null} | ForEach-Object {
					Invoke-Expression ("`$Script:" + $_.Name + " = `"" + $_.Value + "`"")
				}
			}
		}
		Catch [system.exception] {
			$Validate = $false
			Write-Host -ForegroundColor 'Red' "Failed to read XML File Definitions for $xmlFileName" 
			Write-Host -ForegroundColor 'Red' "Error: $($_.Exception.Message)"
			Stop-Transcript
			Exit $ERRORLEVEL
		}
	}	
	Else {
		$Validate = $false
		Write-Host -ForegroundColor 'Red' "Unable to locate $xmlFileName"
		Stop-Transcript
		Exit $ERRORLEVEL
	}
}
Get-ConfigXML "C:\users\henri\Scripts\Powershell\ORK\Test2.XML"
$Variable:03Test1

