<#
.SYNOPSIS
  The script is designed to simplify and optimize the setting of Advanced Networking features on NICs.
  The script IS NOT designed to be run as a whole. It is designed to run only the functions that you require.
.DESCRIPTION
  Run Get-Config first to create a capture of all the network configurations of the server you are
  going to change the configurations on. The script will use this file in the event that you
  need to reset the configurations back.
  The script also uses a reference file from a server that is already configured with the required settings.
  To capture the settings of the reference server, you can run the Get-Config function within this 
  script to save the settings to the $ConfigFile_Original file location and rename the file to the 
  $ConfigFile_Reference file. 
  OR
  Run the following and save the file to the name of the $ConfigFile_Reference file:
    Get-NetAdapterAdvancedProperty | Where-Object InterfaceDescription -notlike 'Microsoft*' | Export-Csv ''C:\Temp\NIC Config - Reference.csv'' -Delimiter ';'
  THIS IS DONE ON THE REFERENCE SERVER
  Once you have a reference file available, you can set the configurations on the target server
.PARAMETER ConfigFile_Original
    This is a required function for the setup of the server

    The configuration file before any changes are made
    This file is created with Get-Config and used in Reset-Config to reset the configurations
.PARAMETER ConfigFile_Reference
    This is a required function for the setup of the server

    The configuration file of the reference server. This file can be made by running Get-Config OR
    Get-NetAdapterAdvancedProperty | Where-Object InterfaceDescription -notlike 'Microsoft*' | Export-Csv ''C:\Temp\NIC Config - Reference.csv'' -Delimiter ';'
.PARAMETER ConfigFile_EnableJumboPackets
    This is not a required function for the setup of the server

    Set the Jumbo Packet size on the adapters as per the file specified.
    This file can be created by running the following commands if you have a reference file.
        $NICConfig = Import-Csv 'C:\Temp\NIC Config - Reference.csv' -Delimiter ';'
        $NICConfig | Where DisplayName -like '*jumbo*' | Export-CSV $ConfigFile_DisableJumboPackets -Delimiter ';'
.PARAMETER ConfigFile_DisableJumboPackets
    This is not a required functino for the setup of the server
    
    Sets the Jumbo Packet size on the adapters as per the file specified.
    The file can be created by running the following commands.
        $NICConfig = Import-Csv 'C:\Temp\NIC Config - Original.csv' -Delimiter ';'
        $NICConfig | Where DisplayName -like '*jumbo*' | Export-CSV $ConfigFile_DisableJumboPackets -Delimiter ';'
.INPUTS
  None
.OUTPUTS
  The functions will output to the screen if there are any settings that it could not apply to the NICs.
  Please review these settings manually.
.NOTES
  Version:        1.0
  Author:         Henri Borsboom
  Creation Date:  2024/01/29
  Purpose/Change: Initial script development
  
.EXAMPLE
  The script is not designed to be run in its entirety.
  Please open the file in PowerShell ISE.
  Set the location for the configuration files.
  For example:
    $ConfigFile_Original = 'C:\Temp\NIC Config - Original.csv'
    $ConfigFile_Reference = 'C:\Temp\NIC Config - Reference.csv'
    $ConfigFile_EnableJumboPackets = 'C:\Temp\NIC Config - Enable Jumbo.csv'
    $ConfigFile_DisableJumboPackets = 'C:\Temp\NIC Config - Disable Jumbo.csv'

  Select all the functions and execute them to load the functions.
  Run only the functions you require from the console in PowerShell ISE.
