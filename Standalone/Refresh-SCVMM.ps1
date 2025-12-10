Function Write-Color {
    Param(
        [String[]] $Text, `
        [ConsoleColor[]] $Color, `
        [switch] $EndLine)
    
    If ($Text.Count -ne $Color.Length) {
        Write-Host "DEBUG!!!!! - Write-Color" -ForegroundColor Red
        Write-Host "The amount of Text variables and the amount of color variables does not match"
        Write-Host "Text Variables:  " $Text.Count
        Write-Host "Color Variables: " $Color.Length
        Break
    }
    Else {
        For ($i = 0; $i -lt $Text.Length; $i++) {
            Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
        }
        Switch ($EndLine){
            $true {Write-Host}
            $false {Write-Host -NoNewline}
        }
    }
}
Function RefreshSCVMHosts {
    Try {
        Write-Host "Collecting all Virtual Machine Hosts loaded in Virtual Machine Manager - " -NoNewline
        $SCVMHosts = Get-SCVMHost
        Write-Host "Complete" -ForegroundColor Green
        $SCVMHosts = $SCVMHosts | Sort Name
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Break
    }
    Write-Host "Total Hosts: " -NoNewline
    Write-Host $SCVMHosts.Count -ForegroundColor Yellow
    Write-Host ""
    $SCVMHostsCount = $SCVMHosts.Count
    $x = 1
    ForEach ($SCVMHost in $SCVMHosts) {
        Try {
            Write-Host "$x/$SCVMHostsCount" -ForegroundColor Cyan -NoNewLine 
            Write-Host " - Processing " -NoNewline
            Write-Host $SCVMHost.Name -NoNewline -ForegroundColor Yellow
            Write-Host ' - ' -NoNewline
            $empty = Read-SCVMHost -VMHost $SCVMHost -errorAction Stop
            Write-Host 'Complete' -ForegroundColor Green
        }
        Catch {
            Write-Host 'Failed' -ForegroundColor Red
        }
        $x ++
    }
}
Function RefreshSCVMs {
    Write-Host ""
    Write-Host "Collecting all Virtual Machines loaded in Virtual Machine Manager - " -NoNewline
    Try {
        $SCVMMVirtuals = Get-SCVirtualMachine -all -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Break
    }
    Write-Host "  Total Virtuals: " -NoNewline
    Write-Host $SCVMMVirtuals.Count -ForegroundColor Yellow
    Write-Host ""
    $SCVMMVirtualsCount = $SCVMMVirtuals.Count
    [int] $x = 1
    
    $SCVMMVirtuals = $SCVMMVirtuals | Sort Name

    ForEach ($VM in $SCVMMVirtuals) {
        $DisplayName = $VM.Name
        Write-Host "$x/$SCVMMVirtualsCount" -ForegroundColor Cyan -NoNewLine 
        Write-Host " - Refreshing" -NoNewline
        Write-Host " $VM " -ForegroundColor Yellow -NoNewline
        Write-Host "- " -NoNewline
        Try {
            $Empty = Read-SCVirtualMachine -VM $VM -errorAction Stop
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch {
            Write-Host "Failed" -ForegroundColor Red
        }
        $x ++
    }
}

RefreshSCVMHosts
RefreshSCVMs