Function Get-ApprovedUpdates {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Server
        
    )
    $OutputFolder = 'C:\Temp\Henri\WSUS'
    If (-not (Test-Path $OutputFolder)) {
        New-Item $OutputFolder -ItemType Directory
    }
    $OutputPath = ($OutputFolder + '\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '_ApprovedUpdates.csv')

    # Check if the WSUS module is available
    If (-not (Get-Module -ListAvailable -Name UpdateServices)) {
        Write-Error "The WSUS PowerShell module is not installed. Please install it before running this script."
        Exit 1
    }

    # Array to store the results
    $ApprovedUpdates = @()

    Try {
        Write-Host "|- Connecting to WSUS Server: $Server - " -NoNewline
        # Connect to the WSUS server
        $WSUS = Get-WSUSServer -Name $Server -PortNumber 8530
        Write-Host "Connected" -ForegroundColor DarkCyan
        # Get the default Update view

        Write-Host "|- Getting Updates - " -NoNewline
        # Retrieve all approved Updates
        $ApprovedUpdatesOnServer = Get-WSUSUpdate -UpdateServer $WSUS -Approval Approved

        Write-Host "Found $($ApprovedUpdatesOnServer.Count) approved updates on $Server."
        ForEach ($Update in $ApprovedUpdatesOnServer) {
            $ApprovedUpdates += [PSCustomObject]@{
                "Server"          = $Server
                "Title"           = $Update.Update.Title
                "KBArticleIDs"    = ("KB" + $Update.Update.KnowledgebaseArticles | Out-String).Trim()
                "Product"         = ($Update.Update | ForEach-Object {$_.ProductTitles}) -join "; "
                "Classification"  = $Update.Update.UpdateClassificationTitle
                "Approved"        = $Update.Update.IsApproved
                "Declined"        = $Update.Update.IsDeclined
                "IsSuperseded"    = $Update.Update.IsSuperseded
                "Ready"           = $Update.Update.State
                "DatePublished"   = $Update.Update.CreationDate
                "SecurityBulletin" = ($Update.Update.SecurityBulletins | Out-String).Trim()
                "MsrcSeverity"     = $Update.Update.MsrcSeverity
            }
        }
    }
    Catch {
        Write-Error "|- Error connecting to or retrieving Updates from WSUS Server: $Server - $($_.Exception.Message)"
    }

    # Export the collected approved Updates to CSV
    If ($ApprovedUpdates) {
        Write-Host "|- Exporting $($ApprovedUpdates.Count) approved Updates to: $OutputPath - " -NoNewline
        $ApprovedUpdates | Export-Csv -Path $OutputPath -NoTypeInformation
        Write-Host "Export complete." -ForegroundColor Green
    } 
    Else {
        Write-Host "|- No approved Updates found on the specified servers." -ForegroundColor Red
    }
}
$WSUSServers = @()
$WSUSServers += ,('ccprdapp039')
$WSUSServers += ,('cbawpprapw023')
$WSUSServers += ,('Cbvmpprapw116')

For ($i = 0; $i -lt $WSUSServers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $WSUSServers.Count.ToString() + ' - Processing ' + $WSUSServers[$i])
    Get-ApprovedUpdates -Server $WSUSServers[$i]
}