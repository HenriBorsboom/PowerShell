# VMware vScout
# Copyright VMware Inc. 2019
#
# Author: Josh Miller
# 
# Technical Contact: Josh Miller
# Email: joshmiller@vmware.com
#
# Description: The script collects a list of enabled, recently active computers
#     from Active Directory and attempts to collect data from each device using
#     WMI queries.The data collected from Active Directory includes the machine
#     names, operating systems, and age of last activity. The data collected by
#     WMI quiry includes the machine name, manufacturer, and model.
#
# DISCLAIMER: VMware offers this script as-is and makes no representations or 
#     warranties of any kind whether express, implied, statutory, or other. 
#     This includes, without limitation, warranties of fitness for a particular
#     purpose, title, non-infringement, course of dealing or performance, usage 
#     of trade, absence of latent or other defects, accuracy, or the presence 
#     or absence of errors, whether known or discoverable. In no event will 
#     VMware be liable to You for any direct, special, indirect, incidental, 
#     consequential, punitive, exemplary, or other losses, costs, expenses, or 
#     damages arising out of Your use of this script.

############ Multithreading Function ############
function Multithread-Scan {
    Param( 
        [Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]$ObjectList,
        $MaxThreads = 20,
        $Sleep = 200, #milliseconds
        $MaxWaitTime = 150, #seconds
        [System.Management.Automation.PSCredential]$Credential,
        $Outpath
    )

    Begin{
        #Open the runspace pool for the threads
        $ISS = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
        $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads, $ISS, $Host)
        $RunspacePool.Open()
        
        #Create the script block
        $Code = { 
            Param(
                $Computer,
                [System.Management.Automation.PSCredential] $Credential
            )

            #Try to get the computer FQDN
            $FQDN = $null
            $FQDNFlag = $null
            try {
                $FQDN = [System.Net.DNS]::GetHostEntry($Computer.CN).HostName
                $FQDNFlag = $true
            } catch {
                $FQDN = ""
                $FQDNFlag = $false
            }

            #If the operating system is Windows or Windows Server proceed, otherwise return the info passed in the Computer parameter
            if(($Computer.OperatingSystem -like "*Windows*") -or ($Computer.OperatingSystem -eq "")) {
    
                #Try to query the computer
                try {
                    #Use the FQDN if available
                    if($FQDNFlag) {
                        #If this is the local machine, do not use the credential property
                        if($FQDN -eq "$env:COMPUTERNAME.$env:USERDNSDOMAIN") {
                            $q = Get-WmiObject -Query "SELECT Name,Manufacturer,Model FROM Win32_ComputerSystem" -ComputerName $FQDN -ErrorAction Stop
                        } else {
                            $q = Get-WmiObject -Query "SELECT Name,Manufacturer,Model FROM Win32_ComputerSystem" -ComputerName $FQDN -Credential $Credential -ErrorAction Stop
                        }
                    } else {
                        #If this is the local machine, do not use the credential property
                        if($Computer.CN -eq $env:COMPUTERNAME) {
                            $q = Get-WmiObject -Query "SELECT Name,Manufacturer,Model FROM Win32_ComputerSystem" -ComputerName $Computer.CN -ErrorAction Stop
                        } else {
                            $q = Get-WmiObject -Query "SELECT Name,Manufacturer,Model FROM Win32_ComputerSystem" -ComputerName $Computer.CN -Credential $Credential -ErrorAction Stop
                        }
                    }

                    $Result = New-Object PSObject -Property @{
                        "Input_CN" = $Computer.CN
                        "AD_OperatingSystem" = $Computer.OperatingSystem
                        "AD_Enabled" = $Computer.Enabled
                        "AD_Age" = $Computer.Age
                        "FQDN" = $FQDN
                        "ComputerName" = $q.Name
                        "Manufacturer" = $q.Manufacturer
                        "Model" = $q.Model
                        "Error" = ""
                    }

                #Catch error if the WMI query is unable to connect to the remote machine
                } catch [System.Runtime.InteropServices.COMException] {
                    $Result = New-Object PSObject -Property @{
                        "Input_CN" = $Computer.CN
                        "AD_OperatingSystem" = $Computer.OperatingSystem
                        "AD_Enabled" = $Computer.Enabled
                        "AD_Age" = $Computer.Age
                        "FQDN" = $FQDN
                        "ComputerName" = ""
                        "Manufacturer" = ""
                        "Model" = ""
                        "Error" = "Remote machine is unavailable"
                    }

                #Catch error if the credentials are wrong
                } catch [System.UnauthorizedAccessException] {
                    $Result = New-Object PSObject -Property @{
                        "Input_CN" = $Computer.CN
                        "AD_OperatingSystem" = $Computer.OperatingSystem
                        "AD_Enabled" = $Computer.Enabled
                        "AD_Age" = $Computer.Age
                        "FQDN" = $FQDN
                        "ComputerName" = ""
                        "Manufacturer" = ""
                        "Model" = ""
                        "Error" = "Access denied"
                    }

                #Catch remaining errors and print the error name
                } catch {
                    $Result = New-Object PSObject -Property @{
                        "Input_CN" = $Computer.CN
                        "AD_OperatingSystem" = $Computer.OperatingSystem
                        "AD_Enabled" = $Computer.Enabled
                        "AD_Age" = $Computer.Age
                        "FQDN" = $FQDN
                        "ComputerName" = ""
                        "Manufacturer" = ""
                        "Model" = ""
                        "Error" = "$($_.Exception.GetType().FullName)"
                    }
                }
            } else {
                $Result = New-Object PSObject -Property @{
                    "Input_CN" = $Computer.CN
                    "AD_OperatingSystem" = $Computer.OperatingSystem
                    "AD_Enabled" = $Computer.Enabled
                    "AD_Age" = $Computer.Age
                    "FQDN" = $FQDN
                    "ComputerName" = ""
                    "Manufacturer" = ""
                    "Model" = ""
                    "Error" = ""
                }
            }
    
            $Result
        }
        
        #Create array list to store jobs
        $Jobs = @()

        #Create array list to store results
        $Results = @()
    }
 
    Process{
        #Create the threads
        Write-Progress -Activity "Preloading threads" -Status "Starting Job $($jobs.count)"
        ForEach ($Object in $ObjectList){
            #Add the code to the thread
            $PowershellThread = [PowerShell]::Create().AddScript($Code)
            
            #Add the parameters to the thread
            $PowershellThread.AddParameter("Computer", $Object) | Out-Null
            $PowershellThread.AddParameter("Credential", $Credential) | Out-Null

            #Add the thread to the runspace pool
            $PowershellThread.RunspacePool = $RunspacePool
            $Handle = $PowershellThread.BeginInvoke()

            #Create the job object to track the thread and add it to the jobs array
            $Job = "" | Select-Object Handle, Thread, object
            $Job.Handle = $Handle
            $Job.Thread = $PowershellThread
            $Job.Object = $Object.ToString()
            $Jobs += $Job
        }
        
    }
 
    End{
        #Get the start time
        $ResultTimer = Get-Date

        #While the number of jobs is greater than 0
        While (@($Jobs | Where-Object {$_.Handle -ne $Null}).Count -gt 0)  {
    
            $Remaining = "$($($Jobs | Where-Object {$_.Handle.IsCompleted -eq $False}).Object)"
            If ($Remaining.Length -gt 60){
                $Remaining = $Remaining.Substring(0,60) + "..."
            }
            Write-Progress `
                -Activity "Waiting for Jobs - $($MaxThreads - $($RunspacePool.GetAvailableRunspaces())) of $MaxThreads threads running" `
                -PercentComplete (($Jobs.Count - $($($Jobs | Where-Object {$_.Handle.IsCompleted -eq $False}).count)) / $Jobs.Count * 100) `
                -Status "$(@($($Jobs | Where-Object {$_.Handle.IsCompleted -eq $False})).count) remaining - $remaining" 
 
            #For each completed job
            ForEach ($Job in $($Jobs | Where-Object {$_.Handle.IsCompleted -eq $True})){
                #Store the result in results
                $Results += $Job.Thread.EndInvoke($Job.Handle)

                #Append results to output file
                $Job.Thread.EndInvoke($Job.Handle) | Select Input_CN,AD_OperatingSystem,AD_Enabled,AD_Age,FQDN,ComputerName,Manufacturer,Model,Error | Export-Csv -Path "$OutputPath\vScout_$Date.csv" -Append -NoTypeInformation

                #Close out the thread
                $Job.Thread.Dispose()
                $Job.Thread = $Null
                $Job.Handle = $Null

                #Update the timer
                $ResultTimer = Get-Date
            }

            #If the max alloted time between results has been exceeded exit
            If (($(Get-Date) - $ResultTimer).totalseconds -gt $MaxWaitTime){
                Write-Host "One or more threads did not return a response."

                #Close the runspase pool
                $RunspacePool.Close() | Out-Null
                $RunspacePool.Dispose() | Out-Null

                #Save the results to CSV
                Write-Host "Checking output..."

                if(!(Test-Path "$OutputPath\vScout_$Date.csv")) {
                    if(($Results | Measure).Count -gt 0) {
                        $Results | Select Input_CN,AD_OperatingSystem,AD_Enabled,AD_Age,FQDN,ComputerName,Manufacturer,Model,Error | Export-Csv -Path "$OutputPath\vScout_$Date.csv" -NoTypeInformation
                        Write-Host "Output located at $OutputPath\vScout_$Date.csv"
                    } else {
                        Write-Host "Scan returned no results"
                    }
                } else {
                    Write-Host "Output located at $OutputPath\vScout_$Date.csv"
                }

                # Prompt to exit
                Write-Host "Press Enter to exit"
                $Host.UI.ReadLine()

                Exit
            }

            #Wait while jobs process
            Start-Sleep -Milliseconds $Sleep
        
        } 
        
        #Close the runspase pool
        $RunspacePool.Close() | Out-Null
        $RunspacePool.Dispose() | Out-Null

        #Return Results
        $Results
    }
}
########## End Multithreading Function ##########

################## Main Script ##################

#Check if PowerShell is version 2 or higher, exit if not
if($PSVersionTable.PSVersion.Major -lt 2) {
    Write-Error "`nPowerShell version 2 or higher is required to run this script."
    Exit
}

#Get the location of the current script
$ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition

#Set the output path
$OutputPath = $ScriptPath + "\VMware Data\vScout"

#Get the current date
$Date = Get-Date -Format "yyyy-MM-dd"

#Get user scan mode
Write-Host "Please select a scan mode:`n1: Local machine`n2: Active Directory`n3: Scan list (scanlist.csv or scanlist.txt)`n" -NoNewline
$mode = $Host.UI.ReadLine()

#If input is not an option, exit
if(($mode -ne 1) -and ($mode -ne 2) -and ($mode -ne 3)) {
    Write-Error "Input `"$mode`" not recognized."
    Exit
}

#Create output path if it doesn't exist
if(!(Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

#Local machine
if($mode -eq 1) {
    Write-Host "Scanning local machine..."

    #Try to get the computer FQDN
    $FQDN = $null
    $FQDNFlag = $null
    try {
        $FQDN = [System.Net.DNS]::GetHostEntry($env:COMPUTERNAME).HostName
        $FQDNFlag = $true
    } catch {
        $FQDN = ""
        $FQDNFlag = $false
    }

    #Try to query the computer
    try {
        #Use the FQDN if available
        if($FQDNFlag) {
            $q = Get-WmiObject -Query "SELECT Name,Manufacturer,Model FROM Win32_ComputerSystem" -ComputerName $FQDN -ErrorAction Stop
        } else {
            $q = Get-WmiObject -Query "SELECT Name,Manufacturer,Model FROM Win32_ComputerSystem" -ComputerName $env:COMPUTERNAME -ErrorAction Stop
        }
        
        $Results = New-Object PSObject -Property @{
            "Input_CN" = $env:COMPUTERNAME
            "AD_OperatingSystem" = ""
            "AD_Enabled" = ""
            "AD_Age" = ""
            "FQDN" = $FQDN
            "ComputerName" = $q.Name
            "Manufacturer" = $q.Manufacturer
            "Model" = $q.Model
            "Error" = ""
        }

    #Catch error if the credentials are wrong
    } catch [System.UnauthorizedAccessException] {
        $Results = New-Object PSObject -Property @{
            "Input_CN" = $env:COMPUTERNAME
            "AD_OperatingSystem" = ""
            "AD_Enabled" = ""
            "AD_Age" = ""
            "FQDN" = $FQDN
            "ComputerName" = ""
            "Manufacturer" = ""
            "Model" = ""
            "Error" = "Access denied"
        }

    #Catch remaining errors and print the error name
    } catch {
        $Results = New-Object PSObject -Property @{
            "Input_CN" = $env:COMPUTERNAME
            "AD_OperatingSystem" = ""
            "AD_Enabled" = ""
            "AD_Age" = ""
            "FQDN" = $FQDN
            "ComputerName" = ""
            "Manufacturer" = ""
            "Model" = ""
            "Error" = "$($_.Exception.GetType().FullName)"
        }
    }

#Scan mode is Active Directory or scan list
} else {

    #Get user credentials
    try {
        $Credential = Get-Credential -Credential $env:USERNAME -ErrorAction Stop
    } catch {
        Write-Error "Credentials not entered."
        Exit
    }

    #Active Directory
    if($mode -eq 2) {
        Write-Host "Scanning Active Directory..."

        #Import the ActiveDirectory module if it is available
        #exit the script if it is not
        if(!(Get-Module -Name ActiveDirectory)) {
            if(!(Get-Module -ListAvailable -Name ActiveDirectory)) {
                Write-Error "`nERROR: Please install the ActiveDirectory module."
                Exit
            }

            Import-Module -Name ActiveDirectory -ErrorAction SilentlyContinue
            if (!(Get-Module -Name ActiveDirectory)) {
                Write-Error "`nERROR: Cannot load the ActiveDirectory module."
                Exit
            }
        }

        #Get list of computers from Active Directory where Enabled = True and the age is less than 90 days
        #Create calculated property for the computer age
        $Calc_Age = @{N="Age";E={((Get-Date) - (@([datetime]::FromFileTime($_.pwdLastSet),[datetime]::FromFileTime($_.lastLogon),[datetime]::FromFileTime($_.lastLogonTimestamp)) | Sort | Select -Last 1)).Days}}

        #Get computers from Active Directory filter on Enabled = True and where Age < 90 days
        $Computers = Get-ADComputer -Filter {Enabled -eq "True"} -Properties cn,operatingSystem,pwdLastSet,lastLogon,lastLogonTimestamp | `
            Select -Property CN,OperatingSystem,Enabled,$Calc_Age | `
            Where Age -le 90
    
        #Start Scans
        $Results = $Computers | Multithread-Scan -Credential $Credential
    
    #Scan list
    } else {
        #Check if the scan list exists
        $ScanList = "$ScriptPath\scanlist.txt"
        $Csv = $False

        if(Test-Path $ScanList) {
            Write-Host "`nScanning scanlist.txt"
        } else {
            $ScanList = "$ScriptPath\scanlist.csv"
            $Csv = $True

            if(Test-Path $ScanList) {
                Write-Host "`nScanning scanlist.csv"
            } else {
                Write-Error "`nError: Scan list not found."
                Exit
            }
        }

        #Create array list to store computers and results
        $Computers = @()
        $Results = @()

        #Import CSV file
        if($Csv) {
            $Header = Get-Content -Path $ScanList -TotalCount 1

            #If importing a previous output
            if(($Header -eq '"Input_CN","AD_OperatingSystem","AD_Enabled","AD_Age","FQDN","ComputerName","Manufacturer","Model","Error"') `
                -or ($Header -eq 'Input_CN,AD_OperatingSystem,AD_Enabled,AD_Age,FQDN,ComputerName,Manufacturer,Model,Error')) {
                
                #Import scan file
                $Computers = Import-Csv -Path $ScanList

                #Existing results are entries with a value for ComputerName or are non-Windows entries
                $Results += $Computers | Where {($_.AD_OperatingSystem -and ($_.AD_OperatingSystem -notlike "*Windows*")) -or $_.ComputerName}

                $Computers = $Computers | Where {(!$_.AD_OperatingSystem -or ($_.AD_OperatingSystem -like "*Windows*")) -and !$_.ComputerName} | `
                    Select -Property @{N="CN";E={$_.Input_CN}},@{N="OperatingSystem";E={$_.AD_OperatingSystem}},@{N="Enabled";E={$_.AD_Enabled}},@{N="Age";E={$_.AD_Age}}

            #If importing a list of machine names
            } else {
                #Import machine list
                $List = Get-Content -Path $ScanList

                #Build array of objects from the list
                $Computers = @()
            
                $List | % {
                    $Computers += New-Object PSObject -Property @{CN = $_}
                }

                $Computers | Add-Member NoteProperty "OperatingSystem" ""
                $Computers | Add-Member NoteProperty "Enabled" ""
                $Computers | Add-Member NoteProperty "Age" ""
            }

        #Import TXT file   
        } else {
            #Import machine list
            $List = Get-Content -Path $ScanList

            #Build array of objects from the list
            $Computers = @()
            
            $List | % {
                $Computers += New-Object PSObject -Property @{CN = $_}
            }

            $Computers | Add-Member NoteProperty "OperatingSystem" ""
            $Computers | Add-Member NoteProperty "Enabled" ""
            $Computers | Add-Member NoteProperty "Age" ""
        }

        $Results += $Computers | Multithread-Scan -Credential $Credential
    }
}

