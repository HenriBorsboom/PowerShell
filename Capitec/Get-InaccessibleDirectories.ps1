function Get-InaccessibleDirectories {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    # Get all directories under the specified path
    Write-Host "Getting folders from $Path"
    $directories = Get-ChildItem -Path $Path -Directory -Recurse -ErrorAction SilentlyContinue
    Write-Host ($directories.Count.ToString() + ' found')
    $InaccessibleDirectories = @()
    For ($i = 0; $i -lt $directories.Count; $i ++) {
        $directory = $directories[$i]
        Write-Progress -Activity ("Getting inaccessible directories - " + ($i / $directories.Count * 100) + ' %') -PercentComplete ($i / $directories.Count * 100)
        #Write-Host (($i + 1).ToString() + '/' + $directories.Count.ToString() + '  - Processing ' + $directory.FullName)
    #foreach ($directory in $directories) {

        # Try accessing the directory, suppress errors
        try {
            [void](Get-ChildItem -Path $directory.FullName -ErrorAction Stop)
        } catch {
            # If an error occurred, the directory is inaccessible
            Write-Host $directory.FullName -ForegroundColor Red
            $Directory.FullName | Out-File 'D:\Temp\CommVault\Inaccessible.txt' -Encoding ascii -Append
            $InaccessibleDirectories += ,($directory.FullName)
        }
    }
    Return $InaccessibleDirectories
}

# Usage example: Get-InaccessibleDirectories -Path "C:\Your\Path\Here"
Get-InaccessibleDirectories -Path 'E:\'