Function Start-Jobs {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet("TargetOnly","ArgumentsOnly","Both")]
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
        [Int32]    $MaximumJobs=$env:NUMBER_OF_PROCESSORS)

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
    $Jobs = @()
    
    Switch ($ReportImmediate) {
        $True { Write-Color -Text "Starting Jobs for ", $Targets.Count, " targets.", " Please wait for the results." -Color White, Cyan, White, Yellow }
    }
    For ($I = 0; $I -lt $Targets.Count; $I ++) {
    #ForEach ($Target in $Targets) {
        Switch ($ReportImmediate) {
            $False { Write-Color -Text ($I + 1),"/",$Targets.Count, " - Starting Job for ", $Targets[$I] -Color Cyan, Cyan, Cyan, White, Yellow }
        }
        Switch ($PassTargetToScriptBlock) {
            "TargetOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Targets[$I])}
            "ArgumentsOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ScriptBlockArguments)}
            "Both" {
                $Arguments = @()
                $Arguments = $Arguments + $Targets[$I]
                ForEach ($ScriptBlockArgument in $ScriptBlockArguments) {
                    $Arguments = $Arguments + $ScriptBlockArgument
                }
                $Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Arguments)}
        }
        $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})

        While ($RunningJobs.Count -ge $MaximumJobs) {
            $FinishedJobs = Wait-Job -Job $Jobs -Any
            Switch ($ReportImmediate) {
                $True {
                    $CompletedJobs = @($Jobs | Where {$_.HasMoreData -eq "True"})
                    ForEach ($CompleteJob in $CompletedJobs) {
                        Receive-Job $CompleteJob
                    }
                }
            }
            $RunningJobs  = @($Jobs | Where-Object {$_.State -eq 'Running'})
        }
    }
    Wait-Job -Job $Jobs | Out-Null
    $FailedJobs = @($Jobs | Where-Object {$_.State -eq 'Failed'})
    If ($FailedJobs.Count -gt 0) {
        ForEach ($FailedJob in $FailedJobs) {
            $FailedJob.ChildJobs[0].JobStateInfo.Reason.Message
        }
    }
    $JobResults = @()
    Switch ($ReportImmediate) {
        $False {
            ForEach ($Job in $Jobs) {
                $JobResults = $JobResults + (Receive-Job $Job)
            }
        }
    }
    Get-Job | Wait-Job | Remove-Job
    Return $JobResults
}
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
    Param (
        [Parameter(Mandatory = $True,  Position = 1)]
        [String] $Domain)

    Import-Module ActiveDirectory
    $Servers = Get-ADComputer -Filter { ObjectClass -eq "Computer" }
    $Servers = $Servers | Sort Name
    $Servers = $Servers.Name

    Return $Servers    
}
Function Create-OU {
    $OUNames = @(
    'Microsoft Exchange Security Groups'
    'Domain Controllers'
    'Johannesburg'
    'Technical Services'
    'Computers'
    'Servers'
    'Recipients'
    'Users'
    'Technical Development'
    'UsersOld'
    'Development - Services'
    'Users'
    'Syspro Africa Support'
    'UsersOld'
    'Development - Manufacturing'
    'UsersOld'
    'Knowledge Transfer'
    'UsersOld'
    'Cape Town'
    'Marketing'
    'Users-FS'
    'Development'
    'Users'
    'Corporate Services'
    'UsersOld'
    'Usersold'
    'Web Development'
    'UsersOld'
    'Marketing'
    'Development - Distribution'
    'Development - Financial'
    'Technical Writing'
    'Printers & Scanners'
    'Distributor Support'
    'UsersOld'
    'Human Resources'
    'UsersOld'
    'Computers'
    'Computers'
    'Development - Core'
    'UsersOld'
    'Printers & Scanners'
    'Printers & Scanners'
    'Administration'
    'Printers & Scanners'
    'Printers & Scanners'
    'Printers & Scanners'
    'Printers & Scanners'
    'Printers & Scanners'
    'Printers & Scanners'
    'Printers & Scanners'
    'Printers & Scanners'
    'Printers & Scanners'
    'Printers & Scanners'
    'Printers & Scanners'
    'Professional Services'
    'Printers & Scanners'
    'Nursery Distributors'
    'Other African Distributors'
    'Other Associates'
    'Territory Distributors'
    'Durban'
    'Training Room'
    'Users'
    'South African Distributors'
    'Workstations'
    'Servers'
    'Accounts Addresses'
    'Independant Distributors'
    'Printers & Scanners'
    'Professional Services'
    'Development - Distribution'
    'Printers & Scanners'
    'Printers & Scanners'
    'Servers'
    'Printers & Scanners'
    'Marketing'
    'Printers & Scanners'
    'Servers'
    'Development - e.net Solutions'
    'Printers & Scanners'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'E-Mail Groups'
    'UsersOld'
    'UsersOld'
    'UsersOld'
    'E-Mail Groups'
    'E-Mail Groups'
    'Printers & Scanners'
    'E-Mail Groups'
    'External Users'
    'Computers'
    'UsersOld'
    'Computers'
    'Workstations'
    'Servers'
    'Computers'
    'Servers'
    'Computers'
    'UsersOld'
    'Computers'
    'Computers'
    'Canada Resellers'
    'USA Resellers'
    'Worcester'
    'Africa Resellers'
    'Computers'
    'UsersOld'
    'Computers'
    'Computers'
    'Computers'
    'Computers'
    'Users'
    'Users'
    'Computers'
    'Users - Use this OU'
    'Computers'
    'Syspro Touch Points'
    'SA'
    'USA'
    'CAN'
    'AUS'
    'UK'
    'Mail Groups'
    'General Users'
    'Computers'
    'Test Machines'
    'Internet Groups'
    'Computers'
    'Contacts'
    'Users0old'
    'Computers'
    'Computers'
    'Users'
    'Computers'
    'Computers'
    'Computers'
    'Workstations'
    'Users - "My Docs" re-direct'
    'Internet Guests - full internet access'
    'Computers - Forefront'
    'International Lync Users'
    'Computers'
    'Development - Supply Chain'
    'Sharepoint 2010 Contacts'
    'Sharepoint 2010 Contacts'
    'Users'
    'Users'
    'Users'
    'Training Rooms'
    'Users'
    'Users'
    'Users'
    'Users'
    'Users'
    'Users'
    'Users'
    'Users'
    'Users'
    'Users'
    'Users'
    'Users'
    'Users'
    'Users'
    'DKM'
    'External Users'
    'Development - Emerging Technologies'
    'E-mail Groups'
    'RTC Special Accounts'
    'Users'
    'Computers'
    'Temp SharePoint Users'
    'Users-FS'
    'Users-FS'
    'Users-FS'
    'Users-FS'
    'Users-FS'
    'Users-FS'
    'Users-FS'
    'Users-FS'
    'Users-FS'
    'Users-FS'
    'Users-FS'
    'Users-FS'
    'Users-FS'
    'Users-FS'
    'Users-FS'
    'Users-FS'
    'Users-FS'
    'Users-FS'
    'Users-FS'
    'Disabled Accounts'
    'Users'
    'Computers'
    'Testers'
    'Developers'
    'Contractors'
    'Contacts'
    'Users-FS'
    'CRM'
    'Professional Services'
    'Computers'
    'E-Mail Groups'
    'Users-FS'
    'Web Development'
    'Computers'
    'E-Mail Groups'
    'Users-FS'
    'Users'
    'Intern Users'
    'Intern Computers'
    'Active Sync Test'
    'Development - Emerging Technologies'
    'Computers'
    'E-Mail Groups'
    'Users-FS'
    'Testers'
    'Developers'
    'UsersTest'
    'Admin Accounts'
    'Meeting Rooms'
    'Azure'
    'Territory Office Users'
    'Azure Users'
    'Users'
    'Computers'
    'Security Groups'
    'Azure Groups'
    'Interns'
    'Sharepoint Service Accounts'
    'Computers'
    'Service Account'
    'SYSPRO Azure'
    'EA Accounts'
    'Consultants'
    'Exclude'
    )
    $OUPath = @(
    'DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Cape Town,DC=sysproza,DC=net'
    'OU=Marketing,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Cape Town,DC=sysproza,DC=net'
    'OU=Development,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Administration,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Durban,DC=sysproza,DC=net'
    'OU=Training Room,OU=Durban,DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Training Room,OU=Durban,DC=sysproza,DC=net'
    'OU=Computers,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net '
    'DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Durban,DC=sysproza,DC=net'
    'OU=Durban,DC=sysproza,DC=net'
    'OU=Development,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Marketing,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Cape Town,DC=sysproza,DC=net'
    'OU=Development - Distribution,OU=Durban,DC=sysproza,DC=net'
    'OU=Durban,DC=sysproza,DC=net'
    'OU=Marketing,OU=Durban,DC=sysproza,DC=net'
    'OU=Durban,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - e.net Solutions,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Administration,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - e.net Solutions,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Marketing,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Development - Distribution,OU=Durban,DC=sysproza,DC=net'
    'OU=Marketing,OU=Durban,DC=sysproza,DC=net'
    'OU=Professional Services,OU=Durban,DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Administration,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - e.net Solutions,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Cape Town,DC=sysproza,DC=net'
    'OU=Durban,DC=sysproza,DC=net'
    'OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Administration,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Computers,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net   '
    'OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net '
    'OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Computers,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Distribution,OU=Durban,DC=sysproza,DC=net'
    'OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Computers,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net  '
    'OU=Marketing,OU=Durban,DC=sysproza,DC=net'
    'OU=Development - Distribution,OU=Durban,DC=sysproza,DC=net'
    'OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - e.net Solutions,OU=Johannesburg,DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Syspro Touch Points,DC=sysproza,DC=net'
    'OU=Syspro Touch Points,DC=sysproza,DC=net'
    'OU=Syspro Touch Points,DC=sysproza,DC=net'
    'OU=Syspro Touch Points,DC=sysproza,DC=net'
    'OU=Syspro Touch Points,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Marketing,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Computers,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Administration,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Professional Services,OU=Durban,DC=sysproza,DC=net'
    'OU=Professional Services,OU=Durban,DC=sysproza,DC=net'
    'OU=Development,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Computers,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - e.net Solutions,OU=Johannesburg,DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Marketing,OU=Durban,DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Supply Chain,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - e.net Solutions,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Administration,OU=Johannesburg,DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Administration,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - e.net Solutions,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Supply Chain,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Disabled Accounts,DC=sysproza,DC=net'
    'OU=Disabled Accounts,DC=sysproza,DC=net'
    'OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net   '
    'OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Development,OU=Cape Town,DC=sysproza,DC=net'
    'DC=sysproza,DC=net'
    'OU=Cape Town,DC=sysproza,DC=net'
    'OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Cape Town,DC=sysproza,DC=net'
    'OU=Web Development,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Web Development,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Web Development,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Marketing,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Cape Town,DC=sysproza,DC=net'
    'OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net'
    'OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Azure,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net   '
    'OU=Azure,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Azure,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net '
    'DC=sysproza,DC=net'
    'OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Interns,DC=sysproza,DC=net'
    'OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Johannesburg,DC=sysproza,DC=net'
    'OU=SYSPRO Azure,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net'
    'OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net'
    )

    Clear-Host
    $Counter = 0
    $ADCount = $OUNames.Count

    For ($i = 0; $i -lt $ADCount; $i ++) {
        Write-Host (($i + 1).ToString() + "\$ADCount - Creating " + $OUNames[$i] + " - ") -NoNewline
        Try {
            New-ADOrganizationalUnit -Name $OUNames[$i] -Path $OUPath[$i] -ErrorAction SilentlyContinue
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch { 
            Write-Host "Failed" -ForegroundColor Red -NoNewline
            Write-Host (" - " + $_)
        }
    }
}
Function Create-User {
    $SAMAccount = @(
    "Ned"
    "Ned-2"
    "IWAM_SYSPRO-DC3JHB"
    "IUSR_SYSPRO-DC3JHB"
    "IWAM_SYSPRO-DC1CT"
    "IUSR_SYSPRO-DC1CT"
    "IWAM_SYSPRO-DC1DBN"
    "IUSR_SYSPRO-DC1DBN"
    "IUSR_SYSPRO-MASTER"
    "IUSR_XBOX2950"
    "IUSR_SYSPRO-DCCT"
    "IUSR_SYSPRO-DCDBN"
    "TsInternetUser"
    "IUSR_SYSPRO-CTDC"
    "HeinrichV"
    "paul"
    "impsrc10"
    "impsrc31"
    "Lesley"
    "Linda"
    "Kerry"
    "Peter"
    "Candyce"
    "Leigh"
    "Kirsty"
    "TESTBED$"
    "SMSService"
    "SCE"
    "Grant"
    "Mullet"
    "webmaster"
    "ArrayUser"
    "krbtgt"
    "SysproDPM"
    "backup10"
    "backup31"
    "Jhb"
    "IUSR_SYSPRO-WEBDEV1"
    "IWAM_SYSPRO-WEBDEV1"
    "IUSR_SYSPRO-TECH1"
    "IUSR_SYSPRO-TECHNT1"
    "IWAM_SYSPRO-TECHNT1"
    "WEBDOMAIN$"
    "NTPORTING"
    "ntdatasvr"
    "base"
    "IWAM_SYSPRO-TECH1"
    "LDAP_ANONYMOUS"
    "Printer"
    "impsrc51"
    "testt"
    "Karin"
    "pauline"
    "Jacqui"
    "Phil"
    "RUSS"
    "impsrc50"
    "Train4"
    "Train5"
    "Train6"
    "Train7"
    "Train8"
    "Train9"
    "Train10"
    "impsrc60"
    "CDR"
    "Supportmail"
    "SMSServer_SYS"
    "SMSClient_SYS"
    "Train2"
    "test2"
    "test3"
    "SMSServer_JHB"
    "SMSClient_JHB"
    "RPRINTER"
    "SUPPORT_388945a0"
    "louise"
    "meryl"
    "Rodney"
    "Neil"
    "Richard"
    "IWAM_SYSPRO-MASTER"
    "Proact"
    "Impafr"
    "Elizabeth"
    "Train3"
    "Test"
    "Test Bed"
    "term"
    "Roshni"
    "SharePoint"
    "test1"
    "Heinrich"
    "Andre"
    "Ingrid"
    "IWAM_SYSPRO-DCCT"
    "Sanet"
    "Maryann"
    "Ria"
    "Nerisha"
    "TrainingHR"
    "MargaretK"
    "GuestHR"
    "Cynthia"
    "CrystalServer"
    "anne"
    "NatalieL"
    "train1"
    "Natalie"
    "kirsten"
    "Kevin"
    "Mandy"
    "momcinstall"
    "SYSPROCTNumber"
    "SYSPRODBNNumber"
    "ShareHelp"
    "momdasql"
    "Offmanagementsa"
    "Accmanagementsa"
    "Custrelationssa"
    "finaccountssa"
    "Gloaccountssa"
    "Humresourcessa"
    "Marketingsa"
    "Pricingsa"
    "prosupportsa"
    "proservicessa"
    "salessatp"
    "techservicessa"
    "vertmarketssa"
    "accmanagementcan"
    "cusrealtionscan"
    "finaccountingcan"
    "gloaccountscan"
    "humresourcescan"
    "marketingcan"
    "offmanagementcan"
    "pricingcan"
    "proservicescan"
    "salescan"
    "vertmarketscan"
    "custrelationaaus"
    "finaccountingaus"
    "gloaccountsaus"
    "humresourcesaus"
    "marketingaus"
    "offmanagementaus"
    "pricingaus"
    "prosupportaus"
    "proservicesaus"
    "traintrabsferaus"
    "humresourcesuk"
    "offmanagementuk"
    "finaccountingusa"
    "gloaccountsusa"
    "humresourcesusa"
    "Marketingusa"
    "offmanagementusa"
    "Pricingusa"
    "prosupportusa"
    "techservicesusa"
    "traintransferusa"
    "vertmarketsusa"
    "SAS Help Desk"
    "Judith"
    "Duppie"
    "IWAM_SYSPRO-DCDBN"
    "dssql"
    "Phil1"
    "remotetest"
    "Sysprotest"
    "admindb"
    "Africa"
    "APS"
    "impactoutdoors"
    "biztalk2"
    "CapeTown"
    "Cornelia"
    "santa"
    "Helen.Hollick"
    "Carol"
    "Benita"
    "DFM"
    "Documentation"
    "Even"
    "Tiffany"
    "dsevents"
    "DSHOTLINE"
    "DSTesters"
    "Durban"
    "DurbanOffice"
    "Eval"
    "HR-Applications"
    "InfoCT"
    "Infodbn"
    "lorna"
    "Carole"
    "DAMIANA"
    "Pat"
    "meet1"
    "Minolta"
    "Peace.Mayaphi"
    "Philtest"
    "Leshec"
    "Lori"
    "richard1"
    "richard2"
    "Spam"
    "sysprobd"
    "Monique"
    "winfax"
    "Word"
    "Developmail"
    "traintransfersa"
    "prosupportcan"
    "techservicescan"
    "traintransfercan"
    "Temp"
    "Tyron"
    "Helga"
    "accmanagementaus"
    "salesaus"
    "techservicesaus"
    "vertmarketsaus"
    "Vista"
    "UKWeb"
    "SAWeb"
    "CANWeb"
    "USAWeb"
    "IWAM_SYSPRO-CTDC"
    "syspropub"
    "Leave"
    "Performance"
    "Night Line"
    "nedbank"
    "Meeting2"
    "Meeting1"
    "Kitchen-Mktg"
    "KitchenU"
    "kitchen"
    "Dining2"
    "Dining1"
    "Birthdays"
    "AbsalomESS"
    "PhilC"
    "CMS"
    "Standards"
    "Marianne"
    "Natasha"
    "Charles"
    "DebbieJ"
    "deloitte"
    "accmanagementuk"
    "custrelationsuk"
    "finaccountinguk"
    "gloaccountsuk"
    "Marketinguk"
    "Pricinguk"
    "prosupportuk"
    "proservicesuk"
    "salesuk"
    "techservicesuk"
    "traintransferuk"
    "vertmarketsuk"
    "sysprofax"
    "Commissions"
    "ALF"
    "Lorraine"
    "Trish"
    "adminsql"
    "accsql"
    "Guest1"
    "Guest2"
    "No-Reply"
    "publications"
    "SLAFax"
    "BoardRoom"
    "sysprosurvey"
    "Flat"
    "SYSPRO Africa"
    "Survey"
    "international"
    "Roam"
    "NAVMSE-SYSPRO-ZA"
    "Mithal"
    "Garett"
    "Rob"
    "Audit"
    "DevRoom2"
    "SueE"
    "Wouter"
    "accmanagementusa"
    "custrelationsusa'"
    "proservicesusa"
    "Salesusa"
    "Intguest"
    "CertificationComment"
    "Tamarine"
    "JudyJ"
    "joseph"
    "Beatrice"
    "CharmaineP"
    "Lyn"
    "SYSPROSmart"
    "Stefan"
    "Mariekie"
    "Denise"
    "Bradley"
    "admin"
    "Praneeta"
    "Shelley"
    "Pravir"
    "Tom"
    "Robyn"
    "Walter"
    "Kathy"
    "Kim"
    "Biancab"
    "Tabisa"
    "Core"
    "TFSSource"
    "SYSPROHelpDesk"
    "licence"
    "Angie"
    "Leatitia"
    "Shane"
    "SAS"
    "Guest1_old"
    "Guest2_old"
    "Guest3_old"
    "Guest4_old"
    "Guest5_old"
    "syspro"
    "PaulB"
    "Lee"
    "Eric"
    "Ian.Hawkeswood"
    "Annette"
    "Judi"
    "Chris"
    "Lena"
    "Ross"
    "Arabang"
    "Elias"
    "Robert"
    "Trevor"
    "CharlesH"
    "Web"
    "Train"
    "Pub"
    "sysprodbn"
    "NavVirus"
    "IUSR_SYSPRO-ZA"
    "DevRoom1"
    "Deirdre"
    "IanL"
    "PaulBLan"
    "Ianm"
    "Iantemp"
    "TUG"
    "Academic"
    "accprint"
    "Gary"
    "Sibongile"
    "Justin"
    "Amos"
    "Mark"
    "Lea"
    "Roxy"
    "zaren"
    "Ashweeta"
    "sysproct"
    "Denis"
    "Auditor"
    "Binca"
    "Estelle"
    "Tanner"
    "Monitor"
    "MerylF"
    "Guest"
    "SIUG"
    "ReceptionDBN"
    "IWAM_XBOX2950"
    "RMS"
    "Learning"
    "ISA"
    "Renier"
    "SysproSmartZA"
    "SysproBuildingServi"
    "sysprosmart_info"
    "ERRTRKStats"
    "RIS"
    "errtrkdfm"
    "administrator"
    "pdr"
    "WebDev"
    "demo1"
    "demo2"
    "Pabx"
    "Gertie"
    "Davidv"
    "Professional.Service"
    "Paulo"
    "Andy"
    "Martin"
    "Brain"
    "GavinV"
    "Phuong"
    "Darshnee"
    "Rene"
    "Angela"
    "Lynne"
    "Anja"
    "Nick"
    "Conrad"
    "varinternet"
    "SpiceWorks"
    "SASMeeting"
    "Sue"
    "Allan"
    "TrainingRoom"
    "mohammed"
    "Sasha"
    "Jon"
    "SM_62e80246a8d74efd8"
    "SM_7bfdf1bd820846eeb"
    "SM_252aed59f8ab47f68"
    "SM_6eb048725def49f6a"
    "EX2010"
    "Rolando"
    "Nicole"
    "Dean"
    "EasternCape"
    "SASHotline"
    "Karenl"
    "Zaakir"
    "Amaro"
    "Mpho"
    "Panasonic"
    "RequestQuotesla"
    "Roamingtestusertest"
    "Brendan"
    "SYSPROQuoting"
    "Ursula"
    "authorise"
    "RenierG"
    "Leighanne"
    "Rebecca"
    "robt"
    "Selma"
    "SOSUser"
    "Craigc"
    "pruser"
    "thierry"
    "jacques"
    "DSCMS"
    "Sarah"
    "CapeTownBoardroom"
    "CapeTownInternetLine"
    "SblSupport"
    "DSCalendar"
    "ChrisV"
    "SCCMNetaccess"
    "SCCMSQL"
    "ACCRepl"
    "CorporateServices"
    "AndyL"
    "guest100"
    "extest_02add6c595ab4"
    "SCOM"
    "Websense"
    "guest101"
    "Moderator"
    "Presenter"
    "Dewald"
    "Nikki"
    "Steph.hawkeswood"
    "ODCService"
    "TracyG"
    "Menwil"
    "SYSPROWCF"
    "SPT"
    "SYSPRO_BI"
    "VS2011"
    "SpiceScan"
    "TyroneJ"
    "traceym"
    "DevErrtrak"
    "Certification"
    "ODBC"
    "MaryG"
    "CathieM"
    "BrianB"
    "reception"
    "SPSEARCH"
    "SPSearchSVC"
    "Marisa"
    "NatashaWT"
    "DbnOps"
    "AuditT"
    "IntServices"
    "POSCAL"
    "Antonio"
    "Debotors"
    "TFSService"
    "Louis"
    "Killian"
    "natashac"
    "CP7"
    "MimeCast"
    "SP2013SQL"
    "SP2013Service"
    "Guest3"
    "SYSAppStore"
    "IreneS"
    "SP2013DistCache"
    "Maria"
    "Zayd"
    "Clare"
    "Marlise"
    "JP"
    "Khotso"
    "Meghan"
    "Sapics"
    "Nathi"
    "vmmlibrary"
    "Hermanus"
    "testbed1"
    "MpumeM"
    "CharityM"
    "NamhlaZ"
    "Terri"
    "AngelaC"
    "Fatima"
    "Daniel"
    "DanielM"
    "Camoren"
    "MFP"
    "Janine"
    "Michelle"
    "SZSPSearch"
    "Lornad"
    "JohanM"
    "ACCSQLMAIL"
    "Odete"
    "AnneT"
    "Jo"
    "Harold"
    "SQLMAIL"
    "DocsNew"
    "CTReception"
    "Haman"
    "$Q5F000-MJU6JVA3N2SJ"
    "SM_a1e79dda0b70444ab"
    "SM_cceb9472514d4dafb"
    "SM_72a3ac8713a74171b"
    "SM_065d4e8e26fc4ab18"
    "Caroline"
    "Bongi"
    "DevRoom3"
    "HR.ROOM"
    "IZWebmaster"
    "sharni"
    "SYSPrinting"
    "ChrisL"
    "Christelle"
    "Caitlin"
    "Franco"
    "Viki"
    "Edina"
    "Jaco"
    "DonovanM"
    "imrilubbe"
    "MeganS"
    "TFSBuild"
    "Willem"
    "MartinvN"
    "SharePointEnterprise"
    "Offline"
    "TestMail"
    "SM-TechDocs"
    "PF-Mailbox"
    "SM-KCCProject"
    "Thabo"
    "SM-PathCare"
    "Quintin"
    "Nicv"
    "Amy"
    "Zanele"
    "Petra"
    "SPPOSSupport"
    "Sabine"
    "Monica"
    "RobertB"
    "Bianca"
    "Essie"
    "HeinrichK"
    "moniqev"
    "Rachel"
    "Vivienne"
    "HR.Admin"
    "Kingston"
    "Seagate"
    "AQ"
    "SOI1"
    "SPCDRequest"
    "JamesB"
    "Gloria"
    "SysproQuote"
    "SS"
    "Clayton"
    "Jason"
    "POSSupport"
    "SP2013Farm"
    "SP2013Admin"
    "SP2013Pool"
    "SP2013Crawl"
    "SP2013Search"
    "SP2013Profiles"
    "Renee"
    "Pieter"
    "LouiseB"
    "PortalSU"
    "PortalSR"
    "Octavia"
    "Neo"
    "Andile"
    "Omphemetse"
    "Ishmael"
    "Siphile"
    "SM-GraduateProgram"
    "Doug"
    "lifeco1"
    "lifeco2"
    "lifeco3"
    "lifeco4"
    "lifeco5"
    "lifeco8"
    "lifeco9"
    "lifeco7"
    "lifeco6"
    "SibongileM"
    "calldesk1"
    "edwardm"
    "CarolH"
    "LeatitiaC"
    "Kabelo"
    "guest103"
    "SM-Academy"
    "ForumAdmin"
    "guest104"
    "hr"
    "Danie"
    "guest105"
    "SP2013Unattend"
    "Herman"
    "Heint"
    "Duane"
    "Hendrie"
    "TestUser"
    "KimV"
    "guest106"
    "Belinda"
    "guest107"
    "RichardMc"
    "Erasmus"
    "guest108"
    "Jenkins"
    "guest109"
    "Zaahida"
    "Mphikeleli"
    "guest110"
    "Caron"
    "Thane"
    "admintpf"
    "Maron"
    "CTProfessional.Servi"
    "Zain"
    "Tanya"
    "Tebogo"
    "Joshua"
    "DevRoom4"
    "ExecMeetingRoom"
    "LyncSynthTest1"
    "LyncSynthTest2"
    "pandg"
    "Kelly"
    "Juliet"
    "HealthMailboxe116f89"
    "HealthMailboxaab5e76"
    "HealthMailbox2622fa3"
    "HealthMailbox65efe52"
    "HealthMailbox7b8e4cc"
    "HealthMailboxa54b3a5"
    "HealthMailbox9ddbf6e"
    "HealthMailboxe2c77a9"
    "HealthMailbox408adca"
    "HealthMailbox0bafa7c"
    "HealthMailboxf10a5d5"
    "HealthMailbox4f6ac08"
    "HealthMailbox7efe1ff"
    "HealthMailbox3997486"
    "HealthMailboxa7d5bcf"
    "Debra"
    "SysAsiaPac"
    "Geoff"
    "FlorenceM"
    "SysproAsia"
    "Alyssa"
    "Themba"
    "Thato"
    "Regomoditswe"
    "Tshepang"
    "Gibran"
    "Thaakirah"
    "Apiwe"
    "Mahlatse"
    "Anje"
    "Israel"
    "ConradB"
    "MonicaP"
    "TebogoM"
    "Lusharn"
    "SpielbergRoom"
    "TarantinoRoom"
    "Anjev"
    "Zeen"
    "SYSPROAcademy"
    "Lufuno"
    "Tshilidzi"
    "ProfessionalServices"
    "TechServComms"
    "Docavepool"
    "DocaveService"
    "DocaveSQL"
    "DocaveFarm"
    "Patrick"
    "Edwardk"
    "DavidA"
    "Samwel"
    "Vaniter"
    "Ferdinand"
    "Veni"
    "Shingi"
    "LyncEnterprise-Appli"
    "Nayaka"
    "MarkM"
    "AfricaMeet1"
    "AfricaMeet2"
    "AfricaMeet3"
    "Annie"
    "ReceptionVoiceMailJH"
    "Sherley"
    "sanjay"
    "ChrisM"
    "Sandra"
    "JulieP"
    "Shalini"
    "MSOL_20d63163196a"
    "Ashley"
    "Roxanne"
    "Vusi"
    "TFSServiceDev"
    "VIPAdmin"
    "DeanB"
    "DavidT"
    "IvanTheInOutBoard"
    "Tholakele"
    "AFRICAExternalCalend"
    "Jino"
    "DWSQLReportNative"
    "Genevieve"
    "DMC"
    "kpims"
    "Cylma"
    "Wynand"
    "CoreReportUser"
    "AnthonyW"
    "Ian"
    "Toni"
    "Vuyane"
    "Vancouver"
    "Manchester"
    "LosAngeles"
    "Singapore"
    "Baobab"
    "Marula"
    "Lourens"
    "InfoZoneService"
    "Alicia"
    "Robin"
    "Sharepoint1"
    "CynthiaG"
    "ADFS_SVC"
    "VacancyDevelopmentM"
    "TestMailboxMove"
    "Henri"
    "AdminUser"
    "AdminJB"
    "testsysprouser"
    "testzasysprouser"
    "Sharon"
    "psdisplay"
    "AdminTS"
    "Debby"
    "Odette"
    "KabeloK"
    "Dolph"
    "firstnamesurname"
    "ATAuser"
    "InactiveUser"
    "SYSPROInternalCommun"
    "ThaboM"
    "Thembi"
    "SysproKitchen"
    "Brendan1"
    "SCSMHelpdesk"
    )
    $UserName = @(
    "Ned"
    "Ned-2"
    "IWAM_SYSPRO-DC3JHB"
    "IUSR_SYSPRO-DC3JHB"
    "IWAM_SYSPRO-DC1CT"
    "IUSR_SYSPRO-DC1CT"
    "IWAM_SYSPRO-DC1DBN"
    "IUSR_SYSPRO-DC1DBN"
    "IUSR_SYSPRO-MASTER"
    "IUSR_XBOX2950"
    "IUSR_SYSPRO-DCCT"
    "IUSR_SYSPRO-DCDBN"
    "TsInternetUser"
    "IUSR_SYSPRO-CTDC"
    "Heinrich van Heusden"
    "Paul Hollick"
    "IMP Source 10 Port User"
    "IMP Source 31 Port User"
    "Lesley Jagger"
    "Linda Samuel"
    "Kerry Scott-brown"
    "Peter Restorick"
    "Candyce Thompson"
    "Leigh Halcomb"
    "Kirsty Viljoen"
    "TESTBED$"
    "SMSService"
    "SCE"
    "Grant Fryer"
    "Mullet"
    "webmaster"
    "ArrayUser"
    "krbtgt"
    "SYSPRO DPM"
    "backup10"
    "backup31"
    "Jhb"
    "IUSR_SYSPRO-WEBDEV1"
    "IWAM_SYSPRO-WEBDEV1"
    "IUSR_SYSPRO-TECH1"
    "IUSR_SYSPRO-TECHNT1"
    "IWAM_SYSPRO-TECHNT1"
    "WEBDOMAIN$"
    "NTPORTING"
    "ntdatasvr"
    "base"
    "IWAM_SYSPRO-TECH1"
    "LDAP_ANONYMOUS"
    "Printer"
    "impsrc51"
    "testt"
    "Karin Pretorius"
    "Pauline Isaac"
    "Jacqui Young"
    "Phil Duff"
    "Russell Hollick"
    "impsrc50"
    "Train4"
    "Train5"
    "Train6"
    "Train7"
    "Train8"
    "Train9"
    "Train10"
    "impsrc60"
    "CDR"
    "Supportmail"
    "SMSServer_SYS"
    "SMSClient_SYS"
    "Train2"
    "test2"
    "test3"
    "SMSServer_JHB"
    "SMSClient_JHB"
    "RPRINTER"
    "SUPPORT_388945a0"
    "Louise Thompson"
    "Meryl Malcomess"
    "Rodney Marais"
    "Neil Hayes"
    "Richard Macfie"
    "IWAM_SYSPRO-MASTER"
    "Proact"
    "Impafr"
    "Elizabeth Daba"
    "Train3"
    "Test"
    "Test Bed"
    "Term"
    "Roshni Naidoo"
    "SharePoint"
    "test1"
    "Heinrich van Tonder"
    "Andre Kester"
    "Ingrid Aubrey"
    "IWAM_SYSPRO-DCCT"
    "Sanet Viljoen"
    "Maryann Sember"
    "Ria Butler"
    "Nerisha Ramsaroop"
    "Training HR"
    "Margaret Khuzwayo"
    "Guest HR"
    "Cynthia Desi"
    "CrystalServer"
    "Anne Morley"
    "Natalie Le Roux"
    "Train1"
    "Natalie Jagger"
    "Kirsten Lentz"
    "Kevin Dherman"
    "Mandy Hawkeswood"
    "MomC Install"
    "SYSPRO CT"
    "SYSPRO DBN"
    "Share Help"
    "mom sql"
    "Office Management"
    "Account Management"
    "Customer Relations"
    "Finance/Accounting"
    "Global Accounts"
    "Human Resources"
    "Marketing"
    "Pricing"
    "Product Support"
    "Professional Services"
    "Sales"
    "Technical Services"
    "Vertical Markets"
    "Account Management"
    "Customer Relations"
    "Finance/Accounting"
    "Global Accounts"
    "Human Resources"
    "Marketing"
    "Office Management"
    "Pricing"
    "Professional Services"
    "Sales"
    "Vertical Markets"
    "Customer Relations"
    "Finance/Accounting"
    "Global Accounts"
    "Human Resources"
    "Marketing"
    "Office Management"
    "Pricing"
    "Product Support"
    "Professional Services"
    "Training/Knowledge Transfe"
    "Human Resources"
    "Office Management"
    "Finance/Accounting"
    "Global Accounts"
    "Human Resources"
    "Marketing"
    "Office Management"
    "Pricing"
    "Product Support"
    "Technical Services"
    "Training/Knowledge Transfer"
    "Vertical Markets"
    "SAS Help Desk"
    "Judith Spencer"
    "Duppie du Plessis"
    "IWAM_SYSPRO-DCDBN"
    "dssql"
    "Phil1"
    "remotetest"
    "Sysprotest"
    "admindb"
    "African Events"
    "APS"
    "Biztalk test"
    "biztalk2"
    "Cape Town"
    "Cornelia Watts"
    "Santa Pillay"
    "Helen Hollick"
    "Carol Richardson"
    "Benita Ravyse"
    "DFM"
    "Documentation"
    "Even Nesset"
    "Tiffany Gierke"
    "DSEvents"
    "DSHOTLINE"
    "DSTesters"
    "Durban Usergroup"
    "DurbanOffice"
    "Eval"
    "HR-Applications"
    "InfoCT"
    "InfoDBN"
    "Lorna Lyte-Mason"
    "Carole Dean"
    "Damiana La Manna"
    "Pat Mc Evilly"
    "meet1"
    "Minolta"
    "Peace Mayaphi"
    "Phil Test"
    "Leshec Claassens"
    "Lorenzo Borelli"
    "richard1"
    "richard2"
    "Spam"
    "sysprobd"
    "Monique McNaught"
    "Winfax"
    "Word Printing"
    "DevelopMail"
    "Training/Knowledge Transfer"
    "Product Support"
    "Technical Services"
    "Training/Knowledge Transfer"
    "Temp"
    "Tyron Stoltz"
    "Helga Geldenhuys"
    "Account Management"
    "Sales"
    "Technical Services"
    "Vertical Markets"
    "Vista"
    "Web Development"
    "Web Development"
    "Web Development"
    "Web Development"
    "IWAM_SYSPRO-CTDC"
    "syspropub"
    "Scheduled Leave for Employees"
    "Performance"
    "Night Line"
    "nedbank"
    "Meeting Room 2"
    "Meeting Room 1"
    "Kitchen Auditorium"
    "Kitchen Upstairs"
    "Kitchen Downstairs"
    "Dining Room 2"
    "Dining Room 1"
    "Birthday List"
    "AbsalomESS"
    "Phil Conference"
    "CMS"
    "Standards"
    "Marianne Erasmus"
    "Natasha Watson"
    "Charles Glass"
    "DebbieJ"
    "deloitte"
    "Account Management"
    "Customer Relations"
    "Finance/Accounting"
    "Global Accounts"
    "Marketing"
    "Pricing"
    "Product Support"
    "Professional Services"
    "Sales"
    "Technical Services"
    "Training/Knowledge Transfer"
    "Vertical Markets"
    "sysprofax"
    "Commissions Claims"
    "ALF Licences"
    "Lorraine Makhubo"
    "Trish Fowler"
    "adminsql"
    "accsql"
    "Guest1"
    "Guest2"
    "No-Reply"
    "publications"
    "SLA Fax"
    "Board Room"
    "sysprosurvey"
    "Syspro Flat"
    "SYSPRO Africa"
    "Survey"
    "International"
    "Roaming Profile"
    "NAV for Microsoft Exchange-SYSPRO-ZA"
    "Mithal Harilal"
    "Garett Murphy"
    "Rob Hurry"
    "Auditorium"
    "DevRoom2"
    "Sue Elsworthy"
    "Wouter Combrinck"
    "Account Management"
    "Customer Relations"
    "Professional Services"
    "Sales"
    "Intguest"
    "Certification Comments"
    "Tamarine Sifolo"
    "Judy Johnson"
    "Joseph Mofokeng"
    "Beatrice Engelbrecht"
    "Charmaine Pamphilon"
    "Lyn Muskett"
    "SYSPROSmart"
    "Stefan Olivier"
    "Mariekie Coetzee"
    "Denise De Oliveira"
    "Bradley Poliah"
    "admin"
    "Praneeta Manilall"
    "Shelley Backhouse"
    "Pravir Rai"
    "Tom Grindley-Ferris"
    "Robyn Heinze"
    "Walter Segale"
    "Kathy Harris (Worrall)"
    "Kim Fouche"
    "Bianca Behrmann"
    "Tabisa Mbuyazwe"
    "Core Core"
    "TFS Source"
    "SYSPRO Help Desk"
    "License"
    "Angie Mansour"
    "Leatitia Heather"
    "Shane Meerholz"
    "SAS"
    "Guest 1"
    "Guest 2"
    "Guest 3"
    "Guest 4"
    "Guest 5"
    "syspro"
    "Paul Borthwick"
    "Lee Ridley"
    "Eric Diale"
    "Ian Hawkeswood"
    "Annette Pollitt"
    "Judi Campleman"
    "Christine English"
    "Lena Marques"
    "Ross Bateman"
    "Arabang Raditapole"
    "Elias Sithole"
    "Robert Zulu"
    "Trevor Wridgway"
    "Charles Hoole"
    "Web Development"
    "Training Room"
    "Pub"
    "sysprodbn"
    "NavVirus"
    "Internet Guest Account"
    "DevRoom1"
    "Deirdre Fryer"
    "Ian Lan"
    "PaulB Lan"
    "Ian Mann"
    "IanTemp"
    "TUG"
    "Academic Alliance"
    "accprint"
    "Gary De Oliveira"
    "Sibongile Nhlapo"
    "Justin Steyn"
    "Amos Moyo"
    "Mark Sher"
    "Lea Erasmus"
    "Roxy Laing"
    "Zaren Ramlugan"
    "Ashweeta Ramsaroop"
    "Syspro-ct"
    "Denis"
    "Auditor"
    "Janet Binca"
    "Estelle Poliah"
    "Tanner Greyling"
    "Monitor DO NOT TOUCH"
    "Meryl Franks"
    "International Guest"
    "SYSPRO Independant User Group"
    "Reception - Dbn"
    "IWAM_XBOX2950"
    "RMS"
    "LearningChannel"
    "ISASupport"
    "Renier Walker"
    "Syspro Certification"
    "Syspro BuildingServices"
    "Sysprosmart Info"
    "ERRTRK Stats"
    "Syspro South Africa"
    "errtrk dfm"
    "administrator"
    "PDR System"
    "WebDev"
    "Demonstration Room 1"
    "Demonstration Room 2"
    "Pabx"
    "Gertie Wolfaardt"
    "David van Rensburg"
    "Professional Services Calendar"
    "Paulo de Matos"
    "Andy Latham"
    "Martin Kelley"
    "Brain Paquette"
    "Gavin Verreyne"
    "Phuong Le"
    "Darshnee Shah"
    "Rene Inzana"
    "Angela Karpik"
    "Lynne Falconer"
    "Anja Soejberg"
    "Nick McGrane"
    "Conrad Marques"
    "VAR Internet"
    "SpiceWorks General"
    "SAS Meeting Room Upstairs"
    "Sue Scheepers"
    "Allan McNally"
    "Training Room"
    "Mohammed Mayet"
    "Sasha Verbiest"
    "Jon Thornton-Dibb"
    "SystemMailbox{1f05a927-f649-4f92-82dc-f938a9c3e86b}"
    "SystemMailbox{e0dc1c29-89c3-4034-b678-e6c29d823ed9}"
    "DiscoverySearchMailbox {D919BA05-46A6-415f-80AD-7E09334BB852}"
    "FederatedEmail.4c1f4d8b-8179-4148-93bf-00a95fa1e042"
    "Exchange 2010"
    "Rolando Campos"
    "Nicole Bruckner"
    "Dean Raemakers"
    "Eastern Cape"
    "SAS Hotline"
    "Karen Loots"
    "Zaakir Bhoola"
    "Amaro de Abreu"
    "Mpho Sedibe"
    "Panasonic DP. 8045"
    "Request Quotesla"
    "Roamingtestusertest"
    "Brendan"
    "SYSPRO Quoting"
    "Ursula Stroud"
    "authorise"
    "Renier Geyser"
    "Leighanne Imbert"
    "Rebecca Clatworthy"
    "Rob Test"
    "Selma Senekal"
    "SOS-User"
    "Craig Campbell"
    "PR User"
    "Thierry van Straaten"
    "Jacques Mouton"
    "DS CMS"
    "Sarah Futter"
    "Cape Town Boardroom"
    "Cape Town Internet Line"
    "SBL Support"
    "DS Calendar"
    "Chris Vogt"
    "SCCM NetAccess"
    "SQL Service"
    "ACCRepl"
    "Corporate Services HUB Meeting Room"
    "Andy Latham"
    "Guest100"
    "extest_02add6c595ab4"
    "SCOM Run As. Account"
    "Websense"
    "Guest101"
    "Moderator"
    "Presenter"
    "Dewald Brink"
    "Nikki Malcomess"
    "Steph Hawkeswood"
    "ODCService"
    "Tracy Robb"
    "Menwil Gordon"
    "SYSPROWCF Services"
    "SP Tester"
    "SYSPRO_BI"
    "VS2011"
    "Spiceworks Scan"
    "Tyrone Jagger"
    "Tracey Moller"
    "DevErrtrak"
    "Certification"
    "ODBC"
    "Mary Githu"
    "Cathie Hall"
    "Brian Stein"
    "SYSPROReception"
    "Sharepoint Search"
    "Sharepoint Search Service"
    "Marisa"
    "Natasha Wilson-Taylor"
    "DBN OPS"
    "Audit Temp"
    "Integrated Services"
    "POINT OF SALES"
    "Antonino Marra"
    "Debtors"
    "TFSService"
    "Louis"
    "Killian Sibanda"
    "Natasha Morgan"
    "Community Preview"
    "MimeCast Query"
    "SP2013SQL"
    "SP2013Service"
    "Guest3"
    "SYSPRO App Store"
    "Irene Snyman"
    "Sharepoint 2013. Distributed Cache"
    "Maria La Manna"
    "Zayd Mahioodin"
    "Clare Forson"
    "Marlise du Plessis"
    "JP van Loggerenberg"
    "Khotso Shomang"
    "Meghan Kemp"
    "Sapics User"
    "Nkosinathi Fungene"
    "vmm library"
    "Hermanus Smalman"
    "testbed"
    "Mpume Madonsela"
    "Charity Mwale"
    "Namhla Zakaza"
    "Terri da Silva"
    "Angela Chandler"
    "Fatima Daya"
    "Daniel Sher"
    "Daniel Monyamane"
    "Camoren Moller"
    "MFP"
    "Janine du Plooy"
    "Michelle Botha"
    "SZSPSearch"
    "Lorna du Plessis"
    "Johan Myburg"
    "ACCSQL Mail"
    "Odete Passingham"
    "Anne Teng"
    "Jo Burnett"
    "Harold Katz"
    "SQLMAIL"
    "DOCSNEW"
    "CPT Reception"
    "Haman"
    "Exchange Online-ApplicationAccount"
    "SystemMailbox{bb558c35-97f1-4cb9-8ff7-d53741dc928c}"
    "Migration.8f3e7716-2011-43e4-96b1-aba62d229136"
    "HealthMailbox8619aab417e849aa9e009c70d95b562c"
    "HealthMailboxd0bc3eb783da4ec1aa033fce8cf58994"
    "Caroline Mozwenyana"
    "Sibongile Keswa"
    "DevRoom3"
    "HR Room"
    "InfoZone Webmaster"
    "Sharni Hart"
    "SYSPRO Server Printing"
    "Chris Lautre"
    "Christelle Swanepoel"
    "Caitlin Shepherd"
    "Franco Gates"
    "Viki Neilson"
    "Edina Beeten"
    "Jaco Maritz"
    "Donovan MacMaster"
    "Imri Lubbe"
    "Megan Schoeman"
    "TFS Build"
    "Willem van Rensburg"
    "Martin van Niekerk"
    "SharePointEnterprise-ApplicationAccount"
    "Offline Test"
    "Test Mail"
    "SM-TechDocs"
    "PF-Mailbox"
    "SM-KCCProject"
    "Thabo Tlebere"
    "SM-PathCare"
    "Quintin Botes"
    "Nic Veldmeijer"
    "Amy Ritson"
    "Zanele Seneka"
    "Petra Van Waardhuizen"
    "SPPOSSupport"
    "Sabine Behrmann"
    "Monica Pretorius"
    "Robert Bouwer"
    "Bianca Haarhoff"
    "Essie Jansen van Vuuren"
    "Heinrich Kolliner"
    "Moniqe Kollner"
    "Rachel van Graan"
    "Vivienne Mseka"
    "HR Admin"
    "Kingston Tech"
    "Seagate Thin"
    "AQ"
    "SOI TEST"
    "SPCDRequest"
    "James Blanckenberg"
    "Gloria Lombard"
    "Syspro.QuotationReminders"
    "SS"
    "Clayton Dormehl"
    "Jason Baxter"
    "POS Support"
    "SP2013Farm"
    "SP2013Admin"
    "SP2013Pool"
    "SP2013Crawl"
    "SP2013Search"
    "SP2013Profiles"
    "Renee van der Berg"
    "Pieter van Heerden"
    "Louise Buchanan"
    "Portal Super User"
    "Portal Super Reader"
    "Octavia Hlophe"
    "Neo Kgopa"
    "Andile Shange"
    "Omphemetse Mabe"
    "Ishmael Mbanjwa"
    "Siphile Mathabela"
    "SM-GraduateProgram"
    "Doug Hunter"
    "lifeco1"
    "lifeco2"
    "lifeco3"
    "lifeco4"
    "lifeco5"
    "lifeco8"
    "lifeco9"
    "lifeco7"
    "lifeco6"
    "Sibongile Makhathini"
    "do not reply"
    "Edward L. Mello"
    "Carol Hart"
    "Laetitia Clark"
    "Kabelo Masuku"
    "Guest103"
    "SM-Academy"
    "ForumAdmin"
    "guest104"
    "HR"
    "Danie du Plessis"
    "guest105"
    "SP2013Unattend"
    "Herman  Boonzaier"
    "Hein Test"
    "Duane van Coller"
    "Hendrie Potgieter"
    "TestUser"
    "Kim van der Walt"
    "guest106"
    "Belinda Chetty"
    "guest107"
    "Richard Mc Cormack"
    "Musa Dlamini"
    "guest108"
    "Jenkins"
    "Guest 109"
    "Zaahida Rayman"
    "Mphikeleli Nkabinde"
    "guest110"
    "Caron Hewitt"
    "Thane Forst"
    "Thane Forst (Admin Account)"
    "Maron Mashile"
    "CT Professional Services Calendar"
    "Zain Ajam"
    "Tanya Botha"
    "Tebogo Moorosi"
    "Joshua Troskie"
    "DevRoom 4"
    "Exec Meeting Room"
    "LyncSynthTestUser1"
    "LyncSynthTestUser2"
    "Proctor Gamble"
    "Kelly Farr"
    "Juliet Ruvengo"
    "HealthMailboxe116f892d91d415faeba39a2cf563fc9"
    "HealthMailboxaab5e76791a444ce967c03a4006d091e"
    "HealthMailbox2622fa33de5044d5aa97535eb2fd80d0"
    "HealthMailbox65efe5295cf246e39376514be3df8493"
    "HealthMailbox7b8e4cc9686b45daaa0b64cd410c4d20"
    "HealthMailboxa54b3a5577c547719b22db013333005b"
    "HealthMailbox9ddbf6ec00b54b459728b7b7b55105f0"
    "HealthMailboxe2c77a998bad4d6b91fe5002cb6dcae7"
    "HealthMailbox408adcada8134cab96669d58b00d9588"
    "HealthMailbox0bafa7c341e44c4da1278e14a19a7402"
    "HealthMailboxf10a5d5321c9441381ab7cdbc7afb45a"
    "HealthMailbox4f6ac08f86e84127bd723a425d6fd6ff"
    "HealthMailbox7efe1ff6c4f14b4287cb357872d14492"
    "HealthMailbox3997486371424dd181f4612c6ee05855"
    "HealthMailboxa7d5bcf008f0440888a57ba12d6a520a"
    "Debra Botha"
    "Syspro AsiaPac"
    "Geoff Garett"
    "Florence Mfiki"
    "Syspro Asia"
    "Alyssa Whale"
    "Themba Makhubele"
    "Thato Fihlo"
    "Regomoditswe Mamba"
    "Tshepang Julie"
    "Gibran Noorbhai"
    "Thaakirah Raffie"
    "Apiwe Hoyi"
    "Mahlatse Sombhane"
    "Anje van Veelen"
    "Israel Kabayo"
    "Conrad Beukes"
    "Monica Pretorius"
    "Tebogo Moorosi"
    "Lusharn Botes"
    "Spielberg Room"
    "Tarantino Room"
    "Anje van Veelen"
    "Zeen Cassim"
    "SYSPRO Academy"
    "Lufuno Mukhwathi"
    "Tshilidzi Makumbane"
    "Professional Services Call Desk"
    "TechServices Communications"
    "Docavepool"
    "DocaveService"
    "DocaveSQL"
    "DocaveFarm"
    "Patrick Wafula"
    "Edward Keya"
    "David Ambuga"
    "Samwel Sakwa"
    "Vaniter Obuya"
    "Ferdinand Odhiambo"
    "Veni Govender"
    "Shingi Nhari"
    "LyncEnterprise-ApplicationAccount"
    "Nayaka Moloto"
    "Mark Mackay"
    "Africa Meet 1"
    "Africa Meet 2"
    "Africa Meet 3"
    "Annie Jurbandam"
    "Reception JHB Voice Mail"
    "Sherley Makofane"
    "Sanjay Galal"
    "Chris Meyers"
    "Sandra Fraga"
    "Julie Pryce-Jones"
    "Shalini Naidoo"
    "MSOL_20d63163196a"
    "Ashley Pillay"
    "Roxanne Govender"
    "Vusi Dhlamini"
    "TFSService Account Dev"
    "VIP Admin"
    "Dean Bunce"
    "David Thompson"
    "Ivan TheInOutBoard"
    "Tholakele Zungu"
    "AFRICA External Calendar"
    "Jino Makau"
    "DWSQLReportNative"
    "Genevieve Aitken"
    "DMC"
    "kpims"
    "Cylma Spaans"
    "Wynand Marais"
    "CoreReportUser"
    "Anthony Wilson"
    "Ian Lawless"
    "Toni Joubert"
    "Vuyane Mtoyi"
    "Vancouver"
    "Manchester"
    "Los Angeles"
    "Singapore"
    "Baobab"
    "Marula"
    "Lourens Kilian"
    "InfoZoneService"
    "Alicia Smuts"
    "Robin van der Plank"
    "Sharepoint"
    "Cynthia Giyani"
    "ADFS SVC"
    "Vacancy Development Manufacturing"
    "TestMailboxMove"
    "Henri Borsboom"
    "Henri Borsboom (Admin Account)"
    "Jason Admin Baxter"
    "Test SYSPRO User"
    "Test SYSPRO ZA User"
    "Sharon Mkhize"
    "Display User"
    "Tyron Stoltz (Admin Account)"
    "Debby Diedericks"
    "Odette Bester"
    "Kabelo Kekana"
    "Dolph Pretorius"
    "firstname surname"
    "ATAuser"
    "Inactive User"
    "SYSPRO Internal Communications"
    "Thabo Mofokeng"
    "Thembi Montsho"
    "Syspro Kitchen"
    "Brendan Vorster"
    "SCSMHelpdesk"
    )
    $DistinguishedName = @(
    "OU=Recipients,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=External Users,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=External Users,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users - Use this OU,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Distribution,OU=Durban,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=UsersOld,OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=General Users,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users - Use this OU,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users - Use this OU,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users0old,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Recipients,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Development,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Professional Services,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users0old,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users0old,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users0old,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Cape Town,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=International Lync Users,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=International Lync Users,DC=sysproza,DC=net"
    "OU=International Lync Users,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Temp SharePoint Users,DC=sysproza,DC=net"
    "OU=Temp SharePoint Users,DC=sysproza,DC=net"
    "OU=Temp SharePoint Users,DC=sysproza,DC=net"
    "OU=Temp SharePoint Users,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Contractors,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Contractors,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Contractors,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Contractors,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Contractors,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Intern Users,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Admin Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Meeting Rooms,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Meeting Rooms,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersTest,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersTest,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Azure Users,OU=Azure,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Territory Office Users,OU=Azure,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Territory Office Users,OU=Azure,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Sharepoint Service Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Sharepoint Service Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Sharepoint Service Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Sharepoint Service Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Users0old,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users0old,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users0old,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Sharepoint Service Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Service Account,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Sharepoint Service Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=EA Accounts,OU=SYSPRO Azure,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Admin Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Consultants,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Consultants,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Consultants,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Consultants,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Meeting Rooms,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Meeting Rooms,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Meeting Rooms,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Meeting Rooms,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Meeting Rooms,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Meeting Rooms,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Sharepoint Service Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Admin Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersTest,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Admin Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Admin Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersTest,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersTest,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Admin Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersTest,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Admin Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Admin Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    )

    Clear-Host
    $ADCount = $UserName.Count

    For ($i = 0; $i -lt $ADCount; $i ++) {
        Write-Host (($i + 1).ToString() + "\$ADCount - Creating " + $UserName[$i] + " - ") -NoNewline
        Try {
            New-ADUser -SamAccountName $SAMAccount[$i] -Name $Username[$i] -Path $DistinguishedName[$i] -ErrorAction SilentlyContinue
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch {
            Write-Host "Failed" -ForegroundColor Red -NoNewline
            Write-Host (" - " + $_)
        }
    }
}
Function Create-Computer {
    $ComputerName = @(
        "SYSPRO-DCVM"
        "SYSJHBDC"
        "TS-MONITOR"
        "CTSTORE"
        "DBNSTORE"
        "SYSPROTMG"
        "SYSJHBTS"
        "SYSPRO-DPM"
        "SYSPRO-DSNT"
        "SYSPRO-INTSVR"
        "SYSPRO-DSSQL"
        "SASSCO"
        "SYSPRO-SAS3K"
        "SYSPRO-ERRTRK"
        "SYSPRO-STRIPSER"
        "WEBMASTER"
        "SYSPRO-MONITOR"
        "CT-LAPTOP"
        "SYSPRO-PRINT"
        "DBNOPS"
        "SYSPRO-SASSERV"
        "VIRTUAL-TBED"
        "SYSPRO-BUILD"
        "RUSSROBOHELP"
        "SYSPRO-ABSALOM"
        "SYSPRO-DSSFS"
        "SYSPRO-EXCHANGE"
        "SYSPRO-WEBSENSE"
        "AQSERVER2003"
        "SHAREPOINT2010"
        "WEBSENSE"
        "SYSPROCMS"
        "TRISH-FAX"
        "WEBDEV-WINR2"
        "CERTIFICATION"
        "SYSPRO-ODC"
        "AQANALYTICSSQL2"
        "AQ-SQL2005"
        "FINSQL"
        "MANSQL"
        "DISTSQL"
        "SASSTEIN"
        "NERISHA"
        "SASREPORT"
        "KERRYSC"
        "JACKIMAC-PC"
        "RUSSXP-VM"
        "SARAHFUT"
        "EVENODCTEST"
        "DEVSERVWIN2003"
        "WEBMONITOR"
        "SHAREPOINT"
        "AUDITORIOUM"
        "VM-WIN8X64CP"
        "DEBBY-TFS2010"
        "SYSPRO-DPM2012"
        "SASHOTLINE"
        "SYSPRO-PROFSERV"
        "INFOZONE"
        "SYSJHBSYSCENTRE"
        "PROXYTEST"
        "SEANPOS"
        "TRAININGPOC"
        "SYSPRO-FTP"
        "syspro-ftpdev"
        "syspro-ftpsvr"
        "SYSPRO-WEBDEV"
        "syspro-wwwsvr"
        "DEVT2"
        "DEVTEST2"
        "CORPTRAIN1"
        "CORPTRAIN2"
        "CORPTRAIN4"
        "CORPTRAIN5"
        "CORPTRAIN6"
        "CORPTRAIN3"
        "VM-SM2012MS"
        "SYSJHBSMAN-DW"
        "GENTRAIN12"
        "GENTRAIN7"
        "AUDIT-TEMP"
        "WINDOWS2012RC"
        "GENTRAIN14"
        "VMDEBBYSQL2005"
        "WIN7_X64"
        "DEBBYSVR2008"
        "VM-DPMWIN2012"
        "SYSJHBDEV"
        "SYSPROHVPROXY"
        "SYSJHBVMM2012"
        "SYSPROHV1"
        "SYSPROHV2"
        "JHBCLIENTTEMP"
        "PHILSTABLET"
        "SYSCTSTORE"
        "PRESENT1"
        "SYSJHBVTRS"
        "LYNMUSKE"
        "WINSLATE2"
        "LORRAINE"
        "WOUTERC"
        "SYSDBNSTORE"
        "JUDYJOHN"
        "SANETVI"
        "SELMAPRE"
        "LORNALYTE"
        "KARINPRE"
        "KIRSTYVI"
        "ROBERTZ"
        "MARKSHE"
        "ERICDIA"
        "MPHOSEBI"
        "MERYL"
        "ASHWEET"
        "LESLEY"
        "STEFANOLI"
        "ZAAKHIRB"
        "CHARMAIND"
        "MENWILG"
        "JUDITHS"
        "GENTRAIN11"
        "CD-BURNER"
        "SUEELSW"
        "DSWIN2000"
        "SYSPABX"
        "SYSPRO-DEVELOP"
        "MARYANNV"
        "PAULH"
        "CAROLED"
        "NATASHAWA"
        "MONIQUEM"
        "SASHAVER"
        "GENTRAIN2"
        "GENTRAIN6"
        "GENTRAIN8"
        "GENTRAIN1"
        "TEMPRECEPTION"
        "CORPTRAIN7"
        "CORPTRAIN8"
        "ROBVS2012"
        "HELGAGELD"
        "LEAERAS"
        "KEVIND"
        "CORNELIAW"
        "EVENNES"
        "ROXYLIA"
        "MARYGIT"
        "TIFFANYG"
        "NERISHAR"
        "SHENAISU"
        "LESLEYT"
        "OMPHEME"
        "DAMIANAL"
        "GENTRAIN3"
        "GENTRAIN5"
        "GENTRAIN4"
        "PRAVIRR"
        "CHRISVOGT"
        "LEIGHANNE"
        "SYSPROSCREENS"
        "SYSPRO-DSFS"
        "SYSPROWIN2008"
        "BIANCAB"
        "NICOLEBR"
        "DENISEDE"
        "NEILHAYE"
        "JUDYCAM"
        "NATALIEJO"
        "CHARLES"
        "ESTELLEPO"
        "LOUISET"
        "ANNEMOR"
        "TREVORW"
        "syspros_imac"
        "GENTRAIN9"
        "GENTRAIN10"
        "NATALIELE"
        "KIRSTENL"
        "LINDASA"
        "KEVIN-SLATE"
        "KILLIANS"
        "LORENZO"
        "MARIEKIEC"
        "BEATRICEEN"
        "RUSSTABLET"
        "RUSSELL"
        "SHELLEY"
        "SYSJHBSP"
        "VM-POSPARENT"
        "VMPOSREMOTE3"
        "SYSJHBSQLSP"
        "GENTRAIN13"
        "SYSJHBVMM"
        "SYSPROWIN2012"
        "XPROBO"
        "DUPPIEDU"
        "SAMSUNGTAB1"
        "VM-GENTRAIN1"
        "VM-GENTRAIN2"
        "VM-GENTRAIN3"
        "VM-GENTRAIN9"
        "VM-GENTRAIN10"
        "VM-GENTRAIN11"
        "VM-GENTRAIN12"
        "XPTEST"
        "GENTRAIN16"
        "TRAINING7"
        "SANTAPIL"
        "SYSPROTRAIN-PC"
        "PROFSERVPC"
        "SYSPRO-E6E74260"
        "PS-POS"
        "SYSCTPS"
        "TECHHVTEST"
        "SYSJHBOPSMGR"
        "MARIALAM"
        "SCREENDUMP-PC"
        "CHARMAINEPA"
        "ADMINADMIN"
        "CLAREFOR"
        "RACHELVA"
        "SYSJHBSERVMAN"
        "NEILTESTWIN8"
        "DEWALDBR"
        "vmcluster"
        "sysvmcluster"
        "VM-GENTRAIN16"
        "VM-GENTRAIN15"
        "TABISANB"
        "VM-GENTRAIN14"
        "VM-GENTRAIN13"
        "VM-CORPTRAINER"
        "ADMIN-PC1"
        "JETI"
        "VM-GENTRAIN5"
        "VM-GENTRAIN6"
        "VM-GENTRAIN7"
        "VM-GENTRAIN8"
        "VM-GENTRAINER"
        "SYSJHBACC"
        "SYSPROCMSOLD"
        "KHOTSOSH"
        "RICHARD"
        "SYSCOREDEV"
        "JACQUENB"
        "SYSJHBHVTR"
        "TRISHY2008R2"
        "TRISHYWINDOWS8"
        "SYSCOREAIO"
        "VM-GENTRAIN4"
        "SYSJHBOWA"
        "MANDYHARW"
        "SYS7SOI2010"
        "SYS7SOI2007"
        "SYSJHBTESTDEV"
        "USER-PC"
        "SCREENSTRAINING"
        "SYSJHBSTORE"
        "BISQL2008R2"
        "ATTTESTINSTALL"
        "TYRONEJA"
        "NKOSINNB"
        "SYSJHBFTP"
        "HERMANUSS"
        "HRTEMP"
        "GRANTF"
        "HEINRICH"
        "sysjhbcentos"
        "LESHECCL"
        "GARETTMU"
        "LEERIDLE"
        "ELIASSIT"
        "AMOSMOYO"
        "CANDYCET"
        "RECEPTI1"
        "RECEPTI2"
        "GERTIEWO"
        "ANNETTEP"
        "PATMCEVI"
        "SUESCHEE"
        "ALICIASM"
        "RENIERWA"
        "PAULBORT"
        "FATIMADA"
        "TAMARINE"
        "PRANEETA"
        "SHELLEYB"
        "TANNERGR"
        "ROLANDOCA"
        "INGRIDAU"
        "DANIELSH"
        "URSULAST"
        "MOHAMMED"
        "SYSJHBMFP"
        "ZAYDMAHI"
        "NIKKIMAL"
        "LORNADUP"
        "GARYDEOL"
        "MARLISED"
        "KATHYHAR"
        "VMLEEWIN7"
        "TOMGRIND"
        "JONTHORN"
        "SERVER2012R2TS"
        "SYSJHBFS"
        "USER1"
        "SYSJHBMAIL"
        "SYS7SVR2008R2"
        "SYSPRO7WIN7"
        "SYSCTDC"
        "SVR2008SQL2012"
        "PAULODE"
        "CAROLINE"
        "HR-PC"
        "SYSJHBPRINT"
        "CAROLINESHAREP"
        "SYSJHBTESTHV"
        "SYSPRO7SVR12"
        "DEVROOM2"
        "SYSJHBDS2012R2"
        "ZARENRAM"
        "TRISHFOW"
        "SYSJHBHV1"
        "SYSJHBCLUSTER"
        "SYSJHBHV2"
        "WINTEST8"
        "AUDITORS"
        "NETEXPRESSBUILD"
        "SYSJHBHV3"
        "SYSDBNDC"
        "KEVINSURFACE"
        "VM-GRANT-7-PRIN"
        "SYSJHBERRTRK"
        "RUSSSURFACEPRO2"
        "HRTEMP1-PC"
        "garys-imac"
        "SYSTEMTEST"
        "HELLSURFACEPRO2"
        "SYSPRO7WIN8"
        "SYSJHBLYNC"
        "LEIGHHAL"
        "VM-SYS7TRAIN1"
        "VM-SYS7TRAIN2"
        "VM-SYS7TRAIN4"
        "VM-SYS7TRAIN3"
        "VM-SYS7TRAIN5"
        "VM-SYS7TRAIN6"
        "VM-SYS7TRAIN8"
        "VM-SYS7TRAIN7"
        "VM-SYS7TRAIN9"
        "TRAINTEMPL"
        "VM-SYS7TRAIN11"
        "VM-SYS7TRAIN13"
        "VM-SYS7TRAIN12"
        "VM-SYS7TRAIN14"
        "VM-SYS7TRAIN15"
        "VM-SYS7TRAINER"
        "VM-SYS7TRAIN16"
        "CHRISTEL"
        "VM-SYSTEMSQL"
        "DEVSERVERRC7"
        "LESLEYJA"
        "JACOMARI"
        "KARENLOO"
        "KCCPROJECT"
        "KEVINDHE"
        "RICHARDM"
        "TECH"
        "SYS-SS-POSSRV"
        "SYS-SS-POSBR"
        "THABOTLE"
        "QUINTINB"
        "JACQUESM"
        "CHARMAIN"
        "AMYRITSO"
        "PETRAVAN"
        "CRAIGCAMB"
        "SYSJHBHV4"
        "SABINEBE"
        "TYRONST"
        "HEINRICHK"
        "ERICDIAL"
        "ANGIEMA"
        "ESSIEJAN"
        "ROBERTB"
        "BIANCAHA"
        "MONIQEVI"
        "SYS-SS-POS7S"
        "SYSJHBCRM"
        "DEVROOM3-PC"
        "THIERRYV"
        "MONICAPR"
        "ROSHNIN"
        "SYSJHBHVTR2"
        "DEIRDREF"
        "LENAMAR"
        "TRACYROB"
        "VIVIENNE"
        "JohanM"
        "SYSLYNCTEST2013"
        "SYSLYNCTEST2010"
        "JAMESBLA"
        "JENOLAED"
        "VMPOSIE10"
        "VMPOSIE11"
        "CLAYTOND"
        "ANDREKES"
        "SYSJHBCERT"
        "SYS-SS-POS6S"
        "PSCALLDESKTEMP"
        "LyncTest"
        "JASONBAX"
        "CAUCLUSTER"
        "AQM"
        "POSONLINEVM"
        "POSOFFLINEVM"
        "SYSJHBSP2"
        "JASONSPNB"
        "VMPOSIE13"
        "VMPOSIE12"
        "AMARODEA"
        "PETERRES"
        "WINDOWS81"
        "RENEEVAN"
        "DOCMAC"
        "POS6CL"
        "POS6SVR"
        "POS7C"
        "POS7SVR"
        "LOUISEBU"
        "ZANELESE"
        "POSTESTSERVER"
        "VM-STHESP2013"
        "SYSJHBWA"
        "OnPos7"
        "OffPos7"
        "SYSJHBDEVAUTO"
        "PATMCE"
        "VM2013SERVER"
        "SYSJHBDPM"
        "GARYDEOLPAR"
        "EDWARDME"
        "CAROLHAR"
        "LEATITIAC"
        "SYSJHBWEBGEN"
        "PREACTOREXPRESS"
        "RENIERNB"
        "KABELOMA"
        "SASTESTNEW"
        "BENITARA"
        "DANIEDUP"
        "ROBVS201"
        "SYSJHBPROXY"
        "JANINEDP"
        "ESSIEVAN"
        "SYSETECHBUILD"
        "DEVROOM2PC"
        "HERMANBO"
        "SIBONGILE"
        "DEVROOM1"
        "DUANEVAN"
        "GLORIALO"
        "ENGCHINETEST1"
        "KEVINHP"
        "DUANEVANC"
        "TRACEYMO"
        "ROSSBATE"
        "HENDRIE"
        "JUSTIN"
        "DAVIDVANR"
        "KIMVANDE"
        "PSOFFLINE1"
        "PSONLINE1"
        "KEVINSURFACE2"
        "DEVROOM3"
        "BELINDAC"
        "LEATITIA-SERVER"
        "NATASHAB"
        "VM-INGRIDWIN10"
        "HEINRICHT"
        "ERASMUSD"
        "SYSJHBTESTHV2"
        "VMMITHALCLIENT"
        "RECOVERY-PC"
        "SIBONGIE"
        "SYSJHBSQLSS"
        "IRENESN"
        "CAMOREN"
        "LYNCUPDATE"
        "SASPOSTEST"
        "SASPOSOFFLINE"
        "ERRTRKSERVER"
        "ERRTRKCLIENT"
        "SASPOOL"
        "SYSJHBLYNCEDGE"
        "SYSJHBDW"
        "ZAAHIDAR"
        "INGRIDCHINESE"
        "VIKISUEN"
        "SYSJHBPROFSERV"
        "ISHMAEL"
        "JPVANLO"
        "DSSCREEN"
        "HEINRICK"
        "DSSCREENS"
        "SYSJHBSPUAT"
        "CARONHEW"
        "SYSSP2016RTM"
        "THANEFOR"
        "VM-POS7TRAIN1"
        "VM-POS7TRAIN2"
        "VM-POS7TRAIN3"
        "VM-POS7TRAIN4"
        "VM-POS7TRAIN5"
        "VM-POS7Train10"
        "VM-POS7Train9"
        "VM-POS7Train6"
        "VM-POS7Train7"
        "VM-POS7Train8"
        "xps13"
        "NATASHAM"
        "SYSJHBSPDZ"
        "DEBBY"
        "MARONMAS"
        "CORNELIA"
        "LOUISE"
        "JOSHUATR"
        "KIMFO"
        "DENISED"
        "NEILHAY"
        "ZAINAJAM"
        "GOODFELLOWS"
        "TRACYROBBTEMP"
        "ANDILES"
        "DEBBYSVR2012"
        "PHIKSWINDOWS"
        "SYSJHBSMPORTAL"
        "TANYABOT"
        "TEBOGOMO"
        "JOSHUAT"
        "KELLYFAR"
        "DEANBUNC"
        "ANDILESAS"
        "THABOT"
        "SYSJHBLYNCPICKU"
        "SYSJHBLYNCAPP"
        "TSPC3"
        "ROBWIN10"
        "TSPC6"
        "TSPC7"
        "INTERNPC4"
        "SIPHILEM"
        "ISHMAELM"
        "TSPC8"
        "VM-SHANETESTING"
        "TSPC4"
        "TSPC1"
        "INTERNPC1"
        "INTERNPC2"
        "INTERNPC3"
        "JULIETRU"
        "ALYSSAWH"
        "INTERNPC5"
        "INTERNPC6"
        "INTERNPC7"
        "INTERNPC8"
        "INTERNPC10"
        "INTERNPC9"
        "INTERNPC12"
        "INTERNPC11"
        "DEVROOM4-PC"
        "STEPHVM"
        "SYSJHBAVE"
        "INFOZONEDEVNEW"
        "BIANCAH"
        "TSPC"
        "SYSJHBWEBDEVDB"
        "SERVER2016"
        "POS7MAINSVR"
        "POS7MAINC"
        "ANGIEPOSONLINE"
        "ANGIEPOSOFFLINE"
        "ACCOUNTSTEMP"
        "PATRICKW"
        "EDWARDKE"
        "JASONLAP"
        "DAVIDAMB"
        "FERDINAN"
        "KENYA5"
        "KERRYSCOT"
        "SS-SHANESVRSIDE"
        "KEVINDH"
        "LOURENSK"
        "DEANRAEM"
        "ANTONIO"
        "DEVROOM4"
        "WALTERVM"
        "MITHALTEMP"
        "ANDILEPOS"
        "shingi-mac"
        "ARABANGR"
        "SHERLEYM"
        "LOANTECH"
        "MARYANNTEMP"
        "PAULBOR"
        "SANDRAFR"
        "TESTM"
        "TRAINING1"
        "TRAINING10"
        "TRAINING9"
        "TRAINING12"
        "TRAINING11"
        "RECEPTIONSP"
        "TRAINING8"
        "TRAINING5"
        "TRAINING4"
        "TRAINING3"
        "TRAINING6"
        "TRAINING28"
        "TRAINING21"
        "TRAINING25"
        "TRAINING22"
        "TRAINING14"
        "TRAINING19"
        "TRAINING20"
        "TRAINING18"
        "TRAINING17"
        "TRAINING27"
        "TRAINING15"
        "TRAINING24"
        "PIETERVA"
        "TRAINING23"
        "TRAINING26"
        "PIETERVH"
        "SHALININ"
        "TRAINING2"
        "SYSJHBTFSDEV"
        "SYSJHBSPDEV"
        "ROSSVM"
        "SYSJHBVIP"
        "ROXANNEG"
        "DFRYERSQLBOX"
        "ASHLEYPI"
        "LEVIOUSD"
        "PSCALLDESKCORI"
        "MITWINOFF"
        "SELMASE"
        "TANNERG"
        "WALTERNB"
        "VM32BIT"
        "SHAREPOINTTEMP2"
        "SHAREPOINTTEMP1"
        "NEILWIN10DEBUG"
        "TRAINING13"
        "TRAINING16"
        "DAVIDTHO"
        "PHIL"
        "IVANINOUTBOARD"
        "THOLAKEL"
        "IVANINOUT"
        "JINOMAKA"
        "SYSJHBHVTR3"
        "GENEVIEV"
        "SYSJHBPROPHIX"
        "SYSJHBSP16DEV"
        "ANDIEWIN10"
        "WYNANDMA"
        "SIBONGIL"
        "ZARENRA"
        "VUSITESTENV1"
        "LEATITIASVR"
        "VM-SYS7TRAIN17"
        "VM-SYS7TRAIN18"
        "VM-SYS7TRAIN19"
        "VM-SYS7TRAIN20"
        "VM-SYS7TRAIN21"
        "VM-SYS7TRAIN22"
        "VM-SYS7TRAIN23"
        "VM-SYS7TRAIN24"
        "VM-SYS7TRAIN25"
        "VM-SYS7TRAIN26"
        "VM-SYS7TRAIN27"
        "VM-SYS7TRAIN28"
        "ANTHONYW"
        "IANLAWLE"
        "VUYANEMT"
        "TONIJOUB"
        "SARAHFU"
        "MITHAL"
        "SANJAYG"
        "SHANEM"
        "PRAVIR"
        "ESTELLEP"
        "ROBINVAN"
        "RENIERN"
        "SYSJHBSSS"
        "APIWEHOY"
        "VUSIWIN12"
        "CYNTHIAG"
        "SYSJHBCA1"
        "SYSJHBCA2"
        "TRAINING29"
        "TRAINING30"
        "EVENNE"
        "WORKSTATION"
        "LEATITIA"
        "LEATITIAOLD"
        "SHARONMK"
        "SYSJHBDISPS"
        "MARYANN"
        "LORRAIN"
        "SYSPRDDCINFRA1"
        "local-pixs-imac"
        "TSPC2"
        "TRACYRO"
        "DOUGHUNT"
        "CYLMASPA"
        "TSPC11"
        "SYSPRDSQLDB01"
        "SYSPRDSP01"
        "DEBBYDIE"
        "CHRISSQL2005"
        "ODETTEBE"
        "HELENHOL"
        "DEPLOYT"
        "TIFFANY"
        "SYSJHBATA"
        "KABELOKE"
        "DOLPHPRE"
        "SYSJHBSCDB01"
        "SYSJHBSCSM01"
        "SYSJHBSCSP01"
        "THABOMOF"
        "THEMBIMO"
        "WIN-DP6Q9GU3K7S"
        "TESTDC2"
        "SYSKITCHTEN"
        "BRENDAN"
        "PETERRE"
    )
    $SAMAccountName = @(
        "SYSPRO-DCVM$"
        "SYSJHBDC$"
        "TS-MONITOR$"
        "CTSTORE$"
        "DBNSTORE$"
        "SYSPROTMG$"
        "SYSJHBTS$"
        "SYSPRO-DPM$"
        "SYSPRO-DSNT$"
        "SYSPRO-INTSVR$"
        "SYSPRO-DSSQL$"
        "SASSCO$"
        "SYSPRO-SAS3K$"
        "SYSPRO-ERRTRK$"
        "SYSPRO-STRIPSER$"
        "WEBMASTER$"
        "SYSPRO-MONITOR$"
        "CT-LAPTOP$"
        "SYSPRO-PRINT$"
        "DBNOPS$"
        "SYSPRO-SASSERV$"
        "VIRTUAL-TBED$"
        "SYSPRO-BUILD$"
        "RUSSROBOHELP$"
        "SYSPRO-ABSALOM$"
        "SYSPRO-DSSFS$"
        "SYSPRO-EXCHANGE$"
        "SYSPRO-WEBSENSE$"
        "AQSERVER2003$"
        "SHAREPOINT2010$"
        "WEBSENSE$"
        "SYSPROCMS$"
        "TRISH-FAX$"
        "WEBDEV-WINR2$"
        "CERTIFICATION$"
        "SYSPRO-ODC$"
        "AQANALYTICSSQL2$"
        "AQ-SQL2005$"
        "FINSQL$"
        "MANSQL$"
        "DISTSQL$"
        "SASSTEIN$"
        "NERISHA$"
        "SASREPORT$"
        "KERRYSC$"
        "JACKIMAC-PC$"
        "RUSSXP-VM$"
        "SARAHFUT$"
        "EVENODCTEST$"
        "DEVSERVWIN2003$"
        "WEBMONITOR$"
        "SHAREPOINT$"
        "AUDITORIOUM$"
        "VM-WIN8X64CP$"
        "DEBBY-TFS2010$"
        "SYSPRO-DPM2012$"
        "SASHOTLINE$"
        "SYSPRO-PROFSERV$"
        "INFOZONE$"
        "SYSJHBSYSCENTRE$"
        "PROXYTEST$"
        "SEANPOS$"
        "TRAININGPOC$"
        "SYSPRO-FTP$"
        "SYSPRO-FTPDEV$"
        "SYSPRO-FTPSVR$"
        "SYSPRO-WEBDEV$"
        "SYSPRO-WWWSVR$"
        "DEVT2$"
        "DEVTEST2$"
        "CORPTRAIN1$"
        "CORPTRAIN2$"
        "CORPTRAIN4$"
        "CORPTRAIN5$"
        "CORPTRAIN6$"
        "CORPTRAIN3$"
        "VM-SM2012MS$"
        "SYSJHBSMAN-DW$"
        "GENTRAIN12$"
        "GENTRAIN7$"
        "AUDIT-TEMP$"
        "WINDOWS2012RC$"
        "GENTRAIN14$"
        "VMDEBBYSQL2005$"
        "WIN7_X64$"
        "DEBBYSVR2008$"
        "VM-DPMWIN2012$"
        "SYSJHBDEV$"
        "SYSPROHVPROXY$"
        "SYSJHBVMM2012$"
        "SYSPROHV1$"
        "SYSPROHV2$"
        "JHBCLIENTTEMP$"
        "PHILSTABLET$"
        "SYSCTSTORE$"
        "PRESENT1$"
        "SYSJHBVTRS$"
        "LYNMUSKE$"
        "WINSLATE2$"
        "LORRAINE$"
        "WOUTERC$"
        "SYSDBNSTORE$"
        "JUDYJOHN$"
        "SANETVI$"
        "SELMAPRE$"
        "LORNALYTE$"
        "KARINPRE$"
        "KIRSTYVI$"
        "ROBERTZ$"
        "MARKSHE$"
        "ERICDIA$"
        "MPHOSEBI$"
        "MERYL$"
        "ASHWEET$"
        "LESLEY$"
        "STEFANOLI$"
        "ZAAKHIRB$"
        "CHARMAIND$"
        "MENWILG$"
        "JUDITHS$"
        "GENTRAIN11$"
        "CD-BURNER$"
        "SUEELSW$"
        "DSWIN2000$"
        "SYSPABX$"
        "SYSPRO-DEVELOP$"
        "MARYANNV$"
        "PAULH$"
        "CAROLED$"
        "NATASHAWA$"
        "MONIQUEM$"
        "SASHAVER$"
        "GENTRAIN2$"
        "GENTRAIN6$"
        "GENTRAIN8$"
        "GENTRAIN1$"
        "TEMPRECEPTION$"
        "CORPTRAIN7$"
        "CORPTRAIN8$"
        "ROBVS2012$"
        "HELGAGELD$"
        "LEAERAS$"
        "KEVIND$"
        "CORNELIAW$"
        "EVENNES$"
        "ROXYLIA$"
        "MARYGIT$"
        "TIFFANYG$"
        "NERISHAR$"
        "SHENAISU$"
        "LESLEYT$"
        "OMPHEME$"
        "DAMIANAL$"
        "GENTRAIN3$"
        "GENTRAIN5$"
        "GENTRAIN4$"
        "PRAVIRR$"
        "CHRISVOGT$"
        "LEIGHANNE$"
        "SYSPROSCREENS$"
        "SYSPRO-DSFS$"
        "SYSPROWIN2008$"
        "BIANCAB$"
        "NICOLEBR$"
        "DENISEDE$"
        "NEILHAYE$"
        "JUDYCAM$"
        "NATALIEJO$"
        "CHARLES$"
        "ESTELLEPO$"
        "LOUISET$"
        "ANNEMOR$"
        "TREVORW$"
        "syspros_imac$"
        "GENTRAIN9$"
        "GENTRAIN10$"
        "NATALIELE$"
        "KIRSTENL$"
        "LINDASA$"
        "KEVIN-SLATE$"
        "KILLIANS$"
        "LORENZO$"
        "MARIEKIEC$"
        "BEATRICEEN$"
        "RUSSTABLET$"
        "RUSSELL$"
        "SHELLEY$"
        "SYSJHBSP$"
        "VM-POSPARENT$"
        "VMPOSREMOTE3$"
        "SYSJHBSQLSP$"
        "GENTRAIN13$"
        "SYSJHBVMM$"
        "SYSPROWIN2012$"
        "XPROBO$"
        "DUPPIEDU$"
        "SAMSUNGTAB1$"
        "VM-GENTRAIN1$"
        "VM-GENTRAIN2$"
        "VM-GENTRAIN3$"
        "VM-GENTRAIN9$"
        "VM-GENTRAIN10$"
        "VM-GENTRAIN11$"
        "VM-GENTRAIN12$"
        "XPTEST$"
        "GENTRAIN16$"
        "TRAINING7$"
        "SANTAPIL$"
        "SYSPROTRAIN-PC$"
        "PROFSERVPC$"
        "SYSPRO-E6E74260$"
        "PS-POS$"
        "SYSCTPS$"
        "TECHHVTEST$"
        "SYSJHBOPSMGR$"
        "MARIALAM$"
        "SCREENDUMP-PC$"
        "CHARMAINEPA$"
        "ADMINADMIN$"
        "CLAREFOR$"
        "RACHELVA$"
        "SYSJHBSERVMAN$"
        "NEILTESTWIN8$"
        "DEWALDBR$"
        "VMCLUSTER$"
        "SYSVMCLUSTER$"
        "VM-GENTRAIN16$"
        "VM-GENTRAIN15$"
        "TABISANB$"
        "VM-GENTRAIN14$"
        "VM-GENTRAIN13$"
        "VM-CORPTRAINER$"
        "ADMIN-PC1$"
        "JETI$"
        "VM-GENTRAIN5$"
        "VM-GENTRAIN6$"
        "VM-GENTRAIN7$"
        "VM-GENTRAIN8$"
        "VM-GENTRAINER$"
        "SYSJHBACC$"
        "SYSPROCMSOLD$"
        "KHOTSOSH$"
        "RICHARD$"
        "SYSCOREDEV$"
        "JACQUENB$"
        "SYSJHBHVTR$"
        "TRISHY2008R2$"
        "TRISHYWINDOWS8$"
        "SYSCOREAIO$"
        "VM-GENTRAIN4$"
        "SYSJHBOWA$"
        "MANDYHARW$"
        "SYS7SOI2010$"
        "SYS7SOI2007$"
        "SYSJHBTESTDEV$"
        "USER-PC$"
        "SCREENSTRAINING$"
        "SYSJHBSTORE$"
        "BISQL2008R2$"
        "ATTTESTINSTALL$"
        "TYRONEJA$"
        "NKOSINNB$"
        "SYSJHBFTP$"
        "HERMANUSS$"
        "HRTEMP$"
        "GRANTF$"
        "HEINRICH$"
        "sysjhbcentos$"
        "LESHECCL$"
        "GARETTMU$"
        "LEERIDLE$"
        "ELIASSIT$"
        "AMOSMOYO$"
        "CANDYCET$"
        "RECEPTI1$"
        "RECEPTI2$"
        "GERTIEWO$"
        "ANNETTEP$"
        "PATMCEVI$"
        "SUESCHEE$"
        "ALICIASM$"
        "RENIERWA$"
        "PAULBORT$"
        "FATIMADA$"
        "TAMARINE$"
        "PRANEETA$"
        "SHELLEYB$"
        "TANNERGR$"
        "ROLANDOCA$"
        "INGRIDAU$"
        "DANIELSH$"
        "URSULAST$"
        "MOHAMMED$"
        "SYSJHBMFP$"
        "ZAYDMAHI$"
        "NIKKIMAL$"
        "LORNADUP$"
        "GARYDEOL$"
        "MARLISED$"
        "KATHYHAR$"
        "VMLEEWIN7$"
        "TOMGRIND$"
        "JONTHORN$"
        "SERVER2012R2TS$"
        "SYSJHBFS$"
        "USER1$"
        "SYSJHBMAIL$"
        "SYS7SVR2008R2$"
        "SYSPRO7WIN7$"
        "SYSCTDC$"
        "SVR2008SQL2012$"
        "PAULODE$"
        "CAROLINE$"
        "HR-PC$"
        "SYSJHBPRINT$"
        "CAROLINESHAREP$"
        "SYSJHBTESTHV$"
        "SYSPRO7SVR12$"
        "DEVROOM2$"
        "SYSJHBDS2012R2$"
        "ZARENRAM$"
        "TRISHFOW$"
        "SYSJHBHV1$"
        "sysjhbcluster$"
        "SYSJHBHV2$"
        "WINTEST8$"
        "AUDITORS$"
        "NETEXPRESSBUILD$"
        "SYSJHBHV3$"
        "SYSDBNDC$"
        "KEVINSURFACE$"
        "VM-GRANT-7-PRIN$"
        "SYSJHBERRTRK$"
        "RUSSSURFACEPRO2$"
        "HRTEMP1-PC$"
        "garys-imac$"
        "SYSTEMTEST$"
        "HELLSURFACEPRO2$"
        "SYSPRO7WIN8$"
        "SYSJHBLYNC$"
        "LEIGHHAL$"
        "VM-SYS7TRAIN1$"
        "VM-SYS7TRAIN2$"
        "VM-SYS7TRAIN4$"
        "VM-SYS7TRAIN3$"
        "VM-SYS7TRAIN5$"
        "VM-SYS7TRAIN6$"
        "VM-SYS7TRAIN8$"
        "VM-SYS7TRAIN7$"
        "VM-SYS7TRAIN9$"
        "TRAINTEMPL$"
        "VM-SYS7TRAIN11$"
        "VM-SYS7TRAIN13$"
        "VM-SYS7TRAIN12$"
        "VM-SYS7TRAIN14$"
        "VM-SYS7TRAIN15$"
        "VM-SYS7TRAINER$"
        "VM-SYS7TRAIN16$"
        "CHRISTEL$"
        "VM-SYSTEMSQL$"
        "DEVSERVERRC7$"
        "LESLEYJA$"
        "JACOMARI$"
        "KARENLOO$"
        "KCCPROJECT$"
        "KEVINDHE$"
        "RICHARDM$"
        "TECH$"
        "SYS-SS-POSSRV$"
        "SYS-SS-POSBR$"
        "THABOTLE$"
        "QUINTINB$"
        "JACQUESM$"
        "CHARMAIN$"
        "AMYRITSO$"
        "PETRAVAN$"
        "CRAIGCAMB$"
        "SYSJHBHV4$"
        "SABINEBE$"
        "TYRONST$"
        "HEINRICHK$"
        "ERICDIAL$"
        "ANGIEMA$"
        "ESSIEJAN$"
        "ROBERTB$"
        "BIANCAHA$"
        "MONIQEVI$"
        "SYS-SS-POS7S$"
        "SYSJHBCRM$"
        "DEVROOM3-PC$"
        "THIERRYV$"
        "MONICAPR$"
        "ROSHNIN$"
        "SYSJHBHVTR2$"
        "DEIRDREF$"
        "LENAMAR$"
        "TRACYROB$"
        "VIVIENNE$"
        "JOHANM$"
        "SYSLYNCTEST2013$"
        "SYSLYNCTEST2010$"
        "JAMESBLA$"
        "JENOLAED$"
        "VMPOSIE10$"
        "VMPOSIE11$"
        "CLAYTOND$"
        "ANDREKES$"
        "SYSJHBCERT$"
        "SYS-SS-POS6S$"
        "PSCALLDESKTEMP$"
        "LYNCTEST$"
        "JASONBAX$"
        "CAUCLUSTER$"
        "AQM$"
        "POSONLINEVM$"
        "POSOFFLINEVM$"
        "SYSJHBSP2$"
        "JASONSPNB$"
        "VMPOSIE13$"
        "VMPOSIE12$"
        "AMARODEA$"
        "PETERRES$"
        "WINDOWS81$"
        "RENEEVAN$"
        "DOCMAC$"
        "POS6CL$"
        "POS6SVR$"
        "POS7C$"
        "POS7SVR$"
        "LOUISEBU$"
        "ZANELESE$"
        "POSTESTSERVER$"
        "VM-STHESP2013$"
        "SYSJHBWA$"
        "ONPOS7$"
        "OFFPOS7$"
        "SYSJHBDEVAUTO$"
        "PATMCE$"
        "VM2013SERVER$"
        "SYSJHBDPM$"
        "GARYDEOLPAR$"
        "EDWARDME$"
        "CAROLHAR$"
        "LEATITIAC$"
        "SYSJHBWEBGEN$"
        "PREACTOREXPRESS$"
        "RENIERNB$"
        "KABELOMA$"
        "SASTESTNEW$"
        "BENITARA$"
        "DANIEDUP$"
        "ROBVS201$"
        "SYSJHBPROXY$"
        "JANINEDP$"
        "ESSIEVAN$"
        "SYSETECHBUILD$"
        "DEVROOM2PC$"
        "HERMANBO$"
        "SIBONGILE$"
        "DEVROOM1$"
        "DUANEVAN$"
        "GLORIALO$"
        "ENGCHINETEST1$"
        "KEVINHP$"
        "DUANEVANC$"
        "TRACEYMO$"
        "ROSSBATE$"
        "HENDRIE$"
        "JUSTIN$"
        "DAVIDVANR$"
        "KIMVANDE$"
        "PSOFFLINE1$"
        "PSONLINE1$"
        "KEVINSURFACE2$"
        "DEVROOM3$"
        "BELINDAC$"
        "LEATITIA-SERVER$"
        "NATASHAB$"
        "VM-INGRIDWIN10$"
        "HEINRICHT$"
        "ERASMUSD$"
        "SYSJHBTESTHV2$"
        "VMMITHALCLIENT$"
        "RECOVERY-PC$"
        "SIBONGIE$"
        "SYSJHBSQLSS$"
        "IRENESN$"
        "CAMOREN$"
        "LYNCUPDATE$"
        "SASPOSTEST$"
        "SASPOSOFFLINE$"
        "ERRTRKSERVER$"
        "ERRTRKCLIENT$"
        "SASPOOL$"
        "SYSJHBLYNCEDGE$"
        "SYSJHBDW$"
        "ZAAHIDAR$"
        "INGRIDCHINESE$"
        "VIKISUEN$"
        "SYSJHBPROFSERV$"
        "ISHMAEL$"
        "JPVANLO$"
        "DSSCREEN$"
        "HEINRICK$"
        "DSSCREENS$"
        "SYSJHBSPUAT$"
        "CARONHEW$"
        "SYSSP2016RTM$"
        "THANEFOR$"
        "VM-POS7TRAIN1$"
        "VM-POS7TRAIN2$"
        "VM-POS7TRAIN3$"
        "VM-POS7TRAIN4$"
        "VM-POS7TRAIN5$"
        "VM-POS7TRAIN10$"
        "VM-POS7TRAIN9$"
        "VM-POS7TRAIN6$"
        "VM-POS7TRAIN7$"
        "VM-POS7TRAIN8$"
        "XPS13$"
        "NATASHAM$"
        "SYSJHBSPDZ$"
        "DEBBY$"
        "MARONMAS$"
        "CORNELIA$"
        "LOUISE$"
        "JOSHUATR$"
        "KIMFO$"
        "DENISED$"
        "NEILHAY$"
        "ZAINAJAM$"
        "GOODFELLOWS$"
        "TRACYROBBTEMP$"
        "ANDILES$"
        "DEBBYSVR2012$"
        "PHIKSWINDOWS$"
        "SYSJHBSMPORTAL$"
        "TANYABOT$"
        "TEBOGOMO$"
        "JOSHUAT$"
        "KELLYFAR$"
        "DEANBUNC$"
        "ANDILESAS$"
        "THABOT$"
        "SYSJHBLYNCPICKU$"
        "SYSJHBLYNCAPP$"
        "TSPC3$"
        "ROBWIN10$"
        "TSPC6$"
        "TSPC7$"
        "INTERNPC4$"
        "SIPHILEM$"
        "ISHMAELM$"
        "TSPC8$"
        "VM-SHANETESTING$"
        "TSPC4$"
        "TSPC1$"
        "INTERNPC1$"
        "INTERNPC2$"
        "INTERNPC3$"
        "JULIETRU$"
        "ALYSSAWH$"
        "INTERNPC5$"
        "INTERNPC6$"
        "INTERNPC7$"
        "INTERNPC8$"
        "INTERNPC10$"
        "INTERNPC9$"
        "INTERNPC12$"
        "INTERNPC11$"
        "DEVROOM4-PC$"
        "STEPHVM$"
        "SYSJHBAVE$"
        "INFOZONEDEVNEW$"
        "BIANCAH$"
        "TSPC$"
        "SYSJHBWEBDEVDB$"
        "SERVER2016$"
        "POS7MAINSVR$"
        "POS7MAINC$"
        "ANGIEPOSONLINE$"
        "ANGIEPOSOFFLINE$"
        "ACCOUNTSTEMP$"
        "PATRICKW$"
        "EDWARDKE$"
        "JASONLAP$"
        "DAVIDAMB$"
        "FERDINAN$"
        "KENYA5$"
        "KERRYSCOT$"
        "SS-SHANESVRSIDE$"
        "KEVINDH$"
        "LOURENSK$"
        "DEANRAEM$"
        "ANTONIO$"
        "DEVROOM4$"
        "WALTERVM$"
        "MITHALTEMP$"
        "ANDILEPOS$"
        "shingi-mac$"
        "ARABANGR$"
        "SHERLEYM$"
        "LOANTECH$"
        "MARYANNTEMP$"
        "PAULBOR$"
        "SANDRAFR$"
        "TESTM$"
        "TRAINING1$"
        "TRAINING10$"
        "TRAINING9$"
        "TRAINING12$"
        "TRAINING11$"
        "RECEPTIONSP$"
        "TRAINING8$"
        "TRAINING5$"
        "TRAINING4$"
        "TRAINING3$"
        "TRAINING6$"
        "TRAINING28$"
        "TRAINING21$"
        "TRAINING25$"
        "TRAINING22$"
        "TRAINING14$"
        "TRAINING19$"
        "TRAINING20$"
        "TRAINING18$"
        "TRAINING17$"
        "TRAINING27$"
        "TRAINING15$"
        "TRAINING24$"
        "PIETERVA$"
        "TRAINING23$"
        "TRAINING26$"
        "PIETERVH$"
        "SHALININ$"
        "TRAINING2$"
        "SYSJHBTFSDEV$"
        "SYSJHBSPDEV$"
        "ROSSVM$"
        "SYSJHBVIP$"
        "ROXANNEG$"
        "DFRYERSQLBOX$"
        "ASHLEYPI$"
        "LEVIOUSD$"
        "PSCALLDESKCORI$"
        "MITWINOFF$"
        "SELMASE$"
        "TANNERG$"
        "WALTERNB$"
        "VM32BIT$"
        "SHAREPOINTTEMP2$"
        "SHAREPOINTTEMP1$"
        "NEILWIN10DEBUG$"
        "TRAINING13$"
        "TRAINING16$"
        "DAVIDTHO$"
        "PHIL$"
        "IVANINOUTBOARD$"
        "THOLAKEL$"
        "IVANINOUT$"
        "JINOMAKA$"
        "SYSJHBHVTR3$"
        "GENEVIEV$"
        "SYSJHBPROPHIX$"
        "SYSJHBSP16DEV$"
        "ANDIEWIN10$"
        "WYNANDMA$"
        "SIBONGIL$"
        "ZARENRA$"
        "VUSITESTENV1$"
        "LEATITIASVR$"
        "VM-SYS7TRAIN17$"
        "VM-SYS7TRAIN18$"
        "VM-SYS7TRAIN19$"
        "VM-SYS7TRAIN20$"
        "VM-SYS7TRAIN21$"
        "VM-SYS7TRAIN22$"
        "VM-SYS7TRAIN23$"
        "VM-SYS7TRAIN24$"
        "VM-SYS7TRAIN25$"
        "VM-SYS7TRAIN26$"
        "VM-SYS7TRAIN27$"
        "VM-SYS7TRAIN28$"
        "ANTHONYW$"
        "IANLAWLE$"
        "VUYANEMT$"
        "TONIJOUB$"
        "SARAHFU$"
        "MITHAL$"
        "SANJAYG$"
        "SHANEM$"
        "PRAVIR$"
        "ESTELLEP$"
        "ROBINVAN$"
        "RENIERN$"
        "SYSJHBSSS$"
        "APIWEHOY$"
        "VUSIWIN12$"
        "CYNTHIAG$"
        "SYSJHBCA1$"
        "SYSJHBCA2$"
        "TRAINING29$"
        "TRAINING30$"
        "EVENNE$"
        "WORKSTATION$"
        "LEATITIA$"
        "LEATITIAOLD$"
        "SHARONMK$"
        "SYSJHBDISPS$"
        "MARYANN$"
        "LORRAIN$"
        "SYSPRDDCINFRA1$"
        "local-pixs-imac$"
        "TSPC2$"
        "TRACYRO$"
        "DOUGHUNT$"
        "CYLMASPA$"
        "TSPC11$"
        "SYSPRDSQLDB01$"
        "SYSPRDSP01$"
        "DEBBYDIE$"
        "CHRISSQL2005$"
        "ODETTEBE$"
        "HELENHOL$"
        "DEPLOYT$"
        "TIFFANY$"
        "SYSJHBATA$"
        "KABELOKE$"
        "DOLPHPRE$"
        "SYSJHBSCDB01$"
        "SYSJHBSCSM01$"
        "SYSJHBSCSP01$"
        "THABOMOF$"
        "THEMBIMO$"
        "WIN-DP6Q9GU3K7S$"
        "TESTDC2$"
        "SYSKITCHTEN$"
        "BRENDAN$"
        "PETERRE$"
    )
    $DistinguishedName = @(
        "OU=Domain Controllers,DC=sysproza,DC=net"
        "OU=Domain Controllers,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Cape Town,DC=sysproza,DC=net"
        "OU=Servers,OU=Durban,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Test Machines,OU=Computers,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Test Machines,OU=Computers,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=E-Mail Groups,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Cape Town,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Durban,DC=sysproza,DC=net"
        "OU=Computers,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers - Forefront,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Development,OU=Cape Town,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers - Forefront,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
        "OU=Computers,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Test Machines,OU=Computers,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers - Forefront,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
        "OU=Computers,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development,OU=Cape Town,DC=sysproza,DC=net"
        "OU=Computers,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Workstations,OU=Computers,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Workstations,OU=Computers,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Domain Controllers,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Domain Controllers,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Workstations,OU=Computers,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Workstations,OU=Computers,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development,OU=Cape Town,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Workstations,OU=Computers,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Workstations,OU=Computers,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Interns,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Interns,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Interns,DC=sysproza,DC=net"
        "OU=Computers,OU=Interns,DC=sysproza,DC=net"
        "OU=Computers,OU=Interns,DC=sysproza,DC=net"
        "OU=Computers,OU=Interns,DC=sysproza,DC=net"
        "OU=Computers,OU=Interns,DC=sysproza,DC=net"
        "OU=Computers,OU=Interns,DC=sysproza,DC=net"
        "OU=Computers,OU=Interns,DC=sysproza,DC=net"
        "OU=Computers,OU=Interns,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Workstations,OU=Computers,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Disabled Accounts,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers - Forefront,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
        "OU=Computers - Forefront,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
        "OU=Computers,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Training Rooms,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Domain Controllers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Workstations,OU=Computers,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Servers,OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Workstations,OU=Computers,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
        "OU=Computers,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
        "OU=Computers,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
        "CN=Computers,DC=sysproza,DC=net"
)

    Clear-Host
    $ADCount = $ComputerName.Count

    For ($i = 0; $i -lt $ADCount; $i ++) {
        Write-Host (($i + 1).ToString() + "\$ADCount - Creating " + $ComputerName[$i] + " - ") -NoNewline
        Try {
            New-ADComputer -SamAccountName $SAMAccountName[$i] -Name $ComputerName[$i] -Path $DistinguishedName[$i] -ErrorAction SilentlyContinue
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch {
            Write-Host "Failed" -ForegroundColor Red -NoNewline
            Write-Host (" - " + $_)
        }
    }
}
Function Create-OU {
    $OUNames = @(
    "Microsoft Exchange Security Groups"
    "Domain Controllers"
    "Johannesburg"
    "Technical Services"
    "Computers"
    "Servers"
    "Recipients"
    "Users"
    "Technical Development"
    "UsersOld"
    "Development - Services"
    "Users"
    "Syspro Africa Support"
    "UsersOld"
    "Development - Manufacturing"
    "UsersOld"
    "Knowledge Transfer"
    "UsersOld"
    "Cape Town"
    "Marketing"
    "Users-FS"
    "Development"
    "Users"
    "Corporate Services"
    "UsersOld"
    "Usersold"
    "Web Development"
    "UsersOld"
    "Marketing"
    "Development - Distribution"
    "Development - Financial"
    "Technical Writing"
    "Printers & Scanners"
    "Distributor Support"
    "UsersOld"
    "Human Resources"
    "UsersOld"
    "Computers"
    "Computers"
    "Development - Core"
    "UsersOld"
    "Printers & Scanners"
    "Printers & Scanners"
    "Administration"
    "Printers & Scanners"
    "Printers & Scanners"
    "Printers & Scanners"
    "Printers & Scanners"
    "Printers & Scanners"
    "Printers & Scanners"
    "Printers & Scanners"
    "Printers & Scanners"
    "Printers & Scanners"
    "Printers & Scanners"
    "Printers & Scanners"
    "Professional Services"
    "Printers & Scanners"
    "Nursery Distributors"
    "Other African Distributors"
    "Other Associates"
    "Territory Distributors"
    "Durban"
    "Training Room"
    "Users"
    "South African Distributors"
    "Workstations"
    "Servers"
    "Accounts Addresses"
    "Independant Distributors"
    "Printers & Scanners"
    "Professional Services"
    "Development - Distribution"
    "Printers & Scanners"
    "Printers & Scanners"
    "Servers"
    "Printers & Scanners"
    "Marketing"
    "Printers & Scanners"
    "Servers"
    "Development - e.net Solutions"
    "Printers & Scanners"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "E-Mail Groups"
    "UsersOld"
    "UsersOld"
    "UsersOld"
    "E-Mail Groups"
    "E-Mail Groups"
    "Printers & Scanners"
    "E-Mail Groups"
    "External Users"
    "Computers"
    "UsersOld"
    "Computers"
    "Workstations"
    "Servers"
    "Computers"
    "Servers"
    "Computers"
    "UsersOld"
    "Computers"
    "Computers"
    "Canada Resellers"
    "USA Resellers"
    "Worcester"
    "Africa Resellers"
    "Computers"
    "UsersOld"
    "Computers"
    "Computers"
    "Computers"
    "Computers"
    "Users"
    "Users"
    "Computers"
    "Users - Use this OU"
    "Computers"
    "Syspro Touch Points"
    "SA"
    "USA"
    "CAN"
    "AUS"
    "UK"
    "Mail Groups"
    "General Users"
    "Computers"
    "Test Machines"
    "Internet Groups"
    "Computers"
    "Contacts"
    "Users0old"
    "Computers"
    "Computers"
    "Users"
    "Computers"
    "Computers"
    "Computers"
    "Workstations"
    "Users - \"My Docs\" re-direct"
    "Internet Guests - full internet access"
    "Computers - Forefront"
    "International Lync Users"
    "Computers"
    "Development - Supply Chain"
    "Sharepoint 2010 Contacts"
    "Sharepoint 2010 Contacts"
    "Users"
    "Users"
    "Users"
    "Training Rooms"
    "Users"
    "Users"
    "Users"
    "Users"
    "Users"
    "Users"
    "Users"
    "Users"
    "Users"
    "Users"
    "Users"
    "Users"
    "Users"
    "Users"
    "DKM"
    "External Users"
    "Development - Emerging Technologies"
    "E-mail Groups"
    "RTC Special Accounts"
    "Users"
    "Computers"
    "Temp SharePoint Users"
    "Users-FS"
    "Users-FS"
    "Users-FS"
    "Users-FS"
    "Users-FS"
    "Users-FS"
    "Users-FS"
    "Users-FS"
    "Users-FS"
    "Users-FS"
    "Users-FS"
    "Users-FS"
    "Users-FS"
    "Users-FS"
    "Users-FS"
    "Users-FS"
    "Users-FS"
    "Users-FS"
    "Users-FS"
    "Disabled Accounts"
    "Users"
    "Computers"
    "Testers"
    "Developers"
    "Contractors"
    "Contacts"
    "Users-FS"
    "CRM"
    "Professional Services"
    "Computers"
    "E-Mail Groups"
    "Users-FS"
    "Web Development"
    "Computers"
    "E-Mail Groups"
    "Users-FS"
    "Users"
    "Intern Users"
    "Intern Computers"
    "Active Sync Test"
    "Development - Emerging Technologies"
    "Computers"
    "E-Mail Groups"
    "Users-FS"
    "Testers"
    "Developers"
    "UsersTest"
    "Admin Accounts"
    "Meeting Rooms"
    "Azure"
    "Territory Office Users"
    "Azure Users"
    "Users"
    "Computers"
    "Security Groups"
    "Azure Groups"
    "Interns"
    "Sharepoint Service Accounts"
    "Computers"
    "Service Account"
    "SYSPRO Azure"
    "EA Accounts"
    "Consultants"
    "Exclude"
    )
    $OUPath = @(
    "DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Cape Town,DC=sysproza,DC=net"
    "OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Cape Town,DC=sysproza,DC=net"
    "OU=Development,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Durban,DC=sysproza,DC=net"
    "OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "OU=Computers,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net "
    "DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Durban,DC=sysproza,DC=net"
    "OU=Durban,DC=sysproza,DC=net"
    "OU=Development,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Cape Town,DC=sysproza,DC=net"
    "OU=Development - Distribution,OU=Durban,DC=sysproza,DC=net"
    "OU=Durban,DC=sysproza,DC=net"
    "OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "OU=Durban,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - e.net Solutions,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - e.net Solutions,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Development - Distribution,OU=Durban,DC=sysproza,DC=net"
    "OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "OU=Professional Services,OU=Durban,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - e.net Solutions,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Cape Town,DC=sysproza,DC=net"
    "OU=Durban,DC=sysproza,DC=net"
    "OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Computers,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net   "
    "OU=Computers,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net "
    "OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Computers,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Distribution,OU=Durban,DC=sysproza,DC=net"
    "OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Computers,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net  "
    "OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "OU=Development - Distribution,OU=Durban,DC=sysproza,DC=net"
    "OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - e.net Solutions,OU=Johannesburg,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Computers,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Computers,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Professional Services,OU=Durban,DC=sysproza,DC=net"
    "OU=Professional Services,OU=Durban,DC=sysproza,DC=net"
    "OU=Development,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Computers,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - e.net Solutions,OU=Johannesburg,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Supply Chain,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - e.net Solutions,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - e.net Solutions,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Supply Chain,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Computers,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net   "
    "OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Development,OU=Cape Town,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Cape Town,DC=sysproza,DC=net"
    "OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Cape Town,DC=sysproza,DC=net"
    "OU=Web Development,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Web Development,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Web Development,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Cape Town,DC=sysproza,DC=net"
    "OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Azure,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net   "
    "OU=Azure,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Azure,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net "
    "DC=sysproza,DC=net"
    "OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Johannesburg,DC=sysproza,DC=net"
    "OU=SYSPRO Azure,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    )

    Clear-Host
    $Counter = 0
    $ADCount = $OUNames.Count

    For ($i = 0; $i -lt $ADCount; $i ++) {
        Write-Host "Processing $i/$ADCount - " -NoNewline
        Try {
            New-ADOrganizationalUnit -Name $OUNames[$i] -Path $OUPath[$i] -ErrorAction SilentlyContinue
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch { 
            Write-Host "Failed" -ForegroundColor Red
            Write-Host (" - " + $_)
        }
    }
}
Function Create-User {
    $SAMAccount = @(
    "Ned"
    "Ned-2"
    "IWAM_SYSPRO-DC3JHB"
    "IUSR_SYSPRO-DC3JHB"
    "IWAM_SYSPRO-DC1CT"
    "IUSR_SYSPRO-DC1CT"
    "IWAM_SYSPRO-DC1DBN"
    "IUSR_SYSPRO-DC1DBN"
    "IUSR_SYSPRO-MASTER"
    "IUSR_XBOX2950"
    "IUSR_SYSPRO-DCCT"
    "IUSR_SYSPRO-DCDBN"
    "TsInternetUser"
    "IUSR_SYSPRO-CTDC"
    "HeinrichV"
    "paul"
    "impsrc10"
    "impsrc31"
    "Lesley"
    "Linda"
    "Kerry"
    "Peter"
    "Candyce"
    "Leigh"
    "Kirsty"
    "TESTBED$"
    "SMSService"
    "SCE"
    "Grant"
    "Mullet"
    "webmaster"
    "ArrayUser"
    "krbtgt"
    "SysproDPM"
    "backup10"
    "backup31"
    "Jhb"
    "IUSR_SYSPRO-WEBDEV1"
    "IWAM_SYSPRO-WEBDEV1"
    "IUSR_SYSPRO-TECH1"
    "IUSR_SYSPRO-TECHNT1"
    "IWAM_SYSPRO-TECHNT1"
    "WEBDOMAIN$"
    "NTPORTING"
    "ntdatasvr"
    "base"
    "IWAM_SYSPRO-TECH1"
    "LDAP_ANONYMOUS"
    "Printer"
    "impsrc51"
    "testt"
    "Karin"
    "pauline"
    "Jacqui"
    "Phil"
    "RUSS"
    "impsrc50"
    "Train4"
    "Train5"
    "Train6"
    "Train7"
    "Train8"
    "Train9"
    "Train10"
    "impsrc60"
    "CDR"
    "Supportmail"
    "SMSServer_SYS"
    "SMSClient_SYS"
    "Train2"
    "test2"
    "test3"
    "SMSServer_JHB"
    "SMSClient_JHB"
    "RPRINTER"
    "SUPPORT_388945a0"
    "louise"
    "meryl"
    "Rodney"
    "Neil"
    "Richard"
    "IWAM_SYSPRO-MASTER"
    "Proact"
    "Impafr"
    "Elizabeth"
    "Train3"
    "Test"
    "Test Bed"
    "term"
    "Roshni"
    "SharePoint"
    "test1"
    "Heinrich"
    "Andre"
    "Ingrid"
    "IWAM_SYSPRO-DCCT"
    "Sanet"
    "Maryann"
    "Ria"
    "Nerisha"
    "TrainingHR"
    "MargaretK"
    "GuestHR"
    "Cynthia"
    "CrystalServer"
    "anne"
    "NatalieL"
    "train1"
    "Natalie"
    "kirsten"
    "Kevin"
    "Mandy"
    "momcinstall"
    "SYSPROCTNumber"
    "SYSPRODBNNumber"
    "ShareHelp"
    "momdasql"
    "Offmanagementsa"
    "Accmanagementsa"
    "Custrelationssa"
    "finaccountssa"
    "Gloaccountssa"
    "Humresourcessa"
    "Marketingsa"
    "Pricingsa"
    "prosupportsa"
    "proservicessa"
    "salessatp"
    "techservicessa"
    "vertmarketssa"
    "accmanagementcan"
    "cusrealtionscan"
    "finaccountingcan"
    "gloaccountscan"
    "humresourcescan"
    "marketingcan"
    "offmanagementcan"
    "pricingcan"
    "proservicescan"
    "salescan"
    "vertmarketscan"
    "custrelationaaus"
    "finaccountingaus"
    "gloaccountsaus"
    "humresourcesaus"
    "marketingaus"
    "offmanagementaus"
    "pricingaus"
    "prosupportaus"
    "proservicesaus"
    "traintrabsferaus"
    "humresourcesuk"
    "offmanagementuk"
    "finaccountingusa"
    "gloaccountsusa"
    "humresourcesusa"
    "Marketingusa"
    "offmanagementusa"
    "Pricingusa"
    "prosupportusa"
    "techservicesusa"
    "traintransferusa"
    "vertmarketsusa"
    "SAS Help Desk"
    "Judith"
    "Duppie"
    "IWAM_SYSPRO-DCDBN"
    "dssql"
    "Phil1"
    "remotetest"
    "Sysprotest"
    "admindb"
    "Africa"
    "APS"
    "impactoutdoors"
    "biztalk2"
    "CapeTown"
    "Cornelia"
    "santa"
    "Helen.Hollick"
    "Carol"
    "Benita"
    "DFM"
    "Documentation"
    "Even"
    "Tiffany"
    "dsevents"
    "DSHOTLINE"
    "DSTesters"
    "Durban"
    "DurbanOffice"
    "Eval"
    "HR-Applications"
    "InfoCT"
    "Infodbn"
    "lorna"
    "Carole"
    "DAMIANA"
    "Pat"
    "meet1"
    "Minolta"
    "Peace.Mayaphi"
    "Philtest"
    "Leshec"
    "Lori"
    "richard1"
    "richard2"
    "Spam"
    "sysprobd"
    "Monique"
    "winfax"
    "Word"
    "Developmail"
    "traintransfersa"
    "prosupportcan"
    "techservicescan"
    "traintransfercan"
    "Temp"
    "Tyron"
    "Helga"
    "accmanagementaus"
    "salesaus"
    "techservicesaus"
    "vertmarketsaus"
    "Vista"
    "UKWeb"
    "SAWeb"
    "CANWeb"
    "USAWeb"
    "IWAM_SYSPRO-CTDC"
    "syspropub"
    "Leave"
    "Performance"
    "Night Line"
    "nedbank"
    "Meeting2"
    "Meeting1"
    "Kitchen-Mktg"
    "KitchenU"
    "kitchen"
    "Dining2"
    "Dining1"
    "Birthdays"
    "AbsalomESS"
    "PhilC"
    "CMS"
    "Standards"
    "Marianne"
    "Natasha"
    "Charles"
    "DebbieJ"
    "deloitte"
    "accmanagementuk"
    "custrelationsuk"
    "finaccountinguk"
    "gloaccountsuk"
    "Marketinguk"
    "Pricinguk"
    "prosupportuk"
    "proservicesuk"
    "salesuk"
    "techservicesuk"
    "traintransferuk"
    "vertmarketsuk"
    "sysprofax"
    "Commissions"
    "ALF"
    "Lorraine"
    "Trish"
    "adminsql"
    "accsql"
    "Guest1"
    "Guest2"
    "No-Reply"
    "publications"
    "SLAFax"
    "BoardRoom"
    "sysprosurvey"
    "Flat"
    "SYSPRO Africa"
    "Survey"
    "international"
    "Roam"
    "NAVMSE-SYSPRO-ZA"
    "Mithal"
    "Garett"
    "Rob"
    "Audit"
    "DevRoom2"
    "SueE"
    "Wouter"
    "accmanagementusa"
    "custrelationsusa'"
    "proservicesusa"
    "Salesusa"
    "Intguest"
    "CertificationComment"
    "Tamarine"
    "JudyJ"
    "joseph"
    "Beatrice"
    "CharmaineP"
    "Lyn"
    "SYSPROSmart"
    "Stefan"
    "Mariekie"
    "Denise"
    "Bradley"
    "admin"
    "Praneeta"
    "Shelley"
    "Pravir"
    "Tom"
    "Robyn"
    "Walter"
    "Kathy"
    "Kim"
    "Biancab"
    "Tabisa"
    "Core"
    "TFSSource"
    "SYSPROHelpDesk"
    "licence"
    "Angie"
    "Leatitia"
    "Shane"
    "SAS"
    "Guest1_old"
    "Guest2_old"
    "Guest3_old"
    "Guest4_old"
    "Guest5_old"
    "syspro"
    "PaulB"
    "Lee"
    "Eric"
    "Ian.Hawkeswood"
    "Annette"
    "Judi"
    "Chris"
    "Lena"
    "Ross"
    "Arabang"
    "Elias"
    "Robert"
    "Trevor"
    "CharlesH"
    "Web"
    "Train"
    "Pub"
    "sysprodbn"
    "NavVirus"
    "IUSR_SYSPRO-ZA"
    "DevRoom1"
    "Deirdre"
    "IanL"
    "PaulBLan"
    "Ianm"
    "Iantemp"
    "TUG"
    "Academic"
    "accprint"
    "Gary"
    "Sibongile"
    "Justin"
    "Amos"
    "Mark"
    "Lea"
    "Roxy"
    "zaren"
    "Ashweeta"
    "sysproct"
    "Denis"
    "Auditor"
    "Binca"
    "Estelle"
    "Tanner"
    "Monitor"
    "MerylF"
    "Guest"
    "SIUG"
    "ReceptionDBN"
    "IWAM_XBOX2950"
    "RMS"
    "Learning"
    "ISA"
    "Renier"
    "SysproSmartZA"
    "SysproBuildingServi"
    "sysprosmart_info"
    "ERRTRKStats"
    "RIS"
    "errtrkdfm"
    "administrator"
    "pdr"
    "WebDev"
    "demo1"
    "demo2"
    "Pabx"
    "Gertie"
    "Davidv"
    "Professional.Service"
    "Paulo"
    "Andy"
    "Martin"
    "Brain"
    "GavinV"
    "Phuong"
    "Darshnee"
    "Rene"
    "Angela"
    "Lynne"
    "Anja"
    "Nick"
    "Conrad"
    "varinternet"
    "SpiceWorks"
    "SASMeeting"
    "Sue"
    "Allan"
    "TrainingRoom"
    "mohammed"
    "Sasha"
    "Jon"
    "SM_62e80246a8d74efd8"
    "SM_7bfdf1bd820846eeb"
    "SM_252aed59f8ab47f68"
    "SM_6eb048725def49f6a"
    "EX2010"
    "Rolando"
    "Nicole"
    "Dean"
    "EasternCape"
    "SASHotline"
    "Karenl"
    "Zaakir"
    "Amaro"
    "Mpho"
    "Panasonic"
    "RequestQuotesla"
    "Roamingtestusertest"
    "Brendan"
    "SYSPROQuoting"
    "Ursula"
    "authorise"
    "RenierG"
    "Leighanne"
    "Rebecca"
    "robt"
    "Selma"
    "SOSUser"
    "Craigc"
    "pruser"
    "thierry"
    "jacques"
    "DSCMS"
    "Sarah"
    "CapeTownBoardroom"
    "CapeTownInternetLine"
    "SblSupport"
    "DSCalendar"
    "ChrisV"
    "SCCMNetaccess"
    "SCCMSQL"
    "ACCRepl"
    "CorporateServices"
    "AndyL"
    "guest100"
    "extest_02add6c595ab4"
    "SCOM"
    "Websense"
    "guest101"
    "Moderator"
    "Presenter"
    "Dewald"
    "Nikki"
    "Steph.hawkeswood"
    "ODCService"
    "TracyG"
    "Menwil"
    "SYSPROWCF"
    "SPT"
    "SYSPRO_BI"
    "VS2011"
    "SpiceScan"
    "TyroneJ"
    "traceym"
    "DevErrtrak"
    "Certification"
    "ODBC"
    "MaryG"
    "CathieM"
    "BrianB"
    "reception"
    "SPSEARCH"
    "SPSearchSVC"
    "Marisa"
    "NatashaWT"
    "DbnOps"
    "AuditT"
    "IntServices"
    "POSCAL"
    "Antonio"
    "Debotors"
    "TFSService"
    "Louis"
    "Killian"
    "natashac"
    "CP7"
    "MimeCast"
    "SP2013SQL"
    "SP2013Service"
    "Guest3"
    "SYSAppStore"
    "IreneS"
    "SP2013DistCache"
    "Maria"
    "Zayd"
    "Clare"
    "Marlise"
    "JP"
    "Khotso"
    "Meghan"
    "Sapics"
    "Nathi"
    "vmmlibrary"
    "Hermanus"
    "testbed1"
    "MpumeM"
    "CharityM"
    "NamhlaZ"
    "Terri"
    "AngelaC"
    "Fatima"
    "Daniel"
    "DanielM"
    "Camoren"
    "MFP"
    "Janine"
    "Michelle"
    "SZSPSearch"
    "Lornad"
    "JohanM"
    "ACCSQLMAIL"
    "Odete"
    "AnneT"
    "Jo"
    "Harold"
    "SQLMAIL"
    "DocsNew"
    "CTReception"
    "Haman"
    "$Q5F000-MJU6JVA3N2SJ"
    "SM_a1e79dda0b70444ab"
    "SM_cceb9472514d4dafb"
    "SM_72a3ac8713a74171b"
    "SM_065d4e8e26fc4ab18"
    "Caroline"
    "Bongi"
    "DevRoom3"
    "HR.ROOM"
    "IZWebmaster"
    "sharni"
    "SYSPrinting"
    "ChrisL"
    "Christelle"
    "Caitlin"
    "Franco"
    "Viki"
    "Edina"
    "Jaco"
    "DonovanM"
    "imrilubbe"
    "MeganS"
    "TFSBuild"
    "Willem"
    "MartinvN"
    "SharePointEnterprise"
    "Offline"
    "TestMail"
    "SM-TechDocs"
    "PF-Mailbox"
    "SM-KCCProject"
    "Thabo"
    "SM-PathCare"
    "Quintin"
    "Nicv"
    "Amy"
    "Zanele"
    "Petra"
    "SPPOSSupport"
    "Sabine"
    "Monica"
    "RobertB"
    "Bianca"
    "Essie"
    "HeinrichK"
    "moniqev"
    "Rachel"
    "Vivienne"
    "HR.Admin"
    "Kingston"
    "Seagate"
    "AQ"
    "SOI1"
    "SPCDRequest"
    "JamesB"
    "Gloria"
    "SysproQuote"
    "SS"
    "Clayton"
    "Jason"
    "POSSupport"
    "SP2013Farm"
    "SP2013Admin"
    "SP2013Pool"
    "SP2013Crawl"
    "SP2013Search"
    "SP2013Profiles"
    "Renee"
    "Pieter"
    "LouiseB"
    "PortalSU"
    "PortalSR"
    "Octavia"
    "Neo"
    "Andile"
    "Omphemetse"
    "Ishmael"
    "Siphile"
    "SM-GraduateProgram"
    "Doug"
    "lifeco1"
    "lifeco2"
    "lifeco3"
    "lifeco4"
    "lifeco5"
    "lifeco8"
    "lifeco9"
    "lifeco7"
    "lifeco6"
    "SibongileM"
    "calldesk1"
    "edwardm"
    "CarolH"
    "LeatitiaC"
    "Kabelo"
    "guest103"
    "SM-Academy"
    "ForumAdmin"
    "guest104"
    "hr"
    "Danie"
    "guest105"
    "SP2013Unattend"
    "Herman"
    "Heint"
    "Duane"
    "Hendrie"
    "TestUser"
    "KimV"
    "guest106"
    "Belinda"
    "guest107"
    "RichardMc"
    "Erasmus"
    "guest108"
    "Jenkins"
    "guest109"
    "Zaahida"
    "Mphikeleli"
    "guest110"
    "Caron"
    "Thane"
    "admintpf"
    "Maron"
    "CTProfessional.Servi"
    "Zain"
    "Tanya"
    "Tebogo"
    "Joshua"
    "DevRoom4"
    "ExecMeetingRoom"
    "LyncSynthTest1"
    "LyncSynthTest2"
    "pandg"
    "Kelly"
    "Juliet"
    "HealthMailboxe116f89"
    "HealthMailboxaab5e76"
    "HealthMailbox2622fa3"
    "HealthMailbox65efe52"
    "HealthMailbox7b8e4cc"
    "HealthMailboxa54b3a5"
    "HealthMailbox9ddbf6e"
    "HealthMailboxe2c77a9"
    "HealthMailbox408adca"
    "HealthMailbox0bafa7c"
    "HealthMailboxf10a5d5"
    "HealthMailbox4f6ac08"
    "HealthMailbox7efe1ff"
    "HealthMailbox3997486"
    "HealthMailboxa7d5bcf"
    "Debra"
    "SysAsiaPac"
    "Geoff"
    "FlorenceM"
    "SysproAsia"
    "Alyssa"
    "Themba"
    "Thato"
    "Regomoditswe"
    "Tshepang"
    "Gibran"
    "Thaakirah"
    "Apiwe"
    "Mahlatse"
    "Anje"
    "Israel"
    "ConradB"
    "MonicaP"
    "TebogoM"
    "Lusharn"
    "SpielbergRoom"
    "TarantinoRoom"
    "Anjev"
    "Zeen"
    "SYSPROAcademy"
    "Lufuno"
    "Tshilidzi"
    "ProfessionalServices"
    "TechServComms"
    "Docavepool"
    "DocaveService"
    "DocaveSQL"
    "DocaveFarm"
    "Patrick"
    "Edwardk"
    "DavidA"
    "Samwel"
    "Vaniter"
    "Ferdinand"
    "Veni"
    "Shingi"
    "LyncEnterprise-Appli"
    "Nayaka"
    "MarkM"
    "AfricaMeet1"
    "AfricaMeet2"
    "AfricaMeet3"
    "Annie"
    "ReceptionVoiceMailJH"
    "Sherley"
    "sanjay"
    "ChrisM"
    "Sandra"
    "JulieP"
    "Shalini"
    "MSOL_20d63163196a"
    "Ashley"
    "Roxanne"
    "Vusi"
    "TFSServiceDev"
    "VIPAdmin"
    "DeanB"
    "DavidT"
    "IvanTheInOutBoard"
    "Tholakele"
    "AFRICAExternalCalend"
    "Jino"
    "DWSQLReportNative"
    "Genevieve"
    "DMC"
    "kpims"
    "Cylma"
    "Wynand"
    "CoreReportUser"
    "AnthonyW"
    "Ian"
    "Toni"
    "Vuyane"
    "Vancouver"
    "Manchester"
    "LosAngeles"
    "Singapore"
    "Baobab"
    "Marula"
    "Lourens"
    "InfoZoneService"
    "Alicia"
    "Robin"
    "Sharepoint1"
    "CynthiaG"
    "ADFS_SVC"
    "VacancyDevelopmentM"
    "TestMailboxMove"
    "Henri"
    "AdminUser"
    "AdminJB"
    "testsysprouser"
    "testzasysprouser"
    "Sharon"
    "psdisplay"
    "AdminTS"
    "Debby"
    "Odette"
    "KabeloK"
    "Dolph"
    "firstnamesurname"
    "ATAuser"
    "InactiveUser"
    "SYSPROInternalCommun"
    "ThaboM"
    "Thembi"
    "SysproKitchen"
    "Brendan1"
    "SCSMHelpdesk"
    )
    $UserName = @(
    "Ned"
    "Ned-2"
    "IWAM_SYSPRO-DC3JHB"
    "IUSR_SYSPRO-DC3JHB"
    "IWAM_SYSPRO-DC1CT"
    "IUSR_SYSPRO-DC1CT"
    "IWAM_SYSPRO-DC1DBN"
    "IUSR_SYSPRO-DC1DBN"
    "IUSR_SYSPRO-MASTER"
    "IUSR_XBOX2950"
    "IUSR_SYSPRO-DCCT"
    "IUSR_SYSPRO-DCDBN"
    "TsInternetUser"
    "IUSR_SYSPRO-CTDC"
    "Heinrich van Heusden"
    "Paul Hollick"
    "IMP Source 10 Port User"
    "IMP Source 31 Port User"
    "Lesley Jagger"
    "Linda Samuel"
    "Kerry Scott-brown"
    "Peter Restorick"
    "Candyce Thompson"
    "Leigh Halcomb"
    "Kirsty Viljoen"
    "TESTBED$"
    "SMSService"
    "SCE"
    "Grant Fryer"
    "Mullet"
    "webmaster"
    "ArrayUser"
    "krbtgt"
    "SYSPRO DPM"
    "backup10"
    "backup31"
    "Jhb"
    "IUSR_SYSPRO-WEBDEV1"
    "IWAM_SYSPRO-WEBDEV1"
    "IUSR_SYSPRO-TECH1"
    "IUSR_SYSPRO-TECHNT1"
    "IWAM_SYSPRO-TECHNT1"
    "WEBDOMAIN$"
    "NTPORTING"
    "ntdatasvr"
    "base"
    "IWAM_SYSPRO-TECH1"
    "LDAP_ANONYMOUS"
    "Printer"
    "impsrc51"
    "testt"
    "Karin Pretorius"
    "Pauline Isaac"
    "Jacqui Young"
    "Phil Duff"
    "Russell Hollick"
    "impsrc50"
    "Train4"
    "Train5"
    "Train6"
    "Train7"
    "Train8"
    "Train9"
    "Train10"
    "impsrc60"
    "CDR"
    "Supportmail"
    "SMSServer_SYS"
    "SMSClient_SYS"
    "Train2"
    "test2"
    "test3"
    "SMSServer_JHB"
    "SMSClient_JHB"
    "RPRINTER"
    "SUPPORT_388945a0"
    "Louise Thompson"
    "Meryl Malcomess"
    "Rodney Marais"
    "Neil Hayes"
    "Richard Macfie"
    "IWAM_SYSPRO-MASTER"
    "Proact"
    "Impafr"
    "Elizabeth Daba"
    "Train3"
    "Test"
    "Test Bed"
    "Term"
    "Roshni Naidoo"
    "SharePoint"
    "test1"
    "Heinrich van Tonder"
    "Andre Kester"
    "Ingrid Aubrey"
    "IWAM_SYSPRO-DCCT"
    "Sanet Viljoen"
    "Maryann Sember"
    "Ria Butler"
    "Nerisha Ramsaroop"
    "Training HR"
    "Margaret Khuzwayo"
    "Guest HR"
    "Cynthia Desi"
    "CrystalServer"
    "Anne Morley"
    "Natalie Le Roux"
    "Train1"
    "Natalie Jagger"
    "Kirsten Lentz"
    "Kevin Dherman"
    "Mandy Hawkeswood"
    "MomC Install"
    "SYSPRO CT"
    "SYSPRO DBN"
    "Share Help"
    "mom sql"
    "Office Management"
    "Account Management"
    "Customer Relations"
    "Finance/Accounting"
    "Global Accounts"
    "Human Resources"
    "Marketing"
    "Pricing"
    "Product Support"
    "Professional Services"
    "Sales"
    "Technical Services"
    "Vertical Markets"
    "Account Management"
    "Customer Relations"
    "Finance/Accounting"
    "Global Accounts"
    "Human Resources"
    "Marketing"
    "Office Management"
    "Pricing"
    "Professional Services"
    "Sales"
    "Vertical Markets"
    "Customer Relations"
    "Finance/Accounting"
    "Global Accounts"
    "Human Resources"
    "Marketing"
    "Office Management"
    "Pricing"
    "Product Support"
    "Professional Services"
    "Training/Knowledge Transfe"
    "Human Resources"
    "Office Management"
    "Finance/Accounting"
    "Global Accounts"
    "Human Resources"
    "Marketing"
    "Office Management"
    "Pricing"
    "Product Support"
    "Technical Services"
    "Training/Knowledge Transfer"
    "Vertical Markets"
    "SAS Help Desk"
    "Judith Spencer"
    "Duppie du Plessis"
    "IWAM_SYSPRO-DCDBN"
    "dssql"
    "Phil1"
    "remotetest"
    "Sysprotest"
    "admindb"
    "African Events"
    "APS"
    "Biztalk test"
    "biztalk2"
    "Cape Town"
    "Cornelia Watts"
    "Santa Pillay"
    "Helen Hollick"
    "Carol Richardson"
    "Benita Ravyse"
    "DFM"
    "Documentation"
    "Even Nesset"
    "Tiffany Gierke"
    "DSEvents"
    "DSHOTLINE"
    "DSTesters"
    "Durban Usergroup"
    "DurbanOffice"
    "Eval"
    "HR-Applications"
    "InfoCT"
    "InfoDBN"
    "Lorna Lyte-Mason"
    "Carole Dean"
    "Damiana La Manna"
    "Pat Mc Evilly"
    "meet1"
    "Minolta"
    "Peace Mayaphi"
    "Phil Test"
    "Leshec Claassens"
    "Lorenzo Borelli"
    "richard1"
    "richard2"
    "Spam"
    "sysprobd"
    "Monique McNaught"
    "Winfax"
    "Word Printing"
    "DevelopMail"
    "Training/Knowledge Transfer"
    "Product Support"
    "Technical Services"
    "Training/Knowledge Transfer"
    "Temp"
    "Tyron Stoltz"
    "Helga Geldenhuys"
    "Account Management"
    "Sales"
    "Technical Services"
    "Vertical Markets"
    "Vista"
    "Web Development"
    "Web Development"
    "Web Development"
    "Web Development"
    "IWAM_SYSPRO-CTDC"
    "syspropub"
    "Scheduled Leave for Employees"
    "Performance"
    "Night Line"
    "nedbank"
    "Meeting Room 2"
    "Meeting Room 1"
    "Kitchen Auditorium"
    "Kitchen Upstairs"
    "Kitchen Downstairs"
    "Dining Room 2"
    "Dining Room 1"
    "Birthday List"
    "AbsalomESS"
    "Phil Conference"
    "CMS"
    "Standards"
    "Marianne Erasmus"
    "Natasha Watson"
    "Charles Glass"
    "DebbieJ"
    "deloitte"
    "Account Management"
    "Customer Relations"
    "Finance/Accounting"
    "Global Accounts"
    "Marketing"
    "Pricing"
    "Product Support"
    "Professional Services"
    "Sales"
    "Technical Services"
    "Training/Knowledge Transfer"
    "Vertical Markets"
    "sysprofax"
    "Commissions Claims"
    "ALF Licences"
    "Lorraine Makhubo"
    "Trish Fowler"
    "adminsql"
    "accsql"
    "Guest1"
    "Guest2"
    "No-Reply"
    "publications"
    "SLA Fax"
    "Board Room"
    "sysprosurvey"
    "Syspro Flat"
    "SYSPRO Africa"
    "Survey"
    "International"
    "Roaming Profile"
    "NAV for Microsoft Exchange-SYSPRO-ZA"
    "Mithal Harilal"
    "Garett Murphy"
    "Rob Hurry"
    "Auditorium"
    "DevRoom2"
    "Sue Elsworthy"
    "Wouter Combrinck"
    "Account Management"
    "Customer Relations"
    "Professional Services"
    "Sales"
    "Intguest"
    "Certification Comments"
    "Tamarine Sifolo"
    "Judy Johnson"
    "Joseph Mofokeng"
    "Beatrice Engelbrecht"
    "Charmaine Pamphilon"
    "Lyn Muskett"
    "SYSPROSmart"
    "Stefan Olivier"
    "Mariekie Coetzee"
    "Denise De Oliveira"
    "Bradley Poliah"
    "admin"
    "Praneeta Manilall"
    "Shelley Backhouse"
    "Pravir Rai"
    "Tom Grindley-Ferris"
    "Robyn Heinze"
    "Walter Segale"
    "Kathy Harris (Worrall)"
    "Kim Fouche"
    "Bianca Behrmann"
    "Tabisa Mbuyazwe"
    "Core Core"
    "TFS Source"
    "SYSPRO Help Desk"
    "License"
    "Angie Mansour"
    "Leatitia Heather"
    "Shane Meerholz"
    "SAS"
    "Guest 1"
    "Guest 2"
    "Guest 3"
    "Guest 4"
    "Guest 5"
    "syspro"
    "Paul Borthwick"
    "Lee Ridley"
    "Eric Diale"
    "Ian Hawkeswood"
    "Annette Pollitt"
    "Judi Campleman"
    "Christine English"
    "Lena Marques"
    "Ross Bateman"
    "Arabang Raditapole"
    "Elias Sithole"
    "Robert Zulu"
    "Trevor Wridgway"
    "Charles Hoole"
    "Web Development"
    "Training Room"
    "Pub"
    "sysprodbn"
    "NavVirus"
    "Internet Guest Account"
    "DevRoom1"
    "Deirdre Fryer"
    "Ian Lan"
    "PaulB Lan"
    "Ian Mann"
    "IanTemp"
    "TUG"
    "Academic Alliance"
    "accprint"
    "Gary De Oliveira"
    "Sibongile Nhlapo"
    "Justin Steyn"
    "Amos Moyo"
    "Mark Sher"
    "Lea Erasmus"
    "Roxy Laing"
    "Zaren Ramlugan"
    "Ashweeta Ramsaroop"
    "Syspro-ct"
    "Denis"
    "Auditor"
    "Janet Binca"
    "Estelle Poliah"
    "Tanner Greyling"
    "Monitor DO NOT TOUCH"
    "Meryl Franks"
    "International Guest"
    "SYSPRO Independant User Group"
    "Reception - Dbn"
    "IWAM_XBOX2950"
    "RMS"
    "LearningChannel"
    "ISASupport"
    "Renier Walker"
    "Syspro Certification"
    "Syspro BuildingServices"
    "Sysprosmart Info"
    "ERRTRK Stats"
    "Syspro South Africa"
    "errtrk dfm"
    "administrator"
    "PDR System"
    "WebDev"
    "Demonstration Room 1"
    "Demonstration Room 2"
    "Pabx"
    "Gertie Wolfaardt"
    "David van Rensburg"
    "Professional Services Calendar"
    "Paulo de Matos"
    "Andy Latham"
    "Martin Kelley"
    "Brain Paquette"
    "Gavin Verreyne"
    "Phuong Le"
    "Darshnee Shah"
    "Rene Inzana"
    "Angela Karpik"
    "Lynne Falconer"
    "Anja Soejberg"
    "Nick McGrane"
    "Conrad Marques"
    "VAR Internet"
    "SpiceWorks General"
    "SAS Meeting Room Upstairs"
    "Sue Scheepers"
    "Allan McNally"
    "Training Room"
    "Mohammed Mayet"
    "Sasha Verbiest"
    "Jon Thornton-Dibb"
    "SystemMailbox{1f05a927-f649-4f92-82dc-f938a9c3e86b}"
    "SystemMailbox{e0dc1c29-89c3-4034-b678-e6c29d823ed9}"
    "DiscoverySearchMailbox {D919BA05-46A6-415f-80AD-7E09334BB852}"
    "FederatedEmail.4c1f4d8b-8179-4148-93bf-00a95fa1e042"
    "Exchange 2010"
    "Rolando Campos"
    "Nicole Bruckner"
    "Dean Raemakers"
    "Eastern Cape"
    "SAS Hotline"
    "Karen Loots"
    "Zaakir Bhoola"
    "Amaro de Abreu"
    "Mpho Sedibe"
    "Panasonic DP. 8045"
    "Request Quotesla"
    "Roamingtestusertest"
    "Brendan"
    "SYSPRO Quoting"
    "Ursula Stroud"
    "authorise"
    "Renier Geyser"
    "Leighanne Imbert"
    "Rebecca Clatworthy"
    "Rob Test"
    "Selma Senekal"
    "SOS-User"
    "Craig Campbell"
    "PR User"
    "Thierry van Straaten"
    "Jacques Mouton"
    "DS CMS"
    "Sarah Futter"
    "Cape Town Boardroom"
    "Cape Town Internet Line"
    "SBL Support"
    "DS Calendar"
    "Chris Vogt"
    "SCCM NetAccess"
    "SQL Service"
    "ACCRepl"
    "Corporate Services HUB Meeting Room"
    "Andy Latham"
    "Guest100"
    "extest_02add6c595ab4"
    "SCOM Run As. Account"
    "Websense"
    "Guest101"
    "Moderator"
    "Presenter"
    "Dewald Brink"
    "Nikki Malcomess"
    "Steph Hawkeswood"
    "ODCService"
    "Tracy Robb"
    "Menwil Gordon"
    "SYSPROWCF Services"
    "SP Tester"
    "SYSPRO_BI"
    "VS2011"
    "Spiceworks Scan"
    "Tyrone Jagger"
    "Tracey Moller"
    "DevErrtrak"
    "Certification"
    "ODBC"
    "Mary Githu"
    "Cathie Hall"
    "Brian Stein"
    "SYSPROReception"
    "Sharepoint Search"
    "Sharepoint Search Service"
    "Marisa"
    "Natasha Wilson-Taylor"
    "DBN OPS"
    "Audit Temp"
    "Integrated Services"
    "POINT OF SALES"
    "Antonino Marra"
    "Debtors"
    "TFSService"
    "Louis"
    "Killian Sibanda"
    "Natasha Morgan"
    "Community Preview"
    "MimeCast Query"
    "SP2013SQL"
    "SP2013Service"
    "Guest3"
    "SYSPRO App Store"
    "Irene Snyman"
    "Sharepoint 2013. Distributed Cache"
    "Maria La Manna"
    "Zayd Mahioodin"
    "Clare Forson"
    "Marlise du Plessis"
    "JP van Loggerenberg"
    "Khotso Shomang"
    "Meghan Kemp"
    "Sapics User"
    "Nkosinathi Fungene"
    "vmm library"
    "Hermanus Smalman"
    "testbed"
    "Mpume Madonsela"
    "Charity Mwale"
    "Namhla Zakaza"
    "Terri da Silva"
    "Angela Chandler"
    "Fatima Daya"
    "Daniel Sher"
    "Daniel Monyamane"
    "Camoren Moller"
    "MFP"
    "Janine du Plooy"
    "Michelle Botha"
    "SZSPSearch"
    "Lorna du Plessis"
    "Johan Myburg"
    "ACCSQL Mail"
    "Odete Passingham"
    "Anne Teng"
    "Jo Burnett"
    "Harold Katz"
    "SQLMAIL"
    "DOCSNEW"
    "CPT Reception"
    "Haman"
    "Exchange Online-ApplicationAccount"
    "SystemMailbox{bb558c35-97f1-4cb9-8ff7-d53741dc928c}"
    "Migration.8f3e7716-2011-43e4-96b1-aba62d229136"
    "HealthMailbox8619aab417e849aa9e009c70d95b562c"
    "HealthMailboxd0bc3eb783da4ec1aa033fce8cf58994"
    "Caroline Mozwenyana"
    "Sibongile Keswa"
    "DevRoom3"
    "HR Room"
    "InfoZone Webmaster"
    "Sharni Hart"
    "SYSPRO Server Printing"
    "Chris Lautre"
    "Christelle Swanepoel"
    "Caitlin Shepherd"
    "Franco Gates"
    "Viki Neilson"
    "Edina Beeten"
    "Jaco Maritz"
    "Donovan MacMaster"
    "Imri Lubbe"
    "Megan Schoeman"
    "TFS Build"
    "Willem van Rensburg"
    "Martin van Niekerk"
    "SharePointEnterprise-ApplicationAccount"
    "Offline Test"
    "Test Mail"
    "SM-TechDocs"
    "PF-Mailbox"
    "SM-KCCProject"
    "Thabo Tlebere"
    "SM-PathCare"
    "Quintin Botes"
    "Nic Veldmeijer"
    "Amy Ritson"
    "Zanele Seneka"
    "Petra Van Waardhuizen"
    "SPPOSSupport"
    "Sabine Behrmann"
    "Monica Pretorius"
    "Robert Bouwer"
    "Bianca Haarhoff"
    "Essie Jansen van Vuuren"
    "Heinrich Kolliner"
    "Moniqe Kollner"
    "Rachel van Graan"
    "Vivienne Mseka"
    "HR Admin"
    "Kingston Tech"
    "Seagate Thin"
    "AQ"
    "SOI TEST"
    "SPCDRequest"
    "James Blanckenberg"
    "Gloria Lombard"
    "Syspro.QuotationReminders"
    "SS"
    "Clayton Dormehl"
    "Jason Baxter"
    "POS Support"
    "SP2013Farm"
    "SP2013Admin"
    "SP2013Pool"
    "SP2013Crawl"
    "SP2013Search"
    "SP2013Profiles"
    "Renee van der Berg"
    "Pieter van Heerden"
    "Louise Buchanan"
    "Portal Super User"
    "Portal Super Reader"
    "Octavia Hlophe"
    "Neo Kgopa"
    "Andile Shange"
    "Omphemetse Mabe"
    "Ishmael Mbanjwa"
    "Siphile Mathabela"
    "SM-GraduateProgram"
    "Doug Hunter"
    "lifeco1"
    "lifeco2"
    "lifeco3"
    "lifeco4"
    "lifeco5"
    "lifeco8"
    "lifeco9"
    "lifeco7"
    "lifeco6"
    "Sibongile Makhathini"
    "do not reply"
    "Edward L. Mello"
    "Carol Hart"
    "Laetitia Clark"
    "Kabelo Masuku"
    "Guest103"
    "SM-Academy"
    "ForumAdmin"
    "guest104"
    "HR"
    "Danie du Plessis"
    "guest105"
    "SP2013Unattend"
    "Herman  Boonzaier"
    "Hein Test"
    "Duane van Coller"
    "Hendrie Potgieter"
    "TestUser"
    "Kim van der Walt"
    "guest106"
    "Belinda Chetty"
    "guest107"
    "Richard Mc Cormack"
    "Musa Dlamini"
    "guest108"
    "Jenkins"
    "Guest 109"
    "Zaahida Rayman"
    "Mphikeleli Nkabinde"
    "guest110"
    "Caron Hewitt"
    "Thane Forst"
    "Thane Forst (Admin Account)"
    "Maron Mashile"
    "CT Professional Services Calendar"
    "Zain Ajam"
    "Tanya Botha"
    "Tebogo Moorosi"
    "Joshua Troskie"
    "DevRoom 4"
    "Exec Meeting Room"
    "LyncSynthTestUser1"
    "LyncSynthTestUser2"
    "Proctor Gamble"
    "Kelly Farr"
    "Juliet Ruvengo"
    "HealthMailboxe116f892d91d415faeba39a2cf563fc9"
    "HealthMailboxaab5e76791a444ce967c03a4006d091e"
    "HealthMailbox2622fa33de5044d5aa97535eb2fd80d0"
    "HealthMailbox65efe5295cf246e39376514be3df8493"
    "HealthMailbox7b8e4cc9686b45daaa0b64cd410c4d20"
    "HealthMailboxa54b3a5577c547719b22db013333005b"
    "HealthMailbox9ddbf6ec00b54b459728b7b7b55105f0"
    "HealthMailboxe2c77a998bad4d6b91fe5002cb6dcae7"
    "HealthMailbox408adcada8134cab96669d58b00d9588"
    "HealthMailbox0bafa7c341e44c4da1278e14a19a7402"
    "HealthMailboxf10a5d5321c9441381ab7cdbc7afb45a"
    "HealthMailbox4f6ac08f86e84127bd723a425d6fd6ff"
    "HealthMailbox7efe1ff6c4f14b4287cb357872d14492"
    "HealthMailbox3997486371424dd181f4612c6ee05855"
    "HealthMailboxa7d5bcf008f0440888a57ba12d6a520a"
    "Debra Botha"
    "Syspro AsiaPac"
    "Geoff Garett"
    "Florence Mfiki"
    "Syspro Asia"
    "Alyssa Whale"
    "Themba Makhubele"
    "Thato Fihlo"
    "Regomoditswe Mamba"
    "Tshepang Julie"
    "Gibran Noorbhai"
    "Thaakirah Raffie"
    "Apiwe Hoyi"
    "Mahlatse Sombhane"
    "Anje van Veelen"
    "Israel Kabayo"
    "Conrad Beukes"
    "Monica Pretorius"
    "Tebogo Moorosi"
    "Lusharn Botes"
    "Spielberg Room"
    "Tarantino Room"
    "Anje van Veelen"
    "Zeen Cassim"
    "SYSPRO Academy"
    "Lufuno Mukhwathi"
    "Tshilidzi Makumbane"
    "Professional Services Call Desk"
    "TechServices Communications"
    "Docavepool"
    "DocaveService"
    "DocaveSQL"
    "DocaveFarm"
    "Patrick Wafula"
    "Edward Keya"
    "David Ambuga"
    "Samwel Sakwa"
    "Vaniter Obuya"
    "Ferdinand Odhiambo"
    "Veni Govender"
    "Shingi Nhari"
    "LyncEnterprise-ApplicationAccount"
    "Nayaka Moloto"
    "Mark Mackay"
    "Africa Meet 1"
    "Africa Meet 2"
    "Africa Meet 3"
    "Annie Jurbandam"
    "Reception JHB Voice Mail"
    "Sherley Makofane"
    "Sanjay Galal"
    "Chris Meyers"
    "Sandra Fraga"
    "Julie Pryce-Jones"
    "Shalini Naidoo"
    "MSOL_20d63163196a"
    "Ashley Pillay"
    "Roxanne Govender"
    "Vusi Dhlamini"
    "TFSService Account Dev"
    "VIP Admin"
    "Dean Bunce"
    "David Thompson"
    "Ivan TheInOutBoard"
    "Tholakele Zungu"
    "AFRICA External Calendar"
    "Jino Makau"
    "DWSQLReportNative"
    "Genevieve Aitken"
    "DMC"
    "kpims"
    "Cylma Spaans"
    "Wynand Marais"
    "CoreReportUser"
    "Anthony Wilson"
    "Ian Lawless"
    "Toni Joubert"
    "Vuyane Mtoyi"
    "Vancouver"
    "Manchester"
    "Los Angeles"
    "Singapore"
    "Baobab"
    "Marula"
    "Lourens Kilian"
    "InfoZoneService"
    "Alicia Smuts"
    "Robin van der Plank"
    "Sharepoint"
    "Cynthia Giyani"
    "ADFS SVC"
    "Vacancy Development Manufacturing"
    "TestMailboxMove"
    "Henri Borsboom"
    "Henri Borsboom (Admin Account)"
    "Jason Admin Baxter"
    "Test SYSPRO User"
    "Test SYSPRO ZA User"
    "Sharon Mkhize"
    "Display User"
    "Tyron Stoltz (Admin Account)"
    "Debby Diedericks"
    "Odette Bester"
    "Kabelo Kekana"
    "Dolph Pretorius"
    "firstname surname"
    "ATAuser"
    "Inactive User"
    "SYSPRO Internal Communications"
    "Thabo Mofokeng"
    "Thembi Montsho"
    "Syspro Kitchen"
    "Brendan Vorster"
    "SCSMHelpdesk"
    )
    $DistinguishedName = @(
    "OU=Recipients,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=External Users,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=External Users,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Training Room,OU=Durban,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users - Use this OU,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Distribution,OU=Durban,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=UsersOld,OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=General Users,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=SA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=CAN,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users - Use this OU,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users - Use this OU,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UK,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users0old,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Recipients,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=USA,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Development,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=AUS,OU=Syspro Touch Points,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Professional Services,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users0old,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users0old,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users0old,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Cape Town,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=International Lync Users,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=International Lync Users,DC=sysproza,DC=net"
    "OU=International Lync Users,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Marketing,OU=Durban,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Temp SharePoint Users,DC=sysproza,DC=net"
    "OU=Temp SharePoint Users,DC=sysproza,DC=net"
    "OU=Temp SharePoint Users,DC=sysproza,DC=net"
    "OU=Temp SharePoint Users,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Contractors,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Contractors,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Contractors,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Contractors,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Contractors,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Intern Users,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Technical Writing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "CN=Managed Service Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Technical Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Internet Guests - full internet access,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Admin Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Distributor Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Meeting Rooms,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Meeting Rooms,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersTest,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersTest,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Azure Users,OU=Azure,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=sysproza,DC=net"
    "OU=Users,OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Territory Office Users,OU=Azure,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersOld,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Territory Office Users,OU=Azure,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Sharepoint Service Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Sharepoint Service Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Sharepoint Service Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Sharepoint Service Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "OU=Interns,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "DC=sysproza,DC=net"
    "OU=Users0old,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users0old,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users0old,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Core,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Sharepoint Service Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Service Account,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Disabled Accounts,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Development - Emerging Technologies,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Marketing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Sharepoint Service Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Financial,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=EA Accounts,OU=SYSPRO Azure,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Distribution,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Admin Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Consultants,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Consultants,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Consultants,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Consultants,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Meeting Rooms,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Meeting Rooms,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Meeting Rooms,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Meeting Rooms,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Meeting Rooms,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Meeting Rooms,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Administration,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Sharepoint Service Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Syspro Africa Support,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Corporate Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Knowledge Transfer,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Admin Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersTest,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Usersold,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Admin Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Admin Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersTest,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersTest,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Admin Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Emerging Technologies,OU=Cape Town,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Development - Manufacturing,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Professional Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=UsersTest,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Admin Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Admin Accounts,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=E-Mail Groups,OU=Technical Services,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Web Development,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "OU=Users-FS,OU=Human Resources,OU=Johannesburg,DC=sysproza,DC=net"
    "CN=Users,DC=sysproza,DC=net"
    )

    Clear-Host
    $ADCount = $UserName.Count

    For ($i = 0; $i -lt $ADCount; $i ++) {
        Write-Host (($i + 1) + "\$ADCount - Creating " + $UserName[$i] + " - ") -NoNewline
        Try {
            New-ADUser -SamAccountName $SAMAccount[$i] -Name $Username[$i] -Path $DistinguishedName[$i] -ErrorAction SilentlyContinue
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch {
            Write-Host "Failed" -ForegroundColor Red
            Write-Host (" - " + $_)
        }
    }
}
Function Connect-SCOM {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet("2012", "2016", "SYSJHBOPSMGR", "SYSJHBSCOM01")]
        [String] $SCOM)

    Import-Module OperationsManager
        Switch ($SCOM) {
            "2012"         { New-SCOMManagementGroupConnection -ComputerName "SYSJHBOPSMGR.sysproza.net" }
            "SYSJHBOPSMGR" { New-SCOMManagementGroupConnection -ComputerName "SYSJHBOPSMGR.sysproza.net" }
            "2016"         { New-SCOMManagementGroupConnection -ComputerName "SYSJHBSCOM01.sysproza.net" }
            "SYSJHBSCOM01" { New-SCOMManagementGroupConnection -ComputerName "SYSJHBSCOM01.sysproza.net" }
    }
}
 Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1, ParameterSetName="Text")]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2, ParameterSetName="Text")]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory = $False , Position = 3, ParameterSetName="Text")]
        [Switch]           $NoNewLine, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $Complete)

    $ErrorActionPreference = "Stop"
    Try {
        If ($Text.Count -ne $ForegroundColor.Count) {
            Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $ForegroundColor.Count.ToString()) -ForegroundColor Red
            Throw
        }
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch { 
        Write-Host "Text Count:  " $Text.Count
        Write-Host "Color Count: " $ForegroundColor.Count
        Write-Host $_
    }
}
Function Get-TotalTime {
    Param(
        [Parameter(Mandatory = $True,  Position = 1)]
        [DateTime] $StartTime, `
        [Parameter(Mandatory = $True,  Position = 2)]
        [DateTime] $EndTime)

    $Duration = New-TimeSpan -Start $StartTime -End $EndTime

    $TotalSeconds = $Duration.TotalSeconds
    $TimeSpan =  [TimeSpan]::FromSeconds($TotalSeconds)
    $ReturnVariable = ("{0:hh\:mm\:ss}" -f $TimeSpan)
    Return $ReturnVariable
}
Function New-WSUSJob {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String[]] $Script)

    
    $ThisJob = Start-Job -ScriptBlock {Param ($Script); Invoke-Expression $Script} -ArgumentList $Script
    While ($ThisJob.State -eq 'Running') {
        Delete-Spot
        Start-Sleep -Milliseconds 100
    }
    $JobResults = Receive-Job $ThisJob
    Get-Job | Wait-Job | Remove-Job
    Return $JobResults
}
Function Update-Host {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String[]] $Script)

    $StartTime  = Get-Date
    $JobResults = New-WSUSJob -Script $Script
    $EndTime    = Get-Date
    $Duration   = Get-TotalTime -StartTime $StartTime -EndTime $EndTime
    Write-Color -Text $JobResults, ' - ', $Duration -ForegroundColor Yellow, White, DarkCyan
}
Function Process-WSUS {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $ServerName, `
        [Parameter(Mandatory=$True, Position=2)]
        [Int] $Port, `
        [Parameter(Mandatory=$False, Position=3)][ValidateSet('CleanupObsoleteComputers','CleanupObsoleteUpdates', 'CleanupUnneededContentFiles', 'CompressUpdates', 'DeclineExpiredUpdates', 'DeclineSupersededUpdates')]
        [String] $Action)

    Import-Module UpdateServices

    Write-Color -Text 'Connecting to ', $ServerName, ':', $Port, ' - ' -ForegroundColor White, DarkCyan, White, DarkCyan, White -NoNewLine
        $Global:WSUSServer = Get-WsusServer -Name $ServerName -PortNumber $Port
    Write-Color -Text 'Complete' -ForegroundColor Green

    Switch ($Action) {
        'CleanupObsoleteComputers' {
            Write-Color -Text 'Cleaning up of Obsolete Computers', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -CleanupObsoleteComputers')
                Update-Host -Script $ThisScript
        }
        'CleanupObsoleteUpdates' {
            Write-Color -Text 'Cleaning up of Obsolete Updates', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -CleanupObsoleteUpdates')
                Update-Host -Script $ThisScript
        }
        'CleanupUnneededContentFiles' {
            Write-Color -Text 'Cleaning up of Unneeded Content Files', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -CleanupUnneededContentFiles')
                Update-Host -Script $ThisScript
        }
        'CompressUpdates' {
            Write-Color -Text 'Compressing Updates', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -CompressUpdates ')
                Update-Host -Script $ThisScript
        }
        'DeclineExpiredUpdates' {
            Write-Color -Text 'Declining Expired Updates', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -DeclineExpiredUpdates')
                Update-Host -Script $ThisScript
        }
        'DeclineSupersededUpdates' {
            Write-Color -Text 'Declining Superseded Updates', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -DeclineSupersededUpdates')
                Update-Host -Script $ThisScript
        }
        Default {
            Write-Color -Text 'Cleaning up of Obsolete Computers', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -CleanupObsoleteComputers')
                Update-Host -Script $ThisScript

            Write-Color -Text 'Cleaning up of Obsolete Updates', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -CleanupObsoleteUpdates')
                Update-Host -Script $ThisScript
    
            Write-Color -Text 'Cleaning up of Unneeded Content Files', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -CleanupUnneededContentFiles')
                Update-Host -Script $ThisScript

            Write-Color -Text 'Compressing Updates', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -CompressUpdates ')
                Update-Host -Script $ThisScript

            Write-Color -Text 'Declining Expired Updates', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -DeclineExpiredUpdates')
                Update-Host -Script $ThisScript

            Write-Color -Text 'Declining Superseded Updates', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -DeclineSupersededUpdates')
                Update-Host -Script $ThisScript
        }
    }
}
Function Delete-Spot {
    If ($Host.Name -notlike '*ISE*') {
        $PShost = Get-Host
        $pswindow = $pshost.ui.rawui

        $x = [Console]::CursorLeft
        $y = [Console]::CursorTop
        [Console]::SetCursorPosition($x, $y)

        $CursorIndex = @('-', '\', '|', '/')
        If ($Global:CurrentSpot -eq $null)              { $Global:CurrentSpot = 0 }
        If ($Global:CurrentSpot -gt $CursorIndex.Count) { $Global:CurrentSpot = 0 }
        If ($Global:MilliCounter -eq $null)                  { $Global:MilliCounter = 0; $Global:SecondCounter = 0 }
        If ($Global:MilliCounter -gt 10)                     { $Global:MilliCounter = 0; $Global:SecondCounter ++ }
        Write-Host ("[" + ("{0:hh\:mm\:ss}" -f [TimeSpan]::FromSeconds((New-TimeSpan -Seconds $SecondCounter).TotalSeconds)) + "] " + $CursorIndex[$Global:CurrentSpot]) -ForegroundColor DarkGreen -NoNewline
        $Global:CurrentSpot ++
        $Global:MilliCounter ++
        [Console]::SetCursorPosition($x, $y)
        Write-Host "" -NoNewline
    }
}
Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)

    $ErrorActionPreference = "Stop"
    Try {
        If ($Text.Count -ne $ForegroundColor.Count) {
            Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $ForegroundColor.Count.ToString()) -ForegroundColor Red
            Throw
        }
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch { 
        Write-Host "Text Count:  " $Text.Count
        Write-Host "Color Count: " $Color.Count
        Write-Host $_
    }
}
Function MaintenanceMode {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$True, Position=2)][ValidateSet(“Start”,”Stop”)]
        [String] $Action)

    $Instance = Get-SCOMClassInstance -Name $Server
   
    Switch ($Action) {
        "Start" {
            Write-Color -Text "Starting Maintenance mode for ", $Server.ToUpper(), " - " -ForegroundColor White, Yellow, White -NoNewLine
                $Time = ((Get-Date).AddMinutes(30))
                Start-SCOMMaintenanceMode -Instance $Instance -EndTime $Time -Reason PlannedApplicationMaintenance -Comment ("Clearing SCOM Cache. " + $env:USERNAME) -ErrorAction Continue
            Write-Color -Text "Complete" -ForegroundColor Green
        }
        "Stop" {
            Write-Color -Text "Stopping Maintenance mode for ", $Server.ToUpper(), " - " -ForegroundColor White, Yellow, White -NoNewLine
                $MMEntry = Get-SCOMMaintenanceMode -Instance $Instance
                $NewEndTime = (Get-Date).addMinutes(0)
                Set-SCOMMaintenanceMode -MaintenanceModeEntry $MMEntry -EndTime $NewEndTime -Comment ("Clearing SCOM Cache. " + $env:USERNAME)
            Write-Color -Text "Complete" -ForegroundColor Green
        }
    }

    
}
Function Clear-Health {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $AgentPath)
    
    Try {
        Write-Color -Text "Processing ", $Server, " - " -ForegroundColor White, Yellow, White -NoNewLine
            Invoke-Command -Session (New-PSSession -ComputerName $Server) -ArgumentList $AgentPath -ScriptBlock {Param($AgentPath); Stop-Service HealthService -Force -Confirm:$false -ErrorAction Stop; Remove-Item $AgentPath -Recurse -Force -ErrorAction Stop; Start-Service HealthService -ErrorAction Stop}
        Write-Color -Text "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }
}
Function Start-MultiThreadJob {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [String[]] $ScriptBlockArguments, `
        [Parameter(Mandatory=$true,Position=2)]
        [String[]] $ScriptBlock)
    
    $SleepTimer = 1
    $GetChildItemJob = Start-Job -ArgumentList $ScriptBlockArguments, $ScriptBlock -ScriptBlock {Param($ScriptBlockArguments); Invoke-Expression $ScriptBlock} -ErrorAction Stop
    $GetChildItemJobState = Get-Job $GetChildItemJob.Id
    While ($GetChildItemJobState.State -eq "Running") {
        Write-Host "." -NoNewline -ForegroundColor Cyan
        Sleep 3
        $SleepTimer ++
    }
    $GetChildItemJobResults = Receive-Job -Job $GetChildItemJob
    Return $GetChildItemJobResults
}
Function AzureHealthStatesRule {
    $errorActionPreference = 'Stop'
    Set-StrictMode -Version 2

    $SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
    $SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory "OperationsManager"
    Import-module $SCOMModulePath

    # set default counts as zero
    $totalAgentCount        = 0
    $UnavailableAgentsCount = 0
    $UnmonitoredAgentsCount = 0
    $HealthyAgentsCount     = 0
    $CriticalAgentsCount    = 0
    $WarningAgentsCount     = 0

    # get the agent data and put it in a hash
    $agents = Get-SCOMAgent | Where-Object {$_.DisplayName -notlike "*.sysproza.net*"}
    # if there's no agents, just simply set all counts to zero
    If (!$agents) {
        # do nothing, the counts will be zero as default
    }
    Else {
        $totalAgentCount = @($agents).Count

        #map to all agents table
        $allAgentsTable = @{}
        $agents | % {$allAgentsTable.Add($_.DisplayName, $_.HealthState)}

        #get the agent watcher class and heartbeat monitor
        $monitor = Get-SCOMMonitor -Name Microsoft.SystemCenter.HealthService.Heartbeat
        $monitorCollection = @($monitor)
        $monitorCollection = $monitorCollection -as [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitor[]]
        $watcherClass = Get-SCOMClass -Name Microsoft.SystemCenter.AgentWatcher
        $watcherInstances = @(Get-SCOMClassInstance -Class $watcherClass)

        #map to all heartbeat monitors table
        $allHeartbeatMonitorsTable = @{}
        $watcherInstances | % {$allHeartbeatMonitorsTable.Add($_.DisplayName, $_.GetMonitoringStates($monitorCollection)[0].HealthState.ToString())}

        #get agents count in different states
        ForEach ($agent in $allAgentsTable.GetEnumerator()) {
            # get count of healthy agents
            If ($agent.Value -eq 'Success' -and $allHeartbeatMonitorsTable[$agent.Name] -eq 'Success') {
                $HealthyAgentsCount++
            }
            # get count of warning agents
            ElseIf ($agent.Value -eq 'Warning' -and $allHeartbeatMonitorsTable[$agent.Name] -eq 'Success') {
                $WarningAgentsCount++
            }
            # get count of critical agents
            ElseIf ($agent.Value -eq 'Error' -and $allHeartbeatMonitorsTable[$agent.Name] -eq 'Success') {
                $CriticalAgentsCount++
            }
        }
        # get count of unmonitored agents
        $UnmonitoredAgentsCount = @($allAgentsTable.GetEnumerator() | ? {$_.Value -eq 'Uninitialized'}).Count
        # get count of unavailable agents
        $UnavailableAgentsCount = $totalAgentCount - $HealthyAgentsCount - $WarningAgentsCount - $CriticalAgentsCount - $UnmonitoredAgentsCount

        #check if the Unavailable agents count is negative
        If ($UnavailableAgentsCount -lt 0) {
            Write-EventLog -LogName "Operations Manager" -Source "Health Service Script" -EventId 21000 -EntryType Warning -Message "AgentStateRollup script detected the Uavailable agents count is negative, script interrupted, will wait for next execution"
            exit
        }
    }

    #add a helper class to get the localized display strings
    $langClass = New-Module {
        $lang = (Get-Culture).ThreeLetterWindowsLanguageName
        $mp = Get-SCOMManagementPack -Name  Microsoft.SystemCenter.OperationsManager.SummaryDashboard
        # Set localized language to ENU if the expected language is not found in MP
        Try {
            $temp = $mp.GetDisplayString($lang)
        }
        Catch [Microsoft.EnterpriseManagement.Common.ObjectNotFoundException] {
            $lang = "ENU"
        }

        Function GetLocalizedDisplayString($elementId) {
            $mp.FindManagementPackElementByName($elementId).GetDisplayString($lang).Name
        }
        
        Export-ModuleMember -Variable * -Function *
    } -asCustomObject

    $api = New-Object -comObject 'MOM.ScriptAPI'
    Function AddPropertyBag ($Name, [System.Int32]$Value) {
        If (!$Value) {$Value = 0}

        $bag = $api.CreateTypedPropertyBag(2)
        $bag.AddValue('AgentStates', $Name)
        $bag.AddValue('Value', $Value)
        $api.AddItem($bag)
        $bag
    }

    #create propertybags for output
    AddPropertyBag $langClass.GetLocalizedDisplayString('HeathStateTotal') $totalAgentCount
    AddPropertyBag $langClass.GetLocalizedDisplayString('HeathStateUninitialized') $UnavailableAgentsCount
    AddPropertyBag $langClass.GetLocalizedDisplayString('HeathStateUnmonitored') $UnmonitoredAgentsCount
    AddPropertyBag $langClass.GetLocalizedDisplayString('HeathStateSuccess') $HealthyAgentsCount
    AddPropertyBag $langClass.GetLocalizedDisplayString('HeathStateError') $CriticalAgentsCount
    AddPropertyBag $langClass.GetLocalizedDisplayString('HeathStateWarning') $WarningAgentsCount
}
Function AzureAlertsCountRule {
    $ErrorActionPreference = 'Stop'
    Set-StrictMode -Version 2

    $SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
    $SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory “OperationsManager”

    Import-module $SCOMModulePath

    $API = New-Object -comObject 'MOM.ScriptAPI'
    $Bag = $API.CreatePropertyBag()

    #$API.LogScriptEvent("GetAzureAlertsCount.ps1",3280,0,"Get Azure Active Alerts Script is starting")

    $AlertsCount = 0
    $AlertsByObject = Get-SCOMAlert -Criteria "ResolutionState = 0 AND Severity NOT LIKE '%Information%' AND PrincipalName NOT LIKE '%.sysproza.net%'" | Group-Object MonitoringObjectId
    ForEach ($Alert in $AlertsByObject.GetEnumerator()) {
        $AlertsCount = $AlertsCount + $Alert.Count
    }

    $Bag.AddValue('AlertsCount', [System.Int32]$AlertsCount)
    #$API.LogScriptEvent("GetAzureAlertsCount.ps1",3281,0,"Get Azure Active Alerts Script is complete. Number of alerts is $AlertsCount")
    $Bag
}
Function EnvironmentAlertsCountRule {
    $ErrorActionPreference = 'Stop'
    Set-StrictMode -Version 2

    $SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
    $SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory “OperationsManager”

    Import-module $SCOMModulePath

    $API = New-Object -comObject 'MOM.ScriptAPI'
    $Bag = $API.CreatePropertyBag()

    #$API.LogScriptEvent("GetEnvironmentAlertsCount.ps1",3280,0,"Get Environment Active Alerts Script is starting")

    $AlertsCount = 0
    $AlertsByObject = Get-SCOMAlert -Criteria "ResolutionState = 0 AND Severity NOT LIKE '%Information%'" | Group-Object MonitoringObjectId
            ForEach ($Alert in $AlertsByObject.GetEnumerator()) {
              $AlertsCount = $AlertsCount + $Alert.Count
              }

    $Bag.AddValue('AlertsCount', [System.Int32]$AlertsCount)
    #$API.LogScriptEvent("GetEnvironmentAlertsCount.ps1",3281,0,"Get Environment Active Alerts Script is complete. Number of alerts is $AlertsCount")
    $Bag
}
Function UnhealthySystems_PowerShellGrid {
    $errorActionPreference = 'Stop'
    Set-StrictMode -Version 2

    $SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
    $SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory "OperationsManager"
    Import-module $SCOMModulePath

    $AlertsByObject = Get-SCOMAlert -Criteria "ResolutionState = 0" | Group-Object Severity
    $UnhealthySystems = $AlertsByObject.Group.PrincipalName | Select -Unique | Sort
    $ID = 0
    ForEach ($System in $UnhealthySystems) {
        $dataObject = $ScriptContext.CreateInstance("xsd://foo!bar/baz02")
        $dataObject["Id"]       = [String]($ID.ToString())
        $dataObject["Computer"] = [String]($System)
        $ScriptContext.ReturnCollection.Add($dataObject)
        $ID ++
    }
}
Function AlertSeverity_PowerShellGrid {
    $errorActionPreference = 'Stop'
    Set-StrictMode -Version 2

    $SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
    $SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory "OperationsManager"
    Import-module $SCOMModulePath

    $AlertsByObject = Get-SCOMAlert -Criteria "ResolutionState = 0" | Group-Object Severity
    $ID = 0
    ForEach ($AlertType in $AlertsByObject) {
        $dataObject = $ScriptContext.CreateInstance("xsd://foo!bar/baz01")
        $dataObject["Id"]       = [String]($ID.ToString())
        $dataObject["Severity"] = [String]($AlertType.Name)
        $dataObject["Count"]    = [String]($AlertType.Count)
        $ScriptContext.ReturnCollection.Add($dataObject)
        $ID ++
    }
}
Function NewestAlerts_PowerShellGrid {
    $errorActionPreference = 'Stop'
    Set-StrictMode -Version 2

    $SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
    $SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory "OperationsManager"
    Import-module $SCOMModulePath

    $Alerts = Get-SCOMAlert -Criteria "ResolutionState = 0" | Sort TimeRaised -Descending
    $MyAlerts = @()
    $ID = 0
    ForEach ($Alert in $Alerts) {
        $AlertDetails = New-Object PSObject -Property @{
            ID = $ID.ToString()
            Age = [String]"{0:HH:mm:ss}" -f ([datetime]((Get-Date)-$Alert.TimeRaised).Ticks)
            Severity = [String]($Alert.Severity)
            Computer = [String]($Alert.PrincipalName)
            Name = [String]($Alert.Name)
        }
        $MyAlerts = $MyAlerts + $AlertDetails
        $ID ++
    }
    $SCOMAlerts = $MyAlerts | Sort Age
    ForEach ($Alert in $SCOMAlerts) {
        $dataObject = $ScriptContext.CreateInstance("xsd://foo!bar/baz03")
        $dataObject["Id"]       = [String]($Alert.ID)
        $dataObject["Age"]      = [String]($Alert.Age)
        $dataObject["Severity"] = [String]($Alert.Severity)
        $dataObject["Computer"] = [String]($Alert.Computer)
        $dataObject["Name"]     = [String]($Alert.Name)
        $ScriptContext.ReturnCollection.Add($dataObject)
    }
}
Function Get-AzureAgentHealth {
$errorActionPreference = 'Stop'
Set-StrictMode -Version 2

$SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
$SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory “OperationsManager”
Import-module $SCOMModulePath

# set default counts as zero
$totalAgentCount = 0
$UnavailableAgentsCount = 0
$UnmonitoredAgentsCount = 0
$HealthyAgentsCount = 0
$CriticalAgentsCount = 0
$WarningAgentsCount = 0

# get the agent data and put it in a hash
$agents = Get-SCOMAgent | Where-Object {$_.DisplayName -like "*.sysprolive.cloud*" -or $_.DisplayName -like "*.dmc.cloud*"}
# if there's no agents, just simply set all counts to zero
if (!$agents)
{
	# do nothing, the counts will be zero as default
}
else
{
	$totalAgentCount = @($agents).Count

	#map to all agents table
	$allAgentsTable = @{}
	$agents | % {$allAgentsTable.Add($_.DisplayName, $_.HealthState)}
	
	#get the agent watcher class and heartbeat monitor
	$monitor = Get-SCOMMonitor -Name Microsoft.SystemCenter.HealthService.Heartbeat
	$monitorCollection = @($monitor)
	$monitorCollection = $monitorCollection -as [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitor[]]
	$watcherClass = Get-SCOMClass -Name Microsoft.SystemCenter.AgentWatcher
	$watcherInstances = @(Get-SCOMClassInstance -Class $watcherClass)

	#map to all heartbeat monitors table
	$allHeartbeatMonitorsTable = @{}
	$watcherInstances | % {$allHeartbeatMonitorsTable.Add($_.DisplayName, $_.GetMonitoringStates($monitorCollection)[0].HealthState.ToString())}

	#get agents count in different states
	foreach ($agent in $allAgentsTable.GetEnumerator())
	{
		# get count of healthy agents
		if ($agent.Value -eq 'Success' -and $allHeartbeatMonitorsTable[$agent.Name] -eq 'Success')
		{
			$HealthyAgentsCount++
		}
		# get count of warning agents
		elseif ($agent.Value -eq 'Warning' -and $allHeartbeatMonitorsTable[$agent.Name] -eq 'Success')
		{
			$WarningAgentsCount++
		}
		# get count of critical agents
		elseif ($agent.Value -eq 'Error' -and $allHeartbeatMonitorsTable[$agent.Name] -eq 'Success')
		{
			$CriticalAgentsCount++
		}
	}
	# get count of unmonitored agents
	$UnmonitoredAgentsCount = @($allAgentsTable.GetEnumerator() | ? {$_.Value -eq 'Uninitialized'}).Count
	# get count of unavailable agents
	$UnavailableAgentsCount = $totalAgentCount - $HealthyAgentsCount - $WarningAgentsCount - $CriticalAgentsCount - $UnmonitoredAgentsCount

	#check if the Unavailable agents count is negative
	if ($UnavailableAgentsCount -lt 0)
	{
		Write-EventLog -LogName "Operations Manager" -Source "Health Service Script" -EventId 21000 -EntryType Warning -Message "AgentStateRollup script detected the Uavailable agents count is negative, script interrupted, will wait for next execution"
		exit
	}
}
	
#add a helper class to get the localized display strings
$langClass = New-Module {

	$lang = (Get-Culture).ThreeLetterWindowsLanguageName
	$mp = Get-SCOMManagementPack -Name Syspro.SystemCenter.Azure.SummaryDashboard
	# Set localized language to ENU if the expected language is not found in MP
	try
	{
		$temp = $mp.GetDisplayString($lang)
	}
	catch [Microsoft.EnterpriseManagement.Common.ObjectNotFoundException]
	{
		$lang = "ENU"
	}

	function GetLocalizedDisplayString($elementId)
	{
		$mp.FindManagementPackElementByName($elementId).GetDisplayString($lang).Name
	}
	Export-ModuleMember -Variable * -Function *
} -asCustomObject

$api = New-Object -comObject 'MOM.ScriptAPI'
function AddPropertyBag ($Name, [System.Int32]$Value)
{
	if (!$Value) {$Value = 0}

	$bag = $api.CreateTypedPropertyBag(2)
	$bag.AddValue('AgentStates', $Name)
	$bag.AddValue('Value', $Value)
	$api.AddItem($bag)
	$bag
}

#create propertybags for output
AddPropertyBag $langClass.GetLocalizedDisplayString('HeathStateTotal') $totalAgentCount
AddPropertyBag $langClass.GetLocalizedDisplayString('HeathStateUninitialized') $UnavailableAgentsCount
AddPropertyBag $langClass.GetLocalizedDisplayString('HeathStateUnmonitored') $UnmonitoredAgentsCount
AddPropertyBag $langClass.GetLocalizedDisplayString('HeathStateSuccess') $HealthyAgentsCount
AddPropertyBag $langClass.GetLocalizedDisplayString('HeathStateError') $CriticalAgentsCount
AddPropertyBag $langClass.GetLocalizedDisplayString('HeathStateWarning') $WarningAgentsCount
}
Function Get-AzureActiveAlertsv2 {
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

$SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
$SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory “OperationsManager”

Import-module $SCOMModulePath

$API = New-Object -comObject 'MOM.ScriptAPI'
$Bag = $API.CreatePropertyBag()

#$API.LogScriptEvent("GetAzureAlertsCount.ps1",3280,0,"Get Azure Active Alerts Script is starting")

$AlertsCount = 0
$AlertsByObject = Get-SCOMAlert -ResolutionState 0 | Where-Object {$_.PrincipalName -like "*dmc.cloud*" -or $_.PrincipalName -like "*.sysprolive.cloud" -and $_.Severity -ne "Information"} | Group-Object MonitoringObjectId
ForEach ($Alert in $AlertsByObject.GetEnumerator()) {
$AlertsCount = $AlertsCount + $Alert.Count
}

$Bag.AddValue('AlertsCount', [System.Int32]$AlertsCount)
#$API.LogScriptEvent("GetAzureAlertsCount.ps1",3281,0,"Get Azure Active Alerts Script is complete. Number of alerts is $AlertsCount")
$Bag
}
Function Get-ActiveAlerts {
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

$SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
$SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory “OperationsManager”

Import-module $SCOMModulePath

$API = New-Object -comObject 'MOM.ScriptAPI'
$Bag = $API.CreatePropertyBag()

$AlertsCount = 0
$AlertsByObject = Get-SCOMAlert -ResolutionState 0 | Where-Object {$_.Severity -ne "Information"} | Group-Object MonitoringObjectId
ForEach ($Alert in $AlertsByObject.GetEnumerator()) {
$AlertsCount = $AlertsCount + $Alert.Count
}

$Bag.AddValue('AlertsCount', [System.Int32]$AlertsCount)
$Bag
}
Function RepeatAlerts_PowerShellGrid {
$AlertDateWeekBegin = [DateTime]::Today.AddDays(-7)
$AlertDateWeekEnd   = [DateTime]::Today.AddDays(-1).AddSeconds(86399)

$WeekAlerts = Get-SCOMAlert | Where-Object {$_.TimeRaised -gt $AlertDateWeekBegin -and $_.TimeRaised -lt $AlertDateWeekEnd -and $_.Severity -ne 0} | Group-Object Name | Sort -Descending Count | Select-Object -First 10
#$SortedAlerts = $WeekAlerts | Group-Object Name | Sort -Descending Count

$ID = 0
ForEach ($AlertCount in $WeekAlerts) {
    $dataObject = $ScriptContext.CreateInstance("xsd://foo!bar/baz")
    $dataObject["Id"]    = [String]($ID.ToString())
    $dataObject["Count"] = [String]($AlertCount.Count)
    $dataobject["Name"]  = [String]($AlertCount.Name)
    $ScriptContext.ReturnCollection.Add($dataObject)
    $ID ++
}
}
Function RepeatAlertsDetails_PowerShellGrid {
Param($globalSelectedItems)
 
$i = 1
ForEach ($globalSelectedItem in $globalSelectedItems) {
    
    $AlertDateWeekBegin = [DateTime]::Today.AddDays(-7)
    $AlertDateWeekEnd   = [DateTime]::Today.AddDays(-1).AddSeconds(86399)
    $WeekAlerts = Get-SCOMAlert | Where-Object {$_.TimeRaised -gt $AlertDateWeekBegin -and $_.TimeRaised -lt $AlertDateWeekEnd -and $_.Severity -ne 0 -and $_.Name -eq $globalSelectedItem["Name"]}
    ForEach ($relatedItem in $WeekAlerts) { 
        # Create the data object which will be the output for our dashboard.
        $dataObject                        = $ScriptContext.CreateInstance("xsd://foo!bar/baz1")
        $dataObject["Id"]                  = $i.ToString()
        $dataObject["Name"]                = [String]($relatedItem.PrincipalName)
        If ($relatedItem.ResolutionState -eq "255") { $dataObject["ResolutionState"] = "Closed" }
        Else { $dataObject["ResolutionState"] = "New" }
        $dataObject["LastModified"]        = [String]($relatedItem.LastModified)
    
        $ScriptContext.ReturnCollection.Add($dataObject) 
        $i++
    }
}
}
Function DiscoverAzureAgentConfiguration {
$errorActionPreference = 'Stop'
Set-StrictMode -Version 2

$SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
$SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory “OperationsManager”
Import-module $SCOMModulePath

# group agents by version and sort
$configurationGroups = Get-SCOMPendingManagement | Where-Object {$_.AgentName -like "*.dmc.cloud*" -or $_.AgentName -like "*.sysprolive.cloud*"} | group AgentPendingActionType
              
#add a helper class to get the localized display strings
$langClass = New-Module {            
    
	$lang = (Get-Culture).ThreeLetterWindowsLanguageName
	$mp = Get-SCOMManagementPack -Name  Syspro.SystemCenter.Azure.SummaryDashboard
	# Set localized language to ENU if the expected language is not found in MP
	try
	{
	$temp = $mp.GetDisplayString($lang)
	}
	catch [Microsoft.EnterpriseManagement.Common.ObjectNotFoundException]
	{
	$lang = "ENU"
	}

    function GetLocalizedDisplayString($elementId) 
	{            
        $localizedName = $mp.FindManagementPackElementByName($elementId).GetDisplayString($lang).Name
        if (!$localizedName) {$localizedName = $elementId}
        $localizedName
    }            
    Export-ModuleMember -Variable * -Function *                
} -asCustomObject 
            

$api = New-Object -comObject "MOM.ScriptAPI"
$discoveryData = $api.CreateDiscoveryData(0, "$MPElement$", "$Target/Id$")
              
if ($configurationGroups)
{
foreach ($configurationGroup in $configurationGroups)
{
    $instance = $discoveryData.CreateClassInstance("$MPElement[Name='Syspro.SystemCenter.AgentConfiguration']$")
    $localizedName = $langClass.GetLocalizedDisplayString($configurationGroup.Name)
    $instance.AddProperty("$MPElement[Name='Syspro.SystemCenter.AgentConfiguration']/Configuration$", $localizedName)
    $instance.AddProperty("$MPElement[Name='Syspro.SystemCenter.AgentConfiguration']/CountOfConfiguration$", $configurationGroup.Group.Count)

    $discoveryData.AddInstance($instance)
                 
}
}
else
{
    $instance = $discoveryData.CreateClassInstance("$MPElement[Name='Syspro.SystemCenter.AgentConfiguration']$")
    $localizedName = $langClass.GetLocalizedDisplayString("NoConfigurationData")
    $instance.AddProperty("$MPElement[Name='Syspro.SystemCenter.AgentConfiguration']/Configuration$", $localizedName)
    $discoveryData.AddInstance($instance)
}
$discoveryData
}
Function DiscoverAzureAgentVersions {
$errorActionPreference = 'Stop'
Set-StrictMode -Version 2

$SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
$SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory “OperationsManager”
Import-module $SCOMModulePath

# group agents by version and sort
$versionGroups = Get-SCOMAgent | Where-Object {$_.DisplayName -like "*.sysprolive.cloud*" -or $_.DisplayName -like "*.dmc.cloud*"} | group Version, PatchList.Value
              
#add a helper class to get the localized display strings
$langClass = New-Module {            
    
	$lang = (Get-Culture).ThreeLetterWindowsLanguageName
	$mp = Get-SCOMManagementPack -Name  Syspro.SystemCenter.Azure.SummaryDashboard
	# Set localized language to ENU if the expected language is not found in MP
	try
	{
	$temp = $mp.GetDisplayString($lang)
	}
	catch [Microsoft.EnterpriseManagement.Common.ObjectNotFoundException]
	{
	$lang = "ENU"
	}

    function GetLocalizedDisplayString($elementId) 
	{            
        $localizedName = $mp.FindManagementPackElementByName($elementId).GetDisplayString($lang).Name
        if (!$localizedName) {$localizedName = $elementId}
        $localizedName
    }            
    Export-ModuleMember -Variable * -Function *                
} -asCustomObject 

$api = New-Object -comObject "MOM.ScriptAPI"
$discoveryData = $api.CreateDiscoveryData(0, "$MPElement$", "$Target/Id$")

if ($versionGroups)
{
foreach ($versionGroup in $versionGroups)
{
    $name = $versionGroup.Values[0]
    if ($name.Trim() -eq '') {$name = $langClass.GetLocalizedDisplayString("NoVersionData")}
                  
    $instance = $discoveryData.CreateClassInstance("$MPElement[Name='Syspro.SystemCenter.AgentVersions']$")
    $instance.AddProperty("$MPElement[Name='Syspro.SystemCenter.AgentVersions']/Version$", $name)
    $instance.AddProperty("$MPElement[Name='Syspro.SystemCenter.AgentVersions']/CumulativeUpdate$", $versionGroup.Values[1])
    $instance.AddProperty("$MPElement[Name='Syspro.SystemCenter.AgentVersions']/CountOfVersion$", $versionGroup.Group.Count)

    $discoveryData.AddInstance($instance)
}
}
else
{
    $instance = $discoveryData.CreateClassInstance("$MPElement[Name='Syspro.SystemCenter.AgentVersions']$")
    $localizedName = $langClass.GetLocalizedDisplayString("NoAgentsFound")
	$instance.AddProperty("$MPElement[Name='Syspro.SystemCenter.AgentVersions']/CumulativeUpdate$", "")
    $instance.AddProperty("$MPElement[Name='Syspro.SystemCenter.AgentVersions']/Version$", $localizedName)
    $discoveryData.AddInstance($instance)
}
$discoveryData
}
Function Delete-Spot {
    If ($Host.Name -notlike '*ISE*') {
        $PShost = Get-Host
        $pswindow = $pshost.ui.rawui

        $x = [Console]::CursorLeft
        $y = [Console]::CursorTop
        [Console]::SetCursorPosition($x, $y)

        $CursorIndex = @('-', '\', '|', '/')
        If ($Global:CurrentSpot -eq $null)              { $Global:CurrentSpot = 0 }
        If ($Global:CurrentSpot -gt $CursorIndex.Count) { $Global:CurrentSpot = 0 }
        If ($Global:MilliCounter -eq $null)                  { $Global:MilliCounter = 0; $Global:SecondCounter = 0 }
        If ($Global:MilliCounter -gt 10)                     { $Global:MilliCounter = 0; $Global:SecondCounter ++ }
        Write-Host ("[" + ("{0:hh\:mm\:ss}" -f [TimeSpan]::FromSeconds((New-TimeSpan -Seconds $SecondCounter).TotalSeconds)) + "] " + $CursorIndex[$Global:CurrentSpot]) -ForegroundColor DarkGreen -NoNewline
        $Global:CurrentSpot ++
        $Global:MilliCounter ++
        [Console]::SetCursorPosition($x, $y)
        Write-Host "" -NoNewline
    }
}
Function Get-TotalTime {
    Param(
        [Parameter(Mandatory = $True,  Position = 1)]
        [DateTime] $StartTime, `
        [Parameter(Mandatory = $True,  Position = 2)]
        [DateTime] $EndTime)

    $Duration = New-TimeSpan -Start $StartTime -End $EndTime

    $TotalSeconds = $Duration.TotalSeconds
    $TimeSpan =  [TimeSpan]::FromSeconds($TotalSeconds)
    $ReturnVariable = ("{0:hh\:mm\:ss}" -f $TimeSpan)
    Return $ReturnVariable
}
Function Temp1 {
Function Update-Host {
    Param ([ValidateSet("Start","Stop")]$Action)

    Switch ($Action) {
        "Start" {
            Write-Host "Getting Updates - " -NoNewline
        }
        "Stop"  {
            Write-Host "Complete" -ForegroundColor Green
        }
    }
}
Function Build-Scripts {
$Approvals = @()
$Approvals += ,("Unapproved")
$Approvals += ,("Declined")
$Approvals += ,("Approved")
$Approvals += ,("AnyExceptDeclined")

$Classifications = @()
$Classifications += ,("All")
$Classifications += ,("Critical")
$Classifications += ,("Security")
$Classifications += ,("WSUS")

$Statuses = @()
$Statuses += ,("Needed")
$Statuses += ,("FailedOrNeeded")
$Statuses += ,("InstalledNotApplicableOrNoStatus")
$Statuses += ,("Failed")
$Statuses += ,("InstalledNotApplicable")
$Statuses += ,("NoStatus")
$Statuses += ,("Any")

$Scripts = @()
ForEach ($Approval in $Approvals) {
    ForEach ($Classification in $Classifications) {
        ForEach ($Status in $Statuses) {
            $Scripts += ,('Update-Host -Action Start; $AllUpdates += ,(Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval ' + $Approval + ' -Classification ' + $Classification + ' -Status ' + $Status + '); Update-Host -Action Stop')
        }
    }
}

    Return $Scripts
}
$AllUpdates = @()
$WSUSServer = Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530
$Scripts = Build-Scripts
For ($i = 0; $i -lt $Scripts.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Scripts.Count.ToString() + ' - ') -NoNewline
    Write-Host $Scripts[$i]
    # Invoke-Expression $Scripts[$i]
}
}
Function Temp2 {
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification All -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification All -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification All -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification All -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification All -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification All -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification All -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Critical -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Critical -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Critical -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Critical -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Critical -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Critical -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Critical -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Security -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Security -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Security -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Security -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Security -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Security -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Security -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification WSUS -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification WSUS -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification WSUS -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification WSUS -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification WSUS -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification WSUS -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification WSUS -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification All -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification All -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification All -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification All -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification All -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification All -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification All -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Critical -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Critical -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Critical -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Critical -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Critical -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Critical -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Critical -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Security -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Security -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Security -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Security -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Security -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Security -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Security -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification WSUS -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification WSUS -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification WSUS -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification WSUS -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification WSUS -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification WSUS -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification WSUS -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification All -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification All -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification All -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification All -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification All -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification All -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification All -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Critical -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Critical -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Critical -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Critical -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Critical -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Critical -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Critical -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Security -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Security -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Security -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Security -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Security -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Security -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Security -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification WSUS -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification WSUS -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification WSUS -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification WSUS -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification WSUS -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification WSUS -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification WSUS -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification All -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification All -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification All -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification All -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification All -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification All -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification All -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Critical -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Critical -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Critical -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Critical -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Critical -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Critical -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Critical -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Security -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Security -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Security -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Security -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Security -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Security -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Security -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification WSUS -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification WSUS -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification WSUS -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification WSUS -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification WSUS -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification WSUS -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification WSUS -Status Any
}
Function Temp3 {
$Approvals = @()
$Approvals += ,("Unapproved")
$Approvals += ,("Declined")
$Approvals += ,("Approved")
$Approvals += ,("AnyExceptDeclined")

$Classifications = @()
$Classifications += ,("All")
$Classifications += ,("Critical")
$Classifications += ,("Security")
$Classifications += ,("WSUS")

$Statuses = @()
$Statuses += ,("Needed")
$Statuses += ,("FailedOrNeeded")
$Statuses += ,("InstalledNotApplicableOrNoStatus")
$Statuses += ,("Failed")
$Statuses += ,("InstalledNotApplicable")
$Statuses += ,("NoStatus")
$Statuses += ,("Any")

$Scripts = @()
ForEach ($Approval in $Approvals) {
    ForEach ($Classification in $Classifications) {
        ForEach ($Status in $Statuses) {
            $Scripts += ,('Update-Host -Action Start; $AllUpdates += ,(Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval ' + $Approval + ' -Classification ' + $Classification + ' -Status ' + $Status + '); Update-Host -Action Stop')
        }
    }
}

$Scripts
}
Function Get-ConfigXML {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$False, Position=0)]
        [String] $XMLFilePath)
	
	If (Test-Path "$XMLFilePath") {
        Try {
			Write-Host " Loading Variable.xml... " -NoNewline
			$global:Variable = [XML](Get-Content "$XMLFilePath" -ErrorAction Stop)
			Write-Host -ForegroundColor 'Green' "Loaded"
			
			# Script Component Variables
			Write-Host -ForegroundColor 'Cyan' " Setting Component Variables" 
			$Components = $Variable.Test.Component | ForEach-Object {$_.Name}
			$Components | ForEach-Object {
				$Component = $_
				$Variable.Installer.Components.Component | Where-Object {$_.Name -eq $Component} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -ne $null} | ForEach-Object {
					Invoke-Expression ("`$Script:" + $_.Name + " = `"" + $_.Value + "`"")
				}
			}
		}
		Catch [system.exception] {
			$Validate = $false
			Write-Host -ForegroundColor 'Red' "Failed to read XML File Definitions for $xmlFileName" 
			Write-Host -ForegroundColor 'Red' "Error: $($_.Exception.Message)"
			Stop-Transcript
			Exit $ERRORLEVEL
		}
	}	
	Else {
		$Validate = $false
		Write-Host -ForegroundColor 'Red' "Unable to locate $xmlFileName"
		Stop-Transcript
		Exit $ERRORLEVEL
	}
}
Function Restart-HealthService {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Computer)

    $ErrorActionPreference = 'Stop'
    $WarningPreference     = 'SilentlyContinue'
    If ($Computer -eq "") {
        Restart-Service HealthService -Force
    }
    Else {
        Invoke-Command -ComputerName $Computer -ScriptBlock { Restart-Service HealthService -Force }
    }
}
Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)

    $ErrorActionPreference = "Stop"
    Try {
        If ($Text.Count -ne $ForegroundColor.Count) {
            Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $ForegroundColor.Count.ToString()) -ForegroundColor Red
            Throw
        }
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch { 
        Write-Host "Text Count:  " $Text.Count
        Write-Host "Color Count: " $Color.Count
        Write-Host $_
    }
}
Function MaintenanceMode {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$True, Position=2)][ValidateSet(“Start”,”Stop”)]
        [String] $Action)

    $Instance = Get-SCOMClassInstance -Name $Server
   
    Switch ($Action) {
        "Start" {
            Write-Color -Text "Starting Maintenance mode for ", $Server.ToUpper(), " - " -ForegroundColor White, Yellow, White -NoNewLine
                $Time = ((Get-Date).AddMinutes(30))
                Start-SCOMMaintenanceMode -Instance $Instance -EndTime $Time -Reason PlannedApplicationMaintenance -Comment ("Clearing SCOM Cache. " + $env:USERNAME) -ErrorAction Continue
            Write-Color -Text "Complete" -ForegroundColor Green
        }
        "Stop" {
            Write-Color -Text "Stopping Maintenance mode for ", $Server.ToUpper(), " - " -ForegroundColor White, Yellow, White -NoNewLine
                $MMEntry = Get-SCOMMaintenanceMode -Instance $Instance
                $NewEndTime = (Get-Date).addMinutes(0)
                Set-SCOMMaintenanceMode -MaintenanceModeEntry $MMEntry -EndTime $NewEndTime -Comment ("Clearing SCOM Cache. " + $env:USERNAME)
            Write-Color -Text "Complete" -ForegroundColor Green
        }
    }

    
}
Function Clear-Health {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $AgentPath)
    
    Try {
        Write-Color -Text "Processing ", $Server, " - " -ForegroundColor White, Yellow, White -NoNewLine
            Invoke-Command -Session (New-PSSession -ComputerName $Server) -ArgumentList $AgentPath -ScriptBlock {Param($AgentPath); Stop-Service HealthService -Force -Confirm:$false -ErrorAction Stop; Remove-Item $AgentPath -Recurse -Force -ErrorAction Stop; Start-Service HealthService -ErrorAction Stop}
        Write-Color -Text "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }
}
function New-SWRandomPassword {
    <#
    .Synopsis
       Generates one or more complex passwords designed to fulfill the requirements for Active Directory
    .DESCRIPTION
       Generates one or more complex passwords designed to fulfill the requirements for Active Directory
    .EXAMPLE
       New-SWRandomPassword
       C&3SX6Kn

       Will generate one password with a length between 8  and 12 chars.
    .EXAMPLE
       New-SWRandomPassword -MinPasswordLength 8 -MaxPasswordLength 12 -Count 4
       7d&5cnaB
       !Bh776T"Fw
       9"C"RxKcY
       %mtM7#9LQ9h

       Will generate four passwords, each with a length of between 8 and 12 chars.
    .EXAMPLE
       New-SWRandomPassword -InputStrings abc, ABC, 123 -PasswordLength 4
       3ABa

       Generates a password with a length of 4 containing atleast one char from each InputString
    .EXAMPLE
       New-SWRandomPassword -InputStrings abc, ABC, 123 -PasswordLength 4 -FirstChar abcdefghijkmnpqrstuvwxyzABCEFGHJKLMNPQRSTUVWXYZ
       3ABa

       Generates a password with a length of 4 containing atleast one char from each InputString that will start with a letter from 
       the string specified with the parameter FirstChar
    .OUTPUTS
       [String]
    .NOTES
       Written by Simon Wåhlin, blog.simonw.se
       I take no responsibility for any issues caused by this script.
    .FUNCTIONALITY
       Generates random passwords
    .LINK
       http://blog.simonw.se/powershell-generating-random-password-for-active-directory/
   
    #>
    [CmdletBinding(DefaultParameterSetName='FixedLength',ConfirmImpact='None')]
    [OutputType([String])]
    Param
    (
        # Specifies minimum password length
        [Parameter(Mandatory=$false,
                   ParameterSetName='RandomLength')]
        [ValidateScript({$_ -gt 0})]
        [Alias('Min')] 
        [int]$MinPasswordLength = 8,
        
        # Specifies maximum password length
        [Parameter(Mandatory=$false,
                   ParameterSetName='RandomLength')]
        [ValidateScript({
                if($_ -ge $MinPasswordLength){$true}
                else{Throw 'Max value cannot be lesser than min value.'}})]
        [Alias('Max')]
        [int]$MaxPasswordLength = 12,

        # Specifies a fixed password length
        [Parameter(Mandatory=$false,
                   ParameterSetName='FixedLength')]
        [ValidateRange(1,2147483647)]
        [int]$PasswordLength = 8,
        
        # Specifies an array of strings containing charactergroups from which the password will be generated.
        # At least one char from each group (string) will be used.
        [String[]]$InputStrings = @('abcdefghijkmnpqrstuvwxyz', 'ABCEFGHJKLMNPQRSTUVWXYZ', '23456789', '!"#%&'),

        # Specifies a string containing a character group from which the first character in the password will be generated.
        # Useful for systems which requires first char in password to be alphabetic.
        [String] $FirstChar,
        
        # Specifies number of passwords to generate.
        [ValidateRange(1,2147483647)]
        [int]$Count = 1
    )
    Begin {
        Function Get-Seed{
            # Generate a seed for randomization
            $RandomBytes = New-Object -TypeName 'System.Byte[]' 4
            $Random = New-Object -TypeName 'System.Security.Cryptography.RNGCryptoServiceProvider'
            $Random.GetBytes($RandomBytes)
            [BitConverter]::ToUInt32($RandomBytes, 0)
        }
    }
    Process {
        For($iteration = 1;$iteration -le $Count; $iteration++){
            $Password = @{}
            # Create char arrays containing groups of possible chars
            [char[][]]$CharGroups = $InputStrings

            # Create char array containing all chars
            $AllChars = $CharGroups | ForEach-Object {[Char[]]$_}

            # Set password length
            if($PSCmdlet.ParameterSetName -eq 'RandomLength')
            {
                if($MinPasswordLength -eq $MaxPasswordLength) {
                    # If password length is set, use set length
                    $PasswordLength = $MinPasswordLength
                }
                else {
                    # Otherwise randomize password length
                    $PasswordLength = ((Get-Seed) % ($MaxPasswordLength + 1 - $MinPasswordLength)) + $MinPasswordLength
                }
            }

            # If FirstChar is defined, randomize first char in password from that string.
            if($PSBoundParameters.ContainsKey('FirstChar')){
                $Password.Add(0,$FirstChar[((Get-Seed) % $FirstChar.Length)])
            }
            # Randomize one char from each group
            Foreach($Group in $CharGroups) {
                if($Password.Count -lt $PasswordLength) {
                    $Index = Get-Seed
                    While ($Password.ContainsKey($Index)){
                        $Index = Get-Seed                        
                    }
                    $Password.Add($Index,$Group[((Get-Seed) % $Group.Count)])
                }
            }

            # Fill out with chars from $AllChars
            for($i=$Password.Count;$i -lt $PasswordLength;$i++) {
                $Index = Get-Seed
                While ($Password.ContainsKey($Index)){
                    $Index = Get-Seed                        
                }
                $Password.Add($Index,$AllChars[((Get-Seed) % $AllChars.Count)])
            }
            Write-Output -InputObject $(-join ($Password.GetEnumerator() | Sort-Object -Property Name | Select-Object -ExpandProperty Value))
        }
    }
}
Function RemoveMG {
    Param ($Server)

    $ErrorActionPreference = "Stop"
    
    Write-Host "Entering PSSession - " -NoNewline
    Invoke-Command -Session (New-PSSession -ComputerName $Server) -ScriptBlock {
    #Enter-PSSession -ComputerName $Server
    Write-Host "Complete" -ForegroundColor Green

    Write-Host "Creating COM object - " -NoNewline
    $SCOMAgent = New-Object -ComObject "AgentConfigManager.MgmtSvcCfg"
    Write-Host "Complete"

    Write-Host "Disabling Active Directory Integration - " -NoNewline
    $SCOMAgent.DisableActiveDirectoryIntegration()
    Write-Host "Complete"

    Write-Host "Current Management Groups - "
    $SCOMAgent.GetManagementGroups()
    Write-Host "Complete"

    Write-Host "Getting SYSPRO-JHB - " -NoNewline
    $OldManagementGroup = $SCOMAgent.GetManagementGroups() | Where-Object {$_.ManagementGroupName -like "*syspro-jhb*"}
    If (!($OldManagementGroup -eq $null -or $OldManagementGroup -eq "")) {
        Write-Host "Complete"
        Write-Host "Removing Group" -NoNewline
        $SCOMAgent.RemoveManagementGroup($OldManagementGroup.managementGroupName.ToString())
        Write-Host "Complete"
        Write-Host "Restarting HealthService - " -NoNewline
        Restart-Service HealthService
        Write-Host "Complete"
    }
    Else {
        Write-Host "Not Found" -ForegroundColor Red
    }
    Write-Host "Getting Management Groups - " -NoNewline
    $SCOMAgent.GetManagementGroups()
    Write-Host "Complete"
    Write-Host "Exiting PS Session - " -NoNewline
    }
    Write-Host "Complete"
}
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
    Catch { 
        Write-Host "Text Count:  " $Text.Count
        Write-Host "Color Count: " $Color.Count
        Write-Host $_
    }
}
Function Refresh-FailOverCluster {
    Param (
        [Parameter(Mandatory=$False, Position=1)] 
        [String[]] $ClusterName)

    Try { Import-Module FailoverClusters }
    Catch { $_; Return $False }
    If ($ClusterName -eq $null -or $ClusterName -eq "") {
        [String[]] $ClusterName = Get-Cluster -Domain $Env:USERDOMAIN
    }
    For ($ClusterIndex = 0; $ClusterIndex -lt $ClusterName.Count; $ClusterIndex ++) {
        Write-Color -Text ($ClusterIndex + 1), "/", $ClusterName.Count, " - Updating ", $ClusterName, " configuration" -Color Cyan, Cyan, Cyan, White, Yellow, White
        Get-ClusterResource -Cluster $ClusterName[$ClusterIndex] | Where-Object {$_.ResourceType.Name -eq 'Virtual Machine Configuration'} | Update-ClusterVirtualMachineConfiguration
    }
}
Function Refresh-SCVMMHostsAndVMs {
    Try { Import-Module VirtualMachineManager }
    Catch { $_; Return $False }

    Try {
        Write-Color "Collecting SCVMM Hosts - " -Color White -NoNewLine
        $SCVMMHosts = Get-SCVMHost
        Write-Color $SCVMMHosts.Count, " found" -Color Yellow, White
    }
    Catch {
        Write-Color "Failed - ", $_ -Color Red, Red
    }
    
    For ($HostIndex = 0; $HostIndex -lt $SCVMMHosts.Count; $HostIndex ++) {
        Try {
            Write-Color -Text ($HostIndex + 1), "/", $SCVMMHosts.Count, " - Refreshing ", $SCVMMHosts[$HostIndex].Name, " - " -Color Cyan, Cyan, Cyan, White, Yellow, White -NoNewLine
            Read-SCVMHost -VMHost $SCVMMHosts[$HostIndex] | Out-Null
            Write-Color -Text "Complete" -Color Green
        
            Write-Color -Text ($HostIndex + 1), "/", $SCVMMHosts.Count, " - Collecting VMs on  ", $SCVMMHosts[$HostIndex].Name, " - " -Color Cyan, Cyan, Cyan, White, Yellow, White -NoNewLine
            $SCVMMHostVMS = Get-SCVirtualMachine -VMHost $SCVMMHosts[$HostIndex]
            Write-Color -Text $SCVMMHostsVMS.Count, " found" -Color Yellow, White
            For ($VMIndex = 0; $VMIndex -lt $SCVMMHostVMS.Count; $VMIndex ++) {
                Try {
                    Write-Color ($HostIndex + 1), "/", $SCVMMHosts.Count, " - ", ($VMIndex + 1), "/", $SCVMMHostVMS.Count, " - Refreshing ", $SCVMMHostVMS[$VMIndex].Name, " - " -Color Cyan, Cyan, Cyan, White, Cyan, Cyan, Cyan, White, Yellow, White -NoNewLine
                    Read-SCVirtualMachine -VM $SCVMMHostVMS[$VMIndex] | Out-Null
                    Write-Color "Complete" -Color Green
                }
                Catch {
                    Write-Color "Failed - ", $_ -Color Red, Red
                }
            }
        }
        Catch {
            Write-Color "Failed - ", $_ -Color Red, Red 
        }
    }
}
Function Recover-Services {
    Param (
        [Parameter(Mandatory=$True, Position=0)]
        [String] $Server)

    Write-Host "Getting Automatic Services that are stopped - " -NoNewline
    Try {
        $Services = Get-WmiObject -Query "Select * from Win32_Service where startmode = 'auto' and state <> 'Running'" -ComputerName $Server -ErrorAction Stop
        Write-Host ($Services.Count.ToString() + " Found")
    }
    Catch {
        Write-Host "0 Found" -ForegroundColor Green
        Return
    }
    For ($i = 0; $i -lt $Services.Count; $i ++) {
        Write-Host (($i + 1).ToString() + '/' + $Services.Count.ToString() + ' Starting ' + $Services[$i].DisplayName + ' - ') -NoNewline
        Invoke-Command -ComputerName $Server -ArgumentList $Services[0] -ScriptBlock { Param ($Service); Start-Service $Service.Name }
        Write-Host "Complete"
    }
}
Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)

    $ErrorActionPreference = "Stop"
    Try {
        If ($Text.Count -ne $ForegroundColor.Count) {
            Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $ForegroundColor.Count.ToString()) -ForegroundColor Red
            Throw
        }
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch { 
        Write-Host "Text Count:  " $Text.Count
        Write-Host "Color Count: " $ForegroundColor.Count
        Write-Host $_
    }
}
Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)

    $ErrorActionPreference = "Stop"
    Try {
        If ($Text.Count -ne $ForegroundColor.Count) {
            Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $ForegroundColor.Count.ToString()) -ForegroundColor Red
            Throw
        }
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch { 
        Write-Host "Text Count:  " $Text.Count
        Write-Host "Color Count: " $ForegroundColor.Count
        Write-Host $_
    }
}
Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)

    $ErrorActionPreference = "Stop"
    Try {
        If ($Text.Count -ne $ForegroundColor.Count) {
            Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $ForegroundColor.Count.ToString()) -ForegroundColor Red
            Throw
        }
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch { 
        Write-Host "Text Count:  " $Text.Count
        Write-Host "Color Count: " $ForegroundColor.Count
        Write-Host $_
    }
}
Function Create-Script {
    Param (
        [Parameter(Mandatory=$True,  Position=1)][ValidateSet("New-DC", "Join-Domain")]
        [String] $Script)

   Switch ($Script) {
        "New-DC" {
            Write-Color -Text "Checking if ", $NewDCScriptFilePath, " exists - " -ForegroundColor White, Yellow, White -NoNewLine
            If (Test-Path $NewDCScriptFilePath) { 
                Write-Color -Text "Removing", " - " -ForegroundColor DarkCyan, White -NoNewLine
                Remove-Item $NewDCScriptFilePath 
            }
            Write-Color -Text "Complete" -ForegroundColor Green
            Write-Color -Text "Creating and exporting ", $NewDCScriptFile, " - " -ForegroundColor White, Yellow, White -NoNewLine
            @(
                '$ADRoles = @()'
                '$ADRoles += ,("RSAT-ADDS-Tools")'
                '$ADRoles += ,("RSAT-ADDS")'
                '$ADRoles += ,("AD-Domain-Services")'
                '$ADRoles += ,("RSAT-AD-Tools")'
                '$ADRoles += ,("GPMC")'
                '$ADRoles += ,("RSAT-AD-AdminCenter")'
                '$ADRoles += ,("RSAT-AD-PowerShell")'
                '$ADRoles += ,("RSAT-DNS-Server")'
                '$ADRoles += ,("DNS")'
                'Get-WindowsFeature $ADRoles | Install-WindowsFeature'
                '$securePW = ConvertTo-SecureString "' + $SafeModeAdminPassword + '" -AsPlainText -Force'
                'Import-Module ADDSDeployment'
                'Install-ADDSForest `'
                '-DatabasePath "C:\Windows\NTDS" `'
                '-DomainMode "Win2012" `'
                '-DomainName "' + $DomainDNSName + '" `'
                '-DomainNetBIOSName "' + $DomainNETBIOSName + '" `'
                '-ForestMode "Win2012" `'
                '-InstallDNS:$true `'
                '-LogPath "C:\Windows\NTDS" `'
                '-NoRebootOnCompletion:$false `'
                '-SYSVOLPath "C:\Windows\SYSVOL" `'
                '-SafeModeAdministratorPassword $securePW `'
                '-Force:$true'
                'Restart-Computer -Force') | Out-File $NewDCScriptFilePath -Encoding ascii -Force -NoClobber
            Write-Color -Text "Complete" -ForegroundColor Green
            Write-Color -Text "Uploading ", $NewDCScriptFilePath, " to Azure Storage Container ", "scripts", " - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine
            Set-AzureStorageBlobContent -Container 'scripts' -File $NewDCScriptFilePath | Out-Null
            Write-Color -Text "Complete" -ForegroundColor Green
        }
        "Join-Domain" {
            Write-Color -Text "Checking if ", $JoinDomainScriptFilePath, " exists - " -ForegroundColor White, Yellow, White -NoNewLine
            If (Test-Path $JoinDomainScriptFilePath) { 
                Write-Color -Text "Removing", " - " -ForegroundColor DarkCyan, White -NoNewLine
                Remove-Item $JoinDomainScriptFilePath 
            }
            Write-Color -Text "Complete" -ForegroundColor Green
            Write-Color -Text "Creating and exporting ", $JoinDomainScriptFile, " - " -ForegroundColor White, Yellow, White -NoNewLine
            @(
                'Set-DnsClientServerAddress -InterfaceIndex ((Get-NetAdapter).ifindex) -ServerAddresses ' + $ADPrivateIP
                'Add-Computer -Domain ' + $DomainDNSName + ' -Credential (New-Object PSCredential("TestUser01", (ConvertTo-SecureString -String "TestUser0001" -AsPlainText -Force)))'
                'Restart-Computer') | Out-File $JoinDomainScriptFilePath -Encoding ascii -Force -NoClobber
            Write-Color -Text "Complete" -ForegroundColor Green
            Write-Color -Text "Uploading ", $JoinDomainScriptFilePath, " to Azure Storage Container ", "scripts", " - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine
            Set-AzureStorageBlobContent -Container 'scripts' -File $JoinDomainScriptFilePath | Out-Null
            Write-Color -Text "Complete" -ForegroundColor Green
        }
    }
}
Function Global-Variables {
    Write-Color -Text "Defining ", "Global", " variables - " -ForegroundColor White, DarkCyan, White -NoNewLine
    $global:locName                  = 'West Europe'
    $global:rgName                   = 'PSTesting01'
    $global:virtNetwork              = 'PSTestingVnet01'
    $global:stName                   = 'pstestingstorage01'
    $global:NewVM                    = $null
    $global:SubscriptionName         = 'Henri Borsboom'
    $global:SubscriptionId           = '859fc944-4695-445e-b779-791416c71e1b'
    $global:DomainDNSName            = "lab.local"
    $global:DomainNETBIOSName        = "lab"
    $global:SafeModeAdminPassword    = "P@ssw0rd"
    $global:NewDCScriptFilePath      = "$env:TEMP\New-DC.ps1"
    $global:NewDCScriptFile          = "New-DC.ps1"
    $global:JoinDomainScriptFilePath = "$env:TEMP\Join-Domain.ps1"
    $global:JoinDomainScriptFile     = "Join-Domain.ps1"
    $Global:VMRole                   = @{}
    $global:cred                     = New-Object PSCredential("TestUser01", (ConvertTo-SecureString -String "TestUser0001" -AsPlainText -Force))
    $global:stType                   = 'Standard_LRS'
    $global:stPermissions            = 'Off'
    $global:vnetSubnetName           = 'singleSubnet'
    $global:vnetSubnetAddressPrefix  = '10.0.0.0/24'
    $global:vnetAddressPrefix        = '10.0.0.0/16'
    $global:vmDiskOSCreateOption     = 'FromImage'
    $global:vmIPAllocationMethod     = 'Dynamic'
    $global:vmDiskDataCaching        = 'None'
    $global:vmDiskDataSize           = 10
    $global:vmSize                   = 'Standard_A1'
    Write-Color -Text "Complete" -ForegroundColor Green
}
Function VMs-To-Deploy {
    Write-Color -Text "Defining ", "Virtual Machines", " to deploy - " -ForegroundColor White, DarkCyan, White -NoNewLine
    $VMRole.Add("Domain Controller", "ADDC1")
    $VMRole.Add("SQL",               "SQL01")
    Write-Color -Text "Complete" -ForegroundColor Green
}
Function Configure-Azure-Deployments {
    Write-Color -Text "Adding ", "Azure RM Account", " - " -ForegroundColor White, Yellow, White -NoNewLine
        Add-AzureRmAccount -Credential $Creds -SubscriptionId $SubscriptionId | Out-Null
    Write-Color -Text "Complete" -ForegroundColor Green

    Write-Color -Text "Creating Resource Group: ", $rgName, " in Location: ", $locName, " - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine
        New-AzureRmResourceGroup -Name $rgName -Location $locName | Out-Null
    Write-Color -Text "Complete" -ForegroundColor Green

    Write-Color -Text "Creating Storage Account: ", $stName, " of Type: ", $stType, " in Resource Group: ", $rgName, " - " -ForegroundColor White, Yellow, White, Yellow, White, Yellow, White -NoNewLine
        $storageAcc = New-AzureRmStorageAccount -ResourceGroupName $rgName -Name $stName -Type $stType -Location $locName
    Write-Color -Text "Complete" -ForegroundColor Green
    
    Write-Color -Text "Setting current storage account to ", $stName, " in Resource Group: ", $rgName, " - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine
        Set-AzureRmCurrentStorageAccount -StorageAccountName $stName -ResourceGroupName $rgName | Out-Null
    Write-Color -Text "Complete" -ForegroundColor Green
    
    Write-Color -Text "Creating ", "scripts", " container on storage with Permissions set to ", $stPermissions, " - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine
        New-AzureStorageContainer -Name 'scripts' -Permission $stPermissions | Out-Null
    Write-Color -Text "Complete" -ForegroundColor Green

    Write-Color -Text "Creating Virtual Network Subnet: ", $vnetSubnetName, " with Address Prefix: ", $vnetSubnetAddressPrefix, " - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine
        $singleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $vnetSubnetName -AddressPrefix $vnetSubnetAddressPrefix
    Write-Color -Text "Complete" -ForegroundColor Green
    
    Write-Color -Text "Creating Virtual Network: ", $virtNetwork, " in Resource Group: ", $rgName, " in Location: ", $locName, " with Address Prefix: ", $vnetAddressPrefix, " with Subnet: ", $vnetSubnetName ," - " -ForegroundColor White, Yellow, White, Yellow, White, Yellow, White, Yellow, White, Yellow, White -NoNewLine
        $global:vnet = New-AzureRmVirtualNetwork -Name $virtNetwork -ResourceGroupName $rgName -Location $locName -AddressPrefix $vnetAddressPrefix -Subnet $singleSubnet
    Write-Color -Text "Complete" -ForegroundColor Green

    $VMConfig = @()
    ForEach ($NewVM in $VMRole.GetEnumerator()) {
        Write-Color -Text "Creating Public IP Address Name: ", ($NewVM.Value + "-IP1"), " for VM: ", $NewVM.Value, " With Allocation Method: ", $vmIPAllocationMethod," - " -ForegroundColor White, Yellow, White, Yellow, White, Yellow, White -NoNewLine
            $pip = New-AzureRmPublicIpAddress -Name ($NewVM.Value + "-IP1") -ResourceGroupName $rgName -Location $locName -AllocationMethod $vmIPAllocationMethod
        Write-Color -Text "Complete" -ForegroundColor Green

        Write-Color -Text "Creating NIC Name: ", ($NewVM.Value + "-NIC1"), " for VM: ", $NewVM.Value, " - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine
            $nic = New-AzureRmNetworkInterface -Name ($NewVM.Value + "-NIC1") -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id
            If ($NewVM.Name -eq 'Domain Controller') {
                $global:ADNIC = $nic
            }
        Write-Color -Text "Complete" -ForegroundColor Green

        Write-Color -Text "Creating VM Config for the ", $NewVM.Name, " with VM Name: ", $NewVM.Value, " and Size: ", $vmSize, " - " -ForegroundColor White, Yellow, White, Yellow, White, Yellow, White -NoNewLine
            $vm = New-AzureRmVMConfig -VMName $NewVM.Value -VMSize $vmSize
        Write-Color -Text "Complete" -ForegroundColor Green

        Write-Color -Text "Setting Operating system on VM to ", "Windows", "for VM: ", $NewVM.Value, " - " -ForegroundColor White, DarkCyan, White, Yellow, White -NoNewLine
            $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $NewVM.Value -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
        Write-Color -Text "Complete" -ForegroundColor Green

        If ($NewVM.Name -eq 'SQL') {
            Write-Color -Text "Setting Source Image Publisher: ", "MicrosoftSQLServer", " with Offer: ", "SQL2014SP2-WS2012R2", " and Edition: ", "Standard", " - " -ForegroundColor White, DarkCyan, White, DarkCyan, White, DarkCyan, White -NoNewLine
                $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftSQLServer -Offer SQL2014SP2-WS2012R2 -Skus Standard -Version "latest"
            Write-Color -Text "Complete" -ForegroundColor Green

            Write-Color -Text "Setting Data Disk: ", "windowsvmdatadisk", " for VM: ", $NewVM.Value, " with Create Option: ", "Empty", " and Caching: ", $vmDiskDataCaching, " and Size: ", $vmDiskDataSize, " GB - " -ForegroundColor White, DarkCyan, White, Yellow, White, DarkCyan, White, Yellow, White, Yellow, White -NoNewLine
                $DataDiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + ("vhds/WindowsVMDataDisk" + $NewVM.Value + ".vhd")
                $vm = Add-AzureRmVMDataDisk -VM $vm -Name "windowsvmdatadisk" -VhdUri $DataDiskUri -CreateOption Empty -Caching $vmDiskDataCaching -DiskSizeInGB $vmDiskDataSize -Lun 0
            Write-Color -Text "Complete" -ForegroundColor Green
        }
        Else {
            Write-Color -Text "Setting Source Image Publisher: ", "MicrosoftWindowsServer", " with Offer: ", "WindowsServer", " and Edition: ", "2012-R2-Datacenter", " - " -ForegroundColor White, DarkCyan, White, DarkCyan, White, DarkCyan, White -NoNewLine
                $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"
            Write-Color -Text "Complete" -ForegroundColor Green
        }

        Write-Color -Text "Adding NIC to VM: ", $NewVM.Value, " and NIC ID: ", $nic.ID, " - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine
            $vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
        Write-Color -Text "Complete" -ForegroundColor Green

        Write-Color -Text "Setting OS Disk: ", "windowsvmosdisk", " for VM: ", $NewVM.Value, " with Create Option: ", $vmDiskOSCreateOption, " - " -ForegroundColor White, DarkCyan, White, Yellow, White, Yellow, White -NoNewLine
            $osDiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + ("vhds/WindowsVMosDisk" + $NewVM.Value + ".vhd")
            $vm = Set-AzureRmVMOSDisk -VM $vm -Name "windowsvmosdisk" -VhdUri $osDiskUri -CreateOption $vmDiskOSCreateOption
        Write-Color -Text "Complete" -ForegroundColor Green
            
        $VMConfig += ,($vm)
    }
    Return $VMConfig
}
Function Deploy-To-Azure {
    Param (
        [Parameter(Mandatory=$True,  Position=1)]
        [Object[]] $VMConfig)

    ForEach ($DeployVM in $VMConfig) {
        Write-Color -Text "Deploying Virtual Machine: ", $DeployVM.Name, " - " -ForegroundColor White, Yellow, White -NoNewLine
            New-AzureRmVM -ResourceGroupName $rgName -Location $locName -VM $DeployVM | Out-Null
        Write-Color -Text "Complete" -ForegroundColor Green
        If ($DeployVM.Name -eq $VMRole.'Domain Controller') {
            Create-Script -Script New-DC
            
            Write-Color -Text "Deploying ", "Custom Script Extension", " with Name: ", "New-DC", " and FileName: ", $NewDCScriptFile, " to the ", "Domain Controller", " - " -ForegroundColor White, DarkCyan, White, DarkCyan, White, Yellow, White, DarkCyan, White -NoNewLine
                Set-AzureRmVMCustomScriptExtension -Location $locName -Name "New-DC" -VMName $DeployVM.Name -ResourceGroupName $rgName -FileName $NewDCScriptFile -ContainerName "scripts" -StorageAccountName $stName -Run ('.\' + $NewDCScriptFile) | Out-Null
            Write-Color -Text "Complete" -ForegroundColor Green
        }
        Else {
            Write-Color -Text "Getting the Private IP Address of the ", "Domain Controller", " - " -ForegroundColor White, DarkCyan, White -NoNewLine
                $Global:ADPrivateIP = (Get-AzureRmNetworkInterfaceIpConfig -NetworkInterface $ADNIC).PrivateIpAddress
            Write-Color -Text "Complete" -ForegroundColor Green

            Create-Script -Script Join-Domain
            
            Write-Color -Text "Deploying ", "Custom Script Extension", " with Name: ", "Join-Domain", " and FileName: ", $JoinDomainScriptFile, " to VM: ", $DeployVM.Name, " - " -ForegroundColor White, DarkCyan, White, DarkCyan, White, Yellow, White, Yellow, White -NoNewLine
                Set-AzureRmVMCustomScriptExtension -Location $locName -Name "Join-Domain" -VMName $DeployVM.Name -ResourceGroupName $rgName -FileName $JoinDomainScriptFile -ContainerName "scripts" -StorageAccountName $stName -Run ('.\' + $JoinDomainScriptFile) | Out-Null
            Write-Color -Text "Complete" -ForegroundColor Green
        }
    }
}
Function Start-Jobs {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet("TargetOnly","ArgumentsOnly","Both")]
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
        [Int32]    $MaximumJobs=$env:NUMBER_OF_PROCESSORS)

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
    $Jobs = @()
    
    Switch ($ReportImmediate) {
        $True { Write-Color -Text "Starting Jobs for ", $Targets.Count, " targets.", " Please wait for the results." -Color White, Cyan, White, Yellow }
    }
    ForEach ($Target in $Targets) {
        Switch ($ReportImmediate) {
            $False { Write-Color -Text "Starting Job for ", $Target -Color White, Yellow }
        }
        Switch ($PassTargetToScriptBlock) {
            "TargetOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Target)}
            "ArgumentsOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ScriptBlockArguments)}
            "Both" {
                $Arguments = @()
                $Arguments = $Arguments + $Target
                ForEach ($ScriptBlockArgument in $ScriptBlockArguments) {
                    $Arguments = $Arguments + $ScriptBlockArgument
                }
                $Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Arguments)}
        }
        $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})

        While ($RunningJobs.Count -ge $MaximumJobs) {
            $FinishedJobs = Wait-Job -Job $Jobs -Any
            Switch ($ReportImmediate) {
                $True {
                    $CompletedJobs = @($Jobs | Where {$_.HasMoreData -eq "True"})
                    ForEach ($CompleteJob in $CompletedJobs) {
                        Receive-Job $CompleteJob
                    }
                }
            }
            $RunningJobs  = @($Jobs | Where-Object {$_.State -eq 'Running'})
        }
    }
    Wait-Job -Job $Jobs | Out-Null
    $FailedJobs = @($Jobs | Where-Object {$_.State -eq 'Failed'})
    If ($FailedJobs.Count -gt 0) {
        ForEach ($FailedJob in $FailedJobs) {
            $FailedJob.ChildJobs[0].JobStateInfo.Reason.Message
        }
    }
    $JobResults = @()
    Switch ($ReportImmediate) {
        $False {
            ForEach ($Job in $Jobs) {
                $JobResults = $JobResults + (Receive-Job $Job)
            }
        }
    }
    Get-Job | Wait-Job | Remove-Job
    Return $JobResults
}
Function Get-DomainComputers {
    Param (
        [Parameter(Mandatory = $False,  Position = 1)]
        [String] $Domain = $env:USERDOMAIN)

    Import-Module ActiveDirectory
    $Servers = Get-ADComputer -Filter { ObjectClass -eq "computer" }
    $Servers = $Servers | Sort Name
    $Servers = $Servers.Name

    Return $Servers    
}
Function DiskSizes {
<#
Param (
    [Parameter(Mandatory=$True, Position=1)]
    [String] $Computer, `
    [Parameter(Mandatory=$false, Position=1)]
    [Switch] $Raw)
#>
Function Test-Online {
    Param (
        [Parameter(Mandatory=$True,  Position=1)]
        [String] $Computer)

    If (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
        Return $True
    }
    Else {
        Return $False
    }
}
Function Get-DiskSize {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Computer, `
        [Parameter(Mandatory=$false, Position=1)]
        [Switch] $Raw)

    If (Test-Online -Computer $Computer) {
        $WMIProperties = @(
            'Name'
            'Size'
            'FreeSpace')
        $FormattedProperties = @(
            'Computer'
            'Name'
            'Size'
            'Free Space'
            'Free Space %')
        $WMIQuery = "SELECT Name, Size, FreeSpace FROM Win32_LogicalDisk WHERE DriveType = 3"
        $Results = Get-WmiObject -Query $WMIQuery -ComputerName $Computer
        
        Switch ($Raw) {
            $False  {
                $FormattedResults = @()
                ForEach ($Volume in $Results) {
                    $FormattedResult = New-Object -TypeName PSObject -Property @{
                        'Computer'     = $Computer
                        'Name'         = $Volume.Name
                        'Size'         = ([string]::Format( "{0:N2}", ($Volume.Size / 1024 / 1024)) + " GB")
                        'Free Space'   = ([string]::Format( "{0:N2}", ($Volume.FreeSpace / 1024 / 1024)) + " GB")
                        'Free Space %' = ([string]::Format( "{0:N1}", ($Volume.FreeSpace / $Volume.Size * 100)) + "%")
                    }
                    $FormattedResults += ,($FormattedResult)
                }
                #$FormattedResults | Select $FormattedProperties
                Return $FormattedResults
            }
            $True  {
                $Results | Select $WMIProperties
            }
        }
    }
    Else {
        Write-Host ($Computer + " is offline") -ForegroundColor Red
    }
}

