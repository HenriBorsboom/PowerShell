<#
.SYNOPSIS
  Report updates approved in the last N days for a specific WSUS target group.

.DESCRIPTION
  Connects to a WSUS server (HTTP/8530 by default), finds all approval entries for the specified
  computer target group (e.g., 'DEV') with Action=Install and CreationDate within the time window.
  Exports CSV and HTML, and prints an on-screen summary.

.NOTES
  Requires the WSUS Administration assembly (installed with WSUS console/RSAT tools).



#>
  param(
    [string]$WsusServer = 'LABWSUS2025',
    [int]$Port = 8530,
    [bool]$UseSsl = $false,
    [string]$TargetGroup = 'DEV',
    [int]$DaysBack = 0,
    [string]$OutCsv = (Join-Path $env:TEMP ("WSUS_Approvals_{0}_{1:yyyy-MM-dd_HHmmss}.csv" -f $TargetGroup,(Get-Date))),
    [string]$OutHtml = (Join-Path $env:TEMP ("WSUS_Approvals_{0}_{1:yyyy-MM-dd_HHmmss}.html" -f $TargetGroup,(Get-Date)))
)


Write-Host "Connecting to WSUS server $WsusServer (Port $Port, UseSsl: $UseSsl)..." -ForegroundColor Cyan

