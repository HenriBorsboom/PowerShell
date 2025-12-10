Function v1 {
# Function to copy files
    # Main script
    $SourcePath = "C:\Temp"
    $DestinationPath = "C:\TempRestore"
    $Reports = Get-ChildItem "C:\Temp\Reports\*.txt"
    For ($x = 0; $x -lt $Reports.Count; $x ++) {
        $ReportFile = $Reports[$x]
    #ForEach ($ReportFile in (Get-ChildItem "C:\Temp\Reports\*.txt")) {
        #$ReportFile = "C:\Temp\Reports"

        # Get number of CPU cores for threading
        $MaxThreads = [System.Environment]::ProcessorCount

        # Start multiple threads
        $ScriptBlock = {
            param($Argument)
            function Copy-Files {
                param(
                    [string]$SourcePath,
                    [string]$DestinationPath,
                    [string]$ReportFile,
                    [int]$ThreadIndex
                )
                
                #$SourcePath = $Argument[0] 
                #$DestinationPath = $Argument[1] 
                #$ReportFile = $Argument[2] 
                #$ThreadIndex = $Argument[3]
        
                $Files = Get-Content $ReportFile
        
                $Counter = 0
        
                foreach ($file in $Files) {
                    $RestorePath = $file.Replace('C:\Temp', '') -split '\\'
                    For ($y = 0; $y -le ($RestorePath.Count - 2); $y ++) {
                        If (Test-Path -LiteralPath ($DestinationPath + '\' + (($RestorePath[0..$y]) -join '\'))) {
                            #folder exists
                        }
                        Else {
                            New-Item ($DestinationPath + '\' + (($RestorePath[0..$y]) -join '\')) -ItemType Directory | Out-Null
                        }
                    }
                    # Copy each file
                    Copy-Item -Path $file -Destination ($File.Replace($SourcePath, $DestinationPath))
                    $Counter++
        
                    # Output status update
                    Write-Output "Thread $ThreadIndex : Copied $Counter out of $($Files.Count) files"
                }
            }
            
            Copy-Files -SourcePath $Argument[0] -DestinationPath $Argument[1] -ReportFile $Argument[2] -ThreadIndex $Argument[3]
        }
        $Threads = @()
        for ($i = 0; $i -lt $MaxThreads; $i++) {
            $Argument = ($SourcePath, $DestinationPath, $ReportFile, $i)
            $Thread = [System.Management.Automation.PowerShell]::Create().AddScript($ScriptBlock).AddArgument($Argument)
            #Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Argument
            $Thread.RunspacePool = $RunspacePool
            $Threads += [PSCustomObject]@{ Index = $i; Thread = $Thread }
            $Thread.BeginInvoke()
        }

        # Wait for all threads to complete
        while ($Threads.Thread.IsCompleted -contains $false) {
            Start-Sleep -Milliseconds 100
        }
    }
    Write-Host "All files copied successfully."
}
# Function to copy files
Function V2 {
# Define source and destination directories
$sourceDir = "C:\Temp\D0\Folder0"
$destinationDir = "C:\TempRestore"

# Get a list of files to copy
$filesToCopy = Get-ChildItem $sourceDir

# Define a function to copy a single file
    function Copy-SingleFile {
        param (
            [string]$source,
            [string]$destination
        )
        Copy-Item -Path $source -Destination $destination -Verbose
    }

# Start a thread job for each file copy
$jobs = foreach ($file in $filesToCopy) {
    Start-ThreadJob -ScriptBlock {
        param($source, $destination)
        . using:Function Copy-SingleFile
        Copy-SingleFile -source $source -destination $destination
    } -ArgumentList $file.FullName, "$destinationDir\$($file.Name)"
}

# Monitor the progress of each job
while ($jobs.State -contains 'Running') {
    foreach ($job in $jobs) {
        $status = $job | Receive-Job
        Write-Progress -Activity "Copying Files" -Status $status
    }
    Start-Sleep -Milliseconds 500
}

Write-Progress -Activity "Copying Files" -Completed

}
Function v3 {
    #$source = "C:\Temp"
    $destination = "C:\TempRestore"
    $Reports = Get-ChildItem 'C:\Temp\Reports\*.txt'

    For ($x = 0; $x -lt $Reports.Count; $x ++) {
        Write-Progress -PercentComplete ($x / $Reports.Count * 100) -Activity ('Copying Reports - ' + ($x / $Reports.Count * 100) + '%') -ID 1
        # Get the list of files in the source directory
        $filesToCopy = Get-Content $Reports[$x]

        # Create a job for each file to copy (multi-threading)
        $jobs = @()
        #foreach ($file in $filesToCopy) {
        for ($i = 0; $i -lt $filesToCopy.Count; $i ++) {
            Write-Progress -PercentComplete ($i / $filesToCopy.Count * 100) -Activity ('Copying ' + $file + ' - ' + ($i / $filesToCopy.Count * 100) + '%') -ParentId 1
            $File = $filesToCopy[$i]
            $jobs += Start-Job -ScriptBlock {
                param ($file)
                $RestorePath = $file.Replace('C:\Temp', '') -split '\\'
                $TargetRestoreFolder = 'C:\TempRestore'
                For ($y = 0; $y -le ($RestorePath.Count - 2); $y ++) {
                    If (Test-Path -LiteralPath ($TargetRestoreFolder + '\' + (($RestorePath[0..$y]) -join '\'))) {
                        #folder exists
                    }
                    Else {
                        New-Item ($TargetRestoreFolder + '\' + (($RestorePath[0..$y]) -join '\')) -ItemType Directory | Out-Null
                    }
                }
                Copy-Item -Path $file -Destination ($file.Replace('C:\Temp', 'C:\TempRestore')) -Force
            } -ArgumentList $file
        }

        # Wait for all jobs to complete
        $jobs | Wait-Job | Out-Null
    }

    Get-Job | Remove-Job
    # Display the status
    Write-Host "$($jobs.Count) files copied to $destination"
}
v3