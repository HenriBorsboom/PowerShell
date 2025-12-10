Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)

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
}
Function Create-Script {
    Param (
        [Parameter(Mandatory=$True,  Position=1)][ValidateSet("New-DC", "Join-Domain")]
        [String] $Script)

   Switch ($Script) {
        "New-DC" {
            Write-Color -Text "Checking if ", $NewDCScriptFilePath, " exists - " -ForegroundColor White, Yellow, White -NoNewLine
            If (Test-Path $NewDCScriptFilePath) { 
                Write-Color -Text "Removing", " - " -ForegroundColor DarkCyan, White -NoNewLine
                Remove-Item $NewDCScriptFilePath 
            }
            Write-Color -Text "Complete" -ForegroundColor Green
            Write-Color -Text "Creating and exporting ", $NewDCScriptFile, " - " -ForegroundColor White, Yellow, White -NoNewLine
            @(
                '$ADRoles = @()'
                '$ADRoles += ,("RSAT-ADDS-Tools")'
                '$ADRoles += ,("RSAT-ADDS")'
                '$ADRoles += ,("AD-Domain-Services")'
                '$ADRoles += ,("RSAT-AD-Tools")'
                '$ADRoles += ,("GPMC")'
                '$ADRoles += ,("RSAT-AD-AdminCenter")'
                '$ADRoles += ,("RSAT-AD-PowerShell")'
                '$ADRoles += ,("RSAT-DNS-Server")'
                '$ADRoles += ,("DNS")'
                'Get-WindowsFeature $ADRoles | Install-WindowsFeature'
                '$securePW = ConvertTo-SecureString "' + $SafeModeAdminPassword + '" -AsPlainText -Force'
                'Import-Module ADDSDeployment'
                'Install-ADDSForest `'
                '-DatabasePath "C:\Windows\NTDS" `'
                '-DomainMode "Win2012" `'
                '-DomainName "' + $DomainDNSName + '" `'
                '-DomainNetBIOSName "' + $DomainNETBIOSName + '" `'
                '-ForestMode "Win2012" `'
                '-InstallDNS:$true `'
                '-LogPath "C:\Windows\NTDS" `'
                '-NoRebootOnCompletion:$false `'
                '-SYSVOLPath "C:\Windows\SYSVOL" `'
                '-SafeModeAdministratorPassword $securePW `'
                '-Force:$true'
                'Restart-Computer -Force') | Out-File $NewDCScriptFilePath -Encoding ascii -Force -NoClobber
            Write-Color -Text "Complete" -ForegroundColor Green
            Write-Color -Text "Uploading ", $NewDCScriptFilePath, " to Azure Storage Container ", "scripts", " - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine
            Set-AzureStorageBlobContent -Container 'scripts' -File $NewDCScriptFilePath | Out-Null
            Write-Color -Text "Complete" -ForegroundColor Green
        }
        "Join-Domain" {
            Write-Color -Text "Checking if ", $JoinDomainScriptFilePath, " exists - " -ForegroundColor White, Yellow, White -NoNewLine
            If (Test-Path $JoinDomainScriptFilePath) { 
                Write-Color -Text "Removing", " - " -ForegroundColor DarkCyan, White -NoNewLine
                Remove-Item $JoinDomainScriptFilePath 
            }
            Write-Color -Text "Complete" -ForegroundColor Green
            Write-Color -Text "Creating and exporting ", $JoinDomainScriptFile, " - " -ForegroundColor White, Yellow, White -NoNewLine
            @(
                'Set-DnsClientServerAddress -InterfaceIndex ((Get-NetAdapter).ifindex) -ServerAddresses ' + $ADPrivateIP
                'Add-Computer -Domain ' + $DomainDNSName + ' -Credential (New-Object PSCredential("TestUser01", (ConvertTo-SecureString -String "TestUser0001" -AsPlainText -Force)))'
                'Restart-Computer') | Out-File $JoinDomainScriptFilePath -Encoding ascii -Force -NoClobber
            Write-Color -Text "Complete" -ForegroundColor Green
            Write-Color -Text "Uploading ", $JoinDomainScriptFilePath, " to Azure Storage Container ", "scripts", " - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine
            Set-AzureStorageBlobContent -Container 'scripts' -File $JoinDomainScriptFilePath | Out-Null
            Write-Color -Text "Complete" -ForegroundColor Green
        }
    }
}
Function Global-Variables {
    Write-Color -Text "Defining ", "Global", " variables - " -ForegroundColor White, DarkCyan, White -NoNewLine
    $global:locName                  = 'West Europe'
    $global:rgName                   = 'PSTesting01'
    $global:virtNetwork              = 'PSTestingVnet01'
    $global:stName                   = 'pstestingstorage01'
    $global:NewVM                    = $null
    $global:SubscriptionName         = 'Henri Borsboom'
    $global:SubscriptionId           = '859fc944-4695-445e-b779-791416c71e1b'
    $global:DomainDNSName            = "lab.local"
    $global:DomainNETBIOSName        = "lab"
    $global:SafeModeAdminPassword    = "P@ssw0rd"
    $global:NewDCScriptFilePath      = "$env:TEMP\New-DC.ps1"
    $global:NewDCScriptFile          = "New-DC.ps1"
    $global:JoinDomainScriptFilePath = "$env:TEMP\Join-Domain.ps1"
    $global:JoinDomainScriptFile     = "Join-Domain.ps1"
    $Global:VMRole                   = @{}
    $global:cred                     = New-Object PSCredential("TestUser01", (ConvertTo-SecureString -String "TestUser0001" -AsPlainText -Force))
    $global:stType                   = 'Standard_LRS'
    $global:stPermissions            = 'Off'
    $global:vnetSubnetName           = 'singleSubnet'
    $global:vnetSubnetAddressPrefix  = '10.0.0.0/24'
    $global:vnetAddressPrefix        = '10.0.0.0/16'
    $global:vmDiskOSCreateOption     = 'FromImage'
    $global:vmIPAllocationMethod     = 'Dynamic'
    $global:vmDiskDataCaching        = 'None'
    $global:vmDiskDataSize           = 10
    $global:vmSize                   = 'Standard_A1'
    Write-Color -Text "Complete" -ForegroundColor Green
}
Function VMs-To-Deploy {
    Write-Color -Text "Defining ", "Virtual Machines", " to deploy - " -ForegroundColor White, DarkCyan, White -NoNewLine
    $VMRole.Add("Domain Controller", "ADDC1")
    $VMRole.Add("SQL",               "SQL01")
    Write-Color -Text "Complete" -ForegroundColor Green
}
Function Configure-Azure-Deployments {
    Write-Color -Text "Adding ", "Azure RM Account", " - " -ForegroundColor White, Yellow, White -NoNewLine
        Add-AzureRmAccount -Credential $Creds -SubscriptionId $SubscriptionId | Out-Null
    Write-Color -Text "Complete" -ForegroundColor Green

    Write-Color -Text "Creating Resource Group: ", $rgName, " in Location: ", $locName, " - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine
        New-AzureRmResourceGroup -Name $rgName -Location $locName | Out-Null
    Write-Color -Text "Complete" -ForegroundColor Green

    Write-Color -Text "Creating Storage Account: ", $stName, " of Type: ", $stType, " in Resource Group: ", $rgName, " - " -ForegroundColor White, Yellow, White, Yellow, White, Yellow, White -NoNewLine
        $storageAcc = New-AzureRmStorageAccount -ResourceGroupName $rgName -Name $stName -Type $stType -Location $locName
    Write-Color -Text "Complete" -ForegroundColor Green
    
    Write-Color -Text "Setting current storage account to ", $stName, " in Resource Group: ", $rgName, " - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine
        Set-AzureRmCurrentStorageAccount -StorageAccountName $stName -ResourceGroupName $rgName | Out-Null
    Write-Color -Text "Complete" -ForegroundColor Green
    
    Write-Color -Text "Creating ", "scripts", " container on storage with Permissions set to ", $stPermissions, " - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine
        New-AzureStorageContainer -Name 'scripts' -Permission $stPermissions | Out-Null
    Write-Color -Text "Complete" -ForegroundColor Green

    Write-Color -Text "Creating Virtual Network Subnet: ", $vnetSubnetName, " with Address Prefix: ", $vnetSubnetAddressPrefix, " - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine
        $singleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $vnetSubnetName -AddressPrefix $vnetSubnetAddressPrefix
    Write-Color -Text "Complete" -ForegroundColor Green
    
    Write-Color -Text "Creating Virtual Network: ", $virtNetwork, " in Resource Group: ", $rgName, " in Location: ", $locName, " with Address Prefix: ", $vnetAddressPrefix, " with Subnet: ", $vnetSubnetName ," - " -ForegroundColor White, Yellow, White, Yellow, White, Yellow, White, Yellow, White, Yellow, White -NoNewLine
        $global:vnet = New-AzureRmVirtualNetwork -Name $virtNetwork -ResourceGroupName $rgName -Location $locName -AddressPrefix $vnetAddressPrefix -Subnet $singleSubnet
    Write-Color -Text "Complete" -ForegroundColor Green

    $VMConfig = @()
    ForEach ($NewVM in $VMRole.GetEnumerator()) {
        Write-Color -Text "Creating Public IP Address Name: ", ($NewVM.Value + "-IP1"), " for VM: ", $NewVM.Value, " With Allocation Method: ", $vmIPAllocationMethod," - " -ForegroundColor White, Yellow, White, Yellow, White, Yellow, White -NoNewLine
            $pip = New-AzureRmPublicIpAddress -Name ($NewVM.Value + "-IP1") -ResourceGroupName $rgName -Location $locName -AllocationMethod $vmIPAllocationMethod
        Write-Color -Text "Complete" -ForegroundColor Green

        Write-Color -Text "Creating NIC Name: ", ($NewVM.Value + "-NIC1"), " for VM: ", $NewVM.Value, " - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine
            $nic = New-AzureRmNetworkInterface -Name ($NewVM.Value + "-NIC1") -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id
            If ($NewVM.Name -eq 'Domain Controller') {
                $global:ADNIC = $nic
            }
        Write-Color -Text "Complete" -ForegroundColor Green

        Write-Color -Text "Creating VM Config for the ", $NewVM.Name, " with VM Name: ", $NewVM.Value, " and Size: ", $vmSize, " - " -ForegroundColor White, Yellow, White, Yellow, White, Yellow, White -NoNewLine
            $vm = New-AzureRmVMConfig -VMName $NewVM.Value -VMSize $vmSize
        Write-Color -Text "Complete" -ForegroundColor Green

        Write-Color -Text "Setting Operating system on VM to ", "Windows", "for VM: ", $NewVM.Value, " - " -ForegroundColor White, DarkCyan, White, Yellow, White -NoNewLine
            $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $NewVM.Value -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
        Write-Color -Text "Complete" -ForegroundColor Green

        If ($NewVM.Name -eq 'SQL') {
            Write-Color -Text "Setting Source Image Publisher: ", "MicrosoftSQLServer", " with Offer: ", "SQL2014SP2-WS2012R2", " and Edition: ", "Standard", " - " -ForegroundColor White, DarkCyan, White, DarkCyan, White, DarkCyan, White -NoNewLine
                $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftSQLServer -Offer SQL2014SP2-WS2012R2 -Skus Standard -Version "latest"
            Write-Color -Text "Complete" -ForegroundColor Green

            Write-Color -Text "Setting Data Disk: ", "windowsvmdatadisk", " for VM: ", $NewVM.Value, " with Create Option: ", "Empty", " and Caching: ", $vmDiskDataCaching, " and Size: ", $vmDiskDataSize, " GB - " -ForegroundColor White, DarkCyan, White, Yellow, White, DarkCyan, White, Yellow, White, Yellow, White -NoNewLine
                $DataDiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + ("vhds/WindowsVMDataDisk" + $NewVM.Value + ".vhd")
                $vm = Add-AzureRmVMDataDisk -VM $vm -Name "windowsvmdatadisk" -VhdUri $DataDiskUri -CreateOption Empty -Caching $vmDiskDataCaching -DiskSizeInGB $vmDiskDataSize -Lun 0
            Write-Color -Text "Complete" -ForegroundColor Green
        }
        Else {
            Write-Color -Text "Setting Source Image Publisher: ", "MicrosoftWindowsServer", " with Offer: ", "WindowsServer", " and Edition: ", "2012-R2-Datacenter", " - " -ForegroundColor White, DarkCyan, White, DarkCyan, White, DarkCyan, White -NoNewLine
                $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"
            Write-Color -Text "Complete" -ForegroundColor Green
        }

        Write-Color -Text "Adding NIC to VM: ", $NewVM.Value, " and NIC ID: ", $nic.ID, " - " -ForegroundColor White, Yellow, White, Yellow, White -NoNewLine
            $vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
        Write-Color -Text "Complete" -ForegroundColor Green

        Write-Color -Text "Setting OS Disk: ", "windowsvmosdisk", " for VM: ", $NewVM.Value, " with Create Option: ", $vmDiskOSCreateOption, " - " -ForegroundColor White, DarkCyan, White, Yellow, White, Yellow, White -NoNewLine
            $osDiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + ("vhds/WindowsVMosDisk" + $NewVM.Value + ".vhd")
            $vm = Set-AzureRmVMOSDisk -VM $vm -Name "windowsvmosdisk" -VhdUri $osDiskUri -CreateOption $vmDiskOSCreateOption
        Write-Color -Text "Complete" -ForegroundColor Green
            
        $VMConfig += ,($vm)
    }
    Return $VMConfig
}
Function Deploy-To-Azure {
    Param (
        [Parameter(Mandatory=$True,  Position=1)]
        [Object[]] $VMConfig)

    ForEach ($DeployVM in $VMConfig) {
        Write-Color -Text "Deploying Virtual Machine: ", $DeployVM.Name, " - " -ForegroundColor White, Yellow, White -NoNewLine
            New-AzureRmVM -ResourceGroupName $rgName -Location $locName -VM $DeployVM | Out-Null
        Write-Color -Text "Complete" -ForegroundColor Green
        If ($DeployVM.Name -eq $VMRole.'Domain Controller') {
            Create-Script -Script New-DC
            
            Write-Color -Text "Deploying ", "Custom Script Extension", " with Name: ", "New-DC", " and FileName: ", $NewDCScriptFile, " to the ", "Domain Controller", " - " -ForegroundColor White, DarkCyan, White, DarkCyan, White, Yellow, White, DarkCyan, White -NoNewLine
                Set-AzureRmVMCustomScriptExtension -Location $locName -Name "New-DC" -VMName $DeployVM.Name -ResourceGroupName $rgName -FileName $NewDCScriptFile -ContainerName "scripts" -StorageAccountName $stName -Run ('.\' + $NewDCScriptFile) | Out-Null
            Write-Color -Text "Complete" -ForegroundColor Green
        }
        Else {
            Write-Color -Text "Getting the Private IP Address of the ", "Domain Controller", " - " -ForegroundColor White, DarkCyan, White -NoNewLine
                $Global:ADPrivateIP = (Get-AzureRmNetworkInterfaceIpConfig -NetworkInterface $ADNIC).PrivateIpAddress
            Write-Color -Text "Complete" -ForegroundColor Green

            Create-Script -Script Join-Domain
            
            Write-Color -Text "Deploying ", "Custom Script Extension", " with Name: ", "Join-Domain", " and FileName: ", $JoinDomainScriptFile, " to VM: ", $DeployVM.Name, " - " -ForegroundColor White, DarkCyan, White, DarkCyan, White, Yellow, White, Yellow, White -NoNewLine
                Set-AzureRmVMCustomScriptExtension -Location $locName -Name "Join-Domain" -VMName $DeployVM.Name -ResourceGroupName $rgName -FileName $JoinDomainScriptFile -ContainerName "scripts" -StorageAccountName $stName -Run ('.\' + $JoinDomainScriptFile) | Out-Null
            Write-Color -Text "Complete" -ForegroundColor Green
        }
    }
}

$ErrorActionPreference        = 'Stop'
$WarningPreference            = 'SilentlyContinue'

Clear-Host
Global-Variables
VMs-To-Deploy
$VMConfig = Configure-Azure-Deployments
Deploy-To-Azure -VMConfig $VMConfig