Function Write-Color {
    [CmdletBinding(DefaultParameterSetName='Normal')]
    Param( 
        [Parameter(Mandatory=$True, Position=1,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$True, Position=1,ParameterSetName='Tab')]
        [String[]] $Text, `
        [Parameter(Mandatory=$False, Position=2,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=2,ParameterSetName='Tab')]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory=$False, Position=3,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=3,ParameterSetName='Tab')]
        [ConsoleColor[]] $BackgroundColor, `
        [Parameter(Mandatory=$False, Position=1,ParameterSetName='Complete')]
        [Switch] $Complete, `
	    [Parameter(Mandatory=$False, Position=4,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=4,ParameterSetName='Tab')]
	    [Parameter(Mandatory=$False, Position=2,ParameterSetName='Complete')]
        [Switch] $NoNewLine, `
        [Parameter(Mandatory=$False, Position=5,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=8,ParameterSetName='Tab')]
	    [Parameter(Mandatory=$False, Position=3,ParameterSetName='Complete')]
        [String] $LogFile = "", `
	    [Parameter(Mandatory=$False, Position=5,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=4,ParameterSetName='Complete')]
        [Int16] $StartTab = 0, `
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=5,ParameterSetName='Complete')]
        [Int16] $LinesBefore = 0, `
        [Parameter(Mandatory=$False, Position=7,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Complete')]
        [Int16] $LinesAfter = 0, `
        [Parameter(Mandatory=$False, Position=9,ParameterSetName='Tab')]
        [String] $TimeFormat = "yyyy-MM-dd HH:mm:ss", `
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Normal')]
        [Parameter(Mandatory=$False, Position=10,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=1,ParameterSetName='Counter')]
        [Int64] $IndexCounter, `
        [Parameter(Mandatory=$False, Position=7,ParameterSetName='Normal')]
        [Parameter(Mandatory=$False, Position=11,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=2,ParameterSetName='Counter')]
        [Int64] $TotalCounter)

    Begin {
        $CurrentActionPreference = $ErrorActionPreference; 
        $ErrorActionPreference = 'Stop'

        If ($Text.Count -gt 0) {
            If ($BackgroundColor.Count -eq 0 -and $ForegroundColor.Count -eq 0) { $OperationMode = 'WriteHost' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -eq 0) { $OperationMode = 'SingleBackground' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -eq 0) { $OperationMode = 'SingleForeground' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count) { $OperationMode = 'SingleForegroundBackground' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count) { $OperationMode = 'SingleBackgroundForeground' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -ge $Text.Count -or $ForegroundColor.Count -eq 0) { $OperationMode = 'Background' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -ge $Text.Count -or $BackgroundColor.Count -eq 0) { $OperationMode = 'Foreground' }
            ElseIf ($BackgroundColor.Count -eq $Text.Count -and $ForegroundColor.Count -eq $Text.Count) { $OperationMode = 'Normal' }
            Else { Throw }
        }
        If ($Complete -eq $True) { $OperationMode = 'Complete' }
    }
    Process {
        If ($LinesBefore -ne 0) { For ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline } }
        If ($StartTab -ne 0) { For ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewLine } }
        If ($TotalCounter -gt 0 -and $IndexCounter -ge 0) {
            $CounterLength = $TotalCounter.ToString().Length
            Write-Host ("[" + ("{0:D$CounterLength}" -f ($IndexCounter + 1) + "/" + $TotalCounter) + "] ") -ForegroundColor DarkCyan -NoNewline
        }
        If ($OperationMode -eq 'WriteHost') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Foreground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Background') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'SingleBackground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -BackgroundColor $BackgroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'SingleForeground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'SingleForegroundBackground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[0] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'SingleBackgroundForeground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -BackgroundColor $BackgroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'Normal') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Complete') { Write-Host 'Complete' -ForegroundColor Green -NoNewLine }
        If ($LinesAfter -ne 0) { For ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host "`n" } }
    }
    End {
        If ($NoNewLine -eq $False) { Write-Host } Else { }
        If ($LogFile -ne "") {
            $TextToFile = ""
            For ($i = 0; $i -lt $Text.Length; $i++) {
                $TextToFile += $Text[$i]
            }
            Write-Output "[$([datetime]::Now.ToString($TimeFormat))] $TextToFile" | Out-File $LogFile -Encoding unicode -Append
        }
        $ErrorActionPreference = $CurrentActionPreference
    }
}
Function Clean-Profiles {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $ProfilesPath = 'C:\Users', `
        [Parameter(Mandatory=$False, Position=2)]
        [String[]] $Extensions = @("*.log","*.dmp","*.tmp","*.hdmp","*.mdmp","*.regtrans-ms","*.htm","*.dat"))

    #region 2. Get List of User Profiles - Obtains $Profiles as the reference List ($Profiles.Name)
        Try {
            Write-Color -Text "Obtaining a list of User Profiles from ", $ProfilesPath.toUpper(), " - " -ForegroundColor White, Yellow, White -NoNewLine
                $Profiles = Get-ChildItem $ProfilesPath -Force | Where-Object {$_.Mode -match "d"} -ErrorAction Stop
            Write-Color -Complete
        }
        Catch {
            Write-Color -Text "Failed! ", $_ -ForegroundColor Red, Red
        }
    #endregion
    #region 3. Delete Extensions from User Profiles Folder
    Write-Color -Text "Obtaining list of files from Profiles" -ForegroundColor White
    #region Variables
    [Int64] $ExtensionsCount = 1
    [Int64] $ProfilesCount = 1

    [Int64] $GrandTotalFiles = 0
    [Int64] $GrandTotalFilesRemoved = 0
    [Int64] $GrandTotalFilesNotRemoved = 0
    [Int64] $GrandTotalSpaceSaved = 0
    [Int64] $GrandTotalSpaceNotSaved = 0
    [Int64] $GrandTotalInaccessibleFiles = 0
    #endregion
    $ReportDetails = @()
    $FailedFiles = @()
    #ForEach ($Profile in $Profiles) {
    For ($i = 0; $i -lt $Profiles.Count; $i++) {
        #region Values
        [Int64] $ProfileTotalTempFiles = 0
        [Int64] $FilesRemoved = 0
        [Int64] $FilesNotRemoved = 0
        [Int64] $SpaceSaved = 0
        [Int64] $SpaceNotSaved = 0
        [Int64] $InaccessibleFiles = 0
        #endregion
        #region Process Profiles - Extensions
        Write-Color -IndexCounter $i -TotalCounter $Profiles.Count -Text "Processing ", $Profiles[$i].FullName, " - " -ForegroundColor White, Yellow, White -NoNewLine
        Try {
            #$TempFiles = Get-ChildItem $Profile.FullName -Recurse -Include $Extensions -Force -ErrorAction SilentlyContinue
            $TempFiles = Get-Childitem $Profiles[$i].FullName -Recurse -Include $Extensions -ErrorAction SilentlyContinue
            If ($TempFiles -ne $null) {
                ForEach ($TempFile in $TempFiles) {
                    [Int64] $TempFileSize = 0
                    Try {
                        #$FileDetails = Get-ChildItem $TempFile.FullName -Recurse -ErrorAction SilentlyContinue
                        Remove-Item $TempFile.FullName -Recurse -ErrorAction Stop | Out-Null
                        $FilesRemoved ++
                        $SpaceSaved = $SpaceSaved + ($TempFile.Length)
                        $ReportDetails += ,(New-Object -TypeName PSObject -Property @{
                            Profile      = $Profile
                            FileName     = $TempFile.FullName
                            FileSize     = $TempFile.Length
                        })

                    } 
                    Catch {
                        $FailedFiles += ,(New-Object -TypeName PSObject -Property @{
                            Profile      = $Profile
                            FileName     = $TempFile.FullName
                            Error        = $_
                        })
                    }
                }
            }
        }
        Catch { }
        #endregion

        Write-Color -Text "Saved (MB): ", ([Math]::Round(($SpaceSaved / 1024 / 1024),2)) -ForegroundColor White, Magenta 
    }
    #$ReportDetails | Select Profile, FileName, FileSize | Format-Table -AutoSize
    $ReportDetails | Select Profile, FileName, FileSize | Export-Csv ($env:temp + "\clean.csv") -Force -NoTypeInformation -Delimiter ","
    #$FailedFiles | Select Profile, Error | Format-Table -AutoSize
    $FailedFiles | Select Profile, Error | Export-Csv ($env:temp + "\Failed.csv") -Force -NoTypeInformation -Delimiter ","
}
Clear-Host
Clean-Profiles
#Notepad ($env:temp + "\clean.csv")
#Notepad ($env:temp + "\Failed.csv")