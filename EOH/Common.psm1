#region Console Output Formatting
Function Write-Color {
    <#
    .SYNOPSIS
	    Write Host with Simpler Color Management
    .DESCRIPTION
	    Write-Color gives you the same functionality as Write-Host but with simpler and quicker color management
    .EXAMPLE
	    Write-Color -Text 'Test 1 '
    .EXAMPLE
	    Write-Color -Text 'Test 1 ' -ForegroundColor Black
    .EXAMPLE
	    Write-Color -Text 'Test 1 ' -BackgroundColor Yellow
    .EXAMPLE
	    Write-Color -Text 'Test 1 ' -ForegroundColor Black -BackgroundColor Yellow
    .EXAMPLE
	    Write-Color -Text 'Test 1 ', 'Test 2 ' -ForegroundColor Yellow -BackgroundColor Black
    .EXAMPLE
	    Write-Color -Text 'Test 1 ', 'Test 2 ' -ForegroundColor Yellow, Green -BackgroundColor Black, Yellow
    .EXAMPLE
	    Write-Color -Complete
    .EXAMPLE
	    Write-Color -Text 'Test 1 ', 'Test 2 ' -ForegroundColor Yellow, Green -BackgroundColor Black, Yellow -NoNewline
    .EXAMPLE
	    Write-Color -Complete -NoNewline
    .INPUTS
	    [String[]]
    .PARAMETER Text
	    This is the collection of text that needs to be written to the host
    .INPUTS
	    [ConsoleColor[]]
    .PARAMETER ForegroundColor
	    This is the collection of Foreground colors that needs to be applied to the text
	    If there is more text in the collection and only 1 Foreground color is specified
	    then the first foreground color will be applied to all text
    .INPUTS
	    [ConsoleColor[]]
    .PARAMETER BackgroundColor
	    This is the collection of Background colors that needs to be applied to the text
	    If there is more text in the collection and only 1 Background color is specified
	    then the first Background color will be applied to all text
    .INPUTS
	    [Switch]
    .PARAMETER NoNewLine
	    This is to specify if you want to terminate the line or not
    .INPUTS
	    [Switch]
    .PARAMETER Complete
	    This is will write to the host "Complete" with the Foreground color set to Green
    .INPUTS
	    [Int64]
    .PARAMETER IndexCounter
	    This is the counter for the current item
    .INPUTS
	    [Int64]
    .PARAMETER TotalCounter
	    This is the total number of items that needs to be processed. This is needed
        to format the counter properly
    .Notes
        NAME:  Write-Color
        AUTHOR: Henri Borsboom
        LASTEDIT: 30/08/2017
        KEYWORDS: Write-Host, Console Output, Color
    .Link
        https://www.linkedin.com/pulse/powershell-<>-henri-borsboom
        #Requires -Version 2.0
    #>
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
Function Delete-LastLine {
    If ($Host.Name -notlike '*ISE*') {
        $PShost = Get-Host
        $pswindow = $pshost.ui.rawui

        $x = [Console]::CursorLeft
        $y = [Console]::CursorTop
        [Console]::SetCursorPosition($x,$y - 1)
        $String = ""
        For ($i = 0; $i -lt $pswindow.windowsize.Width; $i ++) {
            $String = ($String + " ")
        }

        Write-Host $String
        [Console]::SetCursorPosition($x,$y -1)
    }
}
Function Set-SpotProgress {
    If ($Host.Name -notlike '*ISE*') {
        $PShost = Get-Host
        $pswindow = $pshost.ui.rawui

        $x = [Console]::CursorLeft
        $y = [Console]::CursorTop
        [Console]::SetCursorPosition($x, $y)

        $CursorIndex = @('-', '\', '|', '/')
        If ($Global:CurrentSpot -eq $null)              { $Global:CurrentSpot = 0 }
        If ($Global:CurrentSpot -gt $CursorIndex.Count) { $Global:CurrentSpot = 0 }
        Write-Host $CursorIndex[$Global:CurrentSpot] -NoNewline -ForegroundColor Cyan
        $Global:CurrentSpot ++
        [Console]::SetCursorPosition($x, $y)
        Write-Host "" -NoNewline
    }
    # Testing
    <#
    Write-host "line 1 ------------------------"
    Write-host "line 2 ------------------------"
    Write-host "line 3 ------------------------"
    Write-host "line 4 ------------------------" -NoNewline
    For ($i = 0; $i -lt 10; $i ++) {
        Delete-Spot
        Start-Sleep -Milliseconds 100
    }
    write-host
    #>
}
Function Start-Wait {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Int64] $Seconds)

    For ($i = 0; $i -lt $Seconds; $i ++) { Write-Host "." -ForegroundColor Cyan -NoNewline; Start-Sleep -Seconds 1 }
    Write-Host
}
Function Get-TotalTime {
    Param(
        [Parameter(Mandatory=$True,  Position=1)]
        [DateTime] $StartTime, `
        [Parameter(Mandatory=$False, Position=2)]
        [DateTime] $EndTime = (Get-Date))

    $Duration = New-TimeSpan -Start $StartTime -End $EndTime
    $ReturnVariable = ("{0:hh\:mm\:ss}" -f ([TimeSpan]::FromSeconds($Duration.TotalSeconds)))
    Return $ReturnVariable
}
#endregion
#region Logging
Function Write-Log {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $LogData, `
        [Parameter(Mandatory=$False, Position=1)]
        [String] $FilePath)

    If ($FilePath -eq "") {
        If ($Global:LogFile -eq "" -or $Global:LogFile -eq $null) {
            Write-Color -Text "Global Log File Empty." -ForegroundColor Red -NoNewLine
            $FilePath = $env:TEMP + "\" + ('{0:yyyyMMdd-HHmmss}' -f (Get-Date) + ".log");
            $Global:LogFile = $FilePath
            Write-Color -Text " Global Log file set to ", $Global:LogFile -ForegroundColor Yellow, Green
        }
        Else {
            $FilePath = $Global:LogFile
        }
    }
    (("[" + '{0:yyyy-MM-dd HH:mm:ss}' -f (Get-Date) + "]") + " - Start ---------------------------------------------------") | Out-File $FilePath -Encoding ascii -Append
    ForEach ($Data in $LogData) { $Data | Out-File $FilePath -Encoding ascii -Append }
    (("[" + '{0:yyyy-MM-dd HH:mm:ss}' -f (Get-Date) + "]") + " - End -----------------------------------------------------") | Out-File $FilePath -Encoding ascii -Append
}
Function Call-Log {
    If ($Global:LogFile -eq "") { Write-Host "Cannot call Log File as no Global Log file exists" }
    Else { $FilePath = $Global:LogFile }
    notepad $FilePath
}
Function Clear-Log {
    If ($Global:LogFile -eq "") { Write-Host "Cannot call Log File as no Global Log file exists" }
    Else { $FilePath = $Global:LogFile }
    If (Test-Path $FilePath) { Try { Remove-Item $FilePath } Catch { Write-Color -Text "Failed to remove ", $FilePath -ForegroundColor Red, Yellow; Write-Color -Text $_ -ForegroundColor Red } }
}
#endregion
#region Common Lookups and Return Values
Function Get-LastBootTime {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Computer)

    $Installed = Get-WmiObject -class Win32_OperatingSystem -ComputerName $Computer -Property LastBootupTime | `
		Select-Object @{
			label        = 'LastBootupTime';
			expression   = {$_.ConvertToDateTime($_.LastBootupTime)}
		}

    $Details = New-Object PSObject -Property @{
        "Computer"       = $Computer
        "LastBootupTime" = $Installed.LastBootupTime
    }
    Return $Details
}
Function Get-DomainComputers {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Domain = $env:USERDOMAIN)

    Import-Module ActiveDirectory
    $Servers = Get-ADComputer -Filter { ObjectClass -eq "computer" }
    $Servers = $Servers | Sort Name

    Return $Servers.Name
}
Function Get-VMHost {
    Param(
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Computer)

    Try {
        $Registry    = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
        $RegistryKey = $Registry.OpenSubKey('SOFTWARE\\Microsoft\\Virtual Machine\\Guest\\Parameters')
        $Value       = $RegistryKey.GetValue('HostName')
    }
    Catch { $Value = "Not found" }
    Return $Value
}
Function Get-LastBootTime {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Computer)

    $Installed = Get-WmiObject -class Win32_OperatingSystem -ComputerName $Computer -Property LastBootupTime | `
		Select-Object @{
			label        = 'LastBootupTime';
			expression   = {$_.ConvertToDateTime($_.LastBootupTime)}
		}

    $Details = New-Object PSObject -Property @{
        "Computer"       = $Computer
        "LastBootupTime" = $Installed.LastBootupTime
    }
    Return $Details
}
#endregion
#region Email Data
Function Send-Email {
    Param(
        [Parameter(Mandatory=$True, Position=1)]
        [string]   $From = $(throw "Please specify from email address !"), `
        [Parameter(Mandatory=$True, Position=2)]
        [string[]] $To = $(throw "Please Specify a destination !"),
        [Parameter(Mandatory=$True, Position=3)]
        [string]   $Subject = "<No Subject>",
        [Parameter(Mandatory=$True, Position=4)]
        [string]   $Body = $(throw "Please specify a content !"),
        [Parameter(Mandatory=$True, Position=5)]
        [string]   $SMTPServer = $(throw "Please specify a SMTP server !"),
        [Parameter(Mandatory=$True, Position=6)]
        [Int16]    $SMTPPort = $(throw "Please specify a SMTP server !"))

    Try {
        Write-Host "Trying to send message with Send-MailMessage - " -NoNewline
        Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -SMTPServer $SMTPServer -Port $SMTPPort
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host "Trying to send message with System.Net.Mail.MailMessage - " -NoNewline
        $Email = New-Object System.Net.Mail.MailMessage

        ## Fill the fields
        ForEach($MailTo in $To)
        {
          $Email.To.Add($MailTo)
        }

        $Email.From = $From
        $Email.Subject = $Subject
        $Email.Body = $Body

        ## Send the message
        $Client = New-Object System.Net.Mail.SmtpClient $smtpHost
        $client.UseDefaultCredentials = $true
        $client.Send($email)
        Write-Host "Complete" -ForegroundColor Green
    }
    # Testing
    <#
    $Recipients = @()
    $Recipients += ,("user1@domain.local")
    $Recipients += ,("user2@domain.local")
    $Recipients += ,("user3@domain.local")

    $Body = @(
    "This is a test email
    with all the strange details"
    )

    Send-Email `
        -From "source.email@test.local" `
        -To $Recipients `
        -Subject "Subject Matter" `
        -Body $Body `
        -SMTPServer "SMTPServer1.test.local" `
        -SMTPPort 25
    #>
}
#endregion
#region Personal
Function Encrypt-Folder {
    $Folder = 'C:\windows\system32\drivers\en-ZA'
    cd $Folder
    $Files = Get-ChildItem -Path $Folder
    $EncryptCounter = 0
    ForEach ($File in $Files) {
        If ($File.Extension -eq ".mp4") {
            $NewName = ""
            For ($i = (($File.BaseName).Length - 1); $i -gt -1; $i --) { $NewName = $NewName + ($File.BaseName).ToString().Chars($i) }
            Rename-Item $File.Name -NewName ($NewName + ".4pm")
            $EncryptCounter ++
        }
        If ($File.Extension -eq ".swf") {
            $NewName = ""
            For ($i = (($File.BaseName).Length - 1); $i -gt -1; $i --) { $NewName = $NewName + ($File.BaseName).ToString().Chars($i) }
            Rename-Item $File.Name -NewName ($NewName + ".fws")
            $EncryptCounter ++
        }
    }
    Get-ChildItem
    Write-Host
        Write-Host
        Write-Color -Text "Total Files in Folder: ", $Files.Count, " - ", $EncryptCounter, " Encrypted" -ForegroundColor White, Yellow, White, Yellow, White
}
Function Decrypt-Folder {
    $Folder = 'C:\windows\system32\drivers\en-ZA'
    cd $Folder
    $Files = Get-ChildItem -Path $Folder
    $DecryptCounter = 0
    ForEach ($File in $Files) {
        If ($File.Extension -eq ".4pm") {
            $NewName = ""
            For ($i = (($File.BaseName).Length - 1); $i -gt -1; $i --) { $NewName = $NewName + ($File.BaseName).ToString().Chars($i) }
            Rename-Item $File.Name -NewName ($NewName + ".mp4")
            $DecryptCounter ++
        }
        If ($File.Extension -eq ".fws") {
            $NewName = ""
            For ($i = (($File.BaseName).Length - 1); $i -gt 1; $i --) { $NewName = $NewName + ($File.BaseName).ToString().Chars($i) }
            Rename-Item $File.Name -NewName ($NewName + ".swf")
            $DecryptCounter ++
        }
    }
    Get-ChildItem
    Write-Host
    Write-Host
    Write-Color -Text "Total Files in Folder: ", $Files.Count, " - ", $DecryptCounter, " Decrypted" -ForegroundColor White, Yellow, White, Yellow, White
}
#endregion

Function Testing {
<#
hWnd 	A handle to the window
hWndInsertAfter	A handle to the window to precede the positioned window in the Z order
	HWND_BOTTOM (1)
	HWND_NOTOPMOST (-2)
	HWND_TOP (0)
	HWND_TOPMOST (-1)

X [in]			The new position of the left side of the window, in client coordinates.
Y [in]			The new position of the top of the window, in client coordinates.
cx [in]			The new width of the window, in pixels.
cy [in]			The new height of the window, in pixels.
uFlags
	SWP_ASYNCWINDOWPOS	0x4000
	SWP_DEFERERASE 		0x2000
	SWP_DRAWFRAME		0x0020
	SWP_FRAMECHANGED	0x0020
	SWP_HIDEWINDOW		0x0080
	SWP_NOACTIVATE		0x0010
	SWP_NOCOPYBITS		0x0100
	SWP_NOMOVE			0x0002
	SWP_NOOWNERZORDER	0x0200
	SWP_NOREDRAW		0x0008
	SWP_NOREPOSITION	0x0200
	SWP_NOSENDCHANGING	0x0400
	SWP_NOSIZE			0x0001
	SWP_NOZORDER		0x0004
	SWP_SHOWWINDOW		0x0040
#>

$signature = @"
[DllImport("user32.dll")]public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
[DllImport("user32.dll")]
    public static extern bool SetWindowPos(
    IntPtr hWnd,
    IntPtr hWndInsertAfter,
    int X,
    int Y,
    int cx,
    int cy,
    uint uFlags);
"@

$ProcessName = "notepad"
$ThisProcess = Start-Process notepad
$NotePadProcess = (Get-Process $ProcessName)
$showWindowAsync = Add-Type -MemberDefinition $signature -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru
$type = Add-Type -MemberDefinition $signature -Name SetWindowPosition -Namespace SetWindowPos -Using System.Text -PassThru
# Minimize the Windows PowerShell console
$showWindowAsync::ShowWindowAsync((Get-Process -Name $ProcessName).MainWindowHandle, 2)
# Restore it
$showWindowAsync::ShowWindowAsync((Get-Process -Name $ProcessName).MainWindowHandle, -2)
#$showWindowAsync::ShowWindowAsync((Get-Process -Name $ProcessName).MainWindowHandle, 5)

<#
$type = Add-Type -MemberDefinition $signature -Name SetWindowPosition -Namespace SetWindowPos -Using System.Text -PassThru
$handle = (Get-Process -id $Global:PID).MainWindowHandle
$alwaysOnTop = New-Object -TypeName System.IntPtr -ArgumentList (-1)

Switch ($Switch) {
$True {$type::SetWindowPos($NotePadProcess.MainWindowHandle, $alwaysOnTop, 0, 0, 0, 0, 0x0003) | Out-Null}
$False { $type::SetWindowPos($handle, 1, 0, 0, 0, 0, 0x0003) | Out-Null}
}
#>
<#
hWnd 	A handle to the window
hWndInsertAfter	A handle to the window to precede the positioned window in the Z order
	HWND_BOTTOM (1)
	HWND_NOTOPMOST (-2)
	HWND_TOP (0)
	HWND_TOPMOST (-1)

X [in]			The new position of the left side of the window, in client coordinates.
Y [in]			The new position of the top of the window, in client coordinates.
cx [in]			The new width of the window, in pixels.
cy [in]			The new height of the window, in pixels.
uFlags
	SWP_ASYNCWINDOWPOS	0x4000
	SWP_DEFERERASE 		0x2000
	SWP_DRAWFRAME		0x0020
	SWP_FRAMECHANGED	0x0020
	SWP_HIDEWINDOW		0x0080
	SWP_NOACTIVATE		0x0010
	SWP_NOCOPYBITS		0x0100
	SWP_NOMOVE			0x0002
	SWP_NOOWNERZORDER	0x0200
	SWP_NOREDRAW		0x0008
	SWP_NOREPOSITION	0x0200
	SWP_NOSENDCHANGING	0x0400
	SWP_NOSIZE			0x0001
	SWP_NOZORDER		0x0004
	SWP_SHOWWINDOW		0x0040
#>







}

