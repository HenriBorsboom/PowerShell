$ErrorActionPreference = 'Stop'
Function Get-RehydratedFiles {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Source,
        [Parameter(Mandatory=$True, Position=2)]
        [String] $Destination,
        [Parameter(Mandatory=$True, Position=3)]
        [String] $PSDrive
    )
    #$DestinationCredential = Get-Credential
    $StartDate = get-date -Format ("yyyy/MM/dd HH:mm:ss")
    $StartTime = Get-Date
    Try {
        Write-Output ('Creating ' + $PSDrive + ' drive to ' + $Destination)
        New-PSDrive -Name $PSDrive -PSProvider FileSystem -Root $Destination -Credential $DestinationCredential | Out-Null
        Write-Output ('Getting files from ' + $Source)
        $Offline = Get-ChildItem $Source -Recurse -force | Where-Object {$_.Attributes -like '*Offline*'}
        Write-Output ($Offline.Count.ToString() + ' files found')
    }
    Catch {
        Write-Output ('Failed To create PSDrive - ' + $_)
        Exit
    }
    $Success = @()
    $Errors = @()
    For ($i = 0; $i -lt $Offline.Count; $i ++) {
        $RehydratedFlag = $False
        $RemovedFlag = $False
        $CopiedFlag = $False
        Try {
            # Calculate estimated time to completion
            $currentTime = Get-Date
            $elapsedTime = $currentTime - $startTime
            $averageTimePerFile = $elapsedTime / 10
            $remainingFiles = $Offline.Count - $i
            $estimatedTimeRemaining = $averageTimePerFile * $remainingFiles

            # Display estimated time to completion
            $estimatedCompletionTime = $currentTime + $estimatedTimeRemaining
            #Write-Host "Estimated Time to Completion: $estimatedCompletionTime"
            Write-Progress -Activity 'Recovering Files' -PercentComplete (($i + 1) / $Offline.Count * 100) -Status ((($i + 1) / $Offline.Count * 100).ToString() + '% - ETC: ' + $estimatedCompletionTime)
            Write-Output (($i+1).ToString() + '/' + $Offline.Count.ToString() + ' - Processing "' + $Offline[$i].Name +'"')
            $DestinationFile = ($Offline[$i].FullName).Replace($Source,($PSDrive + ':'))
            Write-Output ('|- Rehydrating file')
            Get-Content $Offline[$i].FullName | Out-Null
            $RehydratedFlag = $True
            Write-Output ('|- Removing destination file')
            Remove-Item $DestinationFile
            $RemovedFlag = $True
            Write-Output ('|- Copying file')
            Copy-Item -LiteralPath $Offline[$i].FullName -Destination $DestinationFile
            $CopiedFlag = $True
            Write-Output ('|- Complete')
            $Success += ,(New-Object -TypeName PSObject -Property @{
                File = $Offline[$i].FullName
                Rehydrated = $RehydratedFlag
                Copied = $CopiedFlag
                Removed = $RemovedFlag
            })
        }
        Catch {
            Write-Output ('Failed to process - ' + $_)
            $Errors += ,(New-Object -TypeName PSObject -Property @{
                File = $Offline[$i].FullName
                Rehydrated = $RehydratedFlag
                Copied = $CopiedFlag
                Removed = $RemovedFlag
                Error = $_
            })
            #Exit
        }
    }
    Write-OutPut ('Start Time: ' + $StartDate)
    Write-OutPut ('End Time: ' + (get-date -Format ("yyyy/MM/dd HH:mm:ss")))
    Remove-PSDrive -Name $PSDrive

    $Success | Export-CSV ('Success_' + ($Source -split '\\')[-1] + '_' + (get-date -Format ("yyyy-MM-dd__HH_mm_ss")) + '.csv') -Delimiter ';' -Encoding ASCII -Force -NoTypeInformation
    Write-Output ('Success Export: ' + ('Success_' + ($Source -split '\\')[-1] + '_' + (get-date -Format ("yyyy-MM-dd__HH_mm_ss")) + '.csv'))
    $Errors | Export-CSV ('Errors_' + ($Source -split '\\')[-1] + '_' + (get-date -Format ("yyyy-MM-dd__HH_mm_ss")) + '.csv') -Delimiter ';' -Encoding ASCII -Force -NoTypeInformation
    Write-Output ('Errors Export: ' + ('Errors_' + ($Source -split '\\')[-1] + '_' + (get-date -Format ("yyyy-MM-dd__HH_mm_ss")) + '.csv'))
    $Errors | Out-GridView
}

$Source = 'c:\path'
$Destination = '\\server\share\path'
$PSDrive = 'X'
Get-RehydratedFiles -Source $Source -Destination $Destination -PSDrive $PSDrive