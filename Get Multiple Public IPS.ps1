Clear-Host
#region Getting NAT External Address
Write-Host "Getting NAT External Addresses - " -NoNewline
    $NATExternalAddress = Get-NetNatExternalAddress -ErrorAction Stop
Write-Host "Complete" -ForegroundColor Green
#endregion
#region Processing External Addresses
$PreviousNATName = ""
$PreviousExportFile = ""
ForEach ($NATDetails in $NATExternalAddress) {
    Try {
        If ($NATDetails.NatName -ne $PreviousNATName) {
            $ExportFile = "C:\Temp\" + $NATDetails.NatName + ".CSV"
        }
        ElseIf ($NATDetails.NatName -eq $PreviousNATName) {
            $ExportFile = $PreviousExportFile
        }  
        #region Getting NAT Static Mappings
        Write-Host "Getting Static Mappings for " -NoNewline
        Write-Host $NATDetails.IPAddress -ForegroundColor Yellow -NoNewline
        Write-Host " - " -NoNewline
            $NATStaticMappings = Get-NetNatStaticMapping -NatName $NATDetails.NatName -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
        #endregion
        #region Getting Export NAT Static Mappings
        Write-Host "Exporting NAT Details to " -NoNewline
        Write-Host $ExportFile -ForegroundColor Yellow -NoNewline
        Write-Host " - " -NoNewline
            $NATStaticMappings | Export-Csv -Path $ExportFile -Append -NoClobber -NoTypeInformation -Delimiter ";" -ErrorAction Stop
            #$NATStaticMappings | Format-Table -AutoSize | Out-File $ExportFile -Encoding ascii -Append -Force -NoClobber
        Write-Host "Complete" -ForegroundColor Green
        #endregion
        #region Old Code
        #$NATStaticMappings
        
        #ForEach ($NATStaticMapping in $NATStaticMappings) {
        #    Try {
        #        $Obj = New-Object PSObject -Property @{
        #            NatName           = $NATStaticMapping.NatName
        #            ExternalIPAddress = $NATStaticMapping.ExternalIPAddress
        #            InternalIPAddress = $NATStaticMapping.InternalIPAddress
        #            Protocol          = $NATStaticMapping.Protocol
        #            ExternalPort      = $NATStaticMapping.ExternalPort
        #            InternalPort      = $NATStaticMapping.InternalPort
        #            Active            = $NATStaticMapping.Active
        #        }
        #        $ExportFile = "C:\Temp\" + $NATDetails.IPAddress + " - " + $NATDetails.NatName + ".TXT"
        #        $obj | Format-Table -AutoSize | Out-File $ExportFile -Encoding ascii -Append -Force -NoClobber
        #        $Obj
        #    }
        #    Catch {
        #        Write-Host "Failed" -ForegroundColor Red
        #        Write-Output $_
        #   }
        #}
        #endregion
        $PreviousNATName = $NATDetails.NatName
        $PreviousExportFile = $ExportFile
        $ExportFile = $null
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Output $_
        $ErrorExportFile = $ExportFile + "-ERROR.TXT"
        $_ | Out-File $ErrorExportFile -Append -Encoding ascii -NoClobber -ErrorAction Stop
    }
}
#endregion