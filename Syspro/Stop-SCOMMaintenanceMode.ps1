Param (
    [Parameter(Mandatory=$True, Position=1)]
    [String] $Server, `
    [Parameter(Mandatory=$True, Position=2)]
    [String] $Message, `
    [Parameter(Mandatory=$True, Position=3)]
    [Int]   $Duration)


Function Connect-SCOM {
    Write-Host "Connecting to SCOM - " -NoNewline
    Import-Module OperationsManager -ErrorAction Stop
    Try {
        Get-SCOMManagementGroup -ErrorAction Stop | Out-Null
    }
    Catch {
        New-SCOMManagementGroupConnection -ComputerName 'SYSJHBSCOM01.SYSPROZA.NET'
        Write-Host "Complete" -ForegroundColor Green
    }
}
Function Get-SCOMMaintenanceModeObjects {
    Connect-SCOM
    Write-Host "Getting Maintenance Mode Objects"
    $MM = Get-SCOMMaintenanceMode
    #$MM | Select MonitoringObjectId, Comments
    Return $MM
}
Function Start-ServerScommaintenance { 
    Param(
        [Parameter(Mandatory=$True, Position=1)]
        [String] $ServerName, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $Message, `
        [Parameter(Mandatory=$True, Position=3)]
        [Int]    $MaintModeinMinutes) 
 
    Connect-SCOM
    If ( Get-Command -Name 'Get-SCOMClassInstance' ) { 
        $Server = (Get-SCOMClassInstance -DisplayName "$ServerName*") | Select -First 1 | Select -ExpandProperty Displayname 
        $SCOMManagementServers = (Get-SCOMManagementServer).DisplayName
        If ( $SCOMManagementServers -ccontains $Server) { 
            Write-Warning "Specified Server, $Server, contains a Management Server. You cannot put a management server in Maintenance Mode!" 
        } 
        Else { 
            $Time = ((Get-Date).AddMinutes($MaintModeinMinutes)) 
            $ServerClassIds = Get-SCOMClassInstance -DisplayName $Server 
            ForEach ( $ClassID in $ServerClassIds) { 
                $Server1 = Get-SCOMClassInstance -Id ($ClassID.Id) | Where-Object { $_.DisplayName -match $Server } 
                Write-Host "Placing " ($Server1.Id) ' in maintenance Mode Servername -->' ($Server1.DisplayName) 
                If (!(Get-SCOMMaintenanceMode -Instance $ClassID)) { 
                    Start-SCOMMaintenanceMode -Instance $Server1 -EndTime $Time -Reason PlannedOther -Comment $Message 
                } 
                Else { 
                    Write-Host $ClassID.id " has already been placed in Maintenance Mode"
                } 
            } 
        } 
    } 
    Else { 
        Write-Host "The OperationsManager module is not imported for this session"
    }
} 
Function Stop-ServerScommaintenance { 
    Param(
        [Parameter(Mandatory=$True, Position=1)]        
        [String] $ServerName) 
    
    Connect-SCOM
    If (Get-Command -Name 'Get-SCOMClassInstance') { 
        $Server = (Get-SCOMClassInstance -DisplayName "$ServerName*") | Select -First 1 | Select -ExpandProperty Displayname 
        $SCOMManagementServers = (Get-SCOMManagementServer).DisplayName 
        If ($SCOMManagementServers -ccontains $Server) { 
            Write-Warning "Specified Server, $Server, contains a Management Server. You cannot put a management server in Maintenance Mode!" 
        } 
        Else { 
            $ServerClassIds = Get-SCOMClassInstance -DisplayName $Server
            ForEach ($ClassID in $ServerClassIds) { 
                $Server1 = Get-SCOMClassInstance -Id ($ClassID.Id) | Where-Object { $_.DisplayName -match $Server } 
                Write-Host "Removing " ($Server1.Id) ' from maintenance Mode Servername -->' ($Server1.DisplayName) 
                $Result = (Get-SCOMClassInstance -Id ($ClassID.Id) | Where-Object { $_.Displayname -like "$ServerName*" } ).StopMaintenanceMode((Get-Date).ToUniversalTime()) 
            } 
        } 
    } 
    Else { 
        Write-Host "The OperationsManager module is not imported for this session"
    }
} 
Stop-ServerScommaintenance -ServerName $Server