Function Edit-Service {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Service, `
        [Parameter(Mandatory=$True, Position=2)][ValidateSet("Start", "Stop")] #, "Disable", "Automatic", "Manual")]
        [String] $Action, `
        [Parameter(Mandatory=$True, Position=3)][ValidateSet("Disable", "Automatic", "Manual")]
        [String] $StartType, `
        [Parameter(Mandatory=$True, Position=3, ParameterSetName="Name")]
        [Switch] $Name, 
        [Parameter(Mandatory=$True, Position=3, ParameterSetName="DisplayName")]
        [Switch] $DisplayName)

    Switch ($PSCmdlet.ParameterSetName) {
        "Name"        { Action-Service -Service $Service -Action $Action -StartType $StartType -Name }
        "DisplayName" { Action-Service -Service $Service -Action $Action -StartType $StartType -DisplayName }
        Default       { Action-Service -Service $Service -Action $Action -StartType $StartType -DisplayName }
    }
}
Function Action-Service {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Service, `
        [Parameter(Mandatory=$True, Position=2)]
        [Switch] $Name, `
        [Parameter(Mandatory=$True, Position=3, ParameterSetName="Start")][ValidateSet("Start", "Stop")] #, "Disable", "Automatic", "Manual")]
        [Parameter(Mandatory=$True, Position=3, ParameterSetName="Stop")][ValidateSet("Start", "Stop")] #, "Disable", "Automatic", "Manual")]
        [String] $Action, `
        [Parameter(Mandatory=$False, Position=3, ParameterSetName="Start")][ValidateSet("Disable", "Automatic", "Manual", "Default")]
        [Parameter(Mandatory=$False, Position=3, ParameterSetName="Stop")][ValidateSet("Disable", "Automatic", "Manual", "Default")]
        [String] $StartType)

    $Service = Get-Service | Where-Object { $_ -Like "*$Name*" }
    Switch ($Action) {
        "Start" { 
            If ($Service.StartType -eq "Disabled") { 
                Set-Service $Service.Name -StartMode Manual 
                Start-Service $Service.Name
            }
        }
        "Stop" { 
            Switch ($StartType) {
                "Disable" {
                    Stop-Service $Service.Name -Force
                    Set-Service $Service.Name -StartupType Disabled
                }
                "Automatic" {
                    Stop-Service $Service.Name -Force
                    Set-Service $Service.Name -StartupType Automatic
                }
                "Manual" {
                    Stop-Service $Service.Name -Force
                    Set-Service $Service.Name -StartupType Manual
                }
                "Default" {
                    Stop-Service $Service.Name -Force
                }
            }
        }
    }
}