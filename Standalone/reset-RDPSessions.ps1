<#
.SYNOPSIS
   Checks for disconnected sessions and logs off the disconnected user sessions.

.DESCRIPTION
   Checks for disconnected sessions and logs off the disconnected user sessions.

.NOTES
   File Name: Logoff-DisconnectedSession.ps1
   Author   : Bart Kuppens
   Version  : 1.0

.EXAMPLE
   PS > .\Logoff-DisconnectedSession.ps1
#>
$LogFile = "C:\Users\username\Desktop\DisconnectedSessions\sessions_" + $([DateTime]::Now.ToString('yyyyMMdd')) + ".log"
Function Write-Log ([string] $message) { Out-File -InputObject $message -FilePath $LogFile -Append }
Function Get-Sessions {
    Param (
        [Parameter(Mandatory=$false, Position = 1)]
        [string] $Target)
    
    $QueryResults = Invoke-Command {query session /server:$Target} -ErrorAction Stop
    
    If ($QueryResults -ne $Null) {
        $Starters = New-Object psobject -Property @{"SessionName" = 0; "UserName" = 0; "ID" = 0; "State" = 0; "Type" = 0; "Device" = 0;}
        ForEach ($Result in $QueryResults) {
            Try {
                If ($Result.Trim().SubString(0, $Result.Trim().IndexOf(" ")) -eq "SESSIONNAME") {
                    $Starters.UserName = $Result.indexof("USERNAME");
                    $Starters.ID = $Result.indexof("ID");
                    $Starters.State = $Result.indexof("STATE");
                    $Starters.Type = $Result.indexof("TYPE");
                    $Starters.Device = $Result.indexof("DEVICE");
                    Continue;
                }
                New-Object psobject -Property @{
                    "SessionName" = $Result.trim().substring(0, $Result.trim().indexof(" ")).trim(">");
                    "Username" = $Result.Substring($Starters.Username, $Result.IndexOf(" ", $Starters.Username) - $Starters.Username);
                    "ID" = $Result.Substring($Result.IndexOf(" ", $Starters.Username), $Starters.ID - $Result.IndexOf(" ", $Starters.Username) + 2).trim();
                    "State" = $Result.Substring($Starters.State, $Result.IndexOf(" ", $Starters.State)-$Starters.State).trim();
                    "Type" = $Result.Substring($Starters.Type, $Starters.Device - $Starters.Type).trim();
                    "Device" = $Result.Substring($Starters.Device).trim()
                }
            } 
            Catch {
                $e = $_;
                Write-Log "ERROR: " + $e.PSMessageDetails
            }
        }
    }
}
Function ResetSessions {
    Param (
        [Parameter(Mandatory=$true, Position = 1)]
        [Bool] $Remote, `
        [Parameter(Mandatory=$false, Position = 2)]
        [String] $Target)

    [string]$IncludeStates = '^(Disc)$'
    Switch ($Remote) { $false {$Target = $env:COMPUTERNAME} }
    #Write-Log -Message "Disconnected Sessions CleanUp - $Target"
    #Write-Log -Message "============================================="
    $DisconnectedSessions = Get-Sessions -Target $Target | ? {$_.State -match $IncludeStates -and $_.UserName -ne ""} | Select ID, UserName
    #Write-Log -Message "Logged off sessions"
    #Write-Log -Message "---------------------------------------------"
    ForEach ($Session in $DisconnectedSessions) {
       Invoke-Command { Reset Session $Session.ID /Server:$Target }
       #logoff $Session.ID
       $LogMessage = $Target + " - " + $Session.Username + " - " + (Get-Date).ToLongTimeString()
       Write-Log -Message $LogMessage
    }
    #Write-Log -Message " "
    #Write-Log -Message "Finished"
    $Target = $null
}
Function Get-DomainComputers {
    Import-Module ActiveDirectory
    $Servers = Get-ADComputer -Filter {Name -like "SYS*"}
    $Servers | Sort Name
    Return $Servers    
}
$Servers = Get-DomainComputers
$Servers = $Servers | Sort Name
$Servers = $Servers.Name
$Servers = $Servers | Select -Unique
$Counter = 1
$ServerCount = $Servers.Count
Write-Host "Total Servers: " -NoNewLine
Write-Host $ServerCount -ForegroundColor Yellow
ForEach ($Server in $Servers) {
    Try {
        Write-Host "$Counter/$ServerCount" -NoNewline -ForegroundColor Cyan
        Write-Host " - Getting & Resetting Sessions - " -NoNewline
        Write-Host $Server -NoNewline -ForegroundColor Yellow
        Write-Host " - " -NoNewline
        #ResetSessions -Remote -Target $Server
            ResetSessions -Remote $true -Target $Server
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        $e = $_;
        Write-Log $Server + " - ERROR: " + $e.PSMessageDetails
    }
    $Counter ++
}