Function Stop-Jobs {
    Get-Job | Stop-Job
    Get-Job | Remove-Job
}
Function Wait-Jobs {
    While ((get-job).State -eq 'Running') { "Still busy...."; sleep 1 }
}
Function Start-Jobs {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet("TargetOnly","ArgumentsOnly","Both","None")]
        [String] $PassTargetToScriptBlock, `
        [Parameter(Mandatory=$True, Position=2)]
        [ScriptBlock] $ScriptBlock, `
        [Parameter(Mandatory=$False, Position=3)]
        [Object[]] $ScriptBlockArguments, `
        [Parameter(Mandatory=$True, Position=4)]
        [Object[]] $Targets, `
        [Parameter(Mandatory=$False, Position=5)]
        [Switch] $ReportImmediate=$False, `
        [Parameter(Mandatory=$False, Position=6)]
        [Int32]    $MaximumJobs=$env:NUMBER_OF_PROCESSORS
    )

    $Jobs = @()
    
    For ($Index = 0; $Index -lt $Targets.Count; $Index ++) {
        $Target = $Targets[$index]
        Write-Host (($Index + 1).ToString() + '/' + $Targets.Count.ToString() + ' - Starting Job for ' + $Target)
        Switch ($PassTargetToScriptBlock) {
            "TargetOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Target)}
            "ArgumentsOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ScriptBlockArguments)}
            "Both" {
                $Arguments = @()
                $Arguments = $Arguments + $Target
                ForEach ($ScriptBlockArgument in $ScriptBlockArguments) {
                    $Arguments = $Arguments + $ScriptBlockArgument
                }
                $Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Arguments)
            }
            "None" { $Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock ) }
        }
        $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})

        While ($RunningJobs.Count -ge $MaximumJobs) {
            $ActiveJob = Get-Job | Where State -eq 'Completed'
            Switch ($ReportImmediate) {
                $True {
                    Get-Job | Where State -eq 'Running' | Receive-Job
                }
                $False {
                    If ($Null -ne $ActiveJob) {
                        Receive-Job $ActiveJob | Remove-Job $ActiveJob
                    }
                }
            }
            $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})
        }
    }
    Wait-Job -Job $Jobs | Out-Null
    $FailedJobs = @($Jobs | Where-Object {$_.State -eq 'Failed'})
    If ($FailedJobs.Count -gt 0) {
        ForEach ($FailedJob in $FailedJobs) {
            $FailedJob.ChildJobs[0].JobStateInfo.Reason.Message
        }
    }
    Get-Job | Wait-Job | Remove-Job
    Return $JobResults
}
#Example of Use
Clear-Host
$GetFoldersAndFiles = {
        <#
    .SYNOPSIS
      Recursively export file metadata with age-based CSVs, logging, and a separate error file.

    .PARAMETER Path
      Root folder to scan.

    .PARAMETER OutputFolder
      Folder where CSVs, log file, and error file will be created.

    .PARAMETER LogFile
      (Optional) Path to the main log. Defaults to OutputFolder\Scan_{sanitized Path}_{timestamp}.log

    .PARAMETER ErrorFile
      (Optional) Path to the error file. Defaults to OutputFolder\Scan_{sanitized Path}_{timestamp}.errors.log

    .EXAMPLE
      .\Export-FileAges.ps1 -Path "D:\Data" -OutputFolder "C:\Exports"
    #>
    param(
      [Parameter(Mandatory)][string]$Path,
      [string]$OutputFolder = 'C:\Temp\Henri\DataAge',
      [string]$LogFile = ($OutputFolder + '\' + $env:Computername + '_Scan_' + $Path.Replace(':\', '-').Replace('\','-') + '_' + (get-date).Tostring('yyyy-MM-dd HH-mm-ss') + '.log'),
      [string]$ErrorFile = ($OutputFolder + '\' + $env:Computername + '_Error_' + $Path.Replace(':\', '-').Replace('\','-') + '_' + (get-date).Tostring('yyyy-MM-dd HH-mm-ss') + '.log')
    )
    [string]$RunTimeFile = ($OutputFolder + '\' + $env:Computername + '_RunTime_' + $Path.Replace(':\', '-').Replace('\','-') + '_' + (get-date).Tostring('yyyy-MM-dd HH-mm-ss') + '.log')

    # Ensure output folder exists
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null

    # Initialize log and error files
    "" | Out-File  $LogFile   -Encoding utf8
    "" | Out-File  $ErrorFile -Encoding utf8
    ("Start Time: " + (Get-Date).ToString('yyyy/MM/dd HH:mm:ss')) | Out-File $RunTimeFile -Encoding utf8

    function Write-Log {
      param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR')][string]$Level = 'INFO'
      )
      $ts = (Get-Date).ToString('o')
      "$ts [$Level] $Message" |
        Out-File -FilePath $LogFile -Append -Encoding utf8
    }

    function Write-ErrorLog {
      param([string]$Message)
      $ts = (Get-Date).ToString('o')
      "$ts [ERROR] $Message" |
        Out-File -FilePath $ErrorFile -Append -Encoding utf8
    }
    Write-Log ("Running scan as " + $env:USERNAME)
    Write-Log "Starting scan of '$Path'."

    # Age-based CSV setup
    $filesMap = @{
      files       = ($env:computername + '_' + $Path.Replace(':\', '-').Replace('\','-') + '_' + (get-date).Tostring('yyyy-MM-dd HH-mm-ss') + '_files.csv')
    }

    $writers = @{}
    $header  = 'FullPath,CreationDate,LastAccessDate,LastModifiedDate,Owner,Permissions,Size'

    foreach ($key in $filesMap.Keys) {
      $pathCsv = Join-Path $OutputFolder $filesMap[$key]
      $w = [IO.File]::CreateText($pathCsv)
      $w.WriteLine($header)
      $writers[$key] = $w
      Write-Log "Initialized CSV '$pathCsv'."
    }

    $now = Get-Date
    $iso = [Globalization.CultureInfo]::InvariantCulture

    function Process-File {
      param([string]$filePath)

      try {
        $fi   = [IO.FileInfo]::new($filePath)
        $acl  = $fi.GetAccessControl()
        $owner= $acl.Owner

        $perms = (
          $acl.GetAccessRules($true, $true, [Security.Principal.NTAccount]) |
            ForEach-Object { "$($_.IdentityReference.Value):$($_.FileSystemRights)" } |
            Sort-Object -Unique
        ) -join ';'

        $line = '"{0}",{1},{2},{3},"{4}","{5}",{6}' -f
          ($fi.FullName -replace '"','""'),
          $fi.CreationTime.ToString(),
          $fi.LastAccessTime.ToString(),
          $fi.LastWriteTime.ToString(),
          ($owner -replace '"','""'),
          ($perms -replace '"','""'),
          $fi.Length

        $cat = 'files'

        $writers[$cat].WriteLine($line)
        #Write-Log "Wrote '$filePath' to '$($filesMap[$cat])'."
      }
      catch {
        $msg = "Error processing file '$filePath' - $_"
        Write-Log $msg 'ERROR'
        Write-ErrorLog $msg
      }
    }

    function Process-Directory {
      param([string]$dir)

      # Attempt to get files in this folder
      try {
        [IO.Directory]::EnumerateFiles($dir) | ForEach-Object { Process-File $_ }
        Write-Log "Finished '$dir'"
      }
      catch {
        $msg = "Cannot enumerate files in '$dir' - $_"
        Write-Log $msg 'ERROR'
        Write-ErrorLog $msg
      }

      # Recurse into subdirectories
      try {
        [IO.Directory]::EnumerateDirectories($dir) | ForEach-Object { Process-Directory $_ }
      }
      catch {
        $msg = "Cannot enumerate directories in '$dir' - $_"
        Write-Log $msg 'ERROR'
        Write-ErrorLog $msg
      }
    }

    # Kick off the walk
    Process-Directory $Path

    # Cleanup
    foreach ($w in $writers.Values) { $w.Close() }
    Write-Log "Completed scan of '$Path'."
    Write-Log "Errors (if any) written to '$ErrorFile'."

    Write-Host ($path + " - Completed") -ForegroundColor Green
    ("End Time: " + (Get-Date).ToString('yyyy/MM/dd HH:mm:ss')) | Out-File $RunTimeFile -Encoding utf8 -Append
}

#$LogonDate = (Get-Date).AddMonths(-2)
#$Servers = Get-ADComputer -Filter {Enabled -eq $True -and LastLogonDate -gt $LogonDate -and OperatingSystem -like '*server*'} -Properties LastLogonDate, Enabled, OperatingSystem
#$Credential = Get-Credential

$Drives = @()
ForEach ($DriveLetter in (Get-Volume | Where-Object { $_.DriveLetter -ne $null } | Where-Object { $_.DriveLetter -notin 'C', 'S', 'M' } | Select-Object -ExpandProperty DriveLetter)) {
    If ($DriveLetter -ne 'C' -or $DriveLetter -ne 'S') {
        $Drives += ($DriveLetter + ':\')
    }
}

Start-Jobs -ScriptBlock $GetFoldersAndFiles -Targets $Drives -PassTargetToScriptBlock TargetOnly -MaximumJobs 4

