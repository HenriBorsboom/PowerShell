Function Update-Records {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $RequestedBy
    )
    # Prompt for metadata
    $ExecutedBy = $env:USERNAME
    $DateOfExecution = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Import existing records
    $existingRecords = Import-Csv -Path "C:\Temp\records.csv"

    # Import new records
    $newRecords = Import-Csv -Path "C:\Temp\NewRecords.csv"

    # Find records that aren't already in the existing file
    $uniqueNewRecords = $newRecords | Where-Object {
        $record = $_
        -not ($existingRecords | Where-Object {
            $_.RecordName -eq $record.RecordName -and $_.RecordType -eq $record.RecordType
        })
    }

    # Add metadata to new records
    $augmentedNewRecords = @(
        $uniqueNewRecords | ForEach-Object {
            $_ | Add-Member -NotePropertyName RequestedBy -NotePropertyValue $RequestedBy -Force
            $_ | Add-Member -NotePropertyName ExecutedBy -NotePropertyValue $ExecutedBy -Force
            $_ | Add-Member -NotePropertyName DateOfExecution -NotePropertyValue $DateOfExecution -Force
            $_
        }
    )

    # Merge everything and export
    $finalRecords = $augmentedNewRecords + $existingRecords
    $finalRecords | Export-Csv -Path "C:\Temp\records.csv" -NoTypeInformation
    [String[]] $DomainControllers = Get-ADDomainController -Filter * | Select-Object -ExpandProperty HostName
    foreach ($DC in $DomainControllers) {
        try {
            Copy-Item -Path "C:\Temp\records.csv" -Destination "\\$DC\C$\Temp" -Force
            Write-Host "Copied to $DC successfully." -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to copy to $DC : $_" -ForegroundColor Red
        }
    }
}
Update-Records