Clear-Host
$ClusterNodes = @(
    'SYSJHBHV1'
    '192.168.1.151'
    'SYSJHBHV3'
    'SYSJHBHV4')

$FormattedProperties = @(
    'Computer'
    'Name'
    'Size'
    'Free Space'
    'Free Space %')

$TotalDisks = @()
ForEach ($Server in $ClusterNodes) {
    Write-Host "Getting Disk Sizes from $Server - " -NoNewline
    $Disks = Get-DiskSize -Computer $Server
    Write-Host "Complete - " -NoNewline
    Write-Host "Adding disks to report - " -NoNewline
    ForEach ($Disk in $Disks) {
        $This_Disk = New-Object -TypeName PSObject -Property @{
            'Computer'     = $Disk.'Computer'
            'Name'         = $Disk.'Name'
            'Size'         = $Disk.'Size'
            'Free Space'   = $Disk.'Free Space'
            'Free Space %' = $Disk.'Free Space %'
        }
        $TotalDisks += ,($This_Disk)
    }
    Write-Host "Complete"
}
$TotalDisks | Select $FormattedProperties | Format-Table -AutoSize
        
}
Function VHDLength {
Clear-Host

$DeleteVHDs = @(
"\\SYSJHBHV1\C$\ClusterStorage\Volume3\Absalom\Absalom.vhd"
"\\SYSJHBHV1\C$\ClusterStorage\Volume5\SYSJHBSCDB01Temp.vhdx")

$VHDInfo = @()
$TotalSize = 0
ForEach ($VHD in $DeleteVHDs) {
    $VHDSize = [Math]::Round(((LS $VHD).Length / 1024 /1024 /1024), 2)
    $TotalSize += $VHDSize
    $VHDInfo += ,(New-Object -TypeName PSObject -Property @{ VHD = $VHD; Size = $VHDSize})
}

$VHDInfo
Write-Host
Write-Host ("Total Size: " + $TotalSize.ToString() + " GB")
}
Function VHD-Details {
Clear-Host

$VHDs = @(
"C:/ClusterStorage/Volume2/SHAREPOINT2013/SHAREPOINT2013.VHD",
"C:/ClusterStorage/Volume2/SYSJHBDEV/SYSJHBDEV.vhd",
"C:/ClusterStorage/Volume2/Syspro-CMS/Syspro-CMS.vhd",
"C:/ClusterStorage/Volume2/syspro-develop/U_2013-08-17T173508.vhd",
"C:/ClusterStorage/Volume2/TMG Back Firewall/TMG Back Firewall.vhd",
"C:/ClusterStorage/Volume3/Certification/Certification.vhd",
"C:/ClusterStorage/Volume3/SYSJHBACC/SYSJHBACC.vhdx",
"C:/ClusterStorage/Volume3/SYSJHBACC/SYSJHBACC-Disk2.vhd",
"C:/ClusterStorage/volume3/sysjhbacc/SYSJHBACC-Disk2.vhdx",
"C:/ClusterStorage/Volume3/SYSJHBERRTRK/SYSJHBERRTRK-Disk2.vhdx",
"C:/ClusterStorage/Volume3/SYSJHBERRTRK/Virtual Hard Disks/SYSJHBERRTRK.vhdx",
"C:/ClusterStorage/Volume3/SYSJHBLYNC/SYSJHBLYNC.vhdx",
"C:/ClusterStorage/volume3/sysjhblync/SYSJHBLYNC-Disk2.vhdx",
"C:/ClusterStorage/Volume3/SYSJHBWA/Virtual Hard Disks/SYSJHBWA.vhdx",
"C:/ClusterStorage/Volume3/SYSPRO-DCVM/SYSPRO-DCVM.vhd",
"C:/ClusterStorage/Volume5/SYSJHBMAIL/SYSJHBMAIL-Disk2.vhdx",
"C:/ClusterStorage/Volume5/SYSJHBMAIL/SYSJHBMAIL-F.vhdx",
"C:/ClusterStorage/Volume5/SYSJHBSCOM01/SYSJHBSCOM01.vhdx",
"C:/ClusterStorage/Volume5/SYSJHBSQLSP/SYSJHBSQLSP2.VHD",
"C:/ClusterStorage/Volume5/SYSPRO-ERRTRK/SYSPRO-ERRTRK-1.VHD",
"C:/ClusterStorage/Volume6/Stage-New/second-drive_EE65F7F7-6F0E-41EA-953D-F0502BE98268.avhd",
"C:/ClusterStorage/Volume6/Stage-New/STAGE-OS_3C751701-D577-46EB-BB58-6B6FD0DB6EEA.avhd",
"C:/ClusterStorage/Volume6/SYSJHBDEV/HD-For-SYSPRO-Buildsvhdx.vhdx",
"C:/ClusterStorage/Volume6/SYSJHBFS/SYSJHBFS-Disk2.vhdx",
"C:/ClusterStorage/Volume6/SYSJHBSQLSP/SYSJHBSQLSP-DISK4.VHDX",
"C:/ClusterStorage/Volume6/SYSJHBSQLSP/SYSJHBSQLSP-DISK5.VHDX",
"C:/ClusterStorage/volume7/sysjhbdev/g_2013-08-17t173508.vhd",
"C:/ClusterStorage/Volume7/SYSJHBFS/SYSJHBFS.vhdx",
"C:/ClusterStorage/Volume7/SYSJHBMAIL/SYSJHBMAIL.vhdx",
"C:/ClusterStorage/Volume7/SYSJHBSQLSP/SYSJHBSQLSP.VHD",
"C:/ClusterStorage/Volume7/SYSJHBSQLSP/SYSJHBSQLSP-DISK3.VHDX",
"C:/ClusterStorage/Volume7/sysjhbvmm/Sysjhbvm.vhd",
"C:/ClusterStorage/Volume7/SYSPRO-Build/SYSPRO-BUILD.vhd",
"C:/ClusterStorage/Volume7/SYSPRO-ERRTRK/SYSPRO-ERRTRK-0.VHD")

$VHDTable = @()
ForEach ($VHDPath in $VHDs) {
    $NewString = $VHDPath -split ("/")
    $This_VHD = New-Object -TypeName psobject -Property @{
        Volume = $NewString[2]
        VM     = $NewString[3]
        VHD    = $NewString[-1]
    }
    $VHDTable += ,($This_VHD)
}

Clear-Host; $VHDTable.VHD
}
Function VHD-Details2 {
Clear-Host
$ClusterNodes = @(
    'SYSJHBHV1'
    'SYSJHBHV2'
    'SYSJHBHV3'
    'SYSJHBHV4')

$HostsVMS = @()

ForEach ($Node in $ClusterNodes) {
    Write-Host "Getting VMs on $Node - " -NoNewline
    $NodeVMS = Get-VM -ComputerName $Node
    Write-Host "Complete" -NoNewline
    Write-Host " - Collecting VHD info - " -NoNewline
    ForEach ($VM in $NodeVMS.HardDrives) {
        $This_VM = New-Object -TypeName PSObject -Property @{
            VMName = $VM.VMName
            Path = $VM.Path
        }
        $HostsVMS += ,($This_VM)
    }
    Write-Host "Complete"
}

$CSVVHDs = Get-ChildItem \\sysjhbhv1\c$\ClusterStorage -Recurse -Include "*.*vhd*" | Select FullName
$CSVVHDs
$HostsVMS.Path
}
Function MultiThreadVHDFiles {
Function Start-Jobs {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet("TargetOnly","ArgumentsOnly","Both")]
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
        [Int32]    $MaximumJobs=$env:NUMBER_OF_PROCESSORS)

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
    $Jobs = @()
    
    Switch ($ReportImmediate) {
        $True { Write-Color -Text "Starting Jobs for ", $Targets.Count, " targets.", " Please wait for the results." -Color White, Cyan, White, Yellow }
    }
    ForEach ($Target in $Targets) {
        Switch ($ReportImmediate) {
            $False { Write-Color -Text "Starting Job for ", $Target -Color White, Yellow }
        }
        Switch ($PassTargetToScriptBlock) {
            "TargetOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Target)}
            "ArgumentsOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ScriptBlockArguments)}
            "Both" {
                $Arguments = @()
                $Arguments = $Arguments + $Target
                ForEach ($ScriptBlockArgument in $ScriptBlockArguments) {
                    $Arguments = $Arguments + $ScriptBlockArgument
                }
                $Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Arguments)}
        }
        $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})

        While ($RunningJobs.Count -ge $MaximumJobs) {
            $FinishedJobs = Wait-Job -Job $Jobs -Any
            Switch ($ReportImmediate) {
                $True {
                    $CompletedJobs = @($Jobs | Where {$_.HasMoreData -eq "True"})
                    ForEach ($CompleteJob in $CompletedJobs) {
                        Receive-Job $CompleteJob
                    }
                }
            }
            $RunningJobs  = @($Jobs | Where-Object {$_.State -eq 'Running'})
        }
    }
    Wait-Job -Job $Jobs | Out-Null
    $FailedJobs = @($Jobs | Where-Object {$_.State -eq 'Failed'})
    If ($FailedJobs.Count -gt 0) {
        ForEach ($FailedJob in $FailedJobs) {
            $FailedJob.ChildJobs[0].JobStateInfo.Reason.Message
        }
    }
    $JobResults = @()
    Switch ($ReportImmediate) {
        $False {
            ForEach ($Job in $Jobs) {
                $JobResults = $JobResults + (Receive-Job $Job)
            }
        }
    }
    Get-Job | Wait-Job | Remove-Job
    Return $JobResults
}
$SB2 = {
    Param ($Server)
    $WMIQuery = "SELECT Name, Size, FreeSpace FROM Win32_LogicalDisk WHERE DriveType = 3"
    Write-Host "Getting Logical Disks on $Server - " -NoNewline
    $Results = Get-WmiObject -Query $WMIQuery -ComputerName $Server
    Write-Host "Complete"
    $AllVHDs = @()
    ForEach ($Volume in $Results) {
        Write-Host ("Getting VHD files on " + $Volume.Name[0] + " - ") -NoNewline
        $ServerPath = "\\"+ $Server + "\" + $Volume.Name[0] + "$\"
        $VHDs = Get-ChildItem $ServerPath -Include "*.*vhd*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Complete"
        Write-Host "Adding VHDs to report - " -NoNewline
        ForEach ($VHD in $VHDs) {
            $AllVHDs += ,($VHd.FullName)
        }
        Write-Host "Complete"
    }
    $AllVHDs
}

