Function Exclude-Service {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object] $Service)

    $Exclude = $False
    ForEach ($Exclusion in $Services_RunAs_Exclusions) {
        If ($Service.StartName -like $Exclusion) {
            $Exclude = $True
        }
    }
    Return $Exclude
}
Function Exclude-Task {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object] $Task)

    $Exclude = $False
    ForEach ($Exclusion in $Tasks_Author_Exclusions) {
        If ($Task.Author -like $Exclusion) {
            $Exclude = $True
        }
    }
    Return $Exclude
}
$ErrorActionPreference = "Stop"
Clear-Host
$Servers = @(
"PRDSQLCLUSTER",
"PRDSQLCLUSTER1",
"PRDSQLLISTNER1",
"PRDSRSCLUSTER01",
"PRDSYSCLUSTER01",
"PRGDRDCINFRA01",
"PRGDRFPINFRA01",
"PRGDRRDSBR01",
"PRGDRRDSGW01",
"PRGDRRDSSH01",
"PRGDRSQLDB01",
"PRGDRSYSAPP01",
"PRGPRDDCINFRA01",
"PRGPRDDCINFRA02",
"PRGPRDFPCL",
"PRGPRDFPINFRA01",
"PRGPRDFPINFRA02",
"PRGPRDOMINFRA01",
"PRGPRDRDSBR01",
"PRGPRDRDSBR02",
"PRGPRDRDSGW01",
"PRGPRDRDSGW02",
"PRGPRDRDSSH001",
"PRGPRDRDSSH002",
"PRGPRDRDSSH01",
"PRGPRDRDSSH02",
"PRGPRDSQLCL",
"PRGPRDSQLDB001",
"PRGPRDSQLDB01",
"PRGPRDSQLDB02",
"PRGPRDSYSAPP001",
"PRGPRDSYSAPP01",
"PRGPRDSYSAPP02",
"PRGPRDSYSCL")
$Tasks_Author_Exclusions = @(
"Adobe Systems Incorporated",
"Intel",
"Microsoft",
"Microsoft Office",
"Microsoft VisualStudio",
"Microsoft Corporation")
$Services_RunAs_Exclusions = @(
"System",
"localSystem",
"NT AUTHORITY")
$OwnerInfo = @()
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    $Failure = $False
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - ' + $Servers[$i] + ' - ') -NoNewline
    Write-Host "Getting Services - " -NoNewline
    Try { 
        $Server_Services = Get-WmiObject -Class Win32_Service -Property DisplayName, StartName -ComputerName $Servers[$i]
        ForEach ($Service in $Server_Services) {
            If (Exclude-Service -Service $Service) {
                $Owner_Service = New-Object -TypeName PSObject -Property @{
                    Server             = $Servers[$i]
                    ServiceDisplayName = $Service.DisplayName
                    ServiceStartName   = $Service.StartName
                    TaskName           = $null
                    TaskAuthor         = $null
                }
                $OwnerInfo += ,($Owner_Service)
            }
        }
    }
    Catch {
        Write-Host "Failed " -ForegroundColor Red -NoNewline
        $Owner_Service = New-Object -TypeName PSObject -Property @{
            Server             = $Servers[$i]
            ServiceDisplayName = $null
            ServiceStartName   = $null
            TaskName           = $null
            TaskAuthor         = $null
        }
        $OwnerInfo += ,($Owner_Service)
        $Failure = $true
    }
    If ($Failure -eq $False) {
        Write-Host "Getting Tasks - " -NoNewline
        Try { 
            $Server_Tasks = Invoke-Command -ComputerName $Servers[$i] -ScriptBlock { Get-ScheduledTask }
            ForEach ($Task in $Server_Tasks) {
                If (Exclude-Task -Task $Task) {
                    $Owner_Task = New-Object -TypeName PSObject -Property @{
                        Server             = $Servers[$i]
                        ServiceDisplayName = $Service.DisplayName
                        ServiceStartName   = $Service.StartName
                        TaskName           = $null
                        TaskAuthor         = $null
                    }
                    $OwnerInfo += ,($Owner_Task)
                }
            }
        } 
        Catch { 
            Write-Host "Failed - " -ForegroundColor Red 
        }
    }
    If ($Failure -eq $true) { Write-Host "Warning" -ForegroundColor Yellow }
    Else { Write-Host "Complete" -ForegroundColor Green }
}
$OwnerInfo | Export-Csv $env:TEMP\Owners.csv -Encoding ASCII -Force -NoClobber -NoTypeInformation -Delimiter ","
$OwnerInfo
Notepad $env:TEMP\Owners.csv
        
