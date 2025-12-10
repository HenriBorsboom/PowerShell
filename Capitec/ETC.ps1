$files = Get-ChildItem -File -Recurse -Force
$totalFiles = $files.Count
$processedFiles = 0
$startTime = Get-Date

foreach ($file in $files) {
    # Process the file
    Get-Content $file.FullName | Out-Null

    # Update progress
    $processedFiles++
    $percentComplete = ($processedFiles / $totalFiles) * 100
    
    # Calculate estimated time to completion
    $currentTime = Get-Date
    $elapsedTime = $currentTime - $startTime
    $averageTimePerFile = $elapsedTime / $processedFiles
    $remainingFiles = $totalFiles - $processedFiles
    $estimatedTimeRemaining = $averageTimePerFile * $remainingFiles

    # Display estimated time to completion
    $estimatedCompletionTime = $currentTime + $estimatedTimeRemaining
    #Write-Host "Estimated Time to Completion: $estimatedCompletionTime"
    
    Write-Progress -Activity "Processing Files" -Status ($percentComplete.ToString() + ' % - ETC: ' + $estimatedCompletionTime) -PercentComplete $percentComplete
}