Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $Color, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)
    $ErrorActionPreference = "Stop"
    Try {
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $Color[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch {
        Write-Error $_ 
    }
}
Function Test-Portv1 {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Target, `
        [Parameter(Mandatory=$true, Position=2)]
        [Int64] $Timeout, `
        [Parameter(Mandatory=$True, Position=3)]
        [Int64] $Port)
    
    $ErrorActionPreference = "SilentlyContinue"
            
    $TCPClient = new-Object system.Net.Sockets.TcpClient      # Create TCP Client
    $iar = $TCPClient.BeginConnect($Target,$Port,$null,$null) # Tell TCP Client to connect to machine on Port
    $Wait = $iar.AsyncWaitHandle.WaitOne($Timeout,$False)     # Set the wait time
     
    If (!$Wait) {                                             # Check to see if the connection is done
        $TCPClient.Close()                                    # Close the connection and report timeout
    }
    Else {
        $error.Clear()                                        # Close the connection and report the error if there is one
        $TCPClient.EndConnect($iar) | out-Null
        If (!$?) {
            Write-Host $error[0]
            $Failed = $True
        }
        $TCPClient.Close()
    }
    If ($Failed -eq $False) {                                 # Return TRUE if connection Establish else FALSE
        $State = "Open"
    }
    Else {
        $State = "Closed"
    }
    $ErrorActionPreference = "Stop"
    Return $State
}
Function Test-Portv2 {
    Param(
        <#[Parameter(Mandatory=$True, Position=0, ParameterSetName="ComputerName")]
        [String]               $ComputerName,
        [Parameter(Mandatory=$True, Position=0, ParameterSetName="IP")]
        [System.Net.IPAddress] $IPAddress,#>
        [Parameter(Mandatory=$True, Position=0)]
        [String] $Target, `
        [Parameter(Mandatory=$True, Position=1)]
        [Int32]                $Port)

    <#Switch ($PSCmdlet.ParameterSetName) {
        "ComputerName" { $RemoteServer = $ComputerName }
        "IP"           { $RemoteServer = $IPAddress }
    }#>
    $RemoteServer = $Target
    $Test = New-Object System.Net.Sockets.TcpClient;
    Try {
        #Write-Host "Connecting to "$RemoteServer":"$Port" (TCP).."
        $Test.Connect($RemoteServer, $Port)
        $State = "Open"
        }
    Catch {
        $State = "Close"
    }
    Finally { $test.Dispose() }
    Return $State
}
Function Start-PortScan {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Target, `
        [Parameter(Mandatory=$true, Position=2)]
        [Int64] $Timeout, `
        
        [Parameter(Mandatory=$True, Position=3, ParameterSetName="Port")]
        [Int64] $Port, `

        [Parameter(Mandatory=$True, Position=3, ParameterSetName="PortRange")]
        [Int64] $StartPort, `
        [Parameter(Mandatory=$True, Position=4, ParameterSetName="PortRange")]
        [Int64] $EndPort)

    Switch ($PSCmdlet.ParameterSetName) {
        "Port" {
            #$Results = Test-Portv1 -Target $Target -Timeout $Timeout -Port $Port
            $Results = Test-Portv2 -Target $Target -Port $Port
        }
        "PortRange" {
            For ($Port = $StartPort; $Port -lt $EndPort; $Port ++) {
                #$Results = Test-Portv1 -Target $Target -Timeout $Timeout -Port $Port
                $Results = Test-Portv2 -Target $Target -Port $Port
            }
        }
    }
    If ($Results -eq "Open") {
        Write-Color $Target, " - ", $Port, " - ", $Results -Color Cyan, White, Yellow, White, Green
    }
    Else {
        Write-Color $Target, " - ", $Port, " - ", $Results -Color Cyan, White, Yellow, White, Red
    }
}
$ErrorActionPreference = "Stop"
Clear-Host

$Targets = @(
    "172.16.0.5", `
    "52.166.140.189", `
    "52.174.97.85")

$Port = 3389
$Timeout = 3000
ForEach ($Server in $Targets) {
    Start-PortScan -Target $Server -Timeout $Timeout -Port $Port
}