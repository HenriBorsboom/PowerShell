# OS Functions

Function CopyFile-Domain {
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [string] $File, `
        [Parameter(Mandatory=$True,Position=2)]
        [string] $Path, `
        [Parameter(Mandatory=$false,Position=3)]
        [String] $ReferenceFile)

    $TargetServers = Get-Content "C:\temp\computers.txt"
    Write-Host " Total Targets: " -NoNewline
    Write-Host $TargetServers.Count -ForegroundColor Yellow
    [int] $x = 1
    ForEach ($Target in $TargetServers) {
        [string] $DestComputer = $Target
        $Dest = "\\" + $Target + "\" + $Path
        Try {
            Write-Host "$x - Copying " -NoNewline
            Write-Host "$File" -ForegroundColor Yellow -NoNewline
            Write-Host " to " -NoNewline
            Write-host "$Dest" -NoNewline
            Write-Host " - " -NoNewline
            $Empty = copy-item $File -Destination $Dest -Force
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch {
            Write-Host "Failed" -ForegroundColor Red
        }
        $x ++
    }
}

Function CopyFolder-Domain {
    $VMS = Get-Content "C:\Temp\computers.txt"

    ForEach ($Server in $VMS) {
        $FullPath = "\\" + $Server + "\C$\Windows\System32\WindowsPowerShell\v1.0\Modules\PSWindowsUpdate"

        $Source = "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\PSWindowsUpdate"
        Write-Host "Copying to $server - " -NoNewline
        Try {
            Copy-Item $Source -Destination $FullPath -Recurse -force -ErrorAction Stop
            Write-Host " Complete" -ForegroundColor Green
        }
        Catch {
            Write-Host " Failed" -ForegroundColor Red
        }
    }
}

Function Delete-Extensions {
    Param(
            [Parameter(Mandatory=$True,Position=1)]
            [string] $Extension)
    
    GetUsers-Profiles
    $Profiles = Get-Content "c:\users\users.csv"

    ForEach ($Profile in $Profiles) {
        If ($Profile -ne '"Name"' -and $Profile -ne '"@To be deleted"') {
            $CorrectProfile = $Profile.Remove(0,1)
            $CorrectProfile = $CorrectProfile.remove($CorrectProfile.Length -1 , 1)
        
            $LogFiles = Get-ChildItem $BuildPath -Recurse -Name $Extension -Force -ErrorAction SilentlyContinue
            If ($LogFiles -ne $null) {
                Foreach ($Log in $Logfiles) {
                    $OutputObj  = New-Object -Type PSObject
                    
                    $File = $BuildPath + [string] $Log
                    Try {
                        Remove-Item $File -ErrorAction Stop -Force
                        $OutputObj | Add-Member -MemberType NoteProperty -Name Profile -Value $CorrectProfile
                        $OutputObj | Add-Member -MemberType NoteProperty -Name LOGFile -Value $Log
                        $OutputObj | Add-Member -MemberType NoteProperty -Name Extension -Value $Extension
                        $OutputObj | Add-Member -MemberType NoteProperty -Name Deleted -Value "Yes"
                    }
                    Catch {
                        $OutputObj | Add-Member -MemberType NoteProperty -Name Profile -Value $CorrectProfile
                        $OutputObj | Add-Member -MemberType NoteProperty -Name LOGFile -Value $Log
                        $OutputObj | Add-Member -MemberType NoteProperty -Name Extension -Value $Extension
                        $OutputObj | Add-Member -MemberType NoteProperty -Name Deleted -Value "No"
                    }
                    $OutputObj
                }
            }
            Else {}
        }
    } 
}

