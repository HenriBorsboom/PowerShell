<#
.SYNOPSIS
	Display current TCP/IP connections for local or remote system

.FUNCTIONALITY
    Computers

.DESCRIPTION
	Display current TCP/IP connections for local or remote system.  Includes the process ID (PID) and process name for each connection.
	If the port is not yet established, the port number is shown as an asterisk (*).	
	
.PARAMETER ProcessName
	Gets connections by the name of the process. The default value is '*'.
	
.PARAMETER Port
	The port number of the local computer or remote computer. The default value is '*'.

.PARAMETER Address
	Gets connections by the IP address of the connection, local or remote. Wildcard is supported. The default value is '*'.

.PARAMETER Protocol
	The name of the protocol (TCP or UDP). The default value is '*' (all)
	
.PARAMETER State
	Indicates the state of a TCP connection. The possible states are as follows:
		
	Closed       - The TCP connection is closed. 
	Close_Wait   - The local endpoint of the TCP connection is waiting for a connection termination request from the local user. 
	Closing      - The local endpoint of the TCP connection is waiting for an acknowledgement of the connection termination request sent previously. 
	Delete_Tcb   - The transmission control buffer (TCB) for the TCP connection is being deleted. 
	Established  - The TCP handshake is complete. The connection has been established and data can be sent. 
	Fin_Wait_1   - The local endpoint of the TCP connection is waiting for a connection termination request from the remote endpoint or for an acknowledgement of the connection termination request sent previously. 
	Fin_Wait_2   - The local endpoint of the TCP connection is waiting for a connection termination request from the remote endpoint. 
	Last_Ack     - The local endpoint of the TCP connection is waiting for the final acknowledgement of the connection termination request sent previously. 
	Listen       - The local endpoint of the TCP connection is listening for a connection request from any remote endpoint. 
	Syn_Received - The local endpoint of the TCP connection has sent and received a connection request and is waiting for an acknowledgment. 
	Syn_Sent     - The local endpoint of the TCP connection has sent the remote endpoint a segment header with the synchronize (SYN) control bit set and is waiting for a matching connection request. 
	Time_Wait    - The local endpoint of the TCP connection is waiting for enough time to pass to ensure that the remote endpoint received the acknowledgement of its connection termination request. 
	Unknown      - The TCP connection state is unknown.
	
	Values are based on the TcpState Enumeration:
	http://msdn.microsoft.com/en-us/library/system.net.networkinformation.tcpstate%28VS.85%29.aspx
        
    Cookie Monster - modified these to match netstat output per here:
    http://support.microsoft.com/kb/137984

.PARAMETER ComputerName
    If defined, run this command on a remote system via WMI.  \\computername\c$\netstat.txt is created on that system and the results returned here

.PARAMETER ShowHostNames
    If specified, will attempt to resolve local and remote addresses.

.PARAMETER tempFile
    Temporary file to store results on remote system.  Must be relative to remote system (not a file share).  Default is "C:\netstat.txt"

.PARAMETER AddressFamily
    Filter by IP Address family: IPv4, IPv6, or the default, * (both).

    If specified, we display any result where both the localaddress and the remoteaddress is in the address family.

.EXAMPLE
	Get-NetworkStatistics | Format-Table

.EXAMPLE
	Get-NetworkStatistics iexplore -computername k-it-thin-02 -ShowHostNames | Format-Table

.EXAMPLE
	Get-NetworkStatistics -ProcessName md* -Protocol tcp

.EXAMPLE
	Get-NetworkStatistics -Address 192* -State LISTENING

.EXAMPLE
	Get-NetworkStatistics -State LISTENING -Protocol tcp

.OUTPUTS
	System.Management.Automation.PSObject

.NOTES
	Author: Shay Levy, code butchered by Cookie Monster and Henri Borsboom
	Shay's Blog: http://PowerShay.com
    Cookie Monster's Blog: http://ramblingcookiemonster.wordpress.com
    Henri Borsboom's Blog: https://za.linkedin.com/in/henri-borsboom-0431b32

.LINK
    http://gallery.technet.microsoft.com/scriptcenter/Get-NetworkStatistics-66057d71