Clear-Host
$ClusterNodes = @(
    'SYSJHBHV1'
    'SYSJHBHV2'
    'SYSJHBHV3'
    'SYSJHBHV4')
Start-Jobs -PassTargetToScriptBlock TargetOnly -ScriptBlock $SB2 -MaximumJobs 4 -Targets $ClusterNodes
}
Function MultiThreadVHDFiles2 {
Function Start-Jobs {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet("TargetOnly","ArgumentsOnly","Both")]
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
        [Int32]    $MaximumJobs=$env:NUMBER_OF_PROCESSORS)

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
    $Jobs = @()
    
    Switch ($ReportImmediate) {
        $True { Write-Color -Text "Starting Jobs for ", $Targets.Count, " targets.", " Please wait for the results." -Color White, Cyan, White, Yellow }
    }
    ForEach ($Target in $Targets) {
        Switch ($ReportImmediate) {
            $False { Write-Color -Text "Starting Job for ", $Target -Color White, Yellow }
        }
        Switch ($PassTargetToScriptBlock) {
            "TargetOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Target)}
            "ArgumentsOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ScriptBlockArguments)}
            "Both" {
                $Arguments = @()
                $Arguments = $Arguments + $Target
                ForEach ($ScriptBlockArgument in $ScriptBlockArguments) {
                    $Arguments = $Arguments + $ScriptBlockArgument
                }
                $Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Arguments)}
        }
        $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})

        While ($RunningJobs.Count -ge $MaximumJobs) {
            $FinishedJobs = Wait-Job -Job $Jobs -Any
            Switch ($ReportImmediate) {
                $True {
                    $CompletedJobs = @($Jobs | Where {$_.HasMoreData -eq "True"})
                    ForEach ($CompleteJob in $CompletedJobs) {
                        Receive-Job $CompleteJob
                    }
                }
            }
            $RunningJobs  = @($Jobs | Where-Object {$_.State -eq 'Running'})
        }
    }
    Wait-Job -Job $Jobs | Out-Null
    $FailedJobs = @($Jobs | Where-Object {$_.State -eq 'Failed'})
    If ($FailedJobs.Count -gt 0) {
        ForEach ($FailedJob in $FailedJobs) {
            $FailedJob.ChildJobs[0].JobStateInfo.Reason.Message
        }
    }
    $JobResults = @()
    Switch ($ReportImmediate) {
        $False {
            ForEach ($Job in $Jobs) {
                $JobResults = $JobResults + (Receive-Job $Job)
            }
        }
    }
    Get-Job | Wait-Job | Remove-Job
    Return $JobResults
}