Function Delete-TempFilesAndFolders {
    $Profiles = Get-Content "c:\users\users.csv"

    ForEach ($Profile in $Profiles) {
        $OutputObj2  = New-Object -Type PSObject
        If ($Profile -ne '"Name"' -and $Profile -ne '"@To be deleted"') {
            $CorrectProfile = $Profile.Remove(0,1)
            $CorrectProfile = $CorrectProfile.remove($CorrectProfile.Length -1 , 1)
        
            $buildpath = ".\" + $CorrectProfile + "\AppData\Local\Temp"
            Try {
                Remove-Item -Path $buildpath -Recurse -ErrorAction SilentlyContinue            
                $OutputObj2 | Add-Member -MemberType NoteProperty -Name Profile -Value $CorrectProfile
                $OutputObj2 | Add-Member -MemberType NoteProperty -Name Path -Value $buildpath
                $OutputObj2 | Add-Member -MemberType NoteProperty -Name Deleted -Value "Yes"
            }
            Catch {
                $OutputObj2 | Add-Member -MemberType NoteProperty -Name Profile -Value $CorrectProfile
                $OutputObj2 | Add-Member -MemberType NoteProperty -Name Path -Value $buildpath
                $OutputObj2 | Add-Member -MemberType NoteProperty -Name Deleted -Value "No"
            }
        }
        $OutputObj2
    } 
}

Function Get-IP {
    $CurrentNetAdapter = get-netadapter | where {$_.Status -eq "Up"} | Select Name
    ForEach ($Adapter in $CurrentNetAdapter) {
        $OutputObj  = New-Object -Type PSObject
        Try {
            $CurrentIPAddress = Get-NetIPAddress -InterfaceAlias $Adapter.Name  -ErrorAction Stop | select IPv4Address
            $AdapterName = $Adapter.Name
            $IPv4 = $CurrentIPAddress.IPv4Address
        }
        Catch {
            $IPv4 = "0.0.0.0"
        }
        Finally {
            $OutputObj | Add-Member -MemberType NoteProperty -Name Adapter -Value $Adapter.Name            $OutputObj | Add-Member -MemberType NoteProperty -Name IPv4 -Value $IPv4
            $OutputObj
        }
    }
}

