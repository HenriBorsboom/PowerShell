Clear-Host

$VMHosts = @(
            "NRAZUREVMH101", `
            "NRAZUREVMH103", `
            "NRAZUREVMH201")

#region Common Functions
Function Debug{
    Param([Parameter(Mandatory=$false,Position=1)]
    $Variable)
    
    If ($Variable -eq $null)
    {
        $VariableDetails = "Empty Variable"
    }
    Else
    {
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
    If ($Return.ToLower() -eq "c")
    {
        Return
    }
    Else
    {
        Exit 1
    }
}

Function Strip-Name{
    Param([String] $Name)
        
    $Name = $Name.Remove(0, 7)
    $Name = $Name.Remove($Name.Length - 1, 1)
    Return $Name
}

Function Write-Color {
    Param(
        [String[]]$Text, `
        [ConsoleColor[]]$Color, `
        [bool] $EndLine)
    
    For ($i = 0; $i -lt $Text.Length; $i++) {
        Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
    }
    
    Switch ($EndLine)
    {
        $true {Write-Host}
        $false {Write-Host -NoNewline}
    }
    #Write-Color -Text "Reading data from ","host1", " - ","complete" -Color White,Cyan,White,Green
}

#endregion

Function Clean-TXT{
    Remove-Item ".\*.CSV"
}

Function Get-VMsonHosts{
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [Array] $VMHosts)

    $x = 01
    ForEach ($VMHost in $VMHosts){
        Write-Color -Text "Total Hosts: ", $VMHosts.Count -Color White, Yellow -EndLine $True
        
        Write-Color -Text "$x", " - Obtaining Virtual Machines hosted on ", "$VMHost", " - " -Color Yellow, White, Yellow, White
            $HostedVMS = Get-VMsPerHost -VMHost $VMHost
        Write-Host "Complete" -ForegroundColor Green; Write-Host ""
    
        Write-Color -Text "  Total VMs on ", $VMHost, ": ", $HostedVMS.Count -Color White, Cyan, White, Yellow -EndLine $True
        $y = 01
        ForEach ($VM in $HostedVMS){
            $VMName = $VM.Name
            Write-Color -Text "  $y", " - Obtaining ", "$VMName", " details - " -Color Yellow, White, Cyan, White
            $VMDetails = Get-VMDetails -VMName $VMName -VMHostName $VMHost
            Write-Host "Complete" -ForegroundColor Green -NoNewline
        
            $VMExportFile = ".\" + $VMName + ".CSV"
            Write-Color -Text " - Exporting to ", $VMExportFile, " - " -Color White, Cyan, White
            $VMDetails | Out-File $VMExportFile -Encoding ascii
            (Get-Content $VMExportFile) | ? {$_.trim() -ne "" } | set-content $VMExportFile
            Write-Host "Complete" -ForegroundColor Green
            $y ++
        }
        $x ++
        Write-Host ""
    }
}

Function Get-VMsPerHost{
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [String] $VMHost)

    $HostsVMs = Get-VM -ComputerName $VMHost
    Return $HostsVMs
}