# Load WSUS API
if (-not ([AppDomain]::CurrentDomain.GetAssemblies().Location | Where-Object { $_ -match 'Microsoft.UpdateServices.Administration' })) {
    [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.UpdateServices.Administration') #| Out-Null
}

try {
    $wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($WsusServer, $UseSsl, $Port)
}
catch {
    #Write-Error "Failed to connect to WSUS at $WsusServer:$Port (UseSsl=$UseSsl). $_"
    Write-Error $_
    exit 1
}

# Resolve the target group
$group = $wsus.GetComputerTargetGroups() | Where-Object { $_.Name -eq $TargetGroup }
if (-not $group) {
    Write-Error "WSUS computer target group '$TargetGroup' was not found."
    Write-Host "Available groups:" -ForegroundColor Yellow
    $wsus.GetComputerTargetGroups() | Select-Object Name | Sort-Object Name | Format-Table -AutoSize
    exit 1
}

$since = (Get-Date).Date.AddDays(-1 * [math]::Abs($DaysBack))
Write-Host "Scanning approvals for group '$($group.Name)' since $since ..." -ForegroundColor Cyan

$updates = $wsus.GetUpdates()
$results = New-Object System.Collections.Generic.List[object]
$idx = 0
$approvedUpdates = $updates | Where-Object isApproved -eq $True
foreach ($u in $approvedUpdates) {
    $idx++
    if (($idx % 250) -eq 0) {
        Write-Progress -Activity "Scanning updates" -Status "$idx / $($updates.Count)" -PercentComplete (($idx / $updates.Count) * 100)
    }

    # Some environments expose Categories via GetCategories(), handle both
    try {
        $categories = if ($u.PSObject.Properties.Name -contains 'Categories') { $u.Categories } else { $u.GetCategories() }
    } catch { $categories = @() }

    $classificationTitles = ($categories | Where-Object { $_.Type -eq 'UpdateClassification' } | Select-Object -ExpandProperty Title -ErrorAction SilentlyContinue) -join '; '

    $kb = $null
    if ($u.PSObject.Properties.Name -contains 'KnowledgebaseArticles') {
        $kb = ($u.KnowledgebaseArticles -join ',')
    } elseif ($u.PSObject.Properties.Name -contains 'KnowledgeBaseArticles') {
        $kb = ($u.KnowledgeBaseArticles -join ',')
    } else {
        # fallback: scrape KB* from title
        $kb = ([regex]::Matches($u.Title,'KB\d+')).Value -join ','
    }

    $productTitles = $null
    if ($u.PSObject.Properties.Name -contains 'ProductTitles') {
        $productTitles = ($u.ProductTitles -join ', ')
    } else {
        $productTitles = ($categories | Where-Object { $_.Type -eq 'Product' } | Select-Object -ExpandProperty Title -ErrorAction SilentlyContinue) -join ', '
    }

    $msrc = $null
    if ($u.PSObject.Properties.Name -contains 'MsrcSeverity') { $msrc = $u.MsrcSeverity }

    # Gather approvals for this update that match the group and window
    foreach ($appr in $u.GetUpdateApprovals()) {
        # API property names differ by WSUS build; handle both id props
        $apprGroupMatch = $false
        if ($appr.PSObject.Properties.Name -contains 'ComputerTargetGroupId') {
            $apprGroupMatch = ($appr.ComputerTargetGroupId -eq $group.Id)
        } elseif ($appr.PSObject.Properties.Name -contains 'TargetGroupId') {
            $apprGroupMatch = ($appr.TargetGroupId -eq $group.Id)
        } elseif ($appr.PSObject.Properties.Name -contains 'TargetGroup') {
            $apprGroupMatch = ($appr.TargetGroup.Id -eq $group.Id)
        }

        # Action can be enum or string; normalize to string
        $action = ($appr.Action).ToString()

        if ($apprGroupMatch -and $action -eq 'Install' -and $appr.CreationDate -le $since) {
            $obj = [pscustomobject]@{
                ApprovedOn      = $appr.CreationDate
                TargetGroup     = $group.Name
                Action          = $action
                Deadline        = if ($appr.Deadline -and $appr.Deadline -gt [datetime]::MinValue) { $appr.Deadline } else { $null }
                UpdateTitle     = $u.Title
                KB              = $kb
                UpdateId        = ($u.Id.UpdateId)
                Classification  = $classificationTitles
                IsSuperseded    = $u.IsSuperseded
                IsDeclined      = $u.IsDeclined
                MsrcSeverity    = $msrc
                Products        = $productTitles
                ArrivalDate     = $u.ArrivalDate
            }
            $results.Add($obj) | Out-Null
        }
    }
}

$results = $results | Sort-Object ApprovedOn -Descending

if (-not $results.Count) {
    Write-Warning "No approvals to INSTALL found for group '$($group.Name)' in the last $DaysBack day(s)."
} else {
    # Export CSV
    $null = New-Item -Path (Split-Path $OutCsv) -ItemType Directory -Force -ErrorAction SilentlyContinue
    $results | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $OutCsv

    # Build HTML
    $summary = @"
<h2>WSUS approvals for '$($group.Name)' in the last $DaysBack day(s)</h2>
<p>Server: <b>$WsusServer</b> (Port $Port, SSL: $UseSsl)</p>
<p>Time window: $since to $(Get-Date)</p>
<p>Total approvals: <b>$($results.Count)</b> (distinct updates: <b>$(( $results | Select-Object -ExpandProperty UpdateId -Unique ).Count)</b>)</p>
"@

    $style = @"
<style>
body { font-family: Segoe UI, Arial, sans-serif; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #ddd; padding: 6px; }
th { background: #f3f3f3; position: sticky; top: 0; }
tr:nth-child(even) { background: #fafafa; }
</style>
"@

    $html = $results |
        Select-Object ApprovedOn, TargetGroup, Action, Deadline, KB, UpdateTitle, Classification, MsrcSeverity, Products, IsSuperseded, IsDeclined, ArrivalDate, UpdateId |
        ConvertTo-Html -Title "WSUS Approvals for $($group.Name)" -Head $style -PreContent $summary

    Set-Content -Path $OutHtml -Value $html -Encoding UTF8

    Write-Host ""
    Write-Host "✅ Completed." -ForegroundColor Green
    Write-Host ("Approvals found: {0} (distinct updates: {1})" -f $results.Count, ( $results | Select-Object -ExpandProperty UpdateId -Unique ).Count)
    Write-Host "CSV : $OutCsv"
    Write-Host "HTML: $OutHtml"
}

# Also return objects to the pipeline for immediate inspection if run interactively
$results
