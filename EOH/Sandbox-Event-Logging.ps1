<#Function Write-Log {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $LogData, `
        [Parameter(Mandatory=$False, Position=1)]
        [String] $FilePath = ($env:TEMP + "\log.txt"))
    $LogEntry = @()
    $LogEntry += ,(("[" + '{0:yyyy-MM-dd HH:mm:ss}' -f (Get-Date) + "]") + " - Start ---------------------------------------------------")
    ForEach ($Data in $LogData) { $LogEntry += ,($Data) }
    $LogEntry += ,(("[" + '{0:yyyy-MM-dd HH:mm:ss}' -f (Get-Date) + "]") + " - End -----------------------------------------------------")
    $LogEntry | Out-File $FilePath -Encoding ascii -Append -Force
}
#>
Function Write-Log {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $LogData, `
        [Parameter(Mandatory=$False, Position=1)]
        [String] $FilePath)

    If ($Global:LogFile -eq $null) { $FilePath = $env:TEMP + "\log.txt" }
    (("[" + '{0:yyyy-MM-dd HH:mm:ss}' -f (Get-Date) + "]") + " - Start ---------------------------------------------------") | Out-File $FilePath -Encoding ascii -Append
    ForEach ($Data in $LogData) { $Data | Out-File $FilePath -Encoding ascii -Append }
    (("[" + '{0:yyyy-MM-dd HH:mm:ss}' -f (Get-Date) + "]") + " - End -----------------------------------------------------") | Out-File $FilePath -Encoding ascii -Append
}
Function Call-Log {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $FilePath = ($env:TEMP + "\log.txt"))
    
     notepad $FilePath
}
Function Clear-Log {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $FilePath = ($env:TEMP + "\log.txt"))
    
     If (Test-Path $FilePath) { Remove-Item $FilePath }
}

Function Write-Color {
    Param(
        [Parameter(Mandatory=$True, Position = 1)]
        [String[]] $Text, `
        [Parameter(Mandatory=$False, Position = 2)]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory=$False, Position = 3)]
        [ConsoleColor[]] $BackgroundColor, `
        [Parameter(Mandatory=$False, Position = 4)]
        [Switch] $NoNewLine, `
        [Parameter(Mandatory=$False, Position = 5)]
        [Switch] $Complete, `
        [Parameter(Mandatory=$False, Position = 6)]
        [Switch] $SendToLog)

    $CurrentActionPreference = $ErrorActionPreference
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
    $ErrorActionPreference = $CurrentActionPreference
}
Function Query-WMI {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $RemoteServer, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $NameSpace, `
        [Parameter(Mandatory=$True, Position=3, ParameterSetName="Properties")]
        [String] $Class, `
        [Parameter(Mandatory=$True, Position=4, ParameterSetName="Properties")]
        [String[]] $Property, `
        [Parameter(Mandatory=$True, Position=2, ParameterSetName="Query")]
        [String] $Query)

    Try {
        $WMIResults = Get-WmiObject -Namespace $NameSpace -Class $Class -Property $Property -ComputerName $RemoteServer -ErrorAction Stop
        Write-Log -LogData @("Query-WMI", $NameSpace, $Property, $RemoteServer, $WMIResults)
    }
    Catch {
        Write-Log -LogData @("Query-WMI", "Failure", $_)
        Write-Color -Text $_ -ForegroundColor Red
    }
    Return $WMIResults
}
$Global:LogFile = 'C:\Temp\SandboxLog.txt'
Clear-Log
Query-WMI -RemoteServer 127.0.0.1 -NameSpace 'root\cimv2' -Class "Win32_bios" -Property "manufacturer"
Call-log