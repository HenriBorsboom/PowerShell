#Clear-Host
$Source = '\\olkas0105\c$\ClusterStorage\Volume3'
$VMXML = Get-ChildItem -Path $Source -Include *.xml -Recurse

$RecreateVMs = @()
For ($i = 0; $i -lt $VMXML.Count; $i ++) {
    Try {
        [xml] $XMLTest = Get-Content $VMXML[$i]
        $VMName = $XMLTest.configuration.properties.name.'#text'
        $XMLValid = $True
    }
    Catch {
        $XMLValid = $False
        $VMName = (([String] (Get-Content $VMXML[$i] | Select-String '<name type="string">olk' -SimpleMatch)).Replace('    <name type="string">', '')).Replace('</name>', '')
    }
    Try {
        Write-Host ((($i) + 1).tostring() + "/" + $VMXML.Count.ToString() + " - Processing " + $VMName + " - ") -nonewline
        If ($XMLValid -eq $true) {
            [String[]] $VMXMLDrives = Get-Content $VMXML[$i] | Select-String ".vhd" -SimpleMatch
            $VMDrives = @()
            For ($x = 0; $x -lt $VMXMLDrives.Count; $x ++) {
                $VMDrives += ,(($VMXMLDrives[$x].replace('        <pathname type="string">', '')).replace('</pathname>', ''))
            }
              
            
            $VMDetails = New-Object -TypeName PSObject -Property @{
                VMName = $XMLTest.configuration.properties.name.'#text'
                VMMemory = $XMLTest.configuration.settings.memory.bank.size.'#text'
                VMCPU = $XMLTest.configuration.settings.processors.count.'#text'
                VMDrives =  $VMDrives
            }
            $RecreateVMs += $VMDetails
            Write-Host "Complete"
        }
        Else {
            Write-Host "XMl Invalid"
        }
    }
    Catch {
        Write-Host "Failed"
        $FailedVMs += ,($XMLTest.configuration.properties.name.'#text')
    }
}
$RecreateVMs