Function Get-VMDetails{
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [String] $VMName, `
        [Parameter(Mandatory=$True,Position=2)]
        [String] $VMHostName)
    
    [String] $TempValue
    [Microsoft.HyperV.PowerShell.VirtualMachineBase] $VM = Get-VM -Name $VMName -ComputerName $VMHostName

    $Output = New-Object PSObject

#region Primary Details

    #region Memory Recalculation
        $MemoryAssigned = ($VM.MemoryAssigned / 1024 / 1024 /1024)
            $MemoryAssigned = [math]::Round($MemoryAssigned).ToString() + " GB"
                    
        $MemoryMaximum = ($VM.MemoryDemand / 1024 / 1024 /1024)
            $MemoryMaximum = [math]::Round($MemoryDemand).ToString() + " GB"
                    
        $MemoryStartup = ($VM.MemoryStartup / 1024 / 1024 /1024)
            $MemoryStartup = [math]::Round($MemoryStartup).ToString() + " GB"
                    
        $MemoryMinimum = ($VM.MemoryMinimum / 1024 / 1024 /1024)
            $MemoryMinimum = [math]::Round($MemoryMinimum).ToString() + " GB"
                    
        $MemoryMaximum = ($VM.MemoryMaximum / 1024 / 1024 /1024)
            $MemoryMaximum = [math]::Round($MemoryMaximum).ToString() + " GB"
        
        $MemoryDemand = ($VM.MemoryMaximum / 1024 / 1024 /1024)
            $MemoryDemand = [math]::Round($MemoryDemand).ToString() + " GB"
            
    #endregion
    
    $Output | Add-Member -MemberType NoteProperty -Name VMName -Value $VM.VMName
    $Output | Add-Member -MemberType NoteProperty -Name VMHostName -Value $VM.Computername
    #$Output | Add-Member -MemberType NoteProperty -Name Path -Value $VM.Path
    
    #$Output | Add-Member -MemberType NoteProperty -Name Generation -Value $VM.Generation
    #$Output | Add-Member -MemberType NoteProperty -Name IsClustered -Value $VM.IsClustered
    #$Output | Add-Member -MemberType NoteProperty -Name Version -Value $VM.Version
    
    #$Output | Add-Member -MemberType NoteProperty -Name IntegrationServicesState -Value $VM.IntegrationServicesState
    #$Output | Add-Member -MemberType NoteProperty -Name IntegrationServicesVersion -Value $VM.IntegrationServicesVersion
    
    $Output | Add-Member -MemberType NoteProperty -Name ProcessorCount -Value $VM.ProcessorCount
    
    $Output | Add-Member -MemberType NoteProperty -Name DynamicMemoryEnabled -Value $VM.DynamicMemoryEnabled
    #$Output | Add-Member -MemberType NoteProperty -Name MemoryAssigned -Value $MemoryAssigned
    #$Output | Add-Member -MemberType NoteProperty -Name MemoryDemand -Value $MemoryDemand
    $Output | Add-Member -MemberType NoteProperty -Name MemoryStartup -Value $MemoryStartup
    $Output | Add-Member -MemberType NoteProperty -Name MemoryMinimum -Value $MemoryMinimum
    $Output | Add-Member -MemberType NoteProperty -Name MemoryMaximum -Value $MemoryMaximum
    
    #$Output | Add-Member -MemberType NoteProperty -Name AutomaticStartAction -Value $VM.AutomaticStartAction
    #$Output | Add-Member -MemberType NoteProperty -Name AutomaticStopAction -Value $VM.AutomaticStopAction
    
    # $Output | Add-Member -MemberType NoteProperty -Name VMID -Value $VM.VMID
    # $Output | Add-Member -MemberType NoteProperty -Name ConfigurationLocation -Value $VM.ConfigurationLocation
    
#endregion

#region VHD

    $x = 1
    ForEach ($VHD in $VM.HardDrives){
        #$VHDText = "VHD" + $x + "_ControllerType"; $Output | Add-Member -MemberType NoteProperty -Name $VHDText -Value $VHD.ControllerType
        #$VHDText = "VHD" + $x + "_ControllerNumber"; $Output | Add-Member -MemberType NoteProperty -Name $VHDText -Value $VHD.ControllerNumber
        #$VHDText = "VHD" + $x + "_ControllerLocation"; $Output | Add-Member -MemberType NoteProperty -Name $VHDText -Value $VHD.ControllerLocation
        $VHDText = "VHD" + $x + "_Path"; $Output | Add-Member -MemberType NoteProperty -Name $VHDText -Value $VHD.Path
        $x ++
    }
    $x = 1

#endregion

#region Network Details

    $x = 1
    ForEach ($NetAdapter in $VM.NetworkAdapters){
        #$NetworkAdapterText = "NetworkAdapter" + $x + "_ClusterMonitored"; $Output | Add-Member -MemberType NoteProperty -Name $NetworkAdapterText -Value $NetAdapter.ClusterMonitored
        #$NetworkAdapterText = "NetworkAdapter" + $x + "_IsLegacy"; $Output | Add-Member -MemberType NoteProperty -Name $NetworkAdapterText -Value $NetAdapter.IsLegacy
        #$NetworkAdapterText = "NetworkAdapter" + $x + "_DynamicMacAddressEnabled"; $Output | Add-Member -MemberType NoteProperty -Name $NetworkAdapterText -Value $NetAdapter.DynamicMacAddressEnabled
        #$NetworkAdapterText = "NetworkAdapter" + $x + "_MACAddress"; $Output | Add-Member -MemberType NoteProperty -Name $NetworkAdapterText -Value $NetAdapter.MACAddress
        #$NetworkAdapterText = "NetworkAdapter" + $x + "_SwitchID"; $Output | Add-Member -MemberType NoteProperty -Name $NetworkAdapterText -Value $NetAdapter.SwitchID
        #$NetworkAdapterText = "NetworkAdapter" + $x + "_Connected"; $Output | Add-Member -MemberType NoteProperty -Name $NetworkAdapterText -Value $NetAdapter.Connected
        #$NetworkAdapterText = "NetworkAdapter" + $x + "_SwitchName"; $Output | Add-Member -MemberType NoteProperty -Name $NetworkAdapterText -Value $NetAdapter.SwitchName
        #$NetworkAdapterText = "NetworkAdapter" + $x + "_Name"; $Output | Add-Member -MemberType NoteProperty -Name $NetworkAdapterText -Value $NetAdapter.Name
        
        # Get IP details for Adapter
        $y = 1
        ForEach($IP in $NetAdapter.IPAddresses){
            $IPText = "NetworkAdapter" + $x + "_IP" + $y; $Output | Add-Member -MemberType NoteProperty -Name $IPText -Value $IP
            $y ++
        }
        $y = 1
        $x ++
    }
    $x = 1

#endregion

#region VM Integration Services

    #$x = 1
    #ForEach ($VMIS in $VM.VMIntegrationService){
    #    [String] $VMISText = $VMIS.Name
    #    $VMISText = $VMISText.Trim(); $Output | Add-Member -MemberType NoteProperty -Name $VMISText -Value $VMIS.Enabled
    #    #$VMISText = "VMIntegrationService" + $x + "_Enabled"; $Output | Add-Member -MemberType NoteProperty -Name $VMISText -Value $VMIS.Enabled
    #    $x ++
    #}
    #$x = 1

#endregion

    #region Clear Temporary Variables
        Remove-Variable MemoryAssigned
        Remove-Variable MemoryDemand
        Remove-Variable MemoryStartup
        Remove-Variable MemoryMinimum
        Remove-Variable MemoryMaximum
    #endregion

    Return $Output
}

Function Combine-Details{
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [String] $Outfile)

    $OutFile = ".\" + $OutFile

    If (Test-Path $Outfile)
    {
        $Empty = Remove-Item -Path $Outfile
    }
    $Empty = New-Item -ItemType File -Path $OutFile
        
    Write-Host "Gathering CSV files - " -NoNewline
        $TextFiles = Get-ChildItem ".\*.CSV" | select Name
    Write-Host "Complete" -ForegroundColor Green
    
    ForEach ($File in $TextFiles){
        If ($File -ne $Outfile)
        {
            [string] $ServerName = Strip-Name -Name $File
            $ServerName = $ServerName.Remove($ServerName.Length - 4, 4)

            $FileName = Strip-Name -Name $File
            $FileName = ".\" + $FileName

            Write-Color -Text " Reading contents of ", $FileName, " - " -Color White,Cyan,White
            $FileContents = Get-Content $FileName
            Write-Host "Complete" -ForegroundColor Green -NoNewline
        
            Write-Color " - Adding to ", $OutFile, " - " -Color White, Cyan, White
            Add-Content -Path $OutFile -Value "$ServerName"
            $FileContents | Out-File $OutFile -Append ascii
            Write-output `n | Out-File $OutFile -Append ascii
            Write-Host "Complete" -ForegroundColor Green
        }
    }
}

#Try
#{
    Clean-TXT
    Get-VMsonHosts -VMHosts $VMHosts
    $OutFile = "All VM Details.TXT"
    Combine-Details -Outfile $OutFile
    Notepad.exe $OutFile
#}
#Catch 
#{
#    $ErrorMessage = $_.Exception.Message
#    $FailedItem = $_.Exception.ItemName
#    Write-Host "--- Failed ---" -ForegroundColor Red
#    Write-Host $ErrorMessage
#    Write-Host "--------------"
#    Write-Host $FailedItem
#}
