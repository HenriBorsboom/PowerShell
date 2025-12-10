Function Test-1 {
    Param ($Servers,$UNCPath)

    $x = 1; 
    ForEach ($Server in $Servers) {
        ForEach ($Exe in (Get-ChildItem "\\nrazureapp103\UpdateServicesPackages\EP_SourceDef\x64\*.exe").FullName) { 
            Write-Host "Loop 1: - Patch: $x" 
            Invoke-Command -ComputerName $Server -ArgumentList $Exe -ScriptBlock { Param ($EXE); Start-Process $EXE -Wait }
            $x ++
        }
        $x = 1
    
        ForEach ($Exe in (Get-ChildItem "\\nrazureapp103\UpdateServicesPackages\EP_SourceDef\x64\*.exe").FullName) { 
            Write-Host "Loop 2: - Patch: $x" 
            Invoke-Command -ComputerName $Server -ArgumentList $Exe -ScriptBlock { Param ($EXE); Start-Process $EXE -Wait }
            $x ++
        }
        $x = 1
    }
}
Function Test-2 {
    Param ($Servers,$UNCPath)

    $x = 1; 
    ForEach ($Server in $Servers) {
        ForEach ($Exe in (Get-ChildItem $UNCPath).FullName) { 
            Write-Host "Patch: $x - $Exe" 
            #$Session = New-PSSession -ComputerName $Servers[0] #-Authentication NegotiateWithImplicitCredential
            #Invoke-Command -Session $Session -ArgumentList $Exe -ScriptBlock { Param ($EXE); Start-Process $EXE.ToString() -Wait }
            Invoke-Command -ComputerName $Server -ArgumentList $Exe -ScriptBlock { Param ($EXE); Start-Job -ScriptBlock { Start-Process $EXE -Wait} | Wait-Job | Get-Job }
            $x ++
        }
    }
}

Clear-Host

$Servers = @(
    "NRAZUREAPP102")

$UNCPath = "\\nrazureapp103\UpdateServicesPackages\EndPoint_Def_Manual"
Test-2 -Servers $Servers -UNCPath $UNCPath
