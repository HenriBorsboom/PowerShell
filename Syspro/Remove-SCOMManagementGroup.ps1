Function RemoveMG {
    Param ($Server)

    $ErrorActionPreference = "Stop"
    
    Write-Host "Entering PSSession - " -NoNewline
    Invoke-Command -Session (New-PSSession -ComputerName $Server) -ScriptBlock {
    #Enter-PSSession -ComputerName $Server
    Write-Host "Complete" -ForegroundColor Green

    Write-Host "Creating COM object - " -NoNewline
    $SCOMAgent = New-Object -ComObject "AgentConfigManager.MgmtSvcCfg"
    Write-Host "Complete"

    Write-Host "Disabling Active Directory Integration - " -NoNewline
    $SCOMAgent.DisableActiveDirectoryIntegration()
    Write-Host "Complete"

    Write-Host "Current Management Groups - "
    $SCOMAgent.GetManagementGroups()
    Write-Host "Complete"

    Write-Host "Getting SYSPRO-JHB - " -NoNewline
    $OldManagementGroup = $SCOMAgent.GetManagementGroups() | Where-Object {$_.ManagementGroupName -like "*syspro-jhb*"}
    If (!($OldManagementGroup -eq $null -or $OldManagementGroup -eq "")) {
        Write-Host "Complete"
        Write-Host "Removing Group" -NoNewline
        $SCOMAgent.RemoveManagementGroup($OldManagementGroup.managementGroupName.ToString())
        Write-Host "Complete"
        Write-Host "Restarting HealthService - " -NoNewline
        Restart-Service HealthService
        Write-Host "Complete"
    }
    Else {
        Write-Host "Not Found" -ForegroundColor Red
    }
    Write-Host "Getting Management Groups - " -NoNewline
    $SCOMAgent.GetManagementGroups()
    Write-Host "Complete"
    Write-Host "Exiting PS Session - " -NoNewline
    }
    Write-Host "Complete"
}
Clear-Host
Write-Host "Getting SCOM Agents - " -NoNewline
$Agents = Get-SCOMAgent | Where DisplayName -like "*.sysproza.net" | Sort DisplayName | Select DisplayName
Write-Host "Complete"
$FailedComputers = @()
For ($I = 0; $I -lt $Agents.COunt; $I ++) {
    Write-Host (($I + 1).ToString() + "/" + $Agents.Count) -ForegroundColor Cyan -NoNewline; Write-Host " - Processing " -NoNewline; Write-Host $Agents[$i].DisplayName -ForegroundColor Yellow; Write-Host " - "
    Try { RemoveMG -Server $Agents[$i].DisplayName; Write-Host "Complete" -ForegroundColor Green }
    Catch { Write-Host "Failed - $_" -ForegroundColor Red; $FailedComputers = $FailedComputers + $Agents[$i].DisplayName }
}
$FailedComputers