#>
Function Get-Config {
    Get-NetAdapterAdvancedProperty | Where-Object InterfaceDescription -notlike 'Microsoft*' | Export-Csv $ConfigFile_Original -Delimiter ';'
}
Function Set-Config {
    $NICConfig = Import-Csv $ConfigFile_Reference -Delimiter ';'
    $Errors = @()
    For ($i = 0; $i -lt $NICConfig.Count; $i ++) {
        Write-Host ("Setting Name " + $NICConfig[$i].Name + " DisplayName " + $NICConfig[$i].DisplayName + " Display Value " + $NICConfig[$i].DisplayValue)
        Try {
            If ($NICConfig[$i].DisplayValue -eq $null -or $NICConfig[$i].DisplayValue -eq "") {
                
            }
            Else {
                Set-NetAdapterAdvancedProperty -Name $NICConfig[$i].Name -DisplayName $NICConfig[$i].DisplayName -DisplayValue $NICConfig[$i].DisplayValue -ErrorAction Stop
            }
        }
        Catch {
            Write-Host $_
            $Errors += (New-Object -TypeName PSObject -Property @{
                Name = $NICConfig[$i].Name
                DisplayName = $NICConfig[$i].DisplayName
                DisplayValue = $NICConfig[$i].DisplayValue
                Error = $_
            })
        }
        Start-Sleep -Milliseconds 100
    }
    Return $Errors | Select-Object Name, DisplayName, DisplayValue, Error
}
Function Reset-Config {
    $NICConfig = Import-Csv $ConfigFile_Original  -Delimiter ';'
    $Errors = @()
    For ($i = 0; $i -lt $NICConfig.Count; $i ++) {
        Write-Host ("Setting Name " + $NICConfig[$i].Name + " Registry Keyword " + $NICConfig[$i].RegistryKeyWord + " Registry Value " + $NICConfig[$i].RegistryValue)
        Try {
            Set-NetAdapterAdvancedProperty -Name $NICConfig[$i].Name -RegistryKeyword $NICConfig[$i].RegistryKeyWord -RegistryValue $NICConfig[$i].RegistryValue -ErrorAction Stop
        }
        Catch {
            Write-Host $_
            $Errors += (New-Object -TypeName PSObject -Property @{
                Name = $NICConfig[$i].Name
                RegistryKeyWord = $NICConfig[$i].RegistryKeyWord
                RegistryValue = $NICConfig[$i].RegistryValue
                Error = $_
            })
        }
        Start-Sleep -Milliseconds 100
    }
    Return $Errors | Select-Object Name, DisplayName, DisplayValue, Error
}
Function Enable-Jumbo {
    $NICConfig = Import-Csv $ConfigFile_EnableJumboPackets -Delimiter ';'
    $Errors = @()
    For ($i = 0; $i -lt $NICConfig.Count; $i ++) {
        Write-Host ("Setting Name " + $NICConfig[$i].Name + " DisplayName " + $NICConfig[$i].DisplayName + " Display Value " + $NICConfig[$i].DisplayValue)
        Try {
            If ($NICConfig[$i].DisplayValue -eq $null -or $NICConfig[$i].DisplayValue -eq "") {
                
            }
            Else {
                Set-NetAdapterAdvancedProperty -Name $NICConfig[$i].Name -DisplayName $NICConfig[$i].DisplayName -DisplayValue $NICConfig[$i].DisplayValue -ErrorAction Stop
            }
        }
        Catch {
            Write-Host $_
            $Errors += (New-Object -TypeName PSObject -Property @{
                Name = $NICConfig[$i].Name
                DisplayName = $NICConfig[$i].DisplayName
                DisplayValue = $NICConfig[$i].DisplayValue
                Error = $_
            })
        }
        Start-Sleep -Milliseconds 100
    }
    Return $Errors | Select-Object Name, DisplayName, DisplayValue, Error
}
Function Disable-Jumbo {
    $NICConfig = Import-Csv $ConfigFile_DisableJumboPackets -Delimiter ';'
    $Errors = @()
    For ($i = 0; $i -lt $NICConfig.Count; $i ++) {
        Write-Host ("Setting Name " + $NICConfig[$i].Name + " DisplayName " + $NICConfig[$i].DisplayName + " Display Value " + $NICConfig[$i].DisplayValue)
        Try {
            If ($NICConfig[$i].DisplayValue -eq $null -or $NICConfig[$i].DisplayValue -eq "") {
                
            }
            Else {
                Set-NetAdapterAdvancedProperty -Name $NICConfig[$i].Name -DisplayName $NICConfig[$i].DisplayName -DisplayValue $NICConfig[$i].DisplayValue -ErrorAction Stop
            }
        }
        Catch {
            Write-Host $_
            $Errors += (New-Object -TypeName PSObject -Property @{
                Name = $NICConfig[$i].Name
                DisplayName = $NICConfig[$i].DisplayName
                DisplayValue = $NICConfig[$i].DisplayValue
                Error = $_
            })
        }
        Start-Sleep -Milliseconds 100
    }
    Return $Errors | Select-Object Name, DisplayName, DisplayValue, Error
}
#region Do no run the entire script
Write-Warning 'This script is not meant to be run in entirety'
Write-Host    '----------------------------------------------'
Write-Host    'Please run the Function block and then execute the functions you need only'
Write-Host    '----------------------------------------------'
Read-Host     'The script will now exit'
Exit
#endregion

#region File locations
$ConfigFile_Original = 'C:\Temp\NIC Config - Original.csv'
$ConfigFile_Reference = 'C:\Temp\NIC Config - Reference.csv'
$ConfigFile_EnableJumboPackets = 'C:\Temp\NIC Config - Enable Jumbo.csv'
$ConfigFile_DisableJumboPackets = 'C:\Temp\NIC Config - Disable Jumbo.csv'
#endregion

Get-Config      # Saves the current NIC configurations to file
Set-Config      # Sets the NIC configuration as per the reference file
Reset-Config    # Resets the NIC configurations as per the original file
Enable-Jumbo    # Sets Jumbo Packets on the NICs
Disable-Jumbo   # Resets Jumbo Packets on the NICs to 1514.