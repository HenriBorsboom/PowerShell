Param (
    [Parameter(Mandatory=$False, Position=0)]
    [String] $Computer)

Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $Color, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]         $Nonewline=$False)
    Begin {
    }
    Process {
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $Color[$Index] -NoNewLine
        }
        Switch ($Nonewline){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
}
Function Process-Services {
    Param (
        [Parameter(Mandatory=$False, Position=0)]
        [String] $Computer)

    If ($Computer -eq "" -or $Computer -eq $null) { 
        $Result = Get-WmiObject -Query "Select * From Win32_Service" 
        ForEach ($Service in $Result) {
            If ($Service.StartMode -eq "Auto" -and $Service.State -eq "Stopped") { 
                Try {
                    Write-Color -Text "Starting ", $Service.Name, " - " -Color White, Yellow, White -Nonewline
                    Start-Service $Service.Name -Confirm:$false -ErrorAction Stop -WarningAction SilentlyContinue
                    Write-Color -Text "Complete" -Color Green
                }
                Catch {
                    Write-Color "Failed - $_" -Color Red
                }
            }
        }
    }
    Else {
        If (Test-Connection -ComputerName $Computer -Count 2 -Quiet) {
            $Result = Get-WmiObject -Query "Select * From Win32_Service" -ComputerName $Computer 
            ForEach ($Service in $Result) {
                If ($Service.StartMode -eq "Auto" -and $Service.State -eq "Stopped") { 
                    Try {
                        Write-Color -Text "Starting ", $Service.Name, " - " -Color White, Yellow, White -Nonewline
                         Invoke-Command -ComputerName $Computer -ArgumentList $Service.Name -ScriptBlock { Param ($ServiceName); Start-Service $ServiceName -Confirm:$false -ErrorAction Stop -WarningAction SilentlyContinue }
                        Write-Color -Text "Complete" -Color Green
                    }
                    Catch {
                        Write-Color "Failed - $_" -Color Red
                    }
                }
            }
        }
        Else {
            Write-Color "Unable to test connection to ", $Computer -Color White, Red
        }
}
}
Clear-Host
If ($Computer -eq "" -or $Computer -eq $null) { Process-Services } Else { Process-Services -Computer $Computer }