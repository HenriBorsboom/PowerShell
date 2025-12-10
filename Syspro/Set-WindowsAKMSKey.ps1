Clear-Host
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
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $Color[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch {
        Write-Error $_ 
    }
}
Function Delete-LastLine {
    $CursorLeft = [System.Console]::CursorLeft
    $CursorTop  = [System.Console]::CursorTop
    [System.Console]::SetCursorPosition($CursorLeft ,$CursorTop  - 1)
    Write-Host "                                                                                                                                                                              "
    [System.Console]::SetCursorPosition($CursorLeft ,$CursorTop  - 1)
}
Function Get-HostVMs {
    Param (
        [Parameter(Mandatory=$True, Position=0)]
        [String] $VMHost)

    Write-Color "Getting VMs on ", $VMHost, " - " -Color White, Yellow, White -NoNewLine
        $VMs = (Get-VM -ComputerName $VMHost).Name
    Write-Host "Complete" -ForegroundColor Green

    $VMCount = $VMs.Count
    For ($i = 0; $i -lt $VMCount; $i ++) {
        Try   { 
            Write-Color -Text "Trying to installing ", "Datacenter", " Product Key on ", $VMs[$i], " - " -Color White, Cyan, White, Yellow, White -NoNewLine
            Invoke-Command -ComputerName $VMs[$i] -ScriptBlock { slmgr.vbs /ipk "Y4TGP-NPTV9-HTC2H-7MGQ3-DV4TW" } -ErrorAction Stop; 
            Write-Host "Complete" -ForegroundColor Green }
        Catch { 
            Delete-LastLine
            Try {
                Write-Color -Text "Trying to installing ", "Standard", " Product Key on ", $VMs[$i], " - " -Color White, Cyan, White, Yellow, White -NoNewLine
                Invoke-Command -ComputerName $VMs[$i] -ScriptBlock { slmgr.vbs /ipk "DBGBW-NPF86-BJVTX-K3WKJ-MTB6V" } -ErrorAction Stop; 
                Write-Host "Complete" -ForegroundColor Green
            }
            Catch {
                Delete-LastLine
                Try {
                    Write-Color -Text "Trying to installing ", "Essential", " Product Key on ", $VMs[$i], " - " -Color White, Cyan, White, Yellow, White -NoNewLine
                    Invoke-Command -ComputerName $VMs[$i] -ScriptBlock { slmgr.vbs /ipk "K2XGM-NMBT3-2R6Q8-WF2FK-P36R2" } -ErrorAction Stop; 
                    Write-Host "Complete" -ForegroundColor Green
                }
                Catch { Write-Host "Failed" -ForegroundColor Red }
            }
        }
    }
}    
Function Set-VMLicense {
    Param (
        [Parameter(Mandatory=$True, Position=0)]
        [String[]] $Servers)

    $VMHostCount = $Servers.Count
    For ($i = 0; $i -lt $VMHostCount; $i ++) {
        Get-HostVMs -VMHost $Servers[$i]
    }
}
$Servers = @(
    "SYSJHBHV1", 
    "SYSJHBHV2", 
    "SYSJHBHV3", 
    "SYSJHBHV4", 
    "SYSJHBHVTR", 
    "SYSJHBHVTR2", 
    "SYSJHBHVTR3", 
    "SYSJHBTESTHV", 
    "SYSJHBTESTHV2")
Set-VMLicense -Servers $Servers