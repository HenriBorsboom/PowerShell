Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)

    $ErrorActionPreference = "Stop"
    Try {
        If ($Text.Count -ne $ForegroundColor.Count) {
            Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $ForegroundColor.Count.ToString()) -ForegroundColor Red
            Throw
        }
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch { 
        Write-Host "Text Count:  " $Text.Count
        Write-Host "Color Count: " $ForegroundColor.Count
        Write-Host $_
    }
}

Clear-Host
$ExportFile = 'C:\Temp\Test.htm'
If (Test-Path $ExportFile) { Remove-Item $ExportFile }
Write-Color -Text 'Starting Job to collect Incidents - ' -ForegroundColor White -NoNewLine
$Incidents = Start-Job -ScriptBlock { 
    Import-Module 'C:\Program Files\Microsoft System Center 2012 R2\Service Manager\PowerShell\System.Center.Service.Manager.psm1'
    Import-Module SMLets

    Get-SCSMClassInstance -Class (Get-SCSMClass -Name System.WorkItem.Incident) | ?{$_.Status.Name -eq "IncidentStatusEnum.Active"}
}

$Counter = 1
While ($Incidents.State -eq "Running") {
    Write-Host "." -NoNewline
    Sleep 1
    $Counter ++
}
Write-Color -Text 'Complete' -ForegroundColor Green
$Results = Get-Job | Receive-Job
Get-Job | Remove-Job

$OpenIncidents = @()
For ($i = 0; $i -lt $Results.Count; $i ++) {
    Write-Color -Text (($i + 1).ToString() + '/' + $Results.Count.ToString()), ' - Collecting Information for ', $Results[$i].ID, ' - ' -ForegroundColor Cyan, White, DarkCyan, White -NoNewLine
    $Inc = Get-SCSMIncident -ID $Results[$i].Id -WarningAction SilentlyContinue
    $Open = New-Object PSObject -Property @{
        ID           = $Inc.ID
        Title        = $Inc.Title
        AssignedTo   = $Inc.AssignedTo
        Status       = $Inc.Status
        Priority     = $Inc.Priority
        AffectedUser = $Inc.AffectedUser
        LastModified = $Inc.LastModified
    }
    $OpenIncidents = $OpenIncidents + $Open
    Write-Color -Text 'Complete' -ForegroundColor Green
}
Write-Color -Text 'Exporting information to HTML - ' -ForegroundColor White -NoNewLine
$HTMLHeader = "<style>                                               
    BODY{font-family: Arial; font-size: 8pt;}                                              
    H1{font-size: 16px;}                                               
    H2{font-size: 14px;}                                               
    H3{font-size: 12px;}                                               
    TABLE{border: 1px solid black; border-collapse: collapse; font-size: 8pt;}                                         
    TH{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}                                           
    TD{border: 1px solid black; padding: 5px; }                                            
    td.pass{background: #7FFF00;}                                             
    td.warn{background: #FFE600;}                                             
    td.fail{background: #FF0000; color: #ffffff;}                                          
    </style>"
$Properties = @(
    "ID"
    "Title"
    "AssignedTo"
    "Status"
    "Priority"
    "AffectedUser"
    "LastModified")
$OpenIncidents = $OpenIncidents | Sort LastModified -Descending | Select $Properties
$OpenIncidents = $OpenIncidents | ConvertTo-HTML -Head $HTMLHeader -Body "<H2>Open Incidents</H2>" 
$OpenIncidents = $OpenIncidents | Out-File $ExportFile
Write-Color -Text 'Complete' -ForegroundColor Green
Invoke-Expression $ExportFile