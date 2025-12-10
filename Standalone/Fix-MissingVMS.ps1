#Clear-Host

$MissingVMs = @(
    "WEBSERVER101", `
    "WEBSERVER105", `
    "WEBSERVER107")


#region Common Functions
Function Debug{
    Param(
        [Parameter(Mandatory=$false,Position=1)]
        $Variable)
    
    If ($Variable -eq $null){
        $VariableDetails = "Empty Variable"
    }
    Else{
        $VariableDetails = $Variable.getType()
    }
    
    Write-Host "------ DEBUG ------" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Variable Type: " -NoNewline -ForegroundColor Yellow
    Write-Host "$VariableDetails" -ForegroundColor Red
    Write-Host "  Variable Contents" -ForegroundColor Yellow
    Write-Host "  $Variable" -ForegroundColor Red
    Write-Host "  Complete" -ForegroundColor Green
    Write-Host ""
    
    $Return = Read-Host "Press C to continue. Any other key will quit. "
    If ($Return.ToLower() -eq "c"){
        Return
    }
    Else{
        Exit 1
    }
}

Function Strip-Name{
    Param(
        [String] $Name)
        
    $Name = $Name.Remove(0, 7)
    $Name = $Name.Remove($Name.Length - 1, 1)
    Return $Name
}

Function Write-Color {
    Param(
        [String[]] $Text, `
        [ConsoleColor[]] $Color, `
        [bool] $EndLine)
    
    For ($i = 0; $i -lt $Text.Length; $i++) {
        Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
    }
    Switch ($EndLine){
        $true {Write-Host}
        $false {Write-Host -NoNewline}
    }
}

#endregion

Function Fix-MissingVMS{
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [Array] $MissingVMs, `
        [Parameter(Mandatory=$true,Position=2)]
        [String] $VMHostnameFQDN, `
        [Parameter(Mandatory=$true,Position=3)]
        [String] $ClusterName)
        
    Write-Color -Text "Total Missing VMS: ", $MissingVMs.Count -Color White, Yellow -EndLine $true
    $x = 1
    ForEach ($MissingVM in $MissingVMs){
        Try{
            Write-Color -Text $x, "/", $MissingVMs.Count, " - ", $MissingVM -Color Yellow, Yellow, Yellow, White, Cyan -EndLine $true
            Write-Color -Text " $x", ".1/", $MissingVMs.Count, " - Migrating ", $MissingVM, " on Failover Cluster - " -Color Yellow, Yellow, Yellow, White, Cyan, White
                $empty = Move-ClusterVirtualMachineRole -Name $MissingVM -Cluster $ClusterName -ErrorAction Stop
            Write-Host "Complete" -ForegroundColor Green
            
            Write-Color -Text " $x", ".2/", $MissingVMs.Count, " - Refreshing ", $MissingVM, " in Virtual Machine Manager - " -Color Yellow, Yellow, Yellow, White, Cyan, White
                $empty = Read-SCVirtualMachine -VM $MissingVM -ErrorAction Stop
            Write-Host "Complete" -ForegroundColor Green
            
            Write-Color -Text " $x", ".3/", $MissingVMs.Count, " - Reading VM ", $MissingVM, " details in Virtual Machine Manager - " -Color Yellow, Yellow, Yellow, White, Cyan, White
                $SCVMMVM = Get-SCVirtualMachine -Name $MissingVM -ErrorAction Stop
            Write-Host "Complete" -ForegroundColor Green
            
            Write-Color -Text " $x", ".4/", $MissingVMs.Count, " - Reading Host ", "NRAZUREVMH101", " details in Virtual Machine Manager - " -Color Yellow, Yellow, Yellow, White, Cyan, White
                $vmHost = Get-SCVMHost | Where-Object {$_.Name -eq $VMHostnameFQDN} -ErrorAction Stop
            Write-Host "Complete" -ForegroundColor Green
            
            Write-Color -Text " $x", ".5/", $MissingVMs.Count, " - Moving ", $MissingVM, " in Virtual Machine Manager - " -Color Yellow, Yellow, Yellow, White, Cyan, White
                $empty = Move-SCVirtualMachine -VM $SCVMMVM -VMHost $vmHost -HighlyAvailable $true -UseDiffDiskOptimization -ErrorAction Stop
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch{
            Write-Host "Failed" -ForegroundColor Red
        }
        $x ++
    }
}

Fix-MissingVMS -MissingVMs $MissingVMs -VMHostnameFQDN "NRAZUREVMH101.domain2.local" -ClusterName "NRAZUREVMHC101"