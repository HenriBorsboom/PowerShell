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

Write-Host "Getting SCVM Hosts - " -NoNewline
    $SCVMHosts = Get-SCVMHost | Sort Name
Write-Host "Complete" -ForegroundColor Green

$SCVMHostsCounter = 1
$SCVMHostsCount   = $SCVMHosts.Count

ForEach ($SCVMHost in $SCVMHosts) {
    Write-Color -Text "$SCVMHostsCounter\$SCVMHostsCount", " - Refreshing SCVMHost ", $SCVMHost.Name, " - " -Color Cyan, White, Yellow, White -NoNewLine
        Read-SCVMHost -VMHost $SCVMHost | Out-Null
    Write-Host "Complete" -ForegroundColor Green -NoNewline
    
    Write-Color -Text "$SCVMHostsCounter\$SCVMHostsCount", " - Getting VMs on ", $SCVMHost.Name, " - " -Color Cyan, White, Yellow, White -NoNewLine
        $HostVMS = Get-SCVirtualMachine -VMHost $SCVMHost
    Write-Host "Complete" -ForegroundColor Green
        
    $HostVMsCounter = 1
    $HostVMsCount   = $HostVMS.Count
    ForEach ($VM in $HostVMS) {
        Write-Color -Text "$HostVMsCounter\$HostVMsCount - $SCVMHostsCounter\$SCVMHostsCount", " - Refreshing VM ", $VM.Name, " - " -Color Cyan, White, Yellow, White -NoNewLine
        Read-SCVirtualMachine -VM $VM | Out-Null
        Write-Host "Complete" -ForegroundColor Green
        $HostVMsCounter ++
    }
    $SCVMHostsCounter ++
}