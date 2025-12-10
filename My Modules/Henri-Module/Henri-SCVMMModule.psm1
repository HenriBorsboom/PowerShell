# System Center 2012 R2 Virtual Machine Manager Functions

Function Add-SCVMVHDTags {
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [string] $VHDName, `
        [Parameter(Mandatory=$True,Position=2)]
        [array] $Tags)

    If ($Tags -ne $null) {
        Write-Host "Confirming that " -NoNewline
        Write-Host $VHDName -ForegroundColor Yellow -NoNewline
        Write-Host " exists in VMM Library - " -NoNewline
        Try {
            $VHD = Get-SCVirtualHardDisk -Name $VHDName -ErrorAction Stop
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch {
            Write-Host "Failed" -ForegroundColor Red
            Exit 1
        }

        $CurrentTags = $VHD | select Tag
        [Array] $AllTags = $CurrentTags.Tag
        
        ForEach ($Tag in $Tags) {
            If ($AllTags -notcontains $Tag) {
                $AllTags += $Tag
            }
            Else {
                Write-Host "$VHDName already contains $Tag " -ForegroundColor Yellow -NoNewline
                Write-Host "Skipped" -ForegroundColor Green
            }
        }
        
        $empty = Set-SCVirtualHardDisk -VirtualHardDisk $VHD -Tag $AllTags
        $AllSetTags = Get-SCVirtualHardDisk -Name $VHDName | Select Tag
        ForEach ($Tag in $AllSetTags.Tag) {
            $Output = New-Object PSObject
            $Output | Add-Member -MemberType NoteProperty -Name VHD -Value $VHDName
            $Output | Add-Member -MemberType NoteProperty -Name Tag -Value $Tag
            $Output
        }
    }
    Else {
        Write-Host "Please specify tags in array format"
        Write-Host ' Example 1: @("WindowsServer2012","R2")'
        Write-Host ' Example 2: "WindowsServer", "R2"'
    }
}

Function Clear-SCVMVHDTags {
    Param(
        [parameter(Mandatory=$True,Position=1)]
        [string] $VHDName)

    Write-Host "Confirming " -NoNewline
    Write-Host "$VHDName" -NoNewline -ForegroundColor Yellow
    Write-Host " exists in VMM library - " -NoNewline
    
    Try {
        $VHD = Get-SCVirtualHardDisk -Name $VHDName
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
    }

    $Empty = Set-SCVirtualHardDisk -VirtualHardDisk $VHD -Tag ""
    $Tags = Get-SCVirtualHardDisk -Name $VHDName | Select Tag
    
    ForEach ($Tag in $Tags.Tag) {
        $Output = New-Object PSObject
        $Output | Add-Member -MemberType NoteProperty -Name VHD -Value $VHDName
        $Output | Add-Member -MemberType NoteProperty -Name Tag -Value $Tag
        $Output
    }
}

Function Get-SCVMVHD {
    Param(
        [Parameter(Mandatory=$false,Position=1)]
        [bool] $All, `
        [Parameter(Mandatory=$false,Position=2)]
        [name] $Name)

    If ($All -eq $true) {
        $VHD = Get-SCVirtualHardDisk | Select Name
        Return $VHD
    }
    Else {
        $VHD = Get-SCVirtualHardDisk | Where-Object {$_.Name -like "*$Name*" -or $_.Name -like "$Name*"}
        Return $VHD
    }

    
}

Function Get-SCVMVHDTags {
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [string] $VHDName)

    Write-Host "Confirming " -NoNewline
    Write-Host "$VHDName" -NoNewline -ForegroundColor Yellow
    Write-Host " exists in VMM library - " -NoNewline
    
    Try {
        $VHD = Get-SCVirtualHardDisk -Name $VHDName -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch{ 
        Write-Host "Failed" -ForegroundColor Red
        Exit 1
    }
 
    $Tags = Get-SCVirtualHardDisk -Name $VHDName | Select Tag
    If ($Tags.Tag -ne $null) {
        ForEach ($Tag in $Tags.Tag) {
            $OutFile  = New-Object -Type PSObject
            $OutFile | Add-Member -MemberType NoteProperty -Name VHD -Value $VHDName            $OutFile | Add-Member -MemberType NoteProperty -Name Tag -Value $Tag            $OutFile
        }
    }
    Else {
        Write-Host "There are no tags set on " -NoNewline
        Write-Host $VHDName -ForegroundColor Yellow
    }
}

