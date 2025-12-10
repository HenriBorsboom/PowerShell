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

Function Test-SQLConnection {
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [String] $ConnectionString)
    
    If ($ConnectionString -ne $null) {
       Create SQL Connection
        $con = new-object "System.data.sqlclient.SQLconnection"
        Write-Host "Opening SQL connection to $ConnectionString"

        $con.ConnectionString =("$ConnectionString")
        Try {
            $con.Open() 
            Write-Host "  Successfully opened connection to the database" -ForegroundColor Green
        }
        Catch {
            $error[0]
            Write-Host " Failed to open a connection to the database"
            Exit 1
        }
        Finally {
            Write-Host "  Closing SQL connection - " -NoNewline
            $con.Close()
            $con.Dispose()
            Write-Host "Connection closed." -ForegroundColor Green
        }
    }
    Else {
        Write-Host "Please specify the connection string in the folllowing format:"
        Write-Host "  Test-SQLConnection -ConnectionString 'Data Source=<Server>;Initial Catalog=<Catalog>;User ID=<User>;Password=<Password>'"
        Write-Host "    Where:"
        Write-Host "      Server     - Server to connect to"
        Write-Host "      Catalog    - Catalog to connect to"
        Write-Host "      User       - User with sign on permission"
        Write-Host "      Password   - Password for user"
    }
}