#Save the results to CSV
Write-Host "Checking output..."

if(!(Test-Path "$OutputPath\vScout_$Date.csv")) {
    if(($Results | Measure).Count -gt 0) {
        $Results | Select Input_CN,AD_OperatingSystem,AD_Enabled,AD_Age,FQDN,ComputerName,Manufacturer,Model,Error | Export-Csv -Path "$OutputPath\vScout_$Date.csv" -NoTypeInformation
        Write-Host "Output located at $OutputPath\vScout_$Date.csv"
    } else {
        Write-Host "Scan returned no results"
    }
} else {
    Write-Host "Output located at $OutputPath\vScout_$Date.csv"
}

# Prompt to exit
Write-Host "Press Enter to exit"
$Host.UI.ReadLine()





# SIG # Begin signature block
# MIIFlwYJKoZIhvcNAQcCoIIFiDCCBYQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUMYsbv1kEnTUMwTiVfWj8tbPu
# gsGgggMkMIIDIDCCAgigAwIBAgIQL7KlRTLJ57xHE4/4e2Ex8TANBgkqhkiG9w0B
# AQsFADAoMSYwJAYDVQQDDB1WTXdhcmUgQ29tcGxpYW5jZSBDZXJ0aWZpY2F0ZTAe
# Fw0yMTA0MDcxNzQwNDVaFw0yMjA0MDcxODAwNDVaMCgxJjAkBgNVBAMMHVZNd2Fy
# ZSBDb21wbGlhbmNlIENlcnRpZmljYXRlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
# MIIBCgKCAQEA0080ZZGbVh3yk5f7M6gTJvyTAK1B1t3IFNXwWP8WahyvtEnW05k0
# IxcAGAk9gtoB9XVjxai79YilGCttF0E1mXGMOErhDdGkuNpJvzKo9KH9GL7BkWJU
# QGkRF93EICyCI/J8gTQReHDmUVn9AXJ72lcRLCPMueoEs/jtG1snlNSNqcOGLhzp
# NyHjv6ZX2GuOPoiaBbmbDhRFxnyWAOTEMda2DvQmnq3XPwxVrL1+9S+oHrpHkISq
# /3MHc3+29r6Ey8hdaPikvhrjEUZOZQSb+gdtCF7uNiCwUuOgysaQQEmyEen6mfxi
# r3AGSsnHI6FwHHulZBvmx4qElh14tg6BoQIDAQABo0YwRDAOBgNVHQ8BAf8EBAMC
# B4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHhjJQasCNM1+SeOQIJI
# R5wD9xDWMA0GCSqGSIb3DQEBCwUAA4IBAQC/6sQv82ar2x3pb0yPLGNYxJUBOmBS
# Xoxr7gzMEPDjxolH65gp/P+aAXdX91AfKSwg+Z09qjeqZTKZapRzGJyRQecV4EgS
# XJXIPFkXL+ew2kKx7lEcFxYjyILL486G4pVsavkCDBYLI0HiVKQ00FcLtkgbZLsU
# yBQoKtaFHdbR1etm1jxaspP8PJ1XvapQZMt1HKPtpOP2DiikAcIVA9wD+44Frtw9
# hsZiG6h6x+sJ/96KttIdrAglAetH7rjqlYwKOIlq+8B6XKzYv8v1nyCzdopeeMv8
# Y7RWRlsU2CWu+ls8x/wvugW3r1Qd3oNBX6xIHSObU0q4cJPoh5ailofuMYIB3TCC
# AdkCAQEwPDAoMSYwJAYDVQQDDB1WTXdhcmUgQ29tcGxpYW5jZSBDZXJ0aWZpY2F0
# ZQIQL7KlRTLJ57xHE4/4e2Ex8TAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEK
# MAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3
# AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU0w1UxMEFE5AxkhsV
# mQBzWXdajFYwDQYJKoZIhvcNAQEBBQAEggEATq4Mh5xsgLOR5Nx5fghJDRkByhFY
# F+8u0P7I8ZF/Un8ra6JFOdvgrzEgNwQbSsvhvSbMFeEGJtAttdyrvVaSGTbt0eRq
# afr6pobw0ZQ86oSUWee2WA02Z1F/voVU2ew/afj5mDKNFVdRLlgWeK2/8h+VAkFy
# TZ0wQ6wJ1nsQUH8H6qGaM+qRcY/j1mLYQkk0Y6+ud20uauYqbSCnj2+9uCGgEzFg
# qd2mijI9gjmB36jBTBptf0m2JNNxRJ8Uef6ntGMFPndEANLQClJWHgfi/+/ks5A/
# 44Pjdvz/ovWVQnvlMvg7RQSHH+1dOYzd2bo8Umo+OGqJpbZYBXSDIdbVow==
# SIG # End signature block
