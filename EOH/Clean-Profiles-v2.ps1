<#
Param (
    [Parameter(Mandatory=$False, Position=1)]
    [String] $ProfilesPath = 'C:\Users', `
    [Parameter(Mandatory=$False, Position=2)]
    [String[]] $Extensions = @("*.log","*.dmp","*.tmp","*.hdmp","*.mdmp","*.regtrans-ms","*.htm","*.dat"), `
    [Parameter(Mandatory=$False, Position=3)]
    [Switch] $Force)
#>

[String]   $ProfilesPath = 'C:\Users'
[String[]] $Extensions = @("*.log","*.dmp","*.tmp","*.hdmp","*.mdmp","*.regtrans-ms","*.htm","*.dat")
[Switch]   $Force = $false

Write-Color -Text 'Getting Profiles from ', $ProfilesPath, ' - ' -ForegroundColor White, Yellow, White -NoNewLine
    $Profiles = Get-ChildItem -Path $ProfilesPath -Directory
Write-Color -Text $Profiles.Count, ' Found' -ForegroundColor Yellow, Green

$AllProfileDetails = @()
For ($x = 0; $x -lt $Profiles.Count; $x ++) {
    $RemovedFiles = @()
    $LeftoverFiles = @()
    Write-Color -IndexCounter $x -TotalCounter $Profiles.Count -Text 'Getting Temp files from ', $Profiles[$x].FullName, ' - ' -ForegroundColor White, Yellow, White -NoNewLine
    $TempFiles = Get-ChildItem -Path $Profiles[$x].FullName -Include $Extensions -Recurse -Force -ErrorAction SilentlyContinue
    Write-Color -Text $TempFiles.Count, ' Found' -ForegroundColor Yellow, Yellow
    For ($y = 0; $y -lt $TempFiles.Count; $y ++) {
        Try {
            Write-Color -IndexCounter $y -TotalCounter $TempFiles.Count -Text 'Removing ', $TempFiles[$y].BaseName, ' - ' -ForegroundColor White, Yellow, White -NoNewLine
            Switch ($Force) {
                $True  { Remove-Item -Path $TempFiles[$y].FullName -Force -ErrorAction Stop | Out-Null }
                $False { Remove-Item -Path $TempFiles[$y].FullName -ErrorAction Stop | Out-Null }
            }
            Write-Color -Complete
            $RemovedFiles += ,($TempFiles[$y])
        }
        Catch {
            Write-Color -Text 'Failed' -ForegroundColor Red
            $LeftoverFiles += ,($TempFiles[$y])
        }
    }
    $ProfileDetails = New-Object -TypeName PSObject -Property @{
        ProfileName = $Profiles[$x].FullName
        RemovedFiles = $RemovedFiles
        LeftOverFiles = $LeftoverFiles
    }
    $AllProfiles += ,($ProfileDetails)
}

ForEach ($Profile in $AllProfiles) {
     $LeftOverFiles = [Math]::Round((($Profile.LeftOverFiles | Measure-Object -sum -Property Length).Sum) / 1024 / 1024, 2)
     $RemovedFiles = [Math]::Round((($Profile.RemovedFiles | Measure-Object -sum -Property Length).Sum) / 1024 / 1024, 2)
     Write-Host $Profile.ProfileName
     Write-Host $LeftoverFiles
     Write-Host $RemovedFiles
    }
$AllProfiles