Function Test-ADCredentials {
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [bool] $PowerShellCredentialType, `
        [Parameter(Mandatory=$False,Position=2)]
        [System.Management.Automation.PSCredential] $PowerShellCredentials, `
        [Parameter(Mandatory=$False,Position=3)]
        [String] $Username, `
        [Parameter(Mandatory=$False,Position=4)]
        [String] $Password)
    
    Write-Host "Testing " -NoNewline
    Write-Host $TestingCredentials.UserName -NoNewline -ForegroundColor Yellow
    Write-Host " - " -NoNewline
    
    If ($PowerShellCredentialType -eq $False) {
        If ($Username -ne $null -or $Username -ne "") {
            If ($Password -ne $null -or $Password -ne "") {
                $CreateUsername = $Username
                $CreatePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
                $PowerShellCredentials = New-Object System.Management.Automation.PSCredential($CreateUsername,$CreatePassword)
            }
            Else {
                Write-Host "Username supplied but password is blank" -ForegroundColor Red
            }
        }
        Else {
            Write-Host "Powershell credential was set to false and username is blank. Please try again"
        }
    }

    Try {
        Start-Process -FilePath cmd.exe /c -Credential ($PowerShellCredentials) -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
    }
}

Function Send-Mail {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [String] $From, `
        [Parameter(Mandatory=$true,Position=2)]
        [String] $To, `
        [Parameter(Mandatory=$true,Position=3)]
        [String] $Subject, `
        [Parameter(Mandatory=$true,Position=4)]
        [String] $Body, `
        [Parameter(Mandatory=$true,Position=5)]
        [String] $SMTPServer, `
        [Parameter(Mandatory=$true,Position=6)]
        [String] $SMTPPort)

    Send-MailMessage -From $From `
                     -To $To `
                     -Subject $Subject `
                     -Body $Body `
                     -SmtpServer $SMTPServer `
                     -Port $SMTPPort `
                     -UseSsl `
                     -Credential (Get-Credential)
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

Function Report-WindowsUpdate {
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [bool] $DomainWide, `
        [Parameter(Mandatory=$False,Position=2)]
        [array] $Servers)

    If ($DomainWide -eq $True) {
        $Computers = Get-Content "C:\temp\computers.txt"
        ForEach ($Server in $Computers) {
            Write-Host "Processing $Server - " -NoNewline
            Try {
                Invoke-Command -ComputerName $Server -ScriptBlock {wuauclt /reportnow} -ErrorAction Stop
                Write-Host "Complete" -ForegroundColor Green
            }
            Catch {
                Write-Host "Failed" -ForegroundColor Red
            }
        }
    }
    Else {
        ForEach ($Server in $Servers) {
            Write-Host "Processing $Server - " -NoNewline
            Try {
                Invoke-Command -ComputerName $Server -ScriptBlock {wuauclt /reportnow} -ErrorAction Stop
                Write-Host "Complete" -ForegroundColor Green
            }
            Catch {
                Write-Host "Failed" -ForegroundColor Red
            }
        }
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

Function Debug-Variable {
    Param(
        [Parameter(Mandatory=$false,Position=1)]
        [Object] $Variable)
    
    If ($Variable -eq $null) {
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
    If ($Return.ToLower() -eq "c") {
        Return
    }
    Else {
        Exit 1
    }
}

Function QueryFor-WebServers {
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [bool] $DomainWide, `
        [Parameter(Mandatory=$false,Position=2)]
        [String] $Targets)

    If ($DomainWide -eq $True) {
        $WebServers = Get-Content "c:\temp\computers.txt"
    }
    ElseIf ($Targets -ne "" -or $Targets -ne $null) {
        $WebServers = $Targets
    }
    
    $ProblemServers = @("")

    ForEach ($server in $WebServers) {
        $WMIValues1 = WMIQuery -Server $server -NameSpace "root\WebAdministration" -Class "ApplicationPool"
        If ($WMIValues1 -ne $null) {
            ForEach ($item in $WMIValues1) {
                $NewName = Strip-Name -Name $item
                
                $Output = New-Object PSObject
                $Output | Add-Member -MemberType NoteProperty -Name Server -Value $server
                $Output | Add-Member -MemberType NoteProperty -Name AppPool -Value $NewName
                $Output | Add-Member -MemberType NoteProperty -Name NameSpace -Value "root\WebAdministration"
                $Output
            }
        }
        Else {
            $WMIValues2 = WMIQuery -Server $server -NameSpace "root\microsoftiisv2" -Class "IIsApplicationPoolSetting"
            If ($WMIValues2 -ne $null) {
                ForEach ($item in $WMIValues2) {
                    $NewName = Strip-Name -Name $item
                
                    $Output = New-Object PSObject
                    $Output | Add-Member -MemberType NoteProperty -Name Server -Value $server
                    $Output | Add-Member -MemberType NoteProperty -Name AppPool -Value $NewName
                    $Output | Add-Member -MemberType NoteProperty -Name NameSpace -Value "root\microsoftiisv2"
                    $Output
                }
            }
            Else {
                $Output = New-Object PSObject
                $Output | Add-Member -MemberType NoteProperty -Name Server -Value $server
                $Output | Add-Member -MemberType NoteProperty -Name AppPool -Value "No Value"
                $Output | Add-Member -MemberType NoteProperty -Name NameSpace -Value "root\microsoftiisv2"
                $Output
            }
        }
    }
}

Function Strip-Name {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [String] $Name)

    [String] $NewName = $item
    $NewName = $NewName.Remove(0, 7)
    $NewName = $NewName.Remove($NewName.Length - 1, 1)

    Return $NewName
}

Function List-InetPubWebServers {
    $Web = @(
            "NRAZUREWEB101", `
            "NRAZUREWEB102", `
            "NRAZUREWEB103", `
            "NRAZUREWEB104", `
            "NRAZUREWEB105", `
            "NRAZUREWEB106", `
            "NRAZUREWEB107", `
            "NRAZUREWEB108")

    ForEach ($Server in $Web) {
        Write-Host "Processing $Server - " -NoNewline
        $Path = "\\" + $Server + "\C$\InetPub"
        $Results = Ls $Path -Recurse | Where-Object {$_.Mode -match "d"} | Select Name
        ForEach ($Item in $Results) {
            [String] $OutputItem = $Item
            $OutputItem = $OutputItem.Remove(0, 7)
            $OutputItem = $OutputItem.Remove($OutputItem.Length -1, 1)

            $Output = New-Object PSObject
            $Output | Add-Member -MemberType NoteProperty -Name Server -Value $Server
            $Output | Add-Member -MemberType NoteProperty -Name Item -Value $OutputItem
            $Output | Export-Csv Folders.csv -NoClobber -NoTypeInformation -Append -Force
        }
        
        Write-Host "Complete" -ForegroundColor Green
    }
}

Function Write-Color {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [String[]]$Text, `
        [Parameter(Mandatory=$true,Position=2)]
        [ConsoleColor[]]$Color, `
        [Parameter(Mandatory=$false,Position=3)]
        [bool] $EndLine)
    
    For ($i = 0; $i -lt $Text.Length; $i++) {
        Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
    }
    
    Switch ($EndLine) {
        $true {
            Write-Host
        }
        $false {
            Write-Host -NoNewline
        }
    }
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

Function Get-MSHotfix {
    $outputs = Invoke-Expression "wmic qfe list"
    $outputs = $outputs[1..($outputs.length)]
    
    ForEach ($output in $Outputs) {
        If ($output) {
            $output = $output -replace 'y U','y-U'
            $output = $output -replace 'NT A','NT-A'
            $output = $output -replace '\s+',' '
            $parts = $output -split ' '
            If ($parts[5] -like "*/*/*") {
                $Dateis = [datetime]::ParseExact($parts[5], '%M/%d/yyyy',[Globalization.cultureinfo]::GetCultureInfo("en-US").DateTimeFormat)
            }
            ElseIf (($parts[5] -eq $null) -or ($parts[5] -eq '')) {
                $Dateis = [datetime]1700
            }
            Else {$Dateis = get-date([DateTime][Convert]::ToInt64("$parts[5]", 16))-Format '%M/%d/yyyy'}
            
            New-Object -Type PSObject -Property @{
                KBArticle = [string]$parts[0]
                Computername = [string]$parts[1]
                Description = [string]$parts[2]
                HotFixID = [string]$parts[3]
                InstalledOn = Get-Date($Dateis)-format "dddd d MMMM yyyy"
                InstalledBy = [string]$parts[4]
                FixComments = [string]$parts[6]
                InstallDate = [string]$parts[7]
                Name = [string]$parts[8]
                ServicePackInEffect = [string]$parts[9]
                Status = [string]$parts[10]
            }
        }
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

Function Get-InstalledUpdates {
    [cmdletbinding(DefaultParameterSetName="All")]

    Param(
        [parameter(mandatory=$true,parametersetname='All')]
        [parameter(mandatory=$true,parametersetname='HotFixes')]
        [parameter(mandatory=$true,parametersetname='Updates')]
        [array]$ComputerName,
        [parameter(mandatory=$false,parametersetname='All')][switch]$All,
        [parameter(mandatory=$false,parametersetname='HotFixes')][switch]$HotFixes,
        [parameter(mandatory=$false,parametersetname='Updates')][switch]$Updates)

    $Session = New-PSSession -ComputerName $ComputerName
    Invoke-Command -Session $Session -ScriptBlock {$Session = New-Object -ComObject Microsoft.Update.Session}
    Invoke-Command -Session $Session -ScriptBlock {$Searcher = $Session.CreateUpdateSearcher()}
    Invoke-Command -Session $Session -ScriptBlock {$HistoryCount = $Searcher.GetTotalHistoryCount()}
    
    If (($PSCmdlet.ParameterSetName -eq 'All') -or ($PSCmdlet.ParameterSetName -eq 'Updates')) {
        $Output = Invoke-Command -Session $Session -ScriptBlock {
            $Updates = $Searcher.QueryHistory(0,$HistoryCount) 
            ForEach ($Update in $Updates) {
                [regex]::match($Update.Title,'(KB[0-9]{6,7})').value | Where-Object {$_ -ne ""} | `
                ForEach {
                    $Object = New-Object -TypeName PSObject
                    $Object | Add-Member -MemberType NoteProperty -Name KB -Value $_
                    $Object | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'Update'
                    $Object
                }
            }
        }
        $Output | Select-Object KB,Type,@{Name="ComputerName";Expression={$_.PSComputerName}}
    }
    If (($PSCmdlet.ParameterSetName -eq 'All') -or ($PSCmdlet.ParameterSetName -eq 'HotFixes')) {
        $Output = Invoke-Command -Session $Session -ScriptBlock { 
            $HotFixes = Get-HotFix | Select-Object -ExpandProperty HotFixID 
            ForEach ($HotFix in $HotFixes) {
                $Object = New-Object -TypeName PSObject
                $Object | Add-Member -MemberType NoteProperty -Name KB -Value $HotFix
                $Object | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'HotFix'
                $Object
            }
        }
        $Output | Select-Object KB,Type,@{Name="ComputerName";Expression={$_.PSComputerName}} 
    }
    Remove-PSSession $Session
}

Function Get-IISSites {
    [Void][Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")

    $sm = New-Object Microsoft.Web.Administration.ServerManager

    ForEach ($site in $sm.Sites) {
        $root = $site.Applications | where { $_.Path -eq "/" }
    
        $Output = New-Object PSObject
        $Output | Add-Member -MemberType NoteProperty -Name SiteName -Value $Site.Name
        $Output | Add-Member -MemberType NoteProperty -Name AppPool -Value $root.ApplicationPoolName
        $Output | Add-Member -MemberType NoteProperty -Name ServerName -Value $env:COMPUTERNAME
        $Output
    }
}

Function Create-Credentials {
        Param(
            [Parameter(Mandatory=$true,Position=1)]
            [String] $DomainUser, `
            [Parameter(Mandatory=$true,Position=2)]
            [String] $DomainPassword)

        $creds = New-Object System.Management.Automation.PSCredential($DomainUser,$DomainPassword)
        Return $creds
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

Function GetUsers-Profiles {
    Remove-Item "c:\users\users.csv" -ErrorAction SilentlyContinue
    Get-ChildItem $Path | Where-Object {$_.Mode -match "d"} | select Name | Export-Csv -NoTypeInformation -NoClobber "c:\users\users.csv" -Force 
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

Function Get-ADUsers {
    Param([Parameter(Mandatory=$true,Position=1)]
        [String] $UserProfilePath)

    Import-Module ActiveDirectory
    $UserList = Get-ChildItem -Path $UserProfilePath | Where-Object {$_.Mode -match "d"} | Select Name

    ForEach ($User in $UserList) {
        $UserName = Strip-Name -Name $User

        Try {
            Get-ADUser $UserName -Properties * | Select SamAccountName,Name,Enabled,AccountExpirationDate,LastLogonDate
        }
        Catch {
            Write-Host "Could not get details for $UserName" -ForegroundColor Red
        }
    }
}

Function ADUser-MemberOf {
    Import-Module ActiveDirectory
    $ServiceAccounts = Get-ADUser -Filter 'Name -like "hvi-*"' | select name

    ForEach ($ADUser in $ServiceAccounts) {
        [String] $NewUser = $ADUser
        $NewUser = $NewUser.Remove(0, 7)
        $NewUser = $NewUser.Remove(($NewUser.Length) -1, 1)

        Write-Host $NewUser
        Get-ADUser $NewUser -Properties * | select -ExpandProperty MemberOf
        Write-host ""
    }
}

Function ApplyOffline-WSUSPatches {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [String] $WSUSContentSharePath, `
        [Parameter(Mandatory=$true,Position=2)]
        [String] $VHDFile, `
        [Parameter(Mandatory=$true,Position=3)]
        [String] $TemporaryDirectory, `
        [Parameter(Mandatory=$true,Position=4)]
        [String] $ScratchDirectory)


#region 1. Mounting VHD
    Write-Color -Text "1. ", "Mounting ", $VHDFile, " at ", $TemporaryDirectory, " - " -Color Magenta, White, Cyan, White, Cyan, White
    Try{
        $empty = Mount-WindowsImage -ImagePath "$VHDFile" -Path $TemporaryDirectory -Index 1 -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch{
        Write-Host "Failed" -ForegroundColor Red
        Exit 1
    }
#endregion

#region 2. Obtaining and implementing CAB and MSU Files
    Write-Color "2. ", "Obtaining Update list of ", "CAB and MSU", " files - " -Color Magenta, White, Yellow, White 
    Try{
        $updates = get-childitem -Recurse -Path $WSUSContentSharePath | where {($_.extension -eq ".msu") -or ($_.extension -eq ".cab")} | select fullname
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch{
        Write-Color -Text "Failed! ", "Dismounting and discarding ", $VHDFile, " at ", $TemporaryDirectory, " - " -Color Red, White, Cyan, White, Cyan, White
        Try {
            $empty = Dismount-WindowsImage -Discard -Path $TemporaryDirectory
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch {
            Write-Host "Failed" -ForegroundColor Red
            Write-Host "Please dismount manually"
            Write-Host " If you wish to discard settings made to the VHD, run:"
            Write-Host "Dismount-WindowsImage -Discard -Path <String>" -ForegroundColor Yellow
            Write-Host ""
            Write-Host " If you wish to save settings made to the VHD, run:"
            Write-Host "Dismount-WindowsImage -Path <String> -Save" -ForegroundColor Yellow
        }
        Exit 1
    }

    Write-Color -Text "2.1. ", "Total ", "CAB", " updates: ", $UpdatelistCab.Count -Color Magenta, White, Yellow, White, Yellow -EndLine $true
    $x = 1 
    ForEach ($update in $updates) {
        Try {
            Write-Color "2.1.", $x, "/", $UpdatelistCab.Count, " - Attempting to install in ", $Updatecab.Directory, " - " -Color Magenta, Yellow, Yellow, Yellow, White, Cyan, White
                $empty = Add-WindowsPackage -PackagePath $update.FullName -Path $TemporaryDirectory -ScratchDirectory $ScratchDirectory -WarningAction SilentlyContinue -ErrorAction Stop
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch {
            Write-Host "Not applicable" -ForegroundColor Yellow
        }
        $x ++
    }   
#endregion
   
#region 3. Dismounting and saving VHD
    Write-Color -Text "3. ", "Dismounting and saving ", $VHDFile, " at ", $TemporaryDirectory, " - " -Color Magenta, White, Cyan, White, Cyan, White
    Try {
        Dismount-WindowsImage -Path $TemporaryDirectory -Save
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host "Please dismount manually"
        Write-Host " If you wish to discard settings made to the VHD, run:"
        Write-Host "Dismount-WindowsImage -Discard -Path <String>" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " If you wish to save settings made to the VHD, run:"
        Write-Host "Dismount-WindowsImage -Path <String> -Save" -ForegroundColor Yellow
    }
#endregion
}