$SB2 = {
    Param ($Server)
    $WMIQuery = "SELECT Name, Size, FreeSpace FROM Win32_LogicalDisk WHERE DriveType = 3"
    Write-Host "Getting Logical Disks on $Server - " -NoNewline
    $Results = Get-WmiObject -Query $WMIQuery -ComputerName $Server
    Write-Host "Complete"
    $AllVHDs = @()
    $Properties = @('Root', 'Parent', 'Name', 'FullName', 'Extension', 'Length')
    ForEach ($Volume in $Results) {
        Write-Host ("Getting VHD files on " + $Volume.Name[0] + " - ") -NoNewline
        If ($Volume.Name[0].ToString().ToLower() -eq 'c') {
            $ServerPath = "\\"+ $Server + "\" + $Volume.Name[0] + "$\"
            $VHDs = Get-ChildItem $ServerPath -Include "*.*vhd*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Complete"
            Write-Host "Adding VHDs to report - " -NoNewline
            ForEach ($VHD in $VHDs) {
                $AllVHDs += ,($VHD | Select $Properties)
            }
            Write-Host "Complete"
        }
    }
    $AllVHDs
}

Clear-Host
$ClusterNodes = @(
    'SYSJHBHV1'
    'SYSJHBHV2'
    'SYSJHBHV3'
    'SYSJHBHV4')