Function Get-VMIDsOnHost {
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [Array] $VMHosts, `
        [Parameter(Mandatory=$False,Position=2)]
        [String] $NameFilter, `
        [Parameter(Mandatory=$False,Position=3)]
        [Bool] $Export, `
        [Parameter(Mandatory=$False,Position=4)]
        [string] $ExportFile)
    
    If ($Export -eq $True -and $ExportFile -ne "") {
        Try {
            If ((Test-Path $ExportFile) -eq $True) {
                Remove-Item $ExportFile -Force -ErrorAction Stop
            }
        }
        Catch {
            Write-Host "Unable to remove " -NoNewline
            Write-Host "$ExportFile" -ForegroundColor Red
            Write-Host "Disabling Export"
            
            $Export = $False
        }
    }

    ForEach ($VMHost in $VMHosts) {
            If ($NameFilter -ne "") {
                $VMs = Get-Vm -ComputerName $VMHost -ErrorAction Stop | Where-Object {$_.Name -like $NameFilter} | Select Name
                If ($VMs -eq $null) {
                    Write-Host "Unable to retrieve VMs from " -NoNewline
                    Write-Host "$VMHost " -ForegroundColor Red
                }
            }
            Else {
                $VMs = Get-Vm -ComputerName $VMHost -ErrorAction Stop | Select Name
                If ($VMs -eq $null) {
                    Write-Host "Unable to retrieve VMs from " -NoNewline
                    Write-Host "$VMHost " -ForegroundColor Red
                }
            }
        
            ForEach ($VM in $VMs) {
                $Output = New-Object PSObject
                [String] $VMName = $VM
                $VMName = $VMName.Remove(0, 7)
                $VMName = $VMName.Remove($VMName.Length -1, 1)

                $VMID = Get-VM -Name $VMName -ComputerName $VMHost | Select ID
        
                [String] $NewVMID = $VMID
                $NewVMID = $NewVMID.Remove(0, 5)
                $NewVMID = $NewVMID.Remove($NewVMID.Length - 1, 1)

                $Output | Add-Member -MemberType NoteProperty -Name VM -Value $VMName
                $Output | Add-Member -MemberType NoteProperty -Name ID -Value $NewVMID
                $Output | Add-Member -MemberType NoteProperty -Name Host -Value $VMHost
            
                If ($Export -eq $True) {
                    $Output | Export-Csv -path $ExportFile -Append -NoClobber -NoTypeInformation
                }
                $Output | Sort-Object -Property VMName
            }
        }
    If ($Export -eq $True) {
        Write-Host ""
        Write-Host "Data has been exported to " -NoNewline
        Write-Host "$ExportFile" -ForegroundColor Green -NoNewline
        Write-Host " sucessfully"
    }
}

Function Refresh-SCVMS {
    Write-Host "Collecting all Virtual Machines loaded in Virtual Machine Manager - " -NoNewline
    Try {
        $SCVMMVirtuals = Get-SCVirtualMachine -all -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Exit 1
    }
    
    Write-Host "  Total Virtuals: " -NoNewline
    Write-Host $SCVMMVirtuals.Count -ForegroundColor Yellow
    Write-Host ""
    [int] $x = 1
    ForEach ($VM in $SCVMMVirtuals) {
        $DisplayName = $VM.Name
        Write-Host "$x - Refreshing" -NoNewline
        Write-Host " $VM " -ForegroundColor Yellow -NoNewline
        Write-Host "- " -NoNewline
        Try {
            $Empty = Read-SCVirtualMachine -VM $VM
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch {
            Write-Host "Failed" -ForegroundColor Red
        }
        $x ++
    }
}

Function Remove-SCVMTempTemplate {
    Write-Host "Retrieving templates where name starts with 'Temp*' - " -NoNewline
    $Templates = Get-SCVMTemplate | Where-Object {$_.Name -like "Temp*"}
    Write-Host "Done" -ForegroundColor Green
    
    Write-Host "Checking if templates retrieved containts templates - " -NoNewline
    If ($Templates -ne $null) {
        Write-Host "Templates found" -ForegroundColor Green
        ForEach ($Template in $Templates) {
            Write-Host " Retrieving Template - $Template - information " -ForegroundColor Yellow -NoNewline
                $RemoveTemplate = Get-SCVMTemplate -Name $Template
            Write-Host "Completed" -ForegroundColor Green
        
            Write-Host " Attemping to remove template - $Template - " -ForegroundColor Yellow -NoNewline
            Try {
                $empty = Remove-SCVMTemplate -VMTemplate $RemoveTemplate -ErrorAction Stop
                Write-Host "Succesfull" -ForegroundColor Green
            }
            Catch {
                Write-Host "Failed" -ForegroundColor Red
            }
        }
    }
    Else {
        Write-Host "No Templates found" -ForegroundColor Yellow
    }
}

Function Remove-VMHost {
    Write-Host "Getting the Hosts " -NoNewline
    $VMHosts = Get-SCVMHost
    Write-Host "Complete" -ForegroundColor Green

    ForEach ($VMHost in $VMHosts) {
        $HostName = $VMHost.Name
        Write-Host " Reading Host - $VMhost - information " -NoNewline
        $Empty = Read-SCVMHost -VMHost $VMHost
        Write-Host "Complete" -ForegroundColor Green
    }
}

Function Set-SCVMVHDTags {
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [Array] $Tags, `
        [Parameter(Mandatory=$True,Position=2)]
        [string] $VHDName)

    Import-Module VirtualMachineManager

    If ($Tags -ne $null) {
        Write-Host "Confirming " -NoNewline
        Write-Host "$VHDName" -NoNewline -ForegroundColor Yellow
        Write-Host " exists in VMM library - " -NoNewline
        Try {
            $VHD = Get-SCVirtualHardDisk -Name $VHDName -ErrorAction Stop
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch {
            Write-Host "Failed" -ForegroundColor Red
            Exit
        }
        
        $empty = Set-SCVirtualHardDisk -VirtualHardDisk $VHD -Tag $Tags
        $Tags = Get-SCVirtualHardDisk -Name $VHDName | Select Tag
        
        If ($Tags.Tag -ne $null) {
            ForEach ($Tag in $Tags.Tag) {
                $OutFile  = New-Object -Type PSObject
                $OutFile | Add-Member -MemberType NoteProperty -Name VHD -Value $VHDName                $OutFile | Add-Member -MemberType NoteProperty -Name Tag -Value $Tag                $OutFile
            }
        }
    }
    Else {
        Write-Host 'The Tags supplied are empty. Please supply tags in ARRAY format'
        Write-Host ' Example 1: @("WindowsServer","R2")'
        Write-Host ' Example 2: "WindowsServer","R2"'
    }
}
