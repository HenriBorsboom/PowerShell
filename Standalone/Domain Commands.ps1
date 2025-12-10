#region Common Functions
Function Write-Color {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [String[]] $Text, `
        [Parameter(Mandatory=$true,Position=1)]
        [ConsoleColor[]] $ForeColor, `
        [Parameter(Mandatory=$false,Position=2)]
        [ConsoleColor[]] $BackColor, `
        [Parameter(Mandatory=$false,Position=2)]
        [bool] $EndLine)
    
    Try {
        If ($BackColor -ne $null) {
            If ($BackColor.Length -eq $Text.Count -and $ForeColor.Count -eq $Text.Count) {
                For ($i = 0; $i -lt $Text.Length; $i++) {
                    Write-Host $Text[$i] -Foreground $ForeColor[$i] -BackgroundColor $BackColor[$i] -NoNewLine
                }
                Switch ($EndLine){$true {Write-Host}}
            }
            Else {break}
        }
        ElseIf ($BackColor -eq $null) {
            If ($ForeColor.Length -eq $Text.Count) {
                For ($i = 0; $i -lt $Text.Length; $i++) {
                    Write-Host $Text[$i] -Foreground $ForeColor[$i] -NoNewLine
                }
                Switch ($EndLine){$true {Write-Host}}
            }
            Else {break}
        }
        Else {break}
    }
    Catch {
        Write-Host "DEBUG!!!!! - Write-Color" -ForegroundColor Red
        Write-Host "The amount of Text variables and the amount of color variables does not match"
        Write-Host "Text Variables:  " $Text.Count
        Write-Host "ForeColor Variables: " $ForeColor.Length
        Write-Host "BackColor Variables: " $BackColor.Length
        Break
    }
}
Function Delete-LastLine {
    $x = [Console]::CursorLeft
    $y = [Console]::CursorTop
    [Console]::SetCursorPosition($x,$y - 1)
    Write-Host "                                                                                                                                            "
    [Console]::SetCursorPosition($x,$y - 1)
}
Function Get-DomainComputers {
    Import-Module ActiveDirectory
    $Servers = Get-ADComputer -Filter {Name -notlike "NRAZUREVMHC*" -and Name -notlike "NRAZUREDBSC*" -and Name -notLike "NRAZUREDBSQ*" -and Name -notLike "NRAZUREAPPC*" -and Name -notLike "NRAZUREWGC*" -and Name -notLike "NRAZUREVMHR*" -and Enabled -eq $true -and Name -like "NRAZURE*"}
    $Servers = $Servers | Select -Unique
    $Servers = $Servers | Sort Name
    

    Return $Servers    
}
Function SetStartDetails {
    Param (
        [Parameter(Mandatory=$false, Position=1)]
        [String] $TimerIdentity)

    $EventStartTime = Get-Date
    If ($TimerIdentity -eq "") {
        Write-Color -Text "-- Item Start Time: ", $EventStartTime.TolongTimeString() -ForeColor White, Cyan -BackColor Black, Black -EndLine $true
    }
    Else {
        Write-Color -Text $TimerIdentity, " Start Time: ", $EventStartTime.TolongTimeString() -ForeColor Cyan, White, Cyan -BackColor Black, Black, Black -EndLine $true
    }
    Return $EventStartTime.ToLongTimeString()
}
Function SetTotalTime {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [DateTime] $StartTime, `
        [Parameter(Mandatory=$false, Position=2)]
        [String] $TimerIdentity)

    $EndTime = Get-date
    $TimeSpanDuration = New-TimeSpan -Start $StartTime -End $EndTime
    $TotalSeconds = $TimeSpanDuration.TotalSeconds
    $TimeSpan =  [timespan]::fromseconds($TotalSeconds)
    $Duration = ("{0:hh\:mm\:ss}" -f $TimeSpan)
    
    If ($TimerIdentity -eq "") {
        Write-Color "-- Item End Time: ", $EndTime.ToLongTimeString(), "  --  Running Duration: ", $Duration -ForeColor White, Cyan, White, Cyan -BackColor Black, Black, Black, Black -EndLine $true
    }
    Else {
        Write-Color $TimerIdentity, " Item End Time: ", $EndTime.ToLongTimeString(), "  --  Running Duration: ", $Duration -ForeColor Cyan, White, Cyan, White, Cyan -BackColor Black, Black, Black, Black, Black -EndLine $true
    }
}
#endregion

Function ExecuteCommand {
    Param (
        [Parameter(Mandatory=$true, Position = 1)]
        [array] $Items, `
        [Parameter(Mandatory=$true, Position = 2)]
        [string] $Command, `
        [Parameter(Mandatory=$true, Position = 3)]
        [Bool] $ExecuteRemote, `
        [Parameter(Mandatory=$false, Position = 4)]
        [Bool] $ReportOutput, `
        [Parameter(Mandatory=$false, Position = 5)]
        [Bool] $ClearHost)

    If ($ClearHost -eq $true) {Clear-Host}
    $Count = $Items.Count
    $x = 1
    Write-Color -Text "Total Items: ", $Count -ForeColor White, Yellow -BackColor $null -EndLine $true
    $ScriptStartTime = SetStartDetails -TimerIdentity "Script"
    ForEach ($Item in $Items) {
        $ItemStartTime = SetStartDetails
        Write-Color "$x/$count", " - ", $Item.ToUpper(), " - Running ", $Command.ToUpper(), " - " -ForeColor Cyan, White, Cyan, White, Yellow, White -BackColor $null -EndLine $false
        Try {
            
                If ($ExecuteRemote -eq $true) {
                    $Results = Invoke-Command -ComputerName $Item -ArgumentList $Command -ScriptBlock {Param($ExecuteCommand); Invoke-Expression $ExecuteCommand} -ErrorAction Stop
                }
                Else {
                    Invoke-Expression $Command
                }
            Write-Host "Complete" -ForegroundColor Green
            If ($ReportOutput -eq $true) {Write-Host $Results}
        }
        Catch {
            Write-Host "Failed" -ForegroundColor Red
            If ($ReportOutput -eq $true) {Write-Host $_.Message}
        }
        $x ++
        SetTotalTime -StartTime $ItemStartTime
    }
    SetTotalTime -StartTime $ScriptStartTime -TimerIdentity "Script"
}

ExecuteCommand -Items $Servers.Name -Command 'ipconfig' -ExecuteRemote $true -ReportOutput $false -ClearHost $true