$Results_Excluding_C = Start-Jobs -PassTargetToScriptBlock TargetOnly -ScriptBlock $SB2 -MaximumJobs 4 -Targets $ClusterNodes
$Results_Only_C = Start-Jobs -PassTargetToScriptBlock TargetOnly -ScriptBlock $SB2 -MaximumJobs 4 -Targets $ClusterNodes
$HostsVMS = @()

ForEach ($Node in $ClusterNodes) {
    Write-Host "Getting VMs on $Node - " -NoNewline
    $NodeVMS = Get-VM -ComputerName $Node
    Write-Host "Complete" -NoNewline
    Write-Host " - Collecting VHD info - " -NoNewline
    ForEach ($VM in $NodeVMS.HardDrives) {
        $This_VM = New-Object -TypeName PSObject -Property @{
            VMName = $VM.VMName
            Path = $VM.Path
        }
        $HostsVMS += ,($This_VM)
    }
    Write-Host "Complete"
}
$HostsVMS
}
Function Update-Host {
    Param ([ValidateSet("Start","Stop")]$Action)

    Switch ($Action) {
        "Start" {
            Write-Host "Getting Updates - " -NoNewline
        }
        "Stop"  {
            Write-Host "Complete" -ForegroundColor Green
        }
    }
}
Function Build-Scripts {
$Approvals = @()
$Approvals += ,("Unapproved")
$Approvals += ,("Declined")
$Approvals += ,("Approved")
$Approvals += ,("AnyExceptDeclined")

$Classifications = @()
$Classifications += ,("All")
$Classifications += ,("Critical")
$Classifications += ,("Security")
$Classifications += ,("WSUS")

$Statuses = @()
$Statuses += ,("Needed")
$Statuses += ,("FailedOrNeeded")
$Statuses += ,("Failed")
$Statuses += ,("InstalledNotApplicable")
$Statuses += ,("NoStatus")
$Statuses += ,("Any")

$Scripts = @()
ForEach ($Approval in $Approvals) {
    ForEach ($Classification in $Classifications) {
        ForEach ($Status in $Statuses) {
            $Scripts += ,('Update-Host -Action Start; $AllUpdates += ,(Get-WsusUpdate -UpdateServer $WSUSServer -Approval ' + $Approval + ' -Classification ' + $Classification + ' -Status ' + $Status + ')')
        }
    }
}

    Return $Scripts
}
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
Function SCVMM {
    Param
        ($ComputerName)

    #Write-Color -Text "------------------------------------ ", "VMM Details", " ------------------------------------" -Color Cyan, Yellow, Cyan
    #Write-Host "------------------------------------ " -ForegroundColor Cyan -NoNewline
    #Write-Host "VMM Details" -ForegroundColor Yellow -NoNewline
    #Write-Host " ------------------------------------" -ForegroundColor Cyan
    
    Try {
    Import-Module VirtualMachineManager

    $SelectDetails = @("Name", "ComputerName", "Owner", "UserRole", "Description", "Cloud", "VirtualMachineState", "VMHost", "MostRecentTaskIfLocal")
    $VMDetails = Get-SCVirtualMachine | Where-Object {$_.ComputerName -like "*$ComputerName*"}
    $VMMDetails = $VMDetails | Select $SelectDetails | Format-Table -AutoSize
    Return $VMMDetails
    }
    Catch {
        Write-Color "Failed - ", $_ -Color Red, Red
    }
}
Function Users {
    Param
        ($Server)

    #Write-Color -Text "----------------------------------- ", "User Details", " ------------------------------------" -Color Cyan, Yellow, Cyan
    #Write-Host "------------------------------------ " -ForegroundColor Cyan -NoNewline
    #Write-Host "User Details" -ForegroundColor Yellow -NoNewline
    #Write-Host " -----------------------------------" -ForegroundColor Cyan
    Try {
    $Users = Get-ChildItem -Path ("\\" + $Server + "\C$\Users") # | Select BaseName, LastAccessTime, CreationTime, FullName
    $UsersDetails = $Users | Sort LastAccessTime  -Descending | Select BaseName, LastAccessTime, CreationTime, FullName -First 10
    
    Return $UsersDetails
    }
    Catch {
        Write-Color "Failed" -Color Red
        Return $False
    }
}
Function InstallDate {
    Param 
        ($Computer)

    #Write-Color -Text "---------------------------------- ", "Install Details", " -----------------------------------" -Color Cyan, Yellow, Cyan
    #Write-Host "----------------------------------- " -ForegroundColor Cyan -NoNewline
    #Write-Host "Install Details" -ForegroundColor Yellow -NoNewline
    #Write-Host " ----------------------------------" -ForegroundColor Cyan
    
    Try {
    $Installed = Get-WmiObject -class Win32_OperatingSystem -ComputerName $Computer -Property InstallDate | Select-Object @{label='InstallDate';expression={$_.ConvertToDateTime($_.InstallDate)}}
 
    Return $Installed
    }
    Catch {
        Write-Color "Failed" -Color Red
        Return $False
    }
}
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
Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)

    $ErrorActionPreference = "Stop"
    Try {
        If ($Text.Count -ne $ForegroundColor.Count) {
            Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $ForegroundColor.Count.ToString()) -ForegroundColor Red
            Throw
        }
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch { 
        Write-Host "Text Count:  " $Text.Count
        Write-Host "Color Count: " $ForegroundColor.Count
        Write-Host $_
    }
}
Function Get-RemoteRegistryEntry {
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
        $RegistryKey = $Registry.OpenSubKey($Key)
        $Value       = $RegistryKey.GetValue($Value)
    }
    Catch { $Value = "Not found" }
    Return $Value
} # Example: Get-RemoteRegistryEntry -Computer 'SYSJHBVMM' -Hive LocalMachine -Key "SOFTWARE\\Microsoft\\Virtual Machine\\Guest\\Parameters" -Value "HostName"
Function Get-RemoteVMHost {
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [String] $Computer)

    Try {
        $Registry    = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $Computer)
        $RegistryKey = $Registry.OpenSubKey("SOFTWARE\\Microsoft\\Virtual Machine\\Guest\\Parameters")
        $Value       = $RegistryKey.GetValue("HostName")
    }
    Catch { $Value = "Not found" }
    Return $Value
}        # Example: Get-RemoteVMHost -Computer 'SYSJHBVMM'
Function Get-VMHost {
    Try {
        $Registry    = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $env:COMPUTERNAME)
        $RegistryKey = $Registry.OpenSubKey("SOFTWARE\\Microsoft\\Virtual Machine\\Guest\\Parameters")
        $Value       = $RegistryKey.GetValue("HostName")
    }
    Catch { $Value = "Not found" }
    Return $Value
}              # Example: Get-VMHost
Function Get-PendingReboot {
<#
.SYNOPSIS
    Gets the pending reboot status on a local or remote computer.

.DESCRIPTION
    This function will query the registry on a local or remote computer and determine if the
    system is pending a reboot, from Microsoft updates, Configuration Manager Client SDK, Pending Computer 
    Rename, Domain Join or Pending File Rename Operations. For Windows 2008+ the function will query the 
    CBS registry key as another factor in determining pending reboot state.  "PendingFileRenameOperations" 
    and "Auto Update\RebootRequired" are observed as being consistant across Windows Server 2003 & 2008.
	
    CBServicing = Component Based Servicing (Windows 2008+)
    WindowsUpdate = Windows Update / Auto Update (Windows 2003+)
    CCMClientSDK = SCCM 2012 Clients only (DetermineIfRebootPending method) otherwise $null value
    PendComputerRename = Detects either a computer rename or domain join operation (Windows 2003+)
    PendFileRename = PendingFileRenameOperations (Windows 2003+)
    PendFileRenVal = PendingFilerenameOperations registry value; used to filter if need be, some Anti-
                     Virus leverage this key for def/dat removal, giving a false positive PendingReboot

.PARAMETER ComputerName
    A single Computer or an array of computer names.  The default is localhost ($env:COMPUTERNAME).

.PARAMETER ErrorLog
    A single path to send error data to a log file.

.EXAMPLE
    PS C:\> Get-PendingReboot -ComputerName (Get-Content C:\ServerList.txt) | Format-Table -AutoSize
	
    Computer CBServicing WindowsUpdate CCMClientSDK PendFileRename PendFileRenVal RebootPending
    -------- ----------- ------------- ------------ -------------- -------------- -------------
    DC01           False         False                       False                        False
    DC02           False         False                       False                        False
    FS01           False         False                       False                        False

    This example will capture the contents of C:\ServerList.txt and query the pending reboot
    information from the systems contained in the file and display the output in a table. The
    null values are by design, since these systems do not have the SCCM 2012 client installed,
    nor was the PendingFileRenameOperations value populated.

.EXAMPLE
    PS C:\> Get-PendingReboot
	
    Computer           : WKS01
    CBServicing        : False
    WindowsUpdate      : True
    CCMClient          : False
    PendComputerRename : False
    PendFileRename     : False
    PendFileRenVal     : 
    RebootPending      : True
	
    This example will query the local machine for pending reboot information.
	
.EXAMPLE
    PS C:\> $Servers = Get-Content C:\Servers.txt
    PS C:\> Get-PendingReboot -Computer $Servers | Export-Csv C:\PendingRebootReport.csv -NoTypeInformation
	
    This example will create a report that contains pending reboot information.

.LINK
    Component-Based Servicing:
    http://technet.microsoft.com/en-us/library/cc756291(v=WS.10).aspx
	
    PendingFileRename/Auto Update:
    http://support.microsoft.com/kb/2723674
    http://technet.microsoft.com/en-us/library/cc960241.aspx
    http://blogs.msdn.com/b/hansr/archive/2006/02/17/patchreboot.aspx

    SCCM 2012/CCM_ClientSDK:
    http://msdn.microsoft.com/en-us/library/jj902723.aspx

.NOTES
    Author:  Brian Wilhite
    Email:   bcwilhite (at) live.com
    Date:    29AUG2012
    PSVer:   2.0/3.0/4.0/5.0
    Updated: 27JUL2015
    UpdNote: Added Domain Join detection to PendComputerRename, does not detect Workgroup Join/Change
             Fixed Bug where a computer rename was not detected in 2008 R2 and above if a domain join occurred at the same time.
             Fixed Bug where the CBServicing wasn't detected on Windows 10 and/or Windows Server Technical Preview (2016)
             Added CCMClient property - Used with SCCM 2012 Clients only
             Added ValueFromPipelineByPropertyName=$true to the ComputerName Parameter
             Removed $Data variable from the PSObject - it is not needed
             Bug with the way CCMClientSDK returned null value if it was false
             Removed unneeded variables
             Added PendFileRenVal - Contents of the PendingFileRenameOperations Reg Entry
             Removed .Net Registry connection, replaced with WMI StdRegProv
             Added ComputerPendingRename
#>
    [CmdletBinding()]
    Param(
	    [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
	    [Alias("CN","Computer")]
	    [String[]]$ComputerName="$env:COMPUTERNAME",
	    [String]$ErrorLog)

    Begin {  }
    Process {
        Foreach ($Computer in $ComputerName) {
	        Try {
	            ## Setting pending values to false to cut down on the number of else statements
	            $CompPendRen    = $false
                $PendFileRename = $false
                $Pending        = $false
                $SCCM           = $false
                        
	            ## Setting CBSRebootPend to null since not all versions of Windows has this value
	            $CBSRebootPend = $null
						
	            ## Querying WMI for build version
	            $WMI_OS = Get-WmiObject -Class Win32_OperatingSystem -Property BuildNumber, CSName -ComputerName $Computer -ErrorAction Stop

	            ## Making registry connection to the local/remote computer
	            $HKLM    = [UInt32] "0x80000002"
	            $WMI_Reg = [WMIClass] "\\$Computer\root\default:StdRegProv"
						
	            ## If Vista/2008 & Above query the CBS Reg Key
	            If ([Int32]$WMI_OS.BuildNumber -ge 6001) {
		            $RegSubKeysCBS = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\")
		            $CBSRebootPend = $RegSubKeysCBS.sNames -contains "RebootPending"		
	            }
							
	            ## Query WUAU from the registry
	            $RegWUAURebootReq = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")
	            $WUAURebootReq = $RegWUAURebootReq.sNames -contains "RebootRequired"
						
	            ## Query PendingFileRenameOperations from the registry
	            $RegSubKeySM = $WMI_Reg.GetMultiStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\Session Manager\","PendingFileRenameOperations")
	            $RegValuePFRO = $RegSubKeySM.sValue

	            ## Query JoinDomain key from the registry - These keys are present if pending a reboot from a domain join operation
	            $Netlogon = $WMI_Reg.EnumKey($HKLM,"SYSTEM\CurrentControlSet\Services\Netlogon").sNames
	            $PendDomJoin = ($Netlogon -contains 'JoinDomain') -or ($Netlogon -contains 'AvoidSpnSet')

	            ## Query ComputerName and ActiveComputerName from the registry
	            $ActCompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName\","ComputerName")            
	            $CompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\","ComputerName")

	            If (($ActCompNm -ne $CompNm) -or $PendDomJoin) {
	                $CompPendRen = $true
	            }
						
	            ## If PendingFileRenameOperations has a value set $RegValuePFRO variable to $true
	            If ($RegValuePFRO) {
		            $PendFileRename = $true
	            }

	            ## Determine SCCM 2012 Client Reboot Pending Status
	            ## To avoid nested 'if' statements and unneeded WMI calls to determine if the CCM_ClientUtilities class exist, setting EA = 0
	            $CCMClientSDK = $null
	            $CCMSplat = @{
	                NameSpace    = 'ROOT\ccm\ClientSDK'
	                Class        = 'CCM_ClientUtilities'
	                Name         = 'DetermineIfRebootPending'
	                ComputerName = $Computer
	                ErrorAction  = 'Stop'
	            }
	            ## Try CCMClientSDK
	            Try {
	                $CCMClientSDK = Invoke-WmiMethod @CCMSplat
	            } 
                Catch [System.UnauthorizedAccessException] {
	                $CcmStatus = Get-Service -Name CcmExec -ComputerName $Computer -ErrorAction SilentlyContinue
	                If ($CcmStatus.Status -ne 'Running') {
	                    Write-Warning "$Computer`: Error - CcmExec service is not running."
	                    $CCMClientSDK = $null
	                }
	            } 
                Catch {
	                $CCMClientSDK = $null
	            }

	            If ($CCMClientSDK) {
	                If ($CCMClientSDK.ReturnValue -ne 0) {
		                Write-Warning "Error: DetermineIfRebootPending returned error code $($CCMClientSDK.ReturnValue)"          
		            }
		            If ($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending) {
		                $SCCM = $true
		            }
	            }
                Else {
	                $SCCM = $null
	            }

	            ## Creating Custom PSObject and Select-Object Splat
	            $SelectSplat = @{
	                Property=(
	                    'Computer',
	                    'CBServicing',
	                    'WindowsUpdate',
	                    'CCMClientSDK',
	                    'PendComputerRename',
	                    'PendFileRename',
	                    'PendFileRenVal',
	                    'RebootPending')}
	            New-Object -TypeName PSObject -Property @{
	                Computer           = $WMI_OS.CSName
	                CBServicing        = $CBSRebootPend
	                WindowsUpdate      = $WUAURebootReq
	                CCMClientSDK       = $SCCM
	                PendComputerRename = $CompPendRen
	                PendFileRename     = $PendFileRename
	                PendFileRenVal     = $RegValuePFRO
	                RebootPending      = ($CompPendRen -or $CBSRebootPend -or $WUAURebootReq -or $SCCM -or $PendFileRename)
	            } | Select-Object @SelectSplat
	        } 
            Catch {
	            Write-Warning "$Computer`: $_"
	            ## If $ErrorLog, log the file to a user specified location/path
	            If ($ErrorLog) {
	                Out-File -InputObject "$Computer`,$_" -FilePath $ErrorLog -Append
	            }				
	        }			
        }## End Foreach ($Computer in $ComputerName)			
    }## End Process
    End {  }## End End
}## End Function Get-PendingReboot]
Function Get-LastBootUpTime {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Computer)

    $Installed = Get-WmiObject -class Win32_OperatingSystem -ComputerName $Computer -Property LastBootupTime | Select-Object @{label='LastBootupTime';expression={$_.ConvertToDateTime($_.LastBootupTime)}}
    
    $Details = New-Object PSObject -Property @{
        "Computer" = $Computer
        "BootTime" = $Installed.LastBootupTime
    }

    $Details
}
Function Get-HAVMs {
    Param (
        [Parameter(Mandatory=$True, Position=0, ParameterSetName="Single")]
        [String] $Cluster, `
        [Parameter(Mandatory=$True, Position=0, ParameterSetName="Domain")]
        [String] $Domain)

    Switch ($PSCmdlet.ParameterSetName) {
        "Single" {$Clusters = @($Cluster)}
        "Domain" {$Clusters = (Get-Cluster -Domain $Domain).Name}
    }

    $VMs = @()
    ForEach ($Cluster in $Clusters) {
        $HAVms = ((Get-ClusterResource -Cluster $Cluster | Where ResourceType -eq "Virtual Machine").OwnerGroup).Name
        ForEach ($Server in (Get-ClusterNode -Cluster $Cluster).Name) {
            ForEach ($VM in (Get-VM -ComputerName $Server)) {
                If ($HAVms.Contains($VM.Name)) { $HA = $True } Else {$HA = $False}
                $Details = New-Object PSObject -Property @{
                    Cluster = $Cluster
                    Server  = $Server
                    VMName  = $VM.Name
                    VMState = $VM.State
                    HA      = $HA
                }
                $VMS = $VMS + $Details
            }
        }
    }
    Return $VMs
    
}
Function Get-DomainComputers {
    Param (
        [Parameter(Mandatory = $False,  Position = 1)]
        [String] $Domain = $env:USERDOMAIN)

    Import-Module ActiveDirectory
    $Servers = Get-ADComputer -Filter { ObjectClass -eq "computer" }
    $Servers = $Servers | Sort Name
    $Servers = $Servers.Name

    Return $Servers    
}
Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)

    $ErrorActionPreference = "Stop"
    Try {
        If ($Text.Count -ne $ForegroundColor.Count) {
            Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $ForegroundColor.Count.ToString()) -ForegroundColor Red
            Throw
        }
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch { 
        Write-Host "Text Count:  " $Text.Count
        Write-Host "Color Count: " $ForegroundColor.Count
        Write-Host $_
    }
}
Function Test-Online {
    Param (
        [Parameter(Mandatory=$True,  Position=1)]
        [String] $Computer)

    If (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
        Return $True
    }
    Else {
        Return $False
    }
}
Function Test-Online {
    Param (
        [Parameter(Mandatory=$True,  Position=1)]
        [String] $Computer)

    If (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
        Return $True
    }
    Else {
        Return $False
    }
}
Function Get-DiskSize {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Computer, `
        [Parameter(Mandatory=$false, Position=1)]
        [Switch] $Raw)

    If (Test-Online -Computer $Computer) {
        $WMIProperties = @(
            'Name'
            'Size'
            'FreeSpace')
        $FormattedProperties = @(
            'Computer'
            'Name'
            'Size'
            'Free Space'
            'Free Space %')
        $WMIQuery = "SELECT Name, Size, FreeSpace FROM Win32_LogicalDisk WHERE DriveType = 3"
        $Results = Get-WmiObject -Query $WMIQuery -ComputerName $Computer
        
        Switch ($Raw) {
            $False  {
                $FormattedResults = @()
                ForEach ($Volume in $Results) {
                    $FormattedResult = New-Object -TypeName PSObject -Property @{
                        'Computer'     = $Computer
                        'Name'         = $Volume.Name
                        'Size'         = ([string]::Format( "{0:N2}", ($Volume.Size / 1024 / 1024)) + " GB")
                        'Free Space'   = ([string]::Format( "{0:N2}", ($Volume.FreeSpace / 1024 / 1024)) + " GB")
                        'Free Space %' = ([string]::Format( "{0:N1}", ($Volume.FreeSpace / $Volume.Size * 100)) + "%")
                    }
                    $FormattedResults += ,($FormattedResult)
                }
                $FormattedResults | Select $FormattedProperties
            }
            $True  {
                $Results | Select $WMIProperties
            }
        }
    }
    Else {
        Write-Host ($Computer + " is offline") -ForegroundColor Red
    }
}
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
Function Start-Thread {
    Param (
        [Parameter(Mandatory=$False, Position=0)]
        [Int32]    $MaximumJobs=$env:NUMBER_OF_PROCESSORS, `
        [Parameter(Mandatory=$True, Position=1)]
        [ScriptBlock] $ScriptBlock, `
        [Parameter(Mandatory=$True, Position=2)][ValidateSet("TargetOnly","ArgumentsOnly","Both")]
        [String] $PassTargetToScriptBlock, `
        [Parameter(Mandatory=$False, Position=3)]
        [Object[]] $ScriptBlockArguments, `
        [Parameter(Mandatory=$True, Position=4)]
        [Object[]] $Targets, `
        [Parameter(Mandatory=$False, Position=5)]
        [Switch] $ReportImmediate=$False)

    $Jobs               = @()
    
    Switch ($ReportImmediate) {
        $True { Write-Color -Text "Starting Jobs for ", $Targets.Count, " targets.", " Please wait for the results." -Color White, Cyan, White, Yellow }
    }
    ForEach ($Target in $Targets) {
        Switch ($ReportImmediate) {
            $False { Write-Color -Text "Starting Job for ", $Target -Color White, Yellow }
        }
        Switch ($PassTargetToScriptBlock) {
            "TargetOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Target)}
            "ArgumentsOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ScriptBlockArguments)}
            "Both" {
                $Arguments = @()
                $Arguments = $Arguments + $Target
                ForEach ($ScriptBlockArgument in $ScriptBlockArguments) {
                    $Arguments = $Arguments + $ScriptBlockArgument
                }
                $Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Arguments)}
        }
        $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})

        While ($RunningJobs.Count -ge $MaximumJobs) {
            $FinishedJobs = Wait-Job -Job $Jobs -Any
            Switch ($ReportImmediate) {
                $True {
                    $CompletedJobs = @($Jobs | Where {$_.HasMoreData -eq "True"})
                    ForEach ($CompleteJob in $CompletedJobs) {
                        Receive-Job $CompleteJob
                    }
                }
            }
            $RunningJobs  = @($Jobs | Where-Object {$_.State -eq 'Running'})
        }
    }
    Wait-Job -Job $Jobs | Out-Null
    $FailedJobs = @($Jobs | Where-Object {$_.State -eq 'Failed'})
    If ($FailedJobs.Count -gt 0) {
        ForEach ($FailedJob in $FailedJobs) {
            $FailedJob.ChildJobs[0].JobStateInfo.Reason.Message
        }
    }
    ForEach ($Job in $Jobs) {
        Receive-Job $Job
    }
    Get-Job | Wait-Job | Remove-Job
}
Function Exclude-Service {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object] $Service)

    $Exclude = $False
    ForEach ($Exclusion in $Services_RunAs_Exclusions) {
        If ($Service.StartName -like $Exclusion) {
            $Exclude = $True
        }
    }
    Return $Exclude
}
Function Exclude-Task {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object] $Task)

    $Exclude = $False
    ForEach ($Exclusion in $Tasks_Author_Exclusions) {
        If ($Task.Author -like $Exclusion) {
            $Exclude = $True
        }
    }
    Return $Exclude
}