#>	
[OutputType('System.Management.Automation.PSObject')]
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False, Position=0)]
	[String] $ProcessName      = '*',
	[Parameter(Mandatory=$False, Position=1)]
	[String] $Address          = '*',		
	[Parameter(Mandatory=$False, Position=2)]
	[Object] $Port             = '*',
	[Parameter(Mandatory=$False, Position=3)]
    [String] $Computername     = $env:COMPUTERNAME,
    [Parameter(Mandatory=$False, Position=4)] [ValidateSet('*','tcp','udp')]
	[String] $Protocol         = '*',
    [Parameter(Mandatory=$False, Position=5)] [ValidateSet('*','Closed','Close_Wait','Closing','Delete_Tcb','DeleteTcb','Established','Fin_Wait_1','Fin_Wait_2','Last_Ack','Listening','Syn_Received','Syn_Sent','Time_Wait','Unknown')]
	[String] $State            = '*',
    [Parameter(Mandatory=$False, Position=6)]
    [Switch] $ShowHostnames,
    [Parameter(Mandatory=$False, Position=7)]
    [Switch] $ShowProcessNames = $True,	
    [Parameter(Mandatory=$False, Position=8)]
    [String] $TempFile         = "C:\netstat.txt",
    [Parameter(Mandatory=$False, Position=9)] [Validateset('*','IPv4','IPv6')]
    [String] $AddressFamily    = '*')
    
