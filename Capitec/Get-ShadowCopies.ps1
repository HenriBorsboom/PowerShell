# Function to check shadow copies on a remote server
function Get-ShadowCopies {
    param (
        [string]$ComputerName
    )
    $ShadowDetails = @()
    try {
        $shadowCopies = Get-WmiObject -Class Win32_ShadowCopy -ComputerName $ComputerName -Credential $Credential
        if ($shadowCopies) {
            ForEach ($Copy in $shadowCopies) {
                $ShadowDetails += ,(New-Object -TypeName PSObject -Property @{
                    ComputerName = $ComputerName
                    ShadowID       = $Copy.ID
                    Volume          = $Copy.VolumeName
                    CreationDate   = [Management.ManagementDateTimeConverter]::ToDateTime($Copy.InstallDate).ToString("yyyy-MM-dd")
                    CreationTime   = [Management.ManagementDateTimeConverter]::ToDateTime($Copy.InstallDate).ToString("HH:mm:ss")
                    Size            = [Math]::Round($Copy.DeviceObject.Length / 1MB, 2) + " MB"
                    ShadowCopyState = "Enabled"
                })
            }
        } else {
            $ShadowDetails += ,(New-Object -TypeName PSObject -Property @{
                ComputerName = $ComputerName
                ShadowID       = $null
                Volume          = $null
                CreationDate   = $null
                CreationTime   = $null
                Size            = $null
                ShadowCopyState = "Disabled"
            })
        }
    } catch {
        $ShadowDetails += ,(New-Object -TypeName PSObject -Property @{
            ComputerName = $ComputerName
            ShadowID       = $null
            Volume          = $null
            CreationDate   = $null
            CreationTime   = $null
            Size            = $null
            ShadowCopyState = $_
        })
        #Write-Output "Failed to retrieve shadow copies from $ComputerName. Error: $_"
    }
    Return $ShadowDetails
}
$ResultsFile = 'C:\Temp\Henri\ShadowCopies\Results.csv'
"ComputerName,ShadowID,Volume,CreationDate,CreationTime,Size,ShadowCopyState" | Out-File $ResultsFile -Encoding ascii -Force
$Details = @()
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i].Name + ' - ') -NoNewline
    Try {
        If (Test-Connection $Servers[$i].Name -Count 2 -Quiet) {
            [Object[]] $Shadows = Get-ShadowCopies $Servers[$i].Name
            ForEach ($Entry in $Shadows) {
                $Details += ,(New-Object -TypeName PSObject -Property @{
                    ComputerName = $Entry.ComputerName
                    ShadowID       = $Entry.ShadowID
                    Volume          = $Entry.Volume
                    CreationDate   = $Entry.CreationDate
                    CreationTime   = $Entry.CreationTime
                    Size            = $Entry.Size
                    ShadowCopyState = $Entry.ShadowCopyState
                })
                ($Entry.ComputerName.ToString() + "," + $Entry.ShadowID.ToString() + "," + $Entry.Volume.ToString() + "," + $Entry.CreationDate.ToString() + "," + $Entry.CreationTime.ToString() + "," + $Entry.Size.ToString() + "," + $Entry.ShadowCopyState.ToString()) | Out-File $ResultsFile -Encoding ascii -Append
            }
            Write-Host "Complete" -ForegroundColor Green
        }
        Else {
            $Details += ,(New-Object -TypeName PSObject -Property @{
                ComputerName = $Servers[$i].Name
                ShadowID       = "Offline"
                Volume          = "Offline"
                CreationDate   = "Offline"
                CreationTime   = "Offline"
                Size            = "Offline"
                ShadowCopyState = "Offline"
            })
            ($Entry.ComputerName.ToString() + "," + "Offline" + "," + "Offline" + "," + "Offline" + "," + "Offline" + "," + "Offline" + "," + "Offline") | Out-File $ResultsFile -Encoding ascii -Append
            Write-Host "Offline" -ForegroundColor Yello
        }
    }
    Catch {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            ComputerName = $Servers[$i].Name
            ShadowID       = $_
            Volume          = $null
            CreationDate   = $null
            CreationTime   = $null
            Size            = $null
            ShadowCopyState = $null
        })
        ($Entry.ComputerName.ToString() + "," + $_ + "," + $null + "," + $null + "," + $null + "," + $null + "," + $null) | Out-File $ResultsFile -Encoding ascii -Append
        Write-Host $_ -ForegroundColor Red
    }
}
$Details | Out-GridView