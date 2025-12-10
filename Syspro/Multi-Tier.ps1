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
$ErrorActionPreference = 'Stop'
$WarningPreference     = 'SilentlyContinue'

Clear-Host
#region Global Variables
Write-Color -Text "Setting Global Variables - " -ForegroundColor White -NoNewLine
    #Global Variables
    # Where do we want to put the VM's
    $global:locName = 'West Europe'
    # Resource Group name
    $global:rgName = 'PSTesting01'
    # Virtual Network Name
    $global:virtNetwork = 'PSTestingVnet01'
    #  Storage account names must be between 3 and 24 characters in length and use numbers and lower-case letters only
    $global:stName = 'pstestingstorage01'
    # VMName
    $global:NewVM = $null
    ### New Variables
    $global:SubscriptionName = 'Henri Borsboom'
    $global:SubscriptionId   = '859fc944-4695-445e-b779-791416c71e1b'

    # MIM Servers to Auto Deploy
    $VMRole = @()
    $VMRole += ,('ADDC1')
    $VMRole += ,('SQL01')
    #$VMRole += ,('APP01')

    #Azure RM Account Details
    $AzureUserName = "admin@syspro.com"
    $AzurePassword = ConvertTo-SecureString -String "YourPasswordHere" -AsPlainText -Force
    $global:AzureCredentials = New-Object PSCredential($AzureUserName, $AzurePassword)

    $DomainDNSName = "lab.local"
    $DomainNETBIOSName = "lab"
    $SafeModeAdminPassword = "P@ssw0rd"
    If (Test-Path C:\Temp\New-DC.ps1) { Remove-Item C:\Temp\New-DC.ps1 }
    $DomainScript = @(
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
            'Restart-Computer -Force') | Out-File C:\Temp\New-DC.ps1 -Encoding ascii -Force -NoClobber
Write-Color -Text "Complete" -ForegroundColor Green
#endregion
#region Authenticate to the Azure Portal
Write-Color -Text "Logging into Azure - " -ForegroundColor White -NoNewLine
    Add-AzureRmAccount -Credential $Creds -SubscriptionId $SubscriptionId | Out-Null
Write-Color -Text "Complete" -ForegroundColor Green
#endregion
#region Get the UserID and Password info that we want associated with the new VM's.
Write-Color -Text "Get the UserID and Password info that we want associated with the new VM's - " -ForegroundColor White -NoNewLine
    $global:cred = New-Object PSCredential("TestUser01", (ConvertTo-SecureString -String "TestUser0001" -AsPlainText -Force))
Write-Color -Text "Complete" -ForegroundColor Green
#endregion
#region Selecting The Azure Subscription
#Write-Color -Text "Selecting The Azure Subscription - " -ForegroundColor White -NoNewLine
#    Select-AzureRmSubscription -SubscriptionName $SubscriptionName | Out-Null
#Write-Color -Text "Complete" -ForegroundColor Green
#endregion
#region Create Resource Group
Write-Color -Text "Create Resource Group - " -ForegroundColor White -NoNewLine
    New-AzureRmResourceGroup -Name $rgName -Location $locName | Out-Null
Write-Color -Text "Complete" -ForegroundColor Green
#endregion
#region Create RG Storage Account
Write-Color -Text "Create RG Storage Account - " -ForegroundColor White -NoNewLine
    $storageAcc = New-AzureRmStorageAccount -ResourceGroupName $rgName -Name $stName -Type "Standard_LRS" -Location $locName
Write-Color -Text "Complete" -ForegroundColor Green
#endregion
#region Creating Scripts Container
Write-Color -Text "Creating Scripts Container - " -ForegroundColor White -NoNewLine
    Set-AzureRmCurrentStorageAccount -StorageAccountName $stName -ResourceGroupName $rgName | Out-Null
    New-AzureStorageContainer -Name 'scripts' -Permission Off | Out-Null
    Set-AzureStorageBlobContent -Container 'scripts' -File C:\temp\New-DC.ps1 | Out-Null
    
Write-Color -Text "Complete" -ForegroundColor Green
#endregion
#region Create RG Subnet
Write-Color -Text "Create RG Subnet - " -ForegroundColor White -NoNewLine
    $singleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name singleSubnet -AddressPrefix 10.0.0.0/24