Begin {
    #Define properties
    $Properties = 'Protocol','LocalAddress','LocalPort','RemoteAddress','RemotePort','State','ProcessName','PID'
        
    #Collect processes
    If ($ShowProcessNames -eq $True) { 
        Try   { $Processes = Get-Process -ComputerName $Computername -ErrorAction Stop | Select-Object Name, ID }
        Catch { Write-Warning "Could not run Get-Process -Computername $Computername.  Verify permissions and connectivity.  Defaulting to no ShowProcessNames"; $ShowProcessNames = $False }
    }

    #Store Host Names in Array for quick lookup
    $DNSCache = @{}
}
Process {
    #Handle remote systems
    If ($Computername -ne $env:COMPUTERNAME) {
        #Define command
        [String] $CMD = "cmd /c c:\windows\system32\netstat.exe -ano >> $TempFile"
        
        #Define remote file path - Computername, Drive, Folder path
        $RemoteTempFile = "\\{0}\{1}`${2}" -f "$Computername", (Split-Path $TempFile -Qualifier).TrimEnd(":"), (Split-Path $TempFile -NoQualifier)

        #Delete previous results
        Try   { $null = Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList "cmd /c del $TempFile" -ComputerName $Computername -ErrorAction Stop }
        Catch { Write-Warning "Could not invoke Create Win32_Process on $Computername to delete $TempFile" }

        #Run command
        Try   { $ProcessID = ( Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList $CMD -ComputerName $Computername -ErrorAction Stop ).ProcessID }
        Catch { Throw $_; Break } #If we didn't run netstat, break everything off

        #Wait for process to complete
        While ( $( Try { Get-Process -Id $ProcessID -ComputerName $Computername -ErrorAction Stop } Catch { $False } ) ) { #This while should return true until the process completes
            Start-Sleep -Seconds 2 
        }
        
        #Gather results
        If ( ( Test-Path $RemoteTempFile ) -eq $True ) {
            Try   { $Results = Get-Content $RemoteTempFile | Select-String -Pattern '\s+(TCP|UDP)' }
            Catch {
                Throw "Could not get content from $RemoteTempFile for results"
                Break
            }
            Remove-Item $RemoteTempFile -Force
        }
        Else { 
            Throw "'$TempFile' on $Computername converted to '$RemoteTempFile'.  This path is not accessible from your system."
            Break
        }
    }
    Else {
        #Gather results on local PC
        $Results = netstat -ano | Select-String -Pattern '\s+(TCP|UDP)'
    }

    #Initialize counter for progress
    $TotalCount = $Results.Count
    $Count      = 0
    
    #Loop through each line of results    
	ForEach ($Result in $Results) {
    	$Item = $Results.Line.Split(' ',[System.StringSplitOptions]::RemoveEmptyEntries)
    	If ($Item[1] -notmatch '^\[::') {
            #Parse the netstat line for local address and port
    	    If ( ( $LA = $Item[1] -as [ipaddress]).AddressFamily -eq 'InterNetworkV6') {
    	        $LocalAddress  = $LA.IPAddressToString
    	        $LocalPort     = $Item[1].Split('\]:')[-1]
    	    }
    	    Else {
    	        $LocalAddress  = $Item[1].Split(':')[0]
    	        $LocalPort     = $Item[1].Split(':')[-1]
    	    }
                
            #Parse the netstat line for remote address and port
    	    If ( ( $RA = $Item[2] -as [ipaddress]).AddressFamily -eq 'InterNetworkV6') {
    	        $RemoteAddress = $RA.IPAddressToString
    	        $RemotePort    = $Item[2].Split('\]:')[-1]
    	    }
    	    Else {
    	        $RemoteAddress = $Item[2].Split(':')[0]
    	        $RemotePort    = $Item[2].Split(':')[-1]
    	    }

            #Filter IPv4/IPv6 if specified
            If ($AddressFamily -ne "*") {
                If ($AddressFamily -eq 'IPv4' -and $LocalAddress -match ':' -and $RemoteAddress -match ':|\*' ) {
                    #Both are IPv6, or ipv6 and listening, skip
                    Write-Verbose "Filtered by AddressFamily:`n$Result"
                    Continue
                }
                ElseIf ($AddressFamily -eq 'IPv6' -and $LocalAddress -notmatch ':' -and ( $RemoteAddress -notmatch ':' -or $RemoteAddress -match '*' ) ) {
                    #Both are IPv4, or ipv4 and listening, skip
                    Write-Verbose "Filtered by AddressFamily:`n$Result"
                    Continue
                }
            }
    			
            #parse the netstat line for other properties
    		$ProcId = $Item[-1]
    		$Proto  = $Item[0]
    		$Status = If ($Item[0] -eq 'tcp') { $Item[3] } Else { $null }	

            #Filter the object
			If ( $RemotePort -notlike $Port -and $LocalPort -notlike $Port ) {
                Write-Verbose "remote $RemotePort local $LocalPort port $Port"
                Write-Verbose "Filtered by Port:`n$Result"
                Continue
			}
			If ( $RemoteAddress -notlike $Address -and $LocalAddress -notlike $Address ) {
                Write-Verbose "Filtered by Address:`n$Result"
                Continue
			}
    		If ( $Status -notlike $State ) {
                Write-Verbose "Filtered by State:`n$Result"
                Continue
			}
            If ( $Protocol -notlike $Protocol ) {
                Write-Verbose "Filtered by Protocol:`n$Result"
                Continue
			}
               
            #Display progress bar prior to getting process name or host name
            Write-Progress -Activity "Resolving host and process names" -Status "Resolving process ID $ProcId with remote address $RemoteAddress and local address $LocalAddress" -PercentComplete ( ( $Count / $TotalCount ) * 100 )
    			
            #If we are running ShowProcessNames, get the matching name
            If ($ShowProcessNames -or $PSBoundParameters.ContainsKey -eq 'ProcessName') {
                #Handle case where process spun up in the time between running get-process and running netstat
                If   ( $ProcName = $Processes | Where {$_.ID -eq $ProcId} | Select -ExpandProperty Name ) { }
                Else { $ProcName = "Unknown"}
            }
            Else     { $ProcName = "NA" }
            If ( $ProcName -notlike $ProcessName ) {
                Write-Verbose "Filtered by ProcessName:`n$Result"
                Continue
			}
    							
            #If the showhostnames switch is specified, try to map IP to hostname
            If ( $ShowHostnames -eq $True ) {
                $tmpAddress = $null
                Try   {
                    If ( $RemoteAddress -eq "127.0.0.1" -or $RemoteAddress -eq "0.0.0.0" ) {
                        $RemoteAddress = $Computername
                    }
                    ElseIf ( $RemoteAddress -match "\w" ) {
                        #Check with dns cache first
                        If ( $DNSCache.ContainsKey( $RemoteAddress ) ) {
                            $RemoteAddress = $DNSCache[$RemoteAddress]
                            Write-Verbose "using cached REMOTE '$RemoteAddress'"
                        }
                        Else {
                            #If address isn't in the cache, resolve it and add it
                            $TMPAddress    = $RemoteAddress
                            $RemoteAddress = [System.Net.DNS]::GetHostByAddress("$RemoteAddress").Hostname
                            $DNSCache.add($TMPAddress, $RemoteAddress)
                            Write-Verbose "using non cached REMOTE '$RemoteAddress`t$TMPAddress"
                        }
                    }
                }
                Catch { }
                Try   {
                    If     ( $LocalAddress -eq "127.0.0.1" -or $LocalAddress -eq "0.0.0.0" ) { $LocalAddress = $Computername }
                    ElseIf ( $LocalAddress -match "\w" ) {
                        #Check with dns cache first
                        If ( $DNSCache.containskey($LocalAddress) ) {
                            $LocalAddress = $DNSCache[$LocalAddress]
                            Write-Verbose "using cached LOCAL '$LocalAddress'"
                        }
                        Else {
                            #if address isn't in the cache, resolve it and add it
                            $TMPAddress   = $LocalAddress
                            $LocalAddress = [System.Net.DNS]::GetHostByAddress("$LocalAddress").Hostname
                            $DNSCache.Add($LocalAddress, $TMPAddress)
                            Write-Verbose "using non cached LOCAL '$LocalAddress'`t'$TMPAddress'"
                        }
                    }
                }
                catch{ }
            }
    
    		#Write the object	
    		New-Object -TypeName PSObject -Property @{
				PID           = $ProcId
				ProcessName   = $ProcName
				Protocol      = $Protocol
				LocalAddress  = $LocalAddress
				LocalPort     = $LocalPort
				RemoteAddress = $RemoteAddress
				RemotePort    = $RemotePort
				State         = $Status
			} | Select-Object -Property $Properties								

            #Increment the progress counter
            $Count++
        }
    }
}