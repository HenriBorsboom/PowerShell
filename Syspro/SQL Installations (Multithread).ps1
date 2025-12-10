Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $Color, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)

    $ErrorActionPreference = "Stop"
    Try {
        If ($Text.Count -ne $Color.Count) {
            Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $Color.Count.ToString()) -ForegroundColor Red
            Throw
        }
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $Color[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch { }
}
Function Get-DomainComputers {
    <#Param (
        [Parameter(Mandatory = $True,  Position = 1)]
        [String] $Domain)#>

    Import-Module ActiveDirectory
    $Servers = Get-ADComputer -Filter { ObjectClass -eq "computer" }
    $Servers = $Servers | Sort Name
    $Servers = $Servers.Name

    Return $Servers    
}

Clear-Host

Write-Color -Text "Getting Computer objects in domain - " -Color White -NoNewLine
    $Computers = Get-DomainComputers
Write-Color -Text "Complete" -Color Green

$ScriptBlock = {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Computer, `
        [Parameter(Mandatory=$True, Position=2)]
        [Int32] $Counter, `
        [Parameter(Mandatory=$True, Position=3)]
        [Int32] $Total)

    Function Get-RemoteRegistryDetails {
        Param(
            [Parameter(Mandatory = $True, Position = 1)]
            [String] $Computer, `
            [Parameter(Mandatory = $True, Position = 2)][ValidateSet("ClassesRoot", "CurrentConfig", "CurrentUser", "DynData", "LocalMachine", "PerformanceData", "Users")]
            [String] $Hive, `
            [Parameter(Mandatory = $True, Position = 3)]
            [String] $Key, `
            [Parameter(Mandatory = $True, Position = 1)]
            [String] $Value)

        Try {
            $Registry    = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $Computer)
            $RegistryKey = $Registry.OpenSubKey($Key) # $Registry.OpenSubKey("SOFTWARE\\Microsoft\\Virtual Machine\\Guest\\Parameters")
            $Value       = $RegistryKey.GetValue($Value)
        }
        Catch { $Value = "Not found" }
        Return $Value
    }
    $InstalledSQLInstances = @()
    If (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
        Try { 
            $Instances = Get-RemoteRegistryDetails -Computer $Computer -Hive LocalMachine -Key "SOFTWARE\\Microsoft\\Microsoft SQL Server" -Value "InstalledInstances" -ErrorAction Stop
        }
        Catch { 
            $SQLInstance = New-Object PSObject -Property @{
                Computer = $Computer
                Product  = ""
                Edition  = ""
                Version  = ""
                Success  = "FALSE"
                Error    = $_
            }
            Return $SQLInstance
        }
        ForEach ($Instance in $Instances) {
            Try {
                $Product = Get-RemoteRegistryDetails -Computer $Computer -Hive LocalMachine -Key "SOFTWARE\\Microsoft\\Microsoft SQL Server\\Instance Names\\SQL" -Value $Instance
                $Edition = Get-RemoteRegistryDetails -Computer $Computer -Hive LocalMachine -Key "SOFTWARE\\Microsoft\\Microsoft SQL Server\\$Product\\Setup" -Value "Edition"
                $Version = Get-RemoteRegistryDetails -Computer $Computer -Hive LocalMachine -Key "SOFTWARE\\Microsoft\\Microsoft SQL Server\\$Product\\Setup" -Value "Version"
                $SQLInstance = New-Object PSObject -Property @{
                    Computer = $Computer
                    Product  = $Product
                    Edition  = $Edition
                    Version  = $Version
                    Success  = "TRUE"
                    Error    = ""
                }
                $InstalledSQLInstances = $InstalledSQLInstances + $SQLInstance
            }
            Catch {
                $SQLInstance = New-Object PSObject -Property @{
                    Computer = $Computer
                    Product  = ""
                    Edition  = ""
                    Version  = ""
                    Success  = "FALSE"
                    Error    = $_
                }
                $InstalledSQLInstances = $InstalledSQLInstances + $SQLInstance
            }
        }
        Return $InstalledSQLInstances
    }
    Else {
        $SQLInstance = New-Object PSObject -Property @{
            Computer = $Computer
            Product  = ""
            Edition  = ""
            Version  = ""
            Success  = "FALSE"
            Error    = "Unable to test connection to $Computer" 
        }
        Return $SQLInstance
    }
}

# Thread Loop
$MaximumJobs        = 15
$Jobs               = @()
$ComputerCounter    = 1
$TotalComputerCount = $Computers.Count
$Report             = @()
$Results            = @("Computer", "Product", "Edition", "Version", "Success", "Error")

ForEach ($Computer in $Computers) {
    Write-Color -Text "Starting query on ", $Computer, " - ", "$ComputerCounter\$TotalComputerCount" -Color White, Yellow, White, Cyan
    $Jobs        = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Computer, $ComputerCounter, $TotalComputerCount)
    $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})

    # Throttle jobs
    While ($RunningJobs.Count -ge $MaximumJobs) {
        $FinishedJobs = Wait-Job -Job $Jobs -Any
        $RunningJobs  = @($Jobs | Where-Object {$_.State -eq 'Running'})
    }
    $ComputerCounter ++
}

# Wait for remaining.
Write-Color -Text "Waiting for remaining jobs to complete", " - " -Color Yellow, White -NoNewLine
    Wait-Job -Job $Jobs | Out-Null
Write-Color -Text "Complete" -Color Green

# Check for failed jobs.
$FailedJobs = @($Jobs | ? {$_.State -eq 'Failed'})
If ($FailedJobs.Count -gt 0) {
    $FailedJobs | % {
        $_.ChildJobs[0].JobStateInfo.Reason.Message
    }
}

# Collect job data.
$Jobs | % {
    $Report += $_ | Receive-Job 
}

$Report | Select $Results | Format-Table -AutoSize
$Report | Select $Results | Export-Csv $env:TEMP\sql.csv -Force -NoTypeInformation
Notepad $env:TEMP\sql.csv
Get-Job | Remove-Job