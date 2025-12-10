param(
    [string]$WsusServer = 'LABWSUS2025',
    [int]$Port = 8530,
    [bool]$UseSsl = $false,
    $SourceGroupName = 'DEV',
    $TargetGroupName = 'QA',
    [int]$DaysOld = 1,
    [string]$OutCsv = (Join-Path $env:TEMP ("WSUS_QA_Approvals_{0}_{1:yyyy-MM-dd_HHmmss}.csv" -f $TargetGroup,(Get-Date))),
    [string]$OutHtml = (Join-Path $env:TEMP ("WSUS_QA_Approvals_{0}_{1:yyyy-MM-dd_HHmmss}.html" -f $TargetGroup,(Get-Date)))
)

Write-Host "Connecting to WSUS server $WsusServer (Port $Port, UseSsl: $UseSsl)..." -ForegroundColor Cyan

# Load WSUS API
if (-not ([AppDomain]::CurrentDomain.GetAssemblies().Location | Where-Object { $_ -match 'Microsoft.UpdateServices.Administration' })) {
    [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.UpdateServices.Administration')
}

$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($WsusServer, $UseSsl, $Port)

# Get source and target groups
[object] $sourceGroup = $wsus.GetComputerTargetGroups() | Where-Object Name -like $SourceGroupName
[object] $targetGroup = $wsus.GetComputerTargetGroups() | Where-Object Name -like $TargetGroupName

if (-not $sourceGroup -or -not $targetGroup) {
    Write-Error "One or both target groups not found. Available groups:"
    $wsus.GetComputerTargetGroups() | Select-Object Name | Sort-Object Name | Format-Table -AutoSize
    exit 1
}

$cutoffDate = (Get-Date).AddDays(-$DaysOld)
Write-Host ("Finding updates approved for '" + $SourceGroupName.Name + "' before " + $cutoffDate + "...") -ForegroundColor Cyan

$updates = $wsus.GetUpdates()
$approvedForSource = @()
$approvedForTarget = @()

foreach ($update in $updates | Where-Object IsApproved -eq $True) {
    foreach ($approval in $update.GetUpdateApprovals()) {
        if ($approval.ComputerTargetGroupId -eq $sourceGroup.Id -and
            $approval.Action.ToString() -eq 'Install' -and
            $approval.CreationDate -lt $cutoffDate) {
            $approvedForSource += $update
            break
        }
        elseif ($approval.ComputerTargetGroupId -eq $targetGroup.Id -and
            $approval.Action.ToString() -eq 'Install') {
            $approvedForTarget[$update.Id.UpdateId] = $true
            break
        }
    }
}


$newApprovals = @()
foreach ($update in $approvedForSource | Sort-Object Title -Unique) {
    if (-not $approvedForTarget.ContainsKey($update.Id.UpdateId)) {
        $wsus.ApproveUpdate($update, 'Install', $targetGroup)
        $newApprovals += $update
    }
}

# Generate report
$report = $newApprovals | ForEach-Object {
    [pscustomobject]@{
        Title        = $_.Title
        KB           = ($_.KnowledgebaseArticles -join ',')
        Classification = ($_.GetCategories() | Where-Object { $_.Type -eq 'UpdateClassification' } | Select-Object -ExpandProperty Title) -join ', '
        Products     = ($_.GetCategories() | Where-Object { $_.Type -eq 'Product' } | Select-Object -ExpandProperty Title) -join ', '
        ApprovedOn   = (Get-Date)
        UpdateId     = $_.Id.UpdateId
    }
}

$report | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8

$html = $report | ConvertTo-Html -Title "WSUS QA Approvals" -PreContent "<h2>New Approvals for '$TargetGroup'</h2><p>Source Group: $SourceGroup<br/>Cutoff Date: $cutoffDate<br/>Total New Approvals: $($report.Count)</p>"
Set-Content -Path $OutHtml -Value $html -Encoding UTF8

Write-Host "`n✅ Completed." -ForegroundColor Green
Write-Host "New approvals: $($report.Count)"
Write-Host "CSV : $OutCsv"
Write-Host "HTML: $OutHtml"