Function Get-SubNetItems {
	[CmdletBinding(
		SupportsShouldProcess=$True,
		ConfirmImpact="Low")]	
	
    Param(
		[parameter(Mandatory=$true)]
		[System.Net.IPAddress]$StartScanIP,
		[System.Net.IPAddress]$EndScanIP,
		[Int]$MaxJobs = 20,
		[Int[]]$Ports,
		[Switch]$ShowAll,
		[Switch]$ShowInstantly,
		[Int]$SleepTime = 5,
		[Int]$TimeOut = 90)

	Begin {}

	Process {
		If ($pscmdlet.ShouldProcess("$StartScanIP $EndScanIP" ,"Scan IP range for active machines")) {
			If (Get-Job -name *.*.*.*) {
				Write-Verbose "Removing old jobs."
				Get-Job -name *.*.*.* | Remove-Job -Force
            }
			
			$ScanIPRange = @()
			If ($EndScanIP -ne $null) {
				Write-Verbose "Generating IP range list."
				# Many thanks to Dr. Tobias Weltner, MVP PowerShell and Grant Ward for IP range generator
				$StartIP = $StartScanIP -split '\.'
	  			[Array]::Reverse($StartIP)  
	  			$StartIP = ([System.Net.IPAddress]($StartIP -join '.')).Address 
				
				$EndIP = $EndScanIP -split '\.'
	  			[Array]::Reverse($EndIP)  
	  			$EndIP = ([System.Net.IPAddress]($EndIP -join '.')).Address 
				
				For ($x=$StartIP; $x -le $EndIP; $x++) {    
					$IP = [System.Net.IPAddress]$x -split '\.'
					[Array]::Reverse($IP)   
					$ScanIPRange += $IP -join '.'
                }
			}
			Else {
                $ScanIPRange = $StartScanIP
            }

			Write-Verbose "Creating own list class."
			$Class = @"
			    public class SubNetItem {
				public bool Active;
				public string Host;
				public System.Net.IPAddress IP;
				public string MAC;
				public System.Object Ports;
				public string OS_Name;
				public string OS_Ver;
				public bool WMI;
				public bool WinRM;
			} `
"@		
            Write-Verbose "Start scaning..."	
			$ScanResult = @()
			$ScanCount = 0
			Write-Progress -Activity "Scan IP Range $StartScanIP $EndScanIP" -Status "Scaning:" -Percentcomplete (0)
			Foreach ($IP in $ScanIPRange) {
	 			Write-Verbose "Starting job ($((Get-Job -name *.*.*.* | Measure-Object).Count+1)/$MaxJobs) for $IP."
				Start-Job -Name $IP -ArgumentList $IP,$Ports,$Class -ScriptBlock {
                    Param(
					    [System.Net.IPAddress]$IP = $IP,
					    [Int[]]$Ports = $Ports,
					    $Class = $Class)
					
					Add-Type -TypeDefinition $Class
					
					If (Test-Connection -ComputerName $IP -Quiet) {
						Try {
                            $HostName = [System.Net.Dns]::GetHostbyAddress($IP).HostName
                        }
						Catch {
                            $HostName = $null
                        }
						
						#Get WMI Access, OS Name and version via WMI
						Try {
							#I don't use Get-WMIObject because it havent TimeOut options. 
							$WMIObj = [WMISearcher]''  
							$WMIObj.options.timeout = '0:0:10' 
							$WMIObj.scope.path = "\\$IP\root\cimv2"  
							$WMIObj.query = "SELECT * FROM Win32_OperatingSystem"  
							$Result = $WMIObj.get()  

							If ($Result -ne $null) {
								$OS_Name = $Result | Select-Object -ExpandProperty Caption
								$OS_Ver = $Result | Select-Object -ExpandProperty Version
								$OS_CSDVer = $Result | Select-Object -ExpandProperty CSDVersion
								$OS_Ver += " $OS_CSDVer"
								$WMIAccess = $true
                            }
							Else {
                                $WMIAccess = $false
                            }
						}
						Catch {
                            $WMIAccess = $false
                        }
						
						#Get WinRM Access, OS Name and version via WinRM
						If ($HostName) {
                            $Result = Invoke-Command -ComputerName $HostName -ScriptBlock {systeminfo} -ErrorAction SilentlyContinue
                        }
						Else {
                            $Result = Invoke-Command -ComputerName $IP -ScriptBlock {systeminfo} -ErrorAction SilentlyContinue
                        }
						
						If ($Result -ne $null) {
							If ($OS_Name -eq $null) {
								$OS_Name = ($Result[2..3] -split ":\s+")[1]
								$OS_Ver = ($Result[2..3] -split ":\s+")[3]
                            }
							$WinRMAccess = $true
                        }
						Else { 
                            $WinRMAccess = $false
                        }
						
						#Get MAC Address
						Try {
							$result= nbtstat -A $IP | select-string "MAC"
							$MAC = [string]([Regex]::Matches($result, "([0-9A-F][0-9A-F]-){5}([0-9A-F][0-9A-F])"))
                        }
						Catch {
                            $MAC = $null
                        }
						
						#Get ports status
						$PortsStatus = @()
						ForEach ($Port in $Ports) {
							Try {
								$TCPClient = new-object Net.Sockets.TcpClient
								$TCPClient.Connect($IP, $Port)
								$TCPClient.Close()
								
								$PortStatus = New-Object PSObject -Property @{
		        					Port		= $Port
									Status      = $true
                                }
								$PortsStatus += $PortStatus
                            }
							Catch{
								$PortStatus = New-Object PSObject -Property @{
		        					Port		= $Port
									Status      = $false
                                }
								$PortsStatus += $PortStatus
                                }
						}

						$HostObj = New-Object SubNetItem -Property @{
		        					Active		= $true
									Host        = $HostName
									IP          = $IP
									MAC         = $MAC
									Ports       = $PortsStatus
		        					OS_Name     = $OS_Name
									OS_Ver      = $OS_Ver
		        					WMI         = $WMIAccess
		        					WinRM       = $WinRMAccess
                        }
						$HostObj
					}
					Else {
						$HostObj = New-Object SubNetItem -Property @{
		        					Active		= $false
									Host        = $null
									IP          = $IP
									MAC         = $null
									Ports       = $null
		        					OS_Name     = $null
									OS_Ver      = $null
		        					WMI         = $null
		        					WinRM       = $null
                        }
						$HostObj
                    }
				} | Out-Null
				$ScanCount++
				Write-Progress -Activity "Scan IP Range $StartScanIP $EndScanIP" -Status "Scaning:" -Percentcomplete ([int](($ScanCount+$ScanResult.Count)/(($ScanIPRange | Measure-Object).Count) * 50))
				
				Do {
					Write-Verbose "Trying get part of data."
					Get-Job -State Completed | ForEach {
                        Write-Verbose "Geting job $($_.Name) result."
						$JobResult = Receive-Job -Id ($_.Id)

						If ($ShowAll) {
							If ($ShowInstantly) {
								If ($JobResult.Active -eq $true) {
                                    Write-Host "$($JobResult.IP) is active." -ForegroundColor Green
                                }
								Else {
                                    Write-Host "$($JobResult.IP) is inactive." -ForegroundColor Red
                                }
							}
							
							$ScanResult += $JobResult	
						}
						Else {
							If ($JobResult.Active -eq $true) {
								If ($ShowInstantly) {
                                    Write-Host "$($JobResult.IP) is active." -ForegroundColor Green
                                }
								$ScanResult += $JobResult
							}
						}
						Write-Verbose "Removing job $($_.Name)."
						Remove-Job -Id ($_.Id)
						Write-Progress -Activity "Scan IP Range $StartScanIP $EndScanIP" -Status "Scaning:" -Percentcomplete ([int](($ScanCount+$ScanResult.Count)/(($ScanIPRange | Measure-Object).Count) * 50))
					}
					
					If ((Get-Job -name *.*.*.*).Count -eq $MaxJobs){
						Write-Verbose "Jobs are not completed ($((Get-Job -name *.*.*.* | Measure-Object).Count)/$MaxJobs), please wait..."
						Sleep $SleepTime}
				}
				While ((Get-Job -name *.*.*.*).Count -eq $MaxJobs)
			}
			
			$timeOutCounter = 0
			Do {
				Write-Verbose "Trying get last part of data."
				Get-Job -State Completed | Foreach {
					Write-Verbose "Geting job $($_.Name) result."
					$JobResult = Receive-Job -Id ($_.Id)

					If ($ShowAll) {
						If ($ShowInstantly) {
							If ($JobResult.Active -eq $true) {
                                Write-Host "$($JobResult.IP) is active." -ForegroundColor Green
                            }
							Else {
                                Write-Host "$($JobResult.IP) is inactive." -ForegroundColor Red
                            }
						}
						
						$ScanResult += $JobResult	
					}
					Else {
						If ($JobResult.Active -eq $true) {
							If ($ShowInstantly) {
                                Write-Host "$($JobResult.IP) is active." -ForegroundColor Green
                            }
							$ScanResult += $JobResult
						}
					}
					Write-Verbose "Removing job $($_.Name)."
					Remove-Job -Id ($_.Id)
					Write-Progress -Activity "Scan IP Range $StartScanIP $EndScanIP" -Status "Scaning:" -Percentcomplete ([int](($ScanCount+$ScanResult.Count)/(($ScanIPRange | Measure-Object).Count) * 50))
				}
				
				If (Get-Job -name *.*.*.*) {
					Write-Verbose "All jobs are not completed ($((Get-Job -name *.*.*.* | Measure-Object).Count)/$MaxJobs), please wait... ($timeOutCounter)"
					Sleep $SleepTime
					$timeOutCounter += $SleepTime				

					If ($timeOutCounter -ge $TimeOut) {
						Write-Verbose "Time out... $TimeOut. Can't finish some jobs  ($((Get-Job -name *.*.*.* | Measure-Object).Count)/$MaxJobs) try remove it manualy."
						Break
                    }
				}
			}
			While (Get-Job -name *.*.*.*)
			
			Write-Verbose "Scan finished."
			Return $ScanResult | Sort-Object {"{0:d3}.{1:d3}.{2:d3}.{3:d3}" -f @([int[]]([string]$_.IP).split('.'))}
		}
	}
	
	End {}
}

Function GetUsers-Profiles {
    Remove-Item "c:\users\users.csv" -ErrorAction SilentlyContinue
    Get-ChildItem $Path | Where-Object {$_.Mode -match "d"} | select Name | Export-Csv -NoTypeInformation -NoClobber "c:\users\users.csv" -Force 
}

Function Get-WWNN {
    Remove-Item .\wwn.csv -Force
    $CSCServers = Get-ADComputer -SearchBase "OU=LGZA,OU=ServersEP,DC=linde,DC=lds,DC=grp" -Filter "Name -like 'MLGPRY*'" | select Name

    $x = 1
    Write-Host "Total Servers: " $CSCServers.Count
    ForEach ($CSCServer in $CSCServers) {
        $Server = Strip-Name -Name $CSCServer
        If ($Server -notlike "*VMWHST*") {
            Write-Host "$x - $Server"
            Try {
                $nodewwntmp = Get-WmiObject -ComputerName $Server -class MSFC_FCAdapterHBAAttributes -Namespace “root\wmi” -Impersonation Impersonate -Authentication PacketPrivacy -ErrorAction Stop | select NodeWWN
            
                ForEach ($WMIWWNN in $nodewwntmp) {
                    $output = New-Object PSObject

                    $WWN = (($WMIWWNN.NodeWWN) | ForEach-Object {“{0:x2}” -f $_}) -join “:”
                    $output | Add-Member -MemberType NoteProperty -Name Server -Value $Server
                    $output | Add-Member -MemberType NoteProperty -Name WWNN -Value $WWN
                    $output | Export-Csv -Path ".\wwn.csv" -Encoding ASCII -Append -Delimiter ";" -NoTypeInformation
                }
            }
            Catch {}
        }
        $x ++
    }
    notepad.exe .\wwn.csv
}

Function Invoke-RemoteCommand {
        Param(
            [Parameter(Mandatory=$true,Position=1)]
            [String] $Server, `
            [Parameter(Mandatory=$true,Position=2)]
            [Array] $Command)

        Try {
            $Credentials = Create-Credentials
            $Session = New-PSSession -ComputerName $Server -Credential $Credentials
            $Results = Invoke-Command -Session $Session -ArgumentList $Command -ScriptBlock {Param($PassedArguments) PowerShell.exe $PassedArguments} -ErrorAction Stop
            Return $Results
        }
        Catch {
            Return $null
        }
    }

Function Remove-DomainFile {
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [string] $File, `
        [Parameter(Mandatory=$True,Position=2)]
        [string] $Path)

    $Computers = Get-Content "c:\temp\computers.txt"
    ForEach ($Computer in $Computers) {
        [string] $DestComputer = $Computer
        $Dest = "\\" + $DestComputer + "\" + $Path + "\" + $File
        Try {
            Remove-Item $Dest
            Write-Host "Removed $File on \\$DestComputer\$Path" -ErrorAction Stop
        }
        Catch {
            Write-Host "Could not remove $File at \\$DestComputer\$Path" -ForegroundColor Red
        }
    }
}

Function Restart-ServiceOnComputers {
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [bool] $DomainWide, `
        [Parameter(Mandatory=$False,Position=2)]
        [array] $TargetServers, `
        [Parameter(Mandatory=$True,Position=3)]
        [String] $ServiceName)

    If ($DomainWide -eq $True) {
        $TargetServers = Get-Content "C:\temp\computers.txt"
    }
    Else {
        If ($TargetServers -eq "" -or $TargetServers -eq $null) {
            Write-Host "Domain Wide is set to False and no Target Servers are defined"
            Exit 1 
        }
    }

    Write-Host " Total Targets: " -NoNewline
    Write-Host  $TargetServers.Count -ForegroundColor Yellow

    [int] $x = 1
        
    ForEach ($Server in $TargetServers) {
        Write-Host "$x - Restarting " -NoNewline
        Write-Host "$ServiceName" -ForegroundColor Yellow -NoNewline
        Write-Host " on " -NoNewline
        Write-Host "$Server" -ForegroundColor Yellow -NoNewline 
        Write-Host " - " -NoNewline
        Try {
            $Empty = Icm -ComputerName $Server -ScriptBlock {Restart-Service -Name $ServiceName}
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch {
            Write-Host "Failed" -ForegroundColor Red
        }
        $x ++
    }
}

Function Runon-Domain {
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [bool] $DomainWide, `
        [Parameter(Mandatory=$False,Position=2)]
        [array] $TargetServers, `
        [Parameter(Mandatory=$True,Position=3)]
        [Array] $Command, `
        [Parameter(Mandatory=$false,Position=4)]
        [String] $ReferenceFile)

    If ($DomainWide -eq $True) {
            If ($ReferenceFile -ne $null -or $ReferenceFile -ne "") {
                $TargetServers = Get-Content "C:\temp\computers.txt"
            }
            Else {
                Try {
                    $TargetServers = Get-Content $ReferenceFile -ErrorAction stop
                }
                Catch {
                    Write-Host "Supplied Reference File - " -NoNewline
                    Write-Host "$ReferenceFile" -ForegroundColor Yellow -NoNewline
                    Write-Host " - Does not exist or is inaccessible"
                    Write-Host "Reverting to default Reference file - " -NoNewline
                    Write-Host "C:\Temp\Computers.TXT" -ForegroundColor Yellow
                    $TargetServers = Get-Content "C:\temp\computers.txt"
                }
            }
        }
    Else {
        If ($TargetServers -eq "" -or $TargetServers -eq $null) {
            Write-Host "Domain Wide is set to False and no Target Servers are defined"
            Exit 1
        }
    }    

    Write-Host " Total Targets: " -NoNewline
    Write-Host $TargetServers.Count -ForegroundColor Yellow

    [int] $x = 1

    $TargetServers = $TargetServers | Sort-Object        
    $FullResults
    ForEach ($Server in $TargetServers) {
        Write-Host "$x - Executing " -NoNewline
        Write-Host "$Command" -ForegroundColor Yellow -NoNewline
        Write-Host " on " -NoNewline
        Write-Host "$Server" -ForegroundColor Yellow -NoNewline 
        Write-Host " - " -NoNewline
        $Results = Invoke-RemoteCommand -Server $Server -Command $Command
        If ($Results -ne $null) {
            Write-Host "Complete" -ForegroundColor Green
            $FullResults += $Results
        }
        Else {
            Write-Host "Failed" -ForegroundColor Red
        }
        $x ++
     }
    
    $FullResults
}

Function Run-WMIQuery {
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$True,Position=2)]
        [String] $NameSpace, `
        [Parameter(Mandatory=$True,Position=3)]
        [String] $Class)

    Try {
        $WMIValues = Get-WmiObject -ComputerName $Server -Namespace $NameSpace -Class $Class `
            -Impersonation Impersonate -Authentication PacketPrivacy -ErrorAction Stop | Select Name
        Return $WMIValues
    }
    Catch {
        Return $null
    }
}
