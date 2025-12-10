Param (
        [Parameter(Mandatory=$true,Position=1)]
        [Int64] $Timeout, `
        [Parameter(Mandatory=$true,Position=2)]
        [String] $srv, `
        [Parameter(Mandatory=$true,Position=3)]
        [Int64] $StartPort, `
        [Parameter(Mandatory=$true,Position=4)]
        [Int64] $EndPort)

Function Delete-LastLine {
    Try {
    $x = [Console]::CursorLeft
    $y = [Console]::CursorTop
    [Console]::SetCursorPosition($x,$y - 1)
    Write-Host "                                                                                                                                            "
    [Console]::SetCursorPosition($x,$y - 1)
    }
    Catch {
    }
}
#Function StartPortScan {

       
    For ($port = $StartPort; $port -lt $EndPort; $port ++) {
        If ($port -eq $StartPort) {
            Write-Host "Processing port: " -NoNewline
            Write-Host $port -ForegroundColor Cyan
        }
        If ($port -eq ($StartPort + 1)) {
            Delete-LastLine
            Write-Host "Processing port: " -NoNewline
            Write-Host $port -ForegroundColor Cyan

            Write-Host "Last port state: " -NoNewline
            Write-Host ($port - 1) -ForegroundColor Cyan -NoNewline
            Write-Host " - " -NoNewline
            Write-Host $State -ForegroundColor Yellow
        }
        If ($port -gt ($StartPort + 2)) {
            Delete-LastLine
            Delete-LastLine
            Write-Host "Processing port: " -NoNewline
            Write-Host $port -ForegroundColor Cyan

            Write-Host "Last port state: " -NoNewline
            Write-Host ($port - 1) -ForegroundColor Cyan -NoNewline
            Write-Host " - " -NoNewline
            Write-Host $State -ForegroundColor Yellow
        }
        
        
        # Does a TCP connection on specified port (135 by default)
        $ErrorActionPreference = "SilentlyContinue"
     
        # Create TCP Client
        $tcpclient = new-Object system.Net.Sockets.TcpClient
     
        # Tell TCP Client to connect to machine on Port
        $iar = $tcpclient.BeginConnect($srv,$port,$null,$null)
     
        # Set the wait time
        $wait = $iar.AsyncWaitHandle.WaitOne($timeout,$false)
     
        # Check to see if the connection is done
        If (!$wait) {
            # Close the connection and report timeout
            $tcpclient.Close()
            If ($verbose) {
                Write-Host $srv -ForegroundColor Cyan -NoNewline
                Write-Host " - " -NoNewline
                Write-Host "Connection Timeout" -ForegroundColor Red -NoNewline
                Write-Host " - " -NoNewline
                Write-Host $port
            }
        }
        Else {
            # Close the connection and report the error if there is one
            $error.Clear()
            $tcpclient.EndConnect($iar) | out-Null
            If (!$?) {
                write-host $error[0]
                $failed = $true
            }
            $tcpclient.Close()
        }
     
        # Return $true if connection Establish else $False
        If ($failed -eq $false) {
            Write-Host $srv -ForegroundColor Cyan -NoNewline
            Write-Host " - " -NoNewline
            Write-Host $port -ForegroundColor Green -NoNewline
            Write-Host " - " -NoNewline
            Write-Host "open" -ForegroundColor Green
            #Write-Host ""
            $State = "Open"
        }
        Else {
            $State = "Closed"
            #Write-Host $srv -ForegroundColor Cyan -NoNewline
            #Write-Host " - " -NoNewline
            #Write-Host $port -ForegroundColor Cyan -NoNewline
            #Write-Host " - " -NoNewline
            #Write-Host "closed" -ForegroundColor Yellow
        }
        
        
    }

#}

#Clear-Host