Write-Color -Text "Complete" -ForegroundColor Green
#endregion
#region Create RG Network
Write-Color -Text "Create RG Network - " -ForegroundColor White -NoNewLine
    $global:vnet = New-AzureRmVirtualNetwork -Name $virtNetwork -ResourceGroupName $rgName -Location $locName -AddressPrefix 10.0.0.0/16 -Subnet $singleSubnet
Write-Color -Text "Complete" -ForegroundColor Green
#endregion
#region VM Config for each VM
Write-Color -Text "VM Config for each VM - " -ForegroundColor White -NoNewLine
    $VMConfig = @()
Write-Color -Text "Complete" -ForegroundColor Green
#endregion
#region Create VMConfigs and add to an array
    ForEach ($NewVM in $VMRole) {
        Write-Color -Text "Create VMConfigs and add to an array - " -ForegroundColor White -NoNewLine
            $pip = New-AzureRmPublicIpAddress -Name ($NewVM + "-IP1") -ResourceGroupName $rgName -Location $locName -AllocationMethod Dynamic
            $nic = New-AzureRmNetworkInterface -Name ($NewVM + "-NIC1") -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id            
            If ($NewVM -like "*AD*") {
                $global:ADNIC = $nic
            }
            
            $vm = New-AzureRmVMConfig -VMName $NewVM -VMSize "Standard_A1"
            $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $NewVM -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
            If ($NewVM -like "*SQL*") {
                $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftSQLServer -Offer SQL2014SP2-WS2012R2 -Skus Standard -Version "latest"
            }
            Else {
                $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"
            }
            $vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
        Write-Color -Text "Complete" -ForegroundColor Green
        #endregion
#region VM Disks. Deploying an OS and a Data Disk for each
        Write-Color -Text "VM Disks. Deploying an OS and a Data Disk for each - " -ForegroundColor White -NoNewLine
            $osDiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + ("vhds/WindowsVMosDisk" + $NewVM + ".vhd")
            $DataDiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + ("vhds/WindowsVMDataDisk" + $NewVM + ".vhd")
            $vm = Set-AzureRmVMOSDisk -VM $vm -Name "windowsvmosdisk" -VhdUri $osDiskUri -CreateOption fromImage
            $vm = Add-AzureRmVMDataDisk -VM $vm -Name "windowsvmdatadisk" -VhdUri $DataDiskUri -CreateOption Empty -Caching 'None' -DiskSizeInGB 10 -Lun 0
            $VMConfig += ,($vm)
        Write-Color -Text "Complete" -ForegroundColor Green
      
}
#endregion

#region Provision VM
ForEach ($NewVM in $VMConfig) {
    Write-Color -Text "Provision VM ", $NewVM.Name, " - " -ForegroundColor White, Yellow, White -NoNewLine
        New-AzureRmVM -ResourceGroupName $rgName -Location $locName -VM $NewVM | Out-Null
    Write-Color -Text "Complete" -ForegroundColor Green
    #endregion
#region VM Extension
    Write-Color -Text "VM Extension - " -ForegroundColor White -NoNewLine
        If ($NewVM.Name -like "*AD*") {
            Set-AzureRmVMCustomScriptExtension -Location $locName -Name "ADRolesTest01" -VMName $NewVM.Name -ResourceGroupName $rgName -FileName "New-DC.ps1" -ContainerName "scripts" -StorageAccountName $stName -Run '.\New-DC.ps1' | Out-Null
        }
        Else {
            $ADPrivateIP = (Get-AzureRmNetworkInterfaceIpConfig -NetworkInterface $ADNIC).PrivateIpAddress
            If (Test-Path C:\temp\Join-Domain.ps1) { Remove-Item C:\temp\Join-Domain.ps1 }
            $JoinDomainScript = @(
            'Set-DnsClientServerAddress -InterfaceIndex ((Get-NetAdapter).ifindex) -ServerAddresses ' + $ADPrivateIP
            ''
            ''
            '') | Out-File C:\temp\Join-Domain.ps1
            Set-AzureStorageBlobContent -Container 'scripts' -File C:\temp\Join-Domain.ps1| Out-Null
            Set-AzureRmVMCustomScriptExtension -Location $locName -Name "JoinDomain" -VMName $NewVM.Name -ResourceGroupName $rgName -FileName "Join-Domain.ps1" -ContainerName "scripts" -StorageAccountName $stName -Run '.\Join-Domain.ps1' | Out-Null
        }
    Write-Color -Text "Complete" -ForegroundColor Green
    